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

*Open the plan → you should see a **Nested Loops** operator. If one of the inputs is very small, nested loops are used.*. 

## Step 3: Merge Join 

```sql
-- Merge Join requires ordered inputs; optimizer will add Sorts if needed
SELECT TOP (100) h.SalesOrderID, d.SalesOrderDetailID
FROM Sales.SalesOrderHeader AS h
INNER JOIN Sales.SalesOrderDetail AS d
  ON d.SalesOrderID = h.SalesOrderID
WHERE h.OrderDate >= '2013-07-01';
```

*Open the plan → you should see a **Merge Join** (with Sorts if necessary).Merge Join excels when both inputs are sorted and of similar size, enabling sequential scans, minimal memory, and predictable performance.*


## Step 4: Hash Match 

```sql
SELECT h.SalesOrderID, d.SalesOrderDetailID
FROM Sales.SalesOrderHeader AS h
INNER JOIN Sales.SalesOrderDetail AS d
  ON d.SalesOrderID = h.SalesOrderID
```

*Open the plan → you should see a **Hash Match (Join)**.Hash Join is chosen for large, unsorted inputs with an equality predicate. It builds a hash on the smaller input, then probes efficiently, avoiding sorts and random seeks.*

---

# Exercise 2: Plan warning (implicit conversion)

## Step 1: Reproduce a warning

* Enable Actual Execution Plan (Ctrl+M)

```sql
USE AdventureWorksDW; -- 
SELECT CAST(ProductKey AS char(200)) AS BigKey
FROM FactInternetSales
ORDER BY BigKey

```

**What to see:**
A yellow warning triangle on the **Seek/Scan** operator. In Properties/ToolTip you’ll find a predicate with `CONVERT_IMPLICIT(...)` and a warning like “Operator used tempdb to spill data during execution ...”

## Step 2: Fix the warning

```sql
USE AdventureWorksDW; -- 
SELECT CAST(ProductKey AS char(20)) AS BigKey--Use smaller row width
FROM FactInternetSales
ORDER BY BigKey
```

**Observation:** Still a warning: "Type conversion in expression (CONVERT(char(20),[AdventureWorksDW].[dbo].[FactInternetSales].[ProductKey],0)) may affect "CardinalityEstimate" in query plan choice".

```sql
USE AdventureWorksDW;
SELECT ProductKey   -- lämna som int
FROM dbo.FactInternetSales
ORDER BY ProductKey;
```
**Observation:** *Remove the conversion or live with the warning*


# Exercise 3: Batch mode over rowstore (AdventureWorksDW)

## Step 1: Setup (DW) and create a bigger rowset (temporary)

* Enable Actual Execution Plan (Ctrl+M)


```sql
USE AdventureWorksDW;
GO
```

-- Create a moderately larger rowstore set to reliably trigger batch mode
```sql
IF OBJECT_ID('tempdb..#fis') IS NOT NULL DROP TABLE #fis;
SELECT f.*
INTO #fis
FROM FactInternetSales AS f
CROSS APPLY (VALUES(1),(2),(3),(4)) v(n); -- ~4x rows, still quick to create
```

## Step 2: Try with SQL Server 2017

```sql
ALTER DATABASE [AdventureWorksDW] SET COMPATIBILITY_LEVEL = 140--SQL Server 2017
GO

SELECT CustomerKey, SUM(SalesAmount) AS TotalSales
FROM #fis
GROUP BY CustomerKey
```

**What to see:**
In the plan, key operators (e.g., **Hash Match (Aggregate)**, **Parallelism**) show **Actual Execution Mode = Row**. The operator icons have a small stacked “column” look in newer SSMS.

## Step 3: Contrast with batch mode


```sql
ALTER DATABASE [AdventureWorksDW] SET COMPATIBILITY_LEVEL = 150--SQL Server 2019
GO

SELECT CustomerKey, SUM(SalesAmount) AS TotalSales
FROM #fis
GROUP BY CustomerKey
```


**What to see:**
Operators now show **Actual Execution Mode = Batch**. You can compare both plans side-by-side.

## Step 4: Cleanup (optional)

```sql
DROP TABLE IF EXISTS #fis;
```
