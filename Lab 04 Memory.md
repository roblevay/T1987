# Exercise 1: Memory examination

## Step 1: Memory configuration

- In Sql Server Configuration Manager, restart the SQL Server Service
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

| Clerk                          | Example Pages (KB) | Explanation                                                                                                                  |
| ------------------------------ | ------------------ | ---------------------------------------------------------------------------------------------------------------------------- |
| **MEMORYCLERK\_XTP**           | 243,344            | Minnesallokeringar för In-Memory OLTP (XTP) – hash-index, tabeller, versioner. Kan bli väldigt stort om du använder Hekaton. |
| **MEMORYCLERK\_SOSNODE**       | 51,336             | SQL Server OS (SQLOS) interna resurser: schemaläggare, trådar, anslutningar.                                                 |
| **MEMORYCLERK\_SQLBUFFERPOOL** | 33,408             | Buffer pool – huvudsakliga cachen för data- och indexsidor. Normalt största förbrukaren.                                     |
| **MEMORYCLERK\_SQLSTORENG**    | 31,728             | Storage engine-strukturer: lås, latches, transaktionsobjekt, metadata.                                                       |
| **MEMORYCLERK\_SQLGENERAL**    | 9,456              | Allmänna allokeringar av SQL Server-motorn som inte hör till en särskild subsystem.                                          |

---



---



---

## Step 3: Queries with or without memory grant



* Pick your DW database

```sql
-- USE AdventureWorksDW;

GO
```
- prepare an example table

```sql
IF OBJECT_ID('tempdb..#fis') IS NOT NULL DROP TABLE #fis;

SELECT * INTO #fis FROM FactInternetSales;
INSERT INTO #fis SELECT * FROM FactInternetSales;
INSERT INTO #fis SELECT * FROM FactInternetSales;
```

* From the **Query** menu, select **Include Actual Execution Plan**
* Run a sort (guarantees a memory grant)

## Step 3a: no memory grant

```sql
SELECT SalesOrderNumber
FROM FactInternetSales
ORDER BY SalesOrderNumber
OPTION (MAXDOP 1);
```
1. Open the **Actual Execution Plan**.
2. Right-click the **Select** operator 
3. In **Properties**, expand **MemoryGrantInfo** 

---

## Step 3b: Same query with a  memory grant (for contrast)

```sql
SELECT SalesOrderNumber
FROM #fis
ORDER BY SalesOrderNumber
OPTION (MAXDOP 1);
```

* Compare memory grant info between 3a and 3b!

---

## Step 4: Explanation of Memory Grant Info



   * **RequestedMemory** – what the query asked for
   * **GrantedMemory** – what SQL Server actually granted
   * **MaxUsedMemory** – what the query really used
   * **RequiredMemory** – minimum to start
   * **GrantWaitTime** – wait time for the grant (0 = no pressure)

Here’s a simple way to think about query memory in SQL Server.

When a query needs workspace (for things like **sorts** or **hash joins**), the optimizer estimates how much it will need and asks for it. That estimate shows up as **RequestedMemory**. SQL Server then checks what’s available and decides how much to actually give the query; that’s **GrantedMemory**. If there isn’t enough free memory to satisfy the request, the query may have to **wait**—the time it waits is **GrantWaitTime**. A wait of 0 means there was no memory pressure.

There’s also a floor: **RequiredMemory** is the minimum needed to even start. If SQL Server can’t grant at least this amount, the query won’t run.

During execution, SQL Server tracks what the query actually uses at peak. That’s **MaxUsedMemory**. It’s normal for **MaxUsedMemory** to be lower than **GrantedMemory**—the grant includes safety headroom to avoid running out mid-operation. If the grant is too small for the workload, the query may spill to tempdb and slow down; if it’s larger than needed, it’s safe but ties up memory briefly.

In short: *Request* (estimate), *Grant* (allocation), *Required* (minimum), *MaxUsed* (real peak), and *GrantWaitTime* (pressure signal).


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
EXEC sp_configure 'max server memory (MB)', 2147483647;
RECONFIGURE;
```

* Disable statistics

```sql
SET STATISTICS IO OFF;
SET STATISTICS TIME OFF;
```

---


