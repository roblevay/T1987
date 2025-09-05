


# Exercise 1: Create Database, Filegroup, and Table



## Step 1: Create a new database

- If not already created, create the folder **C:\SQLData**
- Start **SQL Server Management Studio** and connect to the server **North**
- Open a new query window and run the folowing command to create the database **DemoFilegroupDB**

```sql
IF DB_ID('DemoFilegroupDB') IS NOT NULL
BEGIN
    ALTER DATABASE DemoFilegroupDB SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE DemoFilegroupDB;
END;
GO

CREATE DATABASE DemoFilegroupDB
ON PRIMARY (
    NAME = N'DemoFilegroupDB_Primary',
    FILENAME = N'C:\SQLData\DemoFilegroupDB_Primary.mdf',
    SIZE = 100MB, FILEGROWTH = 50MB
)
LOG ON (
    NAME = N'DemoFilegroupDB_Log',
    FILENAME = N'C:\SQLData\DemoFilegroupDB_Log.ldf',
    SIZE = 64MB, FILEGROWTH = 64MB
);
GO
````

---

## Step 2: Add a new filegroup

> A filegroup is a logical container for data files.

```sql
ALTER DATABASE DemoFilegroupDB
ADD FILEGROUP FG_ColdData;
GO
```

---

## Step 3: Add a file to the filegroup

> The file is physically stored on disk and associated with the new filegroup.

```sql
ALTER DATABASE DemoFilegroupDB
ADD FILE (
    NAME = N'DemoFilegroupDB_ColdData',
    FILENAME = N'C:\SQLData\DemoFilegroupDB_ColdData.ndf',
    SIZE = 200MB, FILEGROWTH = 100MB
) TO FILEGROUP FG_ColdData;
GO
```

---

## Step 4: Create a table in the new filegroup

> Use the `ON <filegroup>` clause to place the clustered index (and thus the table data) in the new filegroup.

```sql
USE DemoFilegroupDB;
GO

CREATE TABLE dbo.SalesArchive
(
    SalesOrderID   INT           NOT NULL,
    ProductID      INT           NOT NULL,
    OrderDate      DATE          NOT NULL,
    OrderQty       INT           NOT NULL,
    LineTotal      MONEY         NOT NULL,
    CONSTRAINT PK_SalesArchive PRIMARY KEY CLUSTERED (SalesOrderID, ProductID)
) ON FG_ColdData;
GO
```

---

## Step 5: (Optional) Create an index in PRIMARY

> Indexes can be placed in different filegroups than the table.

```sql
CREATE NONCLUSTERED INDEX IX_SalesArchive_OrderDate
ON dbo.SalesArchive(OrderDate)
ON [PRIMARY];
GO
```

---

## Step 6: Insert some data

> Populate the table with sample data.

```sql
;WITH n AS (
    SELECT TOP (100000)
        ROW_NUMBER() OVER (ORDER BY (SELECT 1)) AS rn
    FROM sys.all_objects a CROSS JOIN sys.all_objects b
)
INSERT dbo.SalesArchive (SalesOrderID, ProductID, OrderDate, OrderQty, LineTotal)
SELECT
    rn,
    (rn % 500) + 1,
    DATEADD(day, -(rn % 365), GETDATE()),
    (rn % 10) + 1,
    ((rn % 10) + 1) * 100.00
FROM n;
GO
```

---

## Step 7: Verify placement

> Use system views to check which filegroups and files the objects are stored in.

```sql
-- Show database files
SELECT file_id, name, type_desc, size * 8 / 1024 AS SizeMB, physical_name
FROM sys.database_files;

-- Show filegroup placement for the table
SELECT
    t.name AS TableName,
    i.name AS IndexName,
    i.type_desc AS IndexType,
    fg.name AS FilegroupName
FROM sys.tables t
JOIN sys.indexes i ON t.object_id = i.object_id
JOIN sys.filegroups fg ON i.data_space_id = fg.data_space_id
WHERE t.name = 'SalesArchive';
```

---

## Step 8: (Optional) Change the default filegroup

> If you want new tables to be created in the new filegroup by default:

```sql
ALTER DATABASE DemoFilegroupDB MODIFY FILEGROUP FG_ColdData DEFAULT;
```

To switch back:

```sql
ALTER DATABASE DemoFilegroupDB MODIFY FILEGROUP [PRIMARY] DEFAULT;
```


# Exercise 2: (optional) Database utilities from Tibor Karaszi

## Step 1: Install and use sp_dbinfo

- Install sp_dbinfo and get a list of all databases

[sp_dbinfo](https://karaszi.com/spdbinfo-database-space-usage-information)

## Step 1: Install and use sp_dbinfo

- Install sp_tableinfo 

[sp_tableinfo ](https://karaszi.com/spdbinfo-database-space-usage-information](https://karaszi.com/sptableinfo-list-tables-and-space-usage)

- Get a list of all the tables in the Adventureworks database

```sql
USE Adventureworks
EXEC sp_tableinfo
```

---



