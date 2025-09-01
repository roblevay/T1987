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


### Exercise 1: Identify Version and Edition (20 min)

**Step 1: Using Object Explorer (GUI)**
- Open **SQL Server Management Studio (SSMS)**.
- Connect to your default instance (`North`).
- Right-click on your instance name in Object Explorer and select **Properties**.
- Note down the **Product version** and **Edition** from the General page.

**Step 2: Using T-SQL queries**
- Open a new query window in SSMS.
- Run these queries:
```sql
SELECT @@VERSION AS SQLVersion;
SELECT SERVERPROPERTY('Edition') AS Edition;
```
