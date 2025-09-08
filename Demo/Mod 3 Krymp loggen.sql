USE master
GO

DROP DATABASE IF EXISTS Newdb
GO
CREATE DATABASE Newdb
GO
BACKUP DATABASE newdb TO DISK='c:\backup\newdb.bak'--Backup av databasen, ska alltid göras

USE newdb
CREATE TABLE bigtable
(
bigcol	CHAR(8000)
)


INSERT INTO bigtable VALUES ('x')--ca 30 s
GO 10000

UPDATE bigtable SET bigcol='y' WHERE bigcol='x'--ca 20 s
UPDATE bigtable SET bigcol='x' WHERE bigcol='y'
GO 20
  
--Kolla logstorlek och utnyttjande
USE newdb;
SELECT
  total_log_size_mb       = CAST(total_log_size_in_bytes/1048576.0 AS decimal(19,2)),
  used_log_space_mb       = CAST(used_log_space_in_bytes/1048576.0  AS decimal(19,2)),
  free_log_space_mb       = CAST((total_log_size_in_bytes - used_log_space_in_bytes)/1048576.0 AS decimal(19,2)),
  used_log_space_percent  = used_log_space_in_percent
FROM sys.dm_db_log_space_usage;



--1. Ta backup ett par gånger av logfilen (om det behövs)
USE  master
GO
BACKUP LOG newdb TO DISK='c:\backup\newdb1.trn' WITH INIT--Backup 
BACKUP LOG newdb TO DISK='c:\backup\newdb2.trn' WITH INIT--Backup 


--Kolla logstorlek och utnyttjande
USE newdb;
SELECT
  total_log_size_mb       = CAST(total_log_size_in_bytes/1048576.0 AS decimal(19,2)),
  used_log_space_mb       = CAST(used_log_space_in_bytes/1048576.0  AS decimal(19,2)),
  free_log_space_mb       = CAST((total_log_size_in_bytes - used_log_space_in_bytes)/1048576.0 AS decimal(19,2)),
  used_log_space_percent  = used_log_space_in_percent
FROM sys.dm_db_log_space_usage;


-- 2. Krymp logfilen
USE Newdb
GO
DBCC SHRINKFILE (N'newdb_log' , EMPTYFILE)
GO



--Kolla logstorlek och utnyttjande
USE newdb;
SELECT
  total_log_size_mb       = CAST(total_log_size_in_bytes/1048576.0 AS decimal(19,2)),
  used_log_space_mb       = CAST(used_log_space_in_bytes/1048576.0  AS decimal(19,2)),
  free_log_space_mb       = CAST((total_log_size_in_bytes - used_log_space_in_bytes)/1048576.0 AS decimal(19,2)),
  used_log_space_percent  = used_log_space_in_percent
FROM sys.dm_db_log_space_usage;

--Om du inte är nöjd, gör om steg 1 och 2 ovan och kolla logstorlek och utnyttjande igen!

--Kolla varför inte töms (vid behov)
SELECT name, recovery_model_desc, log_reuse_wait_desc
FROM sys.databases
WHERE name = 'newdb';
