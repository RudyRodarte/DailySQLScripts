use master
go

set nocount on
declare @Create_Date	datetime
declare @Days			int
declare @Hours			int
declare @Minutes		int 
declare @ServerName		nvarchar(50)

--	Set the Server name
set @ServerName = convert(varchar(50), serverproperty('SERVERNAME'))

--	Get the create date for tempdb, which is created upon server restarts
select  @Create_Date = crdate
from    sysdatabases
where   name = 'tempdb'

--	Perform some date math to get uptime figures in days, hours and minutes
set @Minutes = datediff(mi, @Create_Date, getdate())
set @Days = @Minutes / 1440
set @Hours = ( @Minutes / 60 ) - ( @Days * 24 )
set @Minutes = @Minutes - ( ( @Hours + ( @Days * 24 ) ) * 60 )

--	Display the uptime
raiserror('SQL Server: %s has been online for the past: %d Days - %d Hours - %d Minutes.',10,1,@ServerName,@Days,@Hours,@Minutes) with nowait

--	Notify if the agents are not running
if not exists ( select  1 from    master.sys.sysprocesses where   program_name = N'SQLAgent - Generic Refresher' )
begin
    raiserror('SQL Server is running but SQL Server Agent NOT running',10,1) with nowait
end
else
begin
    raiserror('SQL Server and SQL Server Agent both are running',10,1) with nowait
end