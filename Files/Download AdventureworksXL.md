- https://files.karaszi.com/rot/courses/AdventureworksDW2016_2019.zip


- Download the file to c:\Dbfiles\

- Install:

```sql
USE [master]
RESTORE DATABASE [AdventureworksDW] FROM  DISK = N'C:\Dbfiles\AdventureworksDW2016_2019.bak' 
WITH  FILE = 1,  NOUNLOAD,  REPLACE,  STATS = 5
GO
```

Also install AdventureWorks:
```sql
USE [master]
RESTORE DATABASE [Adventureworks] FROM  DISK = N'C:\Dbfiles\AdventureWorks2016.bak' 
WITH  FILE = 1,  NOUNLOAD,  REPLACE,  STATS = 5
GO

