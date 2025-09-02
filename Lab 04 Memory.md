# Exercise 1: Memory examination



## Step 1: Memory configuration



- Check memory configuration
```sql
EXEC sp_configure 'show advanced options', 1;
RECONFIGURE;
EXEC sp_configure 'max server memory (MB)';
```

-- 2) Lower memory use
EXEC sp_configure 'max server memory (MB)', 1024;
RECONFIGURE;

-- 3) Empty data and procedure cache (nor for production
CHECKPOINT;
DBCC DROPCLEANBUFFERS;
DBCC FREEPROCCACHE;
