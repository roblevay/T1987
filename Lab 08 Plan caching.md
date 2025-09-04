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
EXEC dbo.GetDetailsByProduct_Recompile @ProductID = 897;--Insert the rare product id from step 2 above
EXEC dbo.GetDetailsByProduct_Recompile @ProductID = 870;--Insert the common product id from step 2 above
```

Compare the execution time with the execution time in step 3

### Fix B: Compile for “typical” (ignore sniffed value)

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

EXEC dbo.GetDetailsByProduct_Unknown @ProductID = @Rare;
EXEC dbo.GetDetailsByProduct_Unknown @ProductID = @Common;
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

