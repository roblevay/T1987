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
