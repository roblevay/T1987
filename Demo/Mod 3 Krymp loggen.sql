USE newdb
CREATE TABLE bigtable
(
bigcol	CHAR(8000)
)


INSERT INTO bigtable VALUES ('x')
GO 10000

UPDATE bigtable SET bigcol='y' WHERE bigcol='x'
UPDATE bigtable SET bigcol='x' WHERE bigcol='y'
GO 20

BACKUP DATABASE newdb TO DISK='c:\backup\newdb.bak'--Backup 
--Tac backup många gånger av logfilen
BACKUP LOG newdb TO DISK='c:\backup\newdb1.trn'--Backup 
BACKUP LOG newdb TO DISK='c:\backup\newdb2.trn'--Backup 
BACKUP LOG newdb TO DISK='c:\backup\newdb3.trn'--Backup 
BACKUP LOG newdb TO DISK='c:\backup\newdb4.trn'--Backup 
--Så många som behövs, 

--Krymp logfilen
USE [newdb]
GO
DBCC SHRINKFILE (N'newdb_log' , 20)--Realistiskt värde
GO
--Kolla varför inte töms
SELECT name, recovery_model_desc, log_reuse_wait_desc
FROM sys.databases
WHERE name = 'newdb';
