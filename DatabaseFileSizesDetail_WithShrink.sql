--	This script reports the free space in MB and Percent for database files
--	Be sure to change the the where clause to the database name, data, or log drive 

use master 
go

declare @DBInfo table
    (
      ServerName varchar(100)
    , DatabaseName varchar(100)
    , FileSizeMB int
    , FreeSpaceMB int
    , FreeSpacePct varchar(7)
    , LogicalFileName sysname
    , PhysicalFileName nvarchar(520)
    , Status sysname
    , Updateability sysname
    , RecoveryMode sysname
    , FreeSpacePages int
    , PollDate datetime
    )  

declare @command varchar(5000)  

select  @command = ' Use [' + '?' + '] SELECT  
@@servername as ServerName,  
' + '''' + '?' + '''' + ' AS DatabaseName,  
CAST(sysfiles.size/128.0 AS int) AS FileSize,
CAST(sysfiles.size/128.0 - CAST(FILEPROPERTY(sysfiles.name, ' + '''' + 'SpaceUsed' + '''' + ' ) AS int)/128.0 AS int) AS FreeSpaceMB,         
CAST(100 * (CAST (((sysfiles.size/128.0 -CAST(FILEPROPERTY(sysfiles.name,  
' + '''' + 'SpaceUsed' + '''' + ' ) AS int)/128.0)/(sysfiles.size/128.0))  
AS decimal(24,2))) AS varchar(8)) + ' + '''' + '%' + '''' + ' AS FreeSpacePct,
sysfiles.name AS LogicalFileName,
sysfiles.filename AS PhysicalFileName,
CONVERT(sysname,DatabasePropertyEx(''?'',''Status'')) AS Status,
CONVERT(sysname,DatabasePropertyEx(''?'',''Updateability'')) AS Updateability,
CONVERT(sysname,DatabasePropertyEx(''?'',''Recovery'')) AS RecoveryMode,
GETDATE() as PollDate 
FROM dbo.sysfiles '  

insert  into @DBInfo
        ( ServerName
        , DatabaseName
        , FileSizeMB
        , FreeSpaceMB
        , FreeSpacePct
        , LogicalFileName
        , PhysicalFileName
        , Status
        , Updateability
        , RecoveryMode
        , PollDate
        )
        exec sp_MSforeachdb @command  

select  ServerName
      , DatabaseName
      , FileSizeMB
      , FreeSpaceMB
      , FreeSpacePct
      , LogicalFileName
      , PhysicalFileName
      , Status
      , Updateability
      , RecoveryMode
      , PollDate
from    @DBInfo
--where   LogicalFileName like '%temp%'	--	Uncomment for TempDB files
where PhysicalFileName like 'L:%'		--	Uncomment for Log files
--where PhysicalFileName like 'R:%'		--	Uncomment for data files
--where databasename = 'Admin'		--	Uncomment for a specific database
order by DatabaseName desc

/*******************************************

--	427,955

use tempdb
go

--	Perform a checkpoint before the shrink
checkpoint
go

-- Shrink the log file as needed
-- use the NAME column from above
dbcc shrinkfile ('tempdev')
raiserror('File 00 Done',10,1) with nowait
dbcc shrinkfile ('tempdev2')
raiserror('File 02 Done',10,1) with nowait
dbcc shrinkfile ('tempdev3')
raiserror('File 03 Done',10,1) with nowait
dbcc shrinkfile ('tempdev4')
raiserror('File 04 Done',10,1) with nowait
dbcc shrinkfile ('tempdev5')
raiserror('File 05 Done',10,1) with nowait
dbcc shrinkfile ('tempdev6')
raiserror('File 06 Done',10,1) with nowait
dbcc shrinkfile ('tempdev7')
raiserror('File 07 Done',10,1) with nowait
dbcc shrinkfile ('tempdev8')
raiserror('File 08 Done',10,1) with nowait

-- Shrink the log file as needed
-- TRUNCATEONLY will free up anythign at the end of the file
-- without re-arranging anything inside of the file
dbcc shrinkfile ('tempdev',TRUNCATEONLY)
raiserror('File 00 Done',10,1) with nowait
dbcc shrinkfile ('tempdev2',TRUNCATEONLY)
raiserror('File 02 Done',10,1) with nowait
dbcc shrinkfile ('tempdev3',TRUNCATEONLY)
raiserror('File 03 Done',10,1) with nowait
dbcc shrinkfile ('tempdev4',TRUNCATEONLY)
raiserror('File 04 Done',10,1) with nowait
dbcc shrinkfile ('tempdev5',TRUNCATEONLY)
raiserror('File 05 Done',10,1) with nowait
dbcc shrinkfile ('tempdev6',TRUNCATEONLY)
raiserror('File 06 Done',10,1) with nowait
dbcc shrinkfile ('tempdev7',TRUNCATEONLY)
raiserror('File 07 Done',10,1) with nowait
dbcc shrinkfile ('tempdev8',TRUNCATEONLY)
raiserror('File 08 Done',10,1) with nowait

sp_whoisactive

*/
