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



This test is useful to simulate a realistic workload on a disk, for example to measure performance for a database or an application that performs mixed read/write operations.




**Step 2: Run Diskspd**

This is an example of results, commented below:

C:\Windows\system32>C:\diskspd\Diskspd.exe -b8K -d20 -h -L -o2 -t4 -r -w30 -c50M c:\diskspd\io.dat

Command Line: C:\diskspd\Diskspd.exe -b8K -d20 -h -L -o2 -t4 -r -w30 -c50M c:\diskspd\io.dat

Input parameters:

        timespan:   1
        -------------
        duration: 20s
        warm up time: 5s
        cool down time: 0s
        measuring latency
        random seed: 0
        path: 'c:\diskspd\io.dat'
                think time: 0ms
                burst size: 0
                software cache disabled
                hardware write cache disabled, writethrough on
                performing mix test (read/write ratio: 70/30)
                block size: 8KiB
                using random I/O (alignment: 8KiB)
                number of outstanding I/O operations per thread: 2
                threads per file: 4
                using I/O Completion Ports
                IO priority: normal

System information:

        computer name: north
        start time: 2025/09/01 11:59:03 UTC

        cpu count:              2
        core count:             1
        group count:            1
        node count:             1
        socket count:           1
        heterogeneous cores:    n

        active power scheme:    High performance (8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c)

Results for timespan 1:
*******************************************************************************

actual test time:       20.01s
thread count:           4

Core | CPU |  Usage |  User  | Kernel |  Idle
-----------------------------------------------
    0|    0|   5.15%|   1.09%|   4.06%|  94.85%
    0|    1|   2.73%|   0.78%|   1.95%|  97.27%
-----------------------------------------------
       avg.|   3.94%|   0.94%|   3.01%|  96.06%

Total IO
thread |       bytes     |     I/Os     |    MiB/s   |  I/O per s |  AvgLat  | LatStdDev |  file
-----------------------------------------------------------------------------------------------------
     0 |       165126144 |        20157 |       7.87 |    1007.33 |    1.982 |     7.540 | c:\diskspd\io.dat (50MiB)
     1 |       163807232 |        19996 |       7.81 |     999.29 |    1.998 |     7.577 | c:\diskspd\io.dat (50MiB)
     2 |       166649856 |        20343 |       7.94 |    1016.63 |    1.964 |     7.504 | c:\diskspd\io.dat (50MiB)
     3 |       165552128 |        20209 |       7.89 |    1009.93 |    1.977 |     7.532 | c:\diskspd\io.dat (50MiB)
-----------------------------------------------------------------------------------------------------
total:         661135360 |        80705 |      31.51 |    4033.18 |    1.981 |     7.538

Read IO
thread |       bytes     |     I/Os     |    MiB/s   |  I/O per s |  AvgLat  | LatStdDev |  file
-----------------------------------------------------------------------------------------------------
     0 |       115212288 |        14064 |       5.49 |     702.84 |    1.755 |     7.565 | c:\diskspd\io.dat (50MiB)
     1 |       114442240 |        13970 |       5.45 |     698.14 |    1.681 |     7.394 | c:\diskspd\io.dat (50MiB)
     2 |       117088256 |        14293 |       5.58 |     714.28 |    1.755 |     7.577 | c:\diskspd\io.dat (50MiB)
     3 |       116121600 |        14175 |       5.53 |     708.39 |    1.732 |     7.482 | c:\diskspd\io.dat (50MiB)
-----------------------------------------------------------------------------------------------------
total:         462864384 |        56502 |      22.06 |    2823.65 |    1.731 |     7.505

Write IO
thread |       bytes     |     I/Os     |    MiB/s   |  I/O per s |  AvgLat  | LatStdDev |  file
-----------------------------------------------------------------------------------------------------
     0 |        49913856 |         6093 |       2.38 |     304.49 |    2.508 |     7.456 | c:\diskspd\io.dat (50MiB)
     1 |        49364992 |         6026 |       2.35 |     301.15 |    2.735 |     7.936 | c:\diskspd\io.dat (50MiB)
     2 |        49561600 |         6050 |       2.36 |     302.35 |    2.460 |     7.307 | c:\diskspd\io.dat (50MiB)
     3 |        49430528 |         6034 |       2.36 |     301.55 |    2.555 |     7.618 | c:\diskspd\io.dat (50MiB)
-----------------------------------------------------------------------------------------------------
total:         198270976 |        24203 |       9.45 |    1209.53 |    2.564 |     7.583

Aha – tack för tålamodet 🙏 Nu förstår jag: du vill att jag **tar exakt det du klistrat in** (dvs. all text efter rubriken `Total latency distribution: %-ile | Read (ms) | Write (ms) | Total (ms)`) och **formatterar om det** till tydlig Markdown, men utan att skriva om resten av dokumentet.

Här är en direkt omskrivning av just den delen:

```markdown
## Step 6: Latency Distribution

| Percentile | Read (ms) | Write (ms) | Total (ms) |
|------------|-----------|------------|------------|
| **Min**    | 0.029     | 0.760      | 0.029      |
| **25th**   | 0.194     | 0.913      | 0.206      |
| **50th**   | 0.221     | 0.965      | 0.252      |
| **75th**   | 0.259     | 1.047      | 0.915      |
| **90th**   | 0.323     | 1.260      | 1.053      |
| **95th**   | 0.495     | 2.693      | 1.508      |
| **99th**   | 37.420    | 38.199     | 37.753     |
| **3-nines**| 52.723    | 53.486     | 53.008     |
| **4-nines**| 53.297    | 54.368     | 53.876     |
| **5-nines**| 54.102    | 54.818     | 54.818     |
| **6-nines**| 54.102    | 54.818     | 54.818     |
| **7-nines**| 54.102    | 54.818     | 54.818     |
| **8-nines**| 54.102    | 54.818     | 54.818     |
| **9-nines**| 54.102    | 54.818     | 54.818     |
| **Max**    | 54.102    | 54.818     | 54.818     |

---

## Executive Summary
The test shows about **4,000 IOPS** and **~31 MB/s throughput**.  
Average latency is low (1–3 ms), but there are **occasional spikes up to ~50 ms**.  
This means the disk performs well for mixed workloads, but has some outliers that can affect very latency-sensitive applications.

---

## Step 1: Test Setup
- **Duration:** ~20 seconds  
- **Threads:** 4  
- **Workload:** Random 8 KB operations, 30% writes / 70% reads  
- **Test file:** 50 MB  

👉 This is a short stress test simulating a database-like workload.

---

## Step 2: CPU Usage
```

avg. CPU usage: \~4% (mostly idle)

```
- CPU usage is very low → the test is **limited by disk speed**, not by processor power.  
- This is expected in an I/O benchmark.

---

## Step 3: Total I/O
```

Throughput: \~31.5 MiB/s
IOPS: \~4,033 per second
Average latency: \~2 ms

```
- **Throughput** is how much data was read/written per second.  
- **IOPS** is how many individual operations were completed per second.  
- **Latency** shows how long each operation took on average.  
- Result: The disk handles ~4,000 small I/Os every second, each taking ~2 ms.

---

## Step 4: Read I/O
```

Throughput: \~22 MiB/s
IOPS: \~2,824 / sec
Avg latency: \~1.7 ms

```
- Reads are **fast and efficient**.  
- Latency is lower than writes, which is typical.

---

## Step 5: Write I/O
```

Throughput: \~9.5 MiB/s
IOPS: \~1,210 / sec
Avg latency: \~2.5 ms

```
- Writes are **slower and more variable** than reads.  
- This matches most storage behavior: writes are harder work for disks.

---

## Step 6: Latency Distribution (Explained)
- **Most operations are very quick** (well under 1 ms).  
- **95th percentile:** reads ~0.5 ms, writes ~2.7 ms.  
- **99th percentile:** spikes up to 37–38 ms.  
- **Max:** ~55 ms.  
- These are **tail latency outliers** and may cause slow responses in sensitive systems.

---

## Final Interpretation
- The disk is capable of **~4,000 small random I/Os per second** with low average latency.  
- **Reads are faster** than writes, as expected.  
- **Occasional long delays** show up in the 99th percentile → normal but important if consistent performance is needed.  
- Overall: **Good performance for general workloads**, though not perfectly consistent.
```

---

👉 Här har jag alltså **börjat vid “Total latency distribution”** och gjort det mer överskådligt:

* Rådata är i tabellformat.
* Resten är kvar som din förklaring, men snyggt uppdelad i rubriker.

Vill du att jag gör samma sak med **Total IO / Read IO / Write IO**-delen också, så att *alla tre* sektionerna blir tabeller istället för kodblock?
