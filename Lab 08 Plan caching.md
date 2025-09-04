# Exercise 1: Parameter sniffing 
## Step 1: Setup

* Start SQL Server Management Studio
* Connect to the Server North 
* Open a query window
* Enable Actual Execution Plan (Ctrl+M in SSMS)
*  reset plan cache — **not for production**

```sql
DBCC FREEPROCCACHE; -- not for production
DBCC DROPCLEANBUFFERS;-- not for production
USE AdventureWorks;
GO
```


```sql
-- Create an index ON ProductID WITHOUT INCLUDEs to force Key Lookups
IF NOT EXISTS (
    SELECT 1
    FROM sys.indexes
    WHERE object_id = OBJECT_ID('Sales.SalesOrderDetail')
      AND name = 'IX_Training_SOD_ProductID'
)
CREATE INDEX IX_Training_SOD_ProductID
ON Sales.SalesOrderDetail(ProductID);
```

---

## Step 2: Pick a “common” and a “rare” parameter

```sql
-- Find a very common ProductID and a rare ProductID
DECLARE @Common int, @Rare int;

SELECT TOP (1) @Common = ProductID
FROM Sales.SalesOrderDetail
GROUP BY ProductID
ORDER BY COUNT(*) DESC;  -- most rows

SELECT TOP (1) @Rare = ProductID
FROM Sales.SalesOrderDetail
GROUP BY ProductID
ORDER BY COUNT(*) ASC;   -- fewest rows

SELECT CommonProductID = @Common, RareProductID = @Rare;
```

*You should see two IDs; **@Rare** returns very few rows, **@Common** returns many. In my test, 870 is common and 897 rare*

---

## Step 3: Create a sniffable stored procedure

```sql
CREATE OR ALTER PROC dbo.GetDetailsByProduct
    @ProductID int
AS
BEGIN
    SET NOCOUNT ON;

    -- No hints: plan will compile on first execution for that parameter value
    SELECT SalesOrderDetailID, SalesOrderID, ProductID, OrderQty, UnitPrice
    FROM Sales.SalesOrderDetail
    WHERE ProductID = @ProductID;
END
GO
```

---

## Step 4: Demonstrate parameter sniffing

```sql
SET STATISTICS IO ON;
SET STATISTICS TIME ON;

-- 4a. Compile for RARE (fast plan: Nested Loops + many Key Lookups OK for few rows)
EXEC dbo.GetDetailsByProduct @ProductID = 897;--Insert the rare product id from step 2 above
```

Examine the execution plan. Very likely, a loop join will be used because of the few values returned. 

```sql
-- 4b. Reuse the same plan for COMMON (now the same plan does MANY lookups = slow)
EXEC dbo.GetDetailsByProduct @ProductID = 870;--Insert the common product id from step 2 above

SET STATISTICS IO OFF;
SET STATISTICS TIME OFF;
```

Examine the execution plan. The same execution plan will be used because of parameter sniffing. Make a not of the execution time.

---

## Step 5: Quick fixes (two easy patterns)

### Fix A: Recompile per-execution (best option)

* Create a procedure with recompile
```sql
CREATE OR ALTER PROC dbo.GetDetailsByProduct_Recompile
    @ProductID int
AS
BEGIN
    SET NOCOUNT ON;

    SELECT SalesOrderDetailID, SalesOrderID, ProductID, OrderQty, UnitPrice
    FROM Sales.SalesOrderDetail
    WHERE ProductID = @ProductID
    OPTION (RECOMPILE);  -- compile for the current parameter each time
END
GO
```
Now repeat the test from step 4, using the same values 

```sql
-- Try again
SET STATISTICS IO ON;
SET STATISTICS TIME ON;

EXEC dbo.GetDetailsByProduct_Recompile @ProductID = 897;--Insert the rare product id from step 2 above
EXEC dbo.GetDetailsByProduct_Recompile @ProductID = 870;--Insert the common product id from step 2 above

SET STATISTICS IO ON;
SET STATISTICS TIME ON;
```

Compare the execution plan and the execution time with the execution time in step 3 for the common value. Now, a clustered index scan should be used and the execution time should be shorter.

### Fix B: Compile for “typical” (ignore sniffed value)

Now, use the same method below
```sql
CREATE OR ALTER PROC dbo.GetDetailsByProduct_Unknown
    @ProductID int
AS
BEGIN
    SET NOCOUNT ON;

    SELECT SalesOrderDetailID, SalesOrderID, ProductID, OrderQty, UnitPrice
    FROM Sales.SalesOrderDetail
    WHERE ProductID = @ProductID
    OPTION (OPTIMIZE FOR UNKNOWN);  -- density-based plan (not tied to first param)
END
GO

EXEC dbo.GetDetailsByProduct_Unknown @ProductID = 897;--Insert the rare product id from step 2 above
EXEC dbo.GetDetailsByProduct_Unknown @ProductID = 870;--Insert the common product id from step 2 above

--Note: **Clustered Index Scan** is probably used for both executions
```

*Observation:*

* **RECOMPILE** optimizes per call (great for one-off OLTP lookups).
* **OPTIMIZE FOR UNKNOWN** chooses a “generic” plan that’s stable across parameters.

---

## Step 6: (Optional) Cleanup

```sql
DROP PROC IF EXISTS dbo.GetDetailsByProduct;
DROP PROC IF EXISTS dbo.GetDetailsByProduct_Recompile;
DROP PROC IF EXISTS dbo.GetDetailsByProduct_Unknown;
-- keep the index for future labs, or:
-- DROP INDEX IX_Training_SOD_ProductID ON Sales.SalesOrderDetail;
```



---

# Exercise 2: Query Store (capture, compare, force a plan)

## Step 1: Enable Query Store (AdventureWorks)

```sql
USE AdventureWorks;
GO
ALTER DATABASE AdventureWorks SET QUERY_STORE = ON;
ALTER DATABASE AdventureWorks SET QUERY_STORE (OPERATION_MODE = READ_WRITE);
```

*(Tip: Ensure **Actual Execution Plan** is enabled in SSMS for visual checks.)*

---

## Step 2: Create a parameter-sensitive proc

*  Create a small index to enable alternative plans
* 
```sql
IF NOT EXISTS (
  SELECT 1 FROM sys.indexes 
  WHERE object_id = OBJECT_ID('Sales.SalesOrderDetail')
    AND name = 'IX_Training_SOD_ProductID'
)
CREATE INDEX IX_Training_SOD_ProductID
ON Sales.SalesOrderDetail(ProductID);
```

* Find a rare and a common  product id in the Sales.SalesOrderDetail table

```sql
-- Find a common and a rare ProductID

SELECT Common=(SELECT TOP 1 ProductID
FROM Sales.SalesOrderDetail GROUP BY ProductID ORDER BY COUNT(*) DESC)--870 in my test

SELECT Rare=(SELECT TOP 1 ProductID
FROM Sales.SalesOrderDetail GROUP BY ProductID ORDER BY COUNT(*) ASC)--897 in my test
GO
```

* Make a not of these productids
* Create a procedure for test

```sql
CREATE OR ALTER PROC dbo.GetDetailsByProduct_QS @ProductID int AS
BEGIN
  SET NOCOUNT ON;
  SELECT SalesOrderDetailID, SalesOrderID, ProductID, OrderQty, UnitPrice
  FROM Sales.SalesOrderDetail
  WHERE ProductID = @ProductID;
END
GO
```

---

## Step 3: Produce two different plans for the same query

```sql
DBCC FREEPROCCACHE;  -- demo only

EXEC dbo.GetDetailsByProduct_QS @ProductID = 897 --Or whatever the product id for rare in step 2

EXEC sp_recompile 'dbo.GetDetailsByProduct_QS';       -- force new compile next time

EXEC dbo.GetDetailsByProduct_QS @ProductID =870  --Or whatever the product id for common in step 2
```

*Query Store now has **two plans** for the same query. You may verify that using **Actual Eexecution Plan***

---

## Step 4: Inspect captured plans in Query Store

```sql
-- List the plans for this stored procedure (fast overview)
SELECT 
  qsq.query_id, qsp.plan_id,
  rs.avg_duration * 1.0 / 1000 AS avg_duration_ms,
  rs.avg_logical_io_reads,
  qsp.is_forced_plan
FROM sys.query_store_query_text AS qst
JOIN sys.query_store_query AS qsq ON qst.query_text_id = qsq.query_text_id
JOIN sys.query_store_plan  AS qsp ON qsq.query_id = qsp.query_id
JOIN sys.query_store_runtime_stats AS rs ON qsp.plan_id = rs.plan_id
WHERE qsq.object_id = OBJECT_ID('dbo.GetDetailsByProduct_QS')
ORDER BY avg_duration_ms DESC;
```

*You should see the **same query\_id** with **two plan\_id** entries and different runtimes.*

---

## Step 5: Force the better plan

* Make note of the query id above
* In **Object Explorer**, expand **Adventureworks** and expand **Query Store**
* Under **Query Store**, double-click **Top Resource Consuming Queries**
* In the left window, select the query with the query id identified in step 4 above
* In the plan summary window, select the plan id with the lowest execution time and click **Force Plan**. Click **Yes to accept**
* 




**Test the effect (both calls should now use the forced plan):**

```sql
EXEC dbo.GetDetailsByProduct_QS @ProductID = 897 --Or whatever the product id for rare in step 2
EXEC dbo.GetDetailsByProduct_QS @ProductID =870  --Or whatever the product id for common in step 2
```

* In the Actual Execution Plan, check that the same plan is used for both

---

## Step 6: Unforce (clean up)

```sql
-- See current plans and which one is forced
SELECT qsq.query_id, qsp.plan_id, qsp.is_forced_plan
FROM sys.query_store_query AS qsq
JOIN sys.query_store_plan  AS qsp ON qsq.query_id = qsp.query_id
WHERE qsq.object_id = OBJECT_ID('dbo.GetDetailsByProduct_QS');

-- Unforce
EXEC sp_query_store_unforce_plan @query_id = <query_id>, @plan_id = <plan_id>;

-- (Optional) turn Query Store to read-only or off after the lab
-- ALTER DATABASE AdventureWorks SET QUERY_STORE (OPERATION_MODE = READ_ONLY);
-- ALTER DATABASE AdventureWorks SET QUERY_STORE = OFF;
```




