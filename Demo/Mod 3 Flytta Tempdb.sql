--Skapa först katalogen C:\SQLData i operativsystemet om den inte finns

USE master;
GO

ALTER DATABASE tempdb 
MODIFY FILE (NAME = tempdev, FILENAME = 'C:\SQLData\tempdev.mdf');

ALTER DATABASE tempdb 
MODIFY FILE (NAME = temp2, FILENAME = 'C:\SQLData\temp2.ndf');


ALTER DATABASE tempdb 
MODIFY FILE (NAME = templog, FILENAME = 'C:\SQLData\templog.ldf');
GO


--Starta nu om servern
