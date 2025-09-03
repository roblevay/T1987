# Exercise 1: Inspect and update statistics

## Step 1: Create and inspect a statistic (histogram)

* Create a manual statistic on `LastName`, then inspect it.

```sql
USE AdventureWorks
GO
CREATE STATISTICS ST_Person_LastName ON Person.Person(LastName) WITH FULLSCAN;
DBCC SHOW_STATISTICS ('Person.Person', 'ST_Person_LastName') WITH STAT_HEADER, DENSITY_VECTOR, HISTOGRAM;
```

## Step 2: Run a selective query and compare estimates

* Turn on an estimated/actual plan and run a filter using the same column.

```sql
SET STATISTICS XML ON;  -- optional: to see estimates inline
SELECT COUNT(*) 
FROM Person.Person
WHERE LastName = 'Anderson';
SET STATISTICS XML OFF;
```

## Step 3: Update statistics and re-run

* Update the statistic and re-run the query to compare estimates.

```sql
UPDATE STATISTICS Person.Person ST_Person_LastName WITH FULLSCAN;
-- Re-run the SELECT above
```

---

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


