# Exercise 1: Memory examination

## Step 1: Memory configuration

- Start SQL Server Management Studio
- Connect to the Server North and open a query window
  
* Check memory configuration

```sql
EXEC sp_configure 'show advanced options', 1;
RECONFIGURE;
EXEC sp_configure 'max server memory (MB)';
```

* Lower memory usage

```sql
EXEC sp_configure 'max server memory (MB)', 1024;--Default is 2147483647
RECONFIGURE;
```

* Empty data and procedure cache (not for production!)

```sql
CHECKPOINT;
DBCC DROPCLEANBUFFERS;
DBCC FREEPROCCACHE;
```

---

## Step 2: Inspect memory usage

* Look at process memory

```sql
SELECT 
  physical_memory_kb, 
  committed_kb, 
  committed_target_kb, 
  memory_utilization_percentage
FROM sys.dm_os_process_memory;
```

* Top 10 memory clerks

```sql
SELECT TOP (10)
  mc.type, 
  mc.memory_node_id, 
  pages_kb = mc.pages_kb, 
  virtual_memory_committed_kb = mc.virtual_memory_committed_kb
FROM sys.dm_os_memory_clerks AS mc
ORDER BY mc.pages_kb DESC;
```

---

## Step 3: Run an aggregation query in AdventureWorksDW

* Enable statistics

```sql
SET STATISTICS IO ON;
SET STATISTICS TIME ON;
```

* Run a standard query

```sql
USE AdventureWorksDW2019;
GO
SELECT 
    sc.EnglishProductSubcategoryName,
    t.SalesTerritoryCountry,
    SUM(f.SalesAmount) AS TotalSales
FROM FactInternetSales AS f
JOIN DimProduct AS p              ON f.ProductKey = p.ProductKey
JOIN DimProductSubcategory AS sc  ON p.ProductSubcategoryKey = sc.ProductSubcategoryKey
JOIN DimCustomer AS c             ON f.CustomerKey = c.CustomerKey
JOIN DimGeography AS g            ON c.GeographyKey = g.GeographyKey
JOIN DimSalesTerritory AS t       ON g.SalesTerritoryKey = t.SalesTerritoryKey
GROUP BY sc.EnglishProductSubcategoryName, t.SalesTerritoryCountry
ORDER BY SUM(f.SalesAmount) DESC;
```

* Force low memory grant to trigger spill

```sql
SELECT 
    sc.EnglishProductSubcategoryName,
    t.SalesTerritoryCountry,
    SUM(f.SalesAmount) AS TotalSales
FROM FactInternetSales AS f
JOIN DimProduct AS p              ON f.ProductKey = p.ProductKey
JOIN DimProductSubcategory AS sc  ON p.ProductSubcategoryKey = sc.ProductSubcategoryKey
JOIN DimCustomer AS c             ON f.CustomerKey = c.CustomerKey
JOIN DimGeography AS g            ON c.GeographyKey = g.GeographyKey
JOIN DimSalesTerritory AS t       ON g.SalesTerritoryKey = t.SalesTerritoryKey
GROUP BY sc.EnglishProductSubcategoryName, t.SalesTerritoryCountry
ORDER BY SUM(f.SalesAmount) DESC
OPTION (HASH GROUP, MAX_GRANT_PERCENT = 1);
```

---

## Step 4: Inspect memory grants and spills

* Look at memory grants

```sql
SELECT 
  DB_NAME(rs.database_id) AS dbname,
  mg.request_time, mg.grant_time,
  mg.requested_memory_kb, mg.granted_memory_kb, mg.max_used_memory_kb,
  rs.status, rs.command, rs.wait_type
FROM sys.dm_exec_query_memory_grants AS mg
JOIN sys.dm_exec_requests AS rs
  ON mg.session_id = rs.session_id
ORDER BY mg.request_time DESC;
```

* Tempdb usage

```sql
SELECT * FROM sys.dm_db_file_space_usage;
```

* Find queries with spills

```sql
SELECT TOP (20)
  qs.last_execution_time,
  qs.total_worker_time, qs.total_elapsed_time,
  qp.query_plan
FROM sys.dm_exec_query_stats AS qs
CROSS APPLY sys.dm_exec_query_plan(qs.plan_handle) AS qp
WHERE CAST(qp.query_plan AS NVARCHAR(MAX)) LIKE '%SpillToTempDb%'
ORDER BY qs.last_execution_time DESC;
```

---

## Step 5: Buffer pool growth (AdventureWorks)

* Clear cache

```sql
USE AdventureWorks2019;
GO
CHECKPOINT; 
DBCC DROPCLEANBUFFERS;
```

* Baseline buffer descriptors

```sql
SELECT DB_NAME(database_id) AS dbname, COUNT(*) AS pages
FROM sys.dm_os_buffer_descriptors
GROUP BY database_id
ORDER BY pages DESC;
```

* Read a larger table

```sql
SELECT COUNT(*) 
FROM Sales.SalesOrderDetail AS sod
JOIN Sales.SalesOrderHeader AS soh
  ON sod.SalesOrderID = soh.SalesOrderID
OPTION (MAXDOP 1);
```

* Inspect buffer descriptors again

```sql
SELECT DB_NAME(database_id) AS dbname, COUNT(*) AS pages
FROM sys.dm_os_buffer_descriptors
GROUP BY database_id
ORDER BY pages DESC;
```

---

## Step 6: Reset configuration

* Restore memory setting

```sql
EXEC sp_configure 'max server memory (MB)', 4096;
RECONFIGURE;
```

* Disable statistics

```sql
SET STATISTICS IO OFF;
SET STATISTICS TIME OFF;
```

---

👉 This way, participants follow a **step-by-step structured lab**, see **cause and effect** clearly, and practice **monitoring SQL Server memory usage**.

Would you like me to now generate this as a **PDF handout** with the steps nicely formatted for your students?

