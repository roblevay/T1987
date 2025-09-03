# Exercise 1: Show join algorithms (Nested Loops, Merge Join, Hash Match)

## Step 1: Setup

* Start SQL Server Management Studio
* Connect to the Server North 
* Open a query window
* Enable Actual Execution Plan (Ctrl+M in SSMS)
* (Optional) reset plan cache — **not for production**

```sql
DBCC FREEPROCCACHE; -- not for production
USE AdventureWorks;
GO
```

## Step 2: Nested Loops Join 

```sql
-- Make the outer input 1 row → optimizer naturally prefers Nested Loops
SELECT h.SalesOrderID, d.SalesOrderDetailID
FROM Sales.SalesOrderHeader AS h
INNER JOIN Sales.SalesOrderDetail AS d
  ON d.SalesOrderID = h.SalesOrderID
WHERE h.SalesOrderID = 43659;   -- highly selective outer input (1 row)
```

*Open the plan → you should see a **Nested Loops** operator.*

## Step 3: Merge Join 

```sql
-- Merge Join requires ordered inputs; optimizer will add Sorts if needed
SELECT TOP (100) h.SalesOrderID, d.SalesOrderDetailID
FROM Sales.SalesOrderHeader AS h
INNER JOIN Sales.SalesOrderDetail AS d
  ON d.SalesOrderID = h.SalesOrderID
WHERE h.OrderDate >= '2013-07-01';
```

*Open the plan → you should see a **Merge Join** (with Sorts if necessary).*

## Step 4: Hash Match 

```sql
SELECT h.SalesOrderID, d.SalesOrderDetailID
FROM Sales.SalesOrderHeader AS h
INNER JOIN Sales.SalesOrderDetail AS d
  ON d.SalesOrderID = h.SalesOrderID
```

*Open the plan → you should see a **Hash Match (Join)**.*

---

# Exercise 2: Plan warning (implicit conversion)

## Step 1: Reproduce a warning

* Enable Actual Execution Plan (Ctrl+M)

```sql
USE AdventureWorks;
GO
DECLARE @ln varchar(50) = 'Anderson';  -- intentionally varchar
SELECT BusinessEntityID, LastName
FROM Person.Person
WHERE LastName = @ln;                  -- LastName is nvarchar → implicit convert
```

**What to see:**
A yellow warning triangle on the **Seek/Scan** operator. In Properties/ToolTip you’ll find a predicate with `CONVERT_IMPLICIT(...)` and a warning like “Type conversion in expression may affect Seek Plan.”

## Step 2: Fix the warning

```sql
-- Use matching data type (nvarchar) or an N-prefixed literal
DECLARE @ln nvarchar(50) = N'Anderson';
SELECT BusinessEntityID, LastName
FROM Person.Person
WHERE LastName = @ln;  -- warning disappears
```

**Observation:** Warning icon is gone; predicate no longer shows `CONVERT_IMPLICIT`.

---

# Exercise 3: Batch mode over rowstore (AdventureWorksDW)

## Step 1: Setup (DW) and create a bigger rowset (temporary)

* Enable Actual Execution Plan (Ctrl+M)
* Ensure batch mode on rowstore is allowed (default ON in SQL 2019)

```sql
USE AdventureWorksDW2019;
GO
ALTER DATABASE SCOPED CONFIGURATION SET BATCH_MODE_ON_ROWSTORE = ON;
GO

-- Create a moderately larger rowstore set to reliably trigger batch mode
IF OBJECT_ID('tempdb..#fis') IS NOT NULL DROP TABLE #fis;
SELECT f.*
INTO #fis
FROM FactInternetSales AS f
CROSS APPLY (VALUES(1),(2),(3),(4)) v(n); -- ~4x rows, still quick to create
```

## Step 2: Run an analytic aggregation (should use batch mode)

```sql
SELECT CustomerKey, SUM(SalesAmount) AS TotalSales
FROM #fis
GROUP BY CustomerKey
OPTION (MAXDOP 4);  -- parallel + analytic pattern helps batch mode
```

**What to see:**
In the plan, key operators (e.g., **Hash Match (Aggregate)**, **Parallelism**) show **Actual Execution Mode = Batch**. The operator icons have a small stacked “column” look in newer SSMS.

## Step 3: Contrast with row mode (turn batch off for this statement)

```sql
SELECT CustomerKey, SUM(SalesAmount) AS TotalSales
FROM #fis
GROUP BY CustomerKey
OPTION (MAXDOP 4, USE HINT('DISALLOW_BATCH_MODE'));
```

**What to see:**
Operators now show **Actual Execution Mode = Row**. You can compare both plans side-by-side.

## Step 4: Cleanup (optional)

```sql
DROP TABLE IF EXISTS #fis;
```

---

If you want, I can bundle these into a single handout file and add tiny “Observation” bullets under each step so students know exactly what to click in the plan (operator → Properties → Execution Mode, etc.).

