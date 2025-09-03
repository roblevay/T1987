
# Exercise 1: Simple statistics demo (always shows a difference)

## Step 1: Create data

* Create a table and fill with data

```sql
DBCC FREEPROCCACHE--Nollställ procedurcachen, inte i produktion!

USE AdventureWorks;
GO
IF OBJECT_ID('dbo.Lastnames','U') IS NOT NULL DROP TABLE dbo.Lastnames;
CREATE TABLE dbo.Lastnames(Lastname VARCHAR(50) NOT NULL);

-- Basdata
INSERT dbo.Lastnames(Lastname)
SELECT  LastName FROM Person.Person;
```

## Step 2: Create statistics


```sql
CREATE STATISTICS ST_Lastname ON dbo.Lastnames(Lastname) WITH FULLSCAN;
```

## Step 3: Run the query (before updating stats)


* Turn on **Include Actual Execution Plan** (Ctrl+M).
* Run the query and click on the **Execution Plan** tab
* Hover the mouse pointer over the **Table Scan** operator
* Run and compare **Estimated Number of Rows for all executions vs Actual Number of Rows for all executions** on the plan. They will probably not be the same.

```sql
SELECT COUNT(*) 
FROM dbo.Lastnames
WHERE Lastname = 'Musk';
```

## Step 4: Update statistics and run again

* Insert new values

```sql
INSERT dbo.Lastnames(Lastname) VALUES ('Musk');
GO 5
```

* Run the query again, estimated and actual are not the same

```sql
SELECT COUNT(*) 
FROM dbo.Lastnames
WHERE Lastname = 'Musk';
```

* Update statistics 

```sql
UPDATE STATISTICS  dbo.Lastnames ST_Lastname   WITH FULLSCAN;
```
* In Object Explorer, examine the statistics for ST_Lastname. There should be 5 Musks
* Run the query again, using OPTION RECOMPILE to get s fresh query plan

```sql
SELECT COUNT(*)
FROM dbo.Lastnames
WHERE Lastname = 'Musk';
OPTION (RECOMPILE);   -- Actual and estimated are the same
--Recompile is necessary to get a fresh query plan
```

## Step 5: (Optional) Clean up

```sql
-- DROP TABLE dbo.Lastnames
```


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


