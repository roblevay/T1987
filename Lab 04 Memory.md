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

| Clerk                          | Example Pages (KB) | Explanation                                                                          |
| ------------------------------ | ------------------ | ------------------------------------------------------------------------------------ |
| **MEMORYCLERK\_SOSNODE**       | 40,776             | Memory used by SQL Server OS (internal scheduler, threads, connections).             |
| **MEMORYCLERK\_SQLBUFFERPOOL** | 33,816 / 45,272    | The buffer pool – main cache for data and index pages. Usually the largest consumer. |
| **MEMORYCLERK\_SQLSTORENG**    | 33,392 / 73,984    | Storage engine structures (locks, latches, transaction objects).                     |
| **CACHESTORE\_PHDR**           | 31,864             | Plan header cache – metadata for query plans.                                        |
| **MEMORYCLERK\_SQLGENERAL**    | 17,632             | General-purpose allocations by the SQL Server engine.                                |

---

Awesome — here are the updated steps **3a** and **3b** (simple, repeatable in SQL Server 2019 & 2022), plus the inspection step.

---

## Step 3a: Simple query that always gets a memory grant

* (Optional) enable stats

```sql
SET STATISTICS IO ON;
SET STATISTICS TIME ON;
```

* Pick your DW database

```sql
-- USE AdventureWorksDW2019;
-- USE AdventureWorksDW2022;
GO
```

* Run a sort (guarantees a memory grant)

```sql
SELECT SalesOrderNumber
FROM FactInternetSales
ORDER BY SalesOrderNumber
OPTION (MAXDOP 1);
```

> Make sure **Include Actual Execution Plan** (Ctrl+M) is ON in SSMS.

---

## Step 3b: Same query with a tiny memory grant (for contrast)

```sql
-- Same dataset and sort, but force a very small grant
SELECT SalesOrderNumber
FROM FactInternetSales
ORDER BY SalesOrderNumber
OPTION (MAX_GRANT_PERCENT = 1, MAXDOP 1);
```

> This typically shows a noticeably **smaller GrantedMemory** vs 3a.

---

## Step 4: Inspect the memory grant (where to click)

1. Open the **Actual Execution Plan**.
2. Click the **Select operator** (top of the plan).
3. In **Properties**, expand **MemoryGrantInfo** and compare these fields between **3a** and **3b**:

   * **RequestedMemory** – what the query asked for
   * **GrantedMemory** – what SQL Server actually granted
   * **MaxUsedMemory** – what the query really used
   * **RequiredMemory** – minimum to start
   * **GrantWaitTime** – wait time for the grant (0 = no pressure)

That’s it—quick to run, easy to explain, and it works every time.

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


