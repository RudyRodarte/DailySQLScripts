--	Displays a quick overview of the server
--	https://sqlserverperformance.wordpress.com
--	http://www.sqlskills.com/blogs/glenn/sql-server-diagnostic-information-queries-for-december-2015/ 
use master
go

--	Display the SQL Version
select  @@version
go

--	Display database information
select  @@servername as SERVER_NAME
      , name
      , state_desc
      , create_date
from    sys.databases
order by database_id
   
-- Windows information (SQL Server 2008 R2 SP1 or greater)
select  windows_release
      , windows_service_pack_level
      , windows_sku
      , os_language_version
from    sys.dm_os_windows_info
option  ( recompile );   

-- SQL Server Services information (SQL Server 2008 R2 SP1 or greater)
select  servicename
      , startup_type_desc
      , status_desc
      , last_startup_time
      , service_account
      , is_clustered
      , cluster_nodename
from    sys.dm_server_services
option  ( recompile );

--  Get logins that are connected and how many sessions they have 
select  login_name
      , count(session_id) as [session_count]
from    sys.dm_exec_sessions with ( nolock )
group by login_name
order by count(session_id) desc
option  ( recompile );
go

sp_who2 
go