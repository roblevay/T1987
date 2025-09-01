### Exercise 1: Diskspd

**Step 1: Download Diskspd**

- Create the folder **C:\Diskspd**
- Download **Diskspd.exe** from **https://github.com/roblevay/T1987** to the folder **C:\Diskspd**

**Step 2: Run Diskspd**

- Start a command prompt as Administrator
- Run the command **C:\diskspd\Diskspd.exe -b8K -d20 -h -L -o2 -t4 -r -w30 -c50M c:\diskspd\io.dat**

## Explanation of Parameters

- **`-b8K`**  
  Sets the block size used for I/O operations.  
  *Here: 8 KB per operation.*

- **`-d20`**  
  Specifies the test duration in seconds.  
  *Here: The test runs for 20 seconds.*

- **`-h`**  
  Enables *hardware write caching bypass*.  
  This means data is written directly to disk, bypassing the OS cache.

- **`-L`**  
  Enables latency measurements to collect statistics on I/O delays.

- **`-o2`**  
  Sets the number of outstanding I/O operations (Queue Depth).  
  *Here: 2 concurrent operations per thread.*

- **`-t4`**  
  Specifies the number of threads used for the test.  
  *Here: 4 threads.*

- **`-r`**  
  Configures the test to use random access instead of sequential access.

- **`-w30`**  
  Sets the write percentage in a mixed read/write workload.  
  *Here: 30% writes, 70% reads.*

- **`-c50M`**  
  Creates a 50 MB test file for the benchmark.

- **`c:\diskspd\io.dat`**  
  The file used to run the test.

---

## What Does This Test Do?

- Simulates an I/O workload with **8 KB random read/write operations**.  
- Runs the test for **20 seconds**.  
- Uses **4 threads** with **2 concurrent I/O operations per thread**.  
- Operates on a **50 MB test file**.  
- Mix of **30% writes and 70% reads**.  
- Collects latency statistics and bypasses hardware caching.

---

## Use Case

This test is useful to simulate a realistic workload on a disk, for example to measure performance for a database or an application that performs mixed read/write operations.


- In the results pane, look at the second result in the third column called Text. The message will be similar to:

```SQL Server detected 1 sockets with 1 cores per socket and 2 logical processors per socket, 2 total logical processors; using 2 logical processors based on SQL Server licensing. This is an informational message; no user action is required.```

- In the query window, run  -- SQL Server NUMA Node information  (Query 12). With alla likelihood there will be only one node (one row). You will see the number of logical processors, cpu_count

