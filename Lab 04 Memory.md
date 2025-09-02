# Exercise 1: Memory examination



## Step 1: Memory configuration

- Check memory configuration
```sql
EXEC sp_configure 'show advanced options', 1;
RECONFIGURE;
EXEC sp_configure 'max server memory (MB)';
```

- Lower memory usage
```sql
EXEC sp_configure 'max server memory (MB)', 1024;
RECONFIGURE;
```

```sql
- Empty data and procedure cache (nor for production
CHECKPOINT;
DBCC DROPCLEANBUFFERS;
DBCC FREEPROCCACHE;
```
