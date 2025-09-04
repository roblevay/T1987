# Exercise 1: Parameter sniffing 
## Step 1: Setup



```sql
--clear caches — **not for production**
DBCC FREEPROCCACHE;  -- not for production
DBCC DROPCLEANBUFFERS;  -- not for production

USE AdventureWorks;
GO

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

*You should see two IDs; **@Rare** returns very few rows, **@Common** returns many.*

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
EXEC dbo.GetDetailsByProduct @ProductID = @Rare;

-- 4b. Reuse the same plan for COMMON (now the same plan does MANY lookups = slow)
EXEC dbo.GetDetailsByProduct @ProductID = @Common;

SET STATISTICS IO OFF;
SET STATISTICS TIME OFF;
```

**What to observe:**

* Execution Plan for both calls is the **same** (reused).
* With **@Common**, you’ll see **many Key Lookups** and higher IO/Time; **Estimated vs Actual rows** on the Seek/Lookup will diverge.
* This is **parameter sniffing**: the plan compiled for a rare value is reused for a common value.

---

## Step 5: Quick fixes (two easy patterns)

### Fix A: Recompile per-execution (best demo)

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

-- Try again (compare IO/Time vs Step 4)
EXEC dbo.GetDetailsByProduct_Recompile @ProductID = @Rare;
EXEC dbo.GetDetailsByProduct_Recompile @ProductID = @Common;
```

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

