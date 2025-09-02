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



## Step 2: Inspect memory usage

* Process memory (columns valid in 2019 & 2022)

```sql
SELECT 
  physical_memory_in_use_kb,
  large_page_allocations_kb,
  locked_page_allocations_kb,
  page_fault_count,
  memory_utilization_percentage,
  available_commit_limit_kb,
  process_physical_memory_low,
  process_virtual_memory_low
FROM sys.dm_os_process_memory;
```

| Column                              | Example Value | Explanation                                                                            |
| ----------------------------------- | ------------- | -------------------------------------------------------------------------------------- |
| **physical\_memory\_in\_use\_kb**   | 936,372       | Current RAM used by SQL Server process (\~915 MB).                                     |
| **large\_page\_allocations\_kb**    | 0             | Memory allocated with large pages (2 MB). Usually 0 unless specially configured.       |
| **locked\_page\_allocations\_kb**   | 0             | Memory locked in RAM (not pageable). Requires “Lock pages in memory” privilege.        |
| **page\_fault\_count**              | 285,727       | Number of times data was not in the working set and had to be fetched. Some is normal. |
| **memory\_utilization\_percentage** | 100           | Percentage of committed memory currently in use. 100% is normal.                       |
| **available\_commit\_limit\_kb**    | 15,338,232    | Memory still available to allocate (\~14.6 GB). Higher = plenty of headroom.           |
| **process\_physical\_memory\_low**  | 0             | Flag (1 = low). 0 means no physical memory pressure.                                   |
| **process\_virtual\_memory\_low**   | 0             | Flag (1 = low). 0 means no virtual memory pressure.                                    |


* Top memory clerks (works in 2019 & 2022)

```sql
SELECT TOP (10)
  mc.type, 
  mc.memory_node_id, 
  mc.pages_kb,
  mc.virtual_memory_committed_kb
FROM sys.dm_os_memory_clerks AS mc
ORDER BY mc.pages_kb DESC;
```

---

## Step 3: Run an aggregation in AdventureWorksDW

> Use the DW name that matches your install and uncomment one line:
>
> * `USE AdventureWorksDW2019;`  or
> * `USE AdventureWorksDW2022;`

* Enable statistics

```sql
SET STATISTICS IO ON;
SET STATISTICS TIME ON;
```

* Run a standard query

```sql
-- USE AdventureWorksDW2019;
-- USE AdventureWorksDW2022;
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

* Force a low memory grant to increase chance of spilling to tempdb

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
OPTION (HASH GROUP, MAX_GRANT_PERCENT = 1);  -- supported in 2019 & 2022
```

---

## Step 4: Inspect memory grants and spills

* Current/recent memory grants

```sql
SELECT 
  DB_NAME(rs.database_id) AS dbname,
  mg.request_time, 
  mg.grant_time,
  mg.requested_memory_kb, 
  mg.granted_memory_kb, 
  mg.required_memory_kb,
  mg.max_used_memory_kb,
  rs.status, 
  rs.command, 
  rs.wait_type
FROM sys.dm_exec_query_memory_grants AS mg
JOIN sys.dm_exec_requests AS rs
  ON mg.session_id = rs.session_id
ORDER BY mg.request_time DESC;
```

* Tempdb usage (query the DMV in tempdb context)

```sql
SELECT * 
FROM tempdb.sys.dm_db_file_space_usage;
```

* Find plans that reported spills

```sql
SELECT TOP (20)
  qs.last_execution_time,
  qs.total_worker_time, 
  qs.total_elapsed_time,
  qp.query_plan
FROM sys.dm_exec_query_stats AS qs
CROSS APPLY sys.dm_exec_query_plan(qs.plan_handle) AS qp
WHERE CAST(qp.query_plan AS NVARCHAR(MAX)) LIKE '%SpillToTempDb%'
ORDER BY qs.last_execution_time DESC;
```

---

## Step 5: Observe buffer pool growth (AdventureWorks OLTP)

> Use the OLTP DB name that matches your install and uncomment one line:
>
> * `USE AdventureWorks2019;`  or
> * `USE AdventureWorks2022;`

* Clear cache (test only)

```sql
-- USE AdventureWorks2019;
-- USE AdventureWorks2022;
GO
CHECKPOINT; 
DBCC DROPCLEANBUFFERS;
```

* Baseline: buffer descriptors per database

```sql
SELECT DB_NAME(database_id) AS dbname, COUNT(*) AS pages
FROM sys.dm_os_buffer_descriptors
GROUP BY database_id
ORDER BY pages DESC;
```

* Read a larger table to warm the cache

```sql
SELECT COUNT(*) 
FROM Sales.SalesOrderDetail AS sod
JOIN Sales.SalesOrderHeader AS soh
  ON sod.SalesOrderID = soh.SalesOrderID
OPTION (MAXDOP 1);
```

* Measure buffer descriptors again

```sql
SELECT DB_NAME(database_id) AS dbname, COUNT(*) AS pages
FROM sys.dm_os_buffer_descriptors
GROUP BY database_id
ORDER BY pages DESC;
```

---

## Step 6: Reset configuration

* Restore memory setting (example: 4096 MB or your standard)

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


