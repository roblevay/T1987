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

Toppen! Här är den kompletta versionen med en **kort executive summary** allra överst, följt av rådata, tabell och förklaring:

```markdown
# Exercise 2: Interpret DiskSpd

## Executive Summary
The test sustained about **4,000 IOPS** with a throughput of ~31.5 MiB/s.  
Average latency was low (1–3 ms), but there were **occasional spikes up to 50 ms**.  
This indicates solid performance for typical workloads, with some variability in tail latency.

---

## Raw Results (Timespan 1)

**Actual test time:** 20.01s  
**Thread count:** 4  

### CPU Usage
```

## Core | CPU |  Usage |  User  | Kernel |  Idle

```
0|    0|   5.15%|   1.09%|   4.06%|  94.85%
0|    1|   2.73%|   0.78%|   1.95%|  97.27%
```

---

```
   avg.|   3.94%|   0.94%|   3.01%|  96.06%
```

```

### Total I/O
```

total: 661135360 bytes | 80705 I/Os | 31.51 MiB/s | 4033.18 IOPS | AvgLat 1.98 ms | StdDev 7.54 ms

```

### Read I/O
```

total: 462864384 bytes | 56502 I/Os | 22.06 MiB/s | 2823.65 IOPS | AvgLat 1.73 ms | StdDev 7.51 ms

```

### Write I/O
```

total: 198270976 bytes | 24203 I/Os |  9.45 MiB/s | 1209.53 IOPS | AvgLat 2.56 ms | StdDev 7.58 ms

```

### Latency Distribution
```

## Percentile | Read (ms) | Write (ms) | Total (ms)

50th    |    0.221  |    0.965   |    0.252
95th    |    0.495  |    2.693   |    1.508
99th    |   37.420  |   38.199   |   37.753
Max     |   54.102  |   54.818   |   54.818

```

---

## DiskSpd Results Summary

| Metric          | Reads            | Writes           | Total            |
|-----------------|------------------|------------------|------------------|
| **Throughput**  | ~22.1 MiB/s      | ~9.5 MiB/s       | ~31.5 MiB/s      |
| **IOPS**        | ~2,824 / second  | ~1,210 / second  | ~4,033 / second  |
| **Avg. Latency**| ~1.7 ms          | ~2.5 ms          | ~2.0 ms          |
| **Std. Dev.**   | ~7.5 ms          | ~7.6 ms          | ~7.5 ms          |

---

## Interpreting the Results

### Test Setup
- **Duration:** ~20 seconds  
- **Threads:** 4  
- **Workload:** 8 KB random I/O, 30% writes / 70% reads  
- **File:** 50 MB test file  

### CPU Usage
- Low CPU usage (2–5%).  
- Most cycles spent idle → workload is **I/O-bound**.  

### Total I/O
- Throughput ~31.5 MiB/s across 4 threads.  
- ~4,000 IOPS sustained.  
- Average latency ~2 ms.  
- Even thread distribution → no major imbalance.  

### Read vs Write Performance
- **Reads:** Faster and steadier (~1.7 ms avg).  
- **Writes:** Slower (~2.5 ms avg) and more variable.  

### Latency Distribution
- Majority of ops complete in <1 ms.  
- 95th percentile: reads ~0.5 ms, writes ~2.7 ms.  
- 99th percentile shows spikes up to ~37–54 ms → occasional long delays.  

### Summary
The disk delivers **~4,000 IOPS** with low average latency and a healthy read/write mix.  
However, **tail latency spikes** (tens of ms) appear under load, which could impact latency-sensitive applications (e.g. databases).  
Overall, performance is solid for mixed workloads, but monitoring is advised if strict latency SLAs are required.
```

---

Vill du att jag gör en ännu mer **komprimerad enradig slutsats** (typ “≈4k IOPS, 2 ms latency, risk för spikes upp till 50 ms”) för att använda i tabeller eller presentationsslides?
