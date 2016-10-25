--	http://www.mssqltips.com/sqlservertip/1476/reading-the-sql-server-log-files-using-tsql/
--
--	sp_readerrorlog
--	
--	this procedure takes four parameters:
--	value of error log file you want to read: 0 = current, 1 = archive #1, 2 = archive #2, etc...
--	log file type: 1 or null = error log, 2 = sql agent log
--	search string 1: string one you want to search for
--	search string 2: string two you want to search for to further refine the results

--	any connection issues?
exec sp_readerrorlog 0, 1, 'connection' --	query the error log for a connection message
exec sp_readerrorlog 0, 2, 'connection' --	query the sql server error log for a connection message
exec sp_readerrorlog 0, 2, 'starting'	--	query the sql server error log for a start up message

--	was the system shut down?
exec sp_readerrorlog 1, 1, 'restart'	--	query the error log for a shutdown message
exec sp_readerrorlog 1, 2, 'restart'	--	query the sql server error log for a shutdown message

--	dump all of the current logs
exec sp_readerrorlog 0, 1 --	dump the current error log
exec sp_readerrorlog 0, 2 --	dump the current sql server error log

--	dump all of the previous logs
exec sp_readerrorlog 1, 1 --	dump the previous error log
exec sp_readerrorlog 1, 2 --	dump the previous sql server error log

--	what server and sql version are we on?
select @@servername
select @@version

--	get server up time in 2008
select	sqlserver_start_time
from	sys.dm_os_sys_info;

--	display when tempdb was created. 
--	this indicates when the database server was rebooted
--	because tempdb is recreated upon every reboot
select	  name
		, create_date
from	sys.databases
where	name = 'tempdb'
order by database_id

--	Cluster information
--	what node are we on? (cluster only)
select serverproperty('computernamephysicalnetbios') as [currentnodename] 

--	what nodes are on this cluster? 
select	* 
from	sys.dm_os_cluster_nodes 

-- SQL Server Services information (SQL Server 2014) (Query 8) (SQL Server Services Info) 
select  servicename
      , process_id
      , startup_type_desc
      , status_desc
      , last_startup_time
      , service_account
      , is_clustered
      , cluster_nodename
      , [filename]
from    sys.dm_server_services with ( nolock )
option  ( recompile );