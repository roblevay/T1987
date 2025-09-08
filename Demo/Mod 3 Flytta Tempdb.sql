--Skapa först katalogen D:\SQLData i operativsystemet

USE master;
GO

ALTER DATABASE tempdb 
MODIFY FILE (NAME = tempdev, FILENAME = 'D:\SQLData\tempdev.mdf');

ALTER DATABASE tempdb 
MODIFY FILE (NAME = temp2, FILENAME = 'D:\SQLData\temp2.ndf');


ALTER DATABASE tempdb 
MODIFY FILE (NAME = templog, FILENAME = 'D:\SQLData\templog.ldf');
GO

--Starta nu om servern