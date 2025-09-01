### Exercise 1: CPU configuration

**Step 1: Download Glenn Berrys script**
Go to:  
[https://glennsqlperformance.com/resources/](https://glennsqlperformance.com/resources/)

- Download the latest script matching your SQL Server version (e.g., SQL Server 2022 Diagnostic Information Queries).
- Click on the downward painting arrow and then click Continue with only downloading or something similar.
- Open the file and run it. 

**Step 2: Find out processor info**

- In the results pane, look at the second result in the third column called Text. The message will be similar to:

```SQL Server detected 1 sockets with 1 cores per socket and 2 logical processors per socket, 2 total logical processors; using 2 logical processors based on SQL Server licensing. This is an informational message; no user action is required.```

- In the query window, run  -- SQL Server NUMA Node information  (Query 12). With alla likelihood there will be only one node (one row). You will see the number of logical processors, cpu_count

**Step 3: Processor affinity**

- In Management Studio, connect to your default instance (`North`).
- Right-click on your instance name in Object Explorer and select **Properties**.
- Click on the **Processors** tab
- Verify that the number of nodes and processors are the same as observed in step 2 above
- Deselect the **Automatically set processor affinity mask for all processors
- Check the check box for **Processsor Affinity** for **CPU0**
- Select **Script** and then **Script Action to New Query Window**
- The script should be the following
```sql
ALTER SERVER CONFIGURATION SET PROCESS AFFINITY CPU = 0
GO
```
-Close the Query Window

**Step 4: Cost threshold for parallellism**

- In Management Studio, connect to your default instance (`North`).
- Right-click on your instance name in Object Explorer and select **Properties**.
- Click on the **Advanced** tab
- Change the value of **Cost threshold for parallellism** to 2,meaning that many queries will be run in  parallell
- From the **Query** meny, select **Include Actual Execution Plan**
- Run the following query
```sql
SELECT *
FROM Sales.SalesOrderDetail
ORDER BY UnitPrice DESC
GO
```

- Look at the **Execution Plan**. It should contain parallelism since the cost for the query is around 8
- Change the value of **Cost threshold for parallellism** to **100**,meaning that almost all queries will be run in  parallell and run the query again. This time there will be nor parallellism
- To see the cost of a serial execution, run the following query:
- 
```sql
SELECT *
FROM AdventureWorks.Sales.SalesOrderDetail
ORDER BY UnitPrice ASC
OPTION (MAXDOP 1, RECOMPILE);
GO
```
- Note that the cost is higher with serical execution. The option RECOMPILE is used to avoid using the old query plan


### Exercise 2: Waiting stats


**Step 1: Locking wait stats**
- From Configuration Manager, restart your server and connect to your server in Management Studio
- Open a new query window in SSMS, Query 1.
- Run these queries:
```sql
USE tempdb;
IF OBJECT_ID('dbo.WaitLab') IS NOT NULL DROP TABLE dbo.WaitLab;
CREATE TABLE dbo.WaitLab(id INT PRIMARY KEY, pad CHAR(200) NOT NULL DEFAULT 'x');--Skapar och fyller upp en tabell för övningen
INSERT INTO dbo.WaitLab(id) SELECT TOP (1000) ROW_NUMBER() OVER (ORDER BY (SELECT 1)) FROM sys.all_objects;
GO

BEGIN TRAN;
UPDATE dbo.WaitLab SET pad = pad WHERE id = 500;  -- tar X-lås på raden/sidan
WAITFOR DELAY '00:02:00';  -- håll låset länge, i detta fall 2 minuter
ROLLBACK;  -- Rulla tillbaka
```

- Open a new query window in SSMS, Query 2
- - Run this query:
```sql
SELECT * FROM tempdb.dbo.WaitLab WITH (INDEX(1)) WHERE id = 500; -- behöver S, blockeras av X
```

- Open a new query window in SSMS, Query 3 
- - Run this query:
```sql
SELECT wt.session_id, wt.blocking_session_id, wt.wait_type, wt.wait_duration_ms   
FROM sys.dm_os_waiting_tasks AS wt
JOIN sys.dm_exec_sessions AS s ON s.session_id = wt.session_id AND s.is_user_process = 1--Only user processes

SELECT * FROM sys.dm_os_waiting_tasks
ORDER BY wait_duration_ms DESC--All processes, 
```
- Note that in the first query, with only user processes, the wait types should be **WAITFOR** as in the query and **LCK_M_S**. In the second query, around 10-15 bacground queries appear above the lock. That is normal. Close the query windows

**Step 1: CXPACKET och CXCONSUMER**
- From Configuration Manager, restart your server and connect to your server in Management Studio
- 
- Open a new query window in SSMS, Query 1.
- Run this query:
```sql
;WITH n AS (
  SELECT TOP (2000000) ROW_NUMBER() OVER (ORDER BY (SELECT 1)) AS rn
  FROM master..spt_values a CROSS JOIN master..spt_values b
)
SELECT TOP (1500000) rn, REPLICATE('x',400) AS pad
FROM n
ORDER BY pad
OPTION (MAXDOP 8, QUERYTRACEON 8649, RECOMPILE);
```

- Open a new query window in SSMS, Query 2
- - Run the same query:
```sql
;WITH n AS (
  SELECT TOP (2000000) ROW_NUMBER() OVER (ORDER BY (SELECT 1)) AS rn
  FROM master..spt_values a CROSS JOIN master..spt_values b
)
SELECT TOP (1500000) rn, REPLICATE('x',400) AS pad
FROM n
ORDER BY pad
OPTION (MAXDOP 8, QUERYTRACEON 8649, RECOMPILE);
```

- Open a new query window in SSMS, Query 3 
- - Run this query:
```sql
SELECT wt.session_id, wt.blocking_session_id, wt.wait_type, wt.wait_duration_ms   
FROM sys.dm_os_waiting_tasks AS wt
JOIN sys.dm_exec_sessions AS s ON s.session_id = wt.session_id AND s.is_user_process = 1--Only user processes

SELECT * FROM sys.dm_os_waiting_tasks
ORDER BY wait_duration_ms DESC--All processes, 
```
- You should be able to find CXPACKET waits. If not, run the queries again. Query1 and Query2 should take around 30 seconds to run, be sure to run Query 3 before too much time has passed!
