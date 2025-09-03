
# Exercise 1: Simple statistics demo (always shows a difference)

## Step 1: Create skewed data

* Use a tiny table with one very rare value (1) and many zeros.

```sql
USE AdventureWorks 
GO
IF OBJECT_ID('dbo.StatsDemo','U') IS NOT NULL DROP TABLE dbo.StatsDemo;
CREATE TABLE dbo.StatsDemo(Value int NOT NULL);

-- 500,000 zeros (common value)
INSERT dbo.StatsDemo(Value)
SELECT TOP (500000) 0
FROM sys.all_objects a CROSS JOIN sys.all_objects b;
```

## Step 2: Create statistics



```sql
CREATE STATISTICS ST_Value ON dbo.StatsDemo(Value);
```

## Step 3: Run the query (before updating stats)

* Update the table
```sql
-- 1 row with value = 1 (rare value)
INSERT dbo.StatsDemo(Value) VALUES (1);
```

* Turn on **Include Actual Execution Plan** (Ctrl+M).
* Run and compare **Estimated vs Actual Number of Rows** on the plan.

```sql
SELECT COUNT(*)
FROM dbo.StatsDemo
WHERE Value = 1;   -- Actual = 1; Estimated will be very low/near 0
```

## Step 4: Update statistics and run again

* Now the histogram knows about value **1** → estimate becomes accurate.

```sql
UPDATE STATISTICS dbo.StatsDemo ST_Value WITH FULLSCAN;

SELECT COUNT(*)
FROM dbo.StatsDemo
WHERE Value = 1;   -- Actual = 1; Estimated ≈ 1 (matches)
```

## Step 5: (Optional) Clean up

```sql
-- DROP TABLE dbo.StatsDemo;
```

**Observation:** Före uppdatering missar statistiken den sällsynta “1”: Estimated ≪ 1.
Efter `WITH FULLSCAN` innehåller histogrammet värdet → Estimated ≈ 1. ✔️

# Exercise 2: Create a clustered index (from a heap)

## Step 1: Make a heap copy

* `SELECT INTO` creates a heap by default.

```sql
USE AdventureWorks2019;
GO
IF OBJECT_ID('dbo.PersonHeap') IS NOT NULL DROP TABLE dbo.PersonHeap;
SELECT BusinessEntityID, FirstName, LastName
INTO dbo.PersonHeap
FROM Person.Person;
```

## Step 2: Baseline query (heap scan likely)

```sql
SELECT *
FROM dbo.PersonHeap
WHERE BusinessEntityID = 1;
```

## Step 3: Create a clustered index and re-test

```sql
CREATE CLUSTERED INDEX CX_PersonHeap_BusinessEntityID
ON dbo.PersonHeap(BusinessEntityID);

-- Run again: should now be an efficient seek on the clustered key
SELECT *
FROM dbo.PersonHeap
WHERE BusinessEntityID = 1;
```

*(Cleanup optional)*

```sql
-- DROP TABLE dbo.PersonHeap;
```

---

# Exercise 3: Create a nonclustered index (covering a query)

## Step 1: Baseline query

* Typical OLTP lookup + projection.

```sql
USE AdventureWorks2019;
GO
SELECT SalesOrderID, OrderDate, TotalDue
FROM Sales.SalesOrderHeader
WHERE CustomerID = 11000
  AND OrderDate >= '2014-01-01';
```

## Step 2: Create a nonclustered index and re-run

* Key columns match the predicates; `INCLUDE` covers the SELECT list.

```sql
CREATE NONCLUSTERED INDEX IX_SOH_CustomerID_OrderDate
ON Sales.SalesOrderHeader(CustomerID, OrderDate)
INCLUDE (TotalDue);

-- Re-run the baseline query above
```

*(Tip: Check the actual plan—should switch from scan to seek and become “covered”.)*

---

# Exercise 4: Create and use a Columnstore index (DW)

## Step 1: Copy a fact table

* Work on a copy to keep original intact.

```sql
USE AdventureWorksDW2019;
GO
IF OBJECT_ID('dbo.FactInternetSales_CS') IS NOT NULL DROP TABLE dbo.FactInternetSales_CS;
SELECT *
INTO dbo.FactInternetSales_CS
FROM dbo.FactInternetSales;
```

## Step 2: Build a clustered Columnstore index

* Great for scans/aggregations on wide fact tables.

```sql
CREATE CLUSTERED COLUMNSTORE INDEX CCI_FactInternetSales_CS
ON dbo.FactInternetSales_CS;
```

## Step 3: Run an analytic query

* Verify the plan uses a Columnstore scan and benefits from compression/segment elimination.

```sql
SELECT OrderDateKey, SUM(SalesAmount) AS TotalSales
FROM dbo.FactInternetSales_CS
GROUP BY OrderDateKey
ORDER BY OrderDateKey;
```

*(Cleanup optional)*

```sql
-- DROP TABLE dbo.FactInternetSales_CS;
```


