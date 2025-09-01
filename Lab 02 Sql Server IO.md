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

Absolut! Då gör jag en ny version som är **mindre tekniskt tung** och mer **pedagogiskt uppdelad** – en slags ”guide till hur man läser DiskSpd-resultatet”. Du får rådata + förklaring sida vid sida.

```markdown
# Exercise 2: Interpret DiskSpd

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

## Step 6: Latency Distribution
```

Median (50th percentile): 0.2–1 ms
95th percentile: 0.5 ms (reads), 2.7 ms (writes)
99th percentile: 37–38 ms
Max: \~55 ms

```
- **Most operations are very quick** (well under 1 ms).  
- **Some operations take much longer** (tens of ms).  
- These rare outliers are called **tail latency** and may cause slow responses in sensitive systems.

---

## Final Interpretation
- The disk is capable of **~4,000 small random I/Os per second** with low average latency.  
- **Reads are faster** than writes, as expected.  
- **Occasional long delays** show up in the 99th percentile → this is normal but important if you need very predictable performance.  
- Overall: **Good performance for general workloads**, but not perfectly consistent.
```

---


