-- This script will delete temp tables
if OBJECT_ID('tempdb..##PROC_HISTORY') is not null
begin
    Truncate table ##PROC_HISTORY
    drop table ##PROC_HISTORY
end
go

create table ##PROC_HISTORY (
	  REC_ID				int identity(1,1) primary key clustered
	, Server_Name			varchar(255)
	, Database_Name			varchar(255)
	, [Schema_Name]			varchar(255)
	, [Stored_Procedure]	varchar(255)
	, Execution_Count		int
	, Collection_Time		datetime
)

insert into ##PROC_HISTORY(Server_Name, Database_Name, [Schema_Name], [Stored_Procedure], Execution_Count, Collection_Time)
SELECT	  @@Servername as Server_Name
		, DB_NAME(st.dbid) as Database_Name
		, OBJECT_SCHEMA_NAME(st.objectid,dbid) as [Schema_Name]
		, OBJECT_NAME(st.objectid,dbid) as [Stored_Procedure]
		, max(cp.usecounts) as Execution_count
		, getdate() as Collection_Time
FROM	sys.dm_exec_cached_plans cp
		CROSS APPLY sys.dm_exec_sql_text(cp.plan_handle) st
where	DB_NAME(st.dbid) is not null and cp.objtype = 'proc'
--and		db_name(st.dbid) = 'CAPS'	--	Target a particular database
group by cp.plan_handle, DB_NAME(st.dbid),
OBJECT_SCHEMA_NAME(objectid,st.dbid), 
OBJECT_NAME(objectid,st.dbid) 
order by max(cp.usecounts)

select	Server_Name
		, Database_Name
		, [Schema_Name]
		, Stored_Procedure
		, Execution_Count
		, Collection_Time
from	##PROC_HISTORY
where	Stored_Procedure not like 'sp_ms%'	--	Exclude replication procedures
--AND		Database_Name not in  ('Admin')	--	Exclude these databases
order by Database_Name, Stored_Procedure

/*
select	*
from	##PROC_HISTORY
where	Stored_Procedure not like 'sp_ms%'
--AND		Database_Name in  ('DfaSys2', 'Dimensional', 'MonthEnd', 'Orders', 'Returns', 'Trading_Algorithm')
order by Database_Name, Execution_Count desc

select	*
from	##PROC_HISTORY
where	Stored_Procedure not like 'sp_ms%'
AND		Database_Name not in  ('master', 'msdb')
order by Database_Name, Stored_Procedure

select	*
from	##PROC_HISTORY
where	Stored_Procedure not like 'sp_ms%'
AND		Database_Name = 'CAPS'
order by Database_Name, Stored_Procedure


*/