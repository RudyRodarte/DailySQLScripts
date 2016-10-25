use DBName
go

--	View the plan, along with a FreeProcCache command
--	SQL Server 2008+ only
SELECT  deqs.plan_handle ,
        deqs.sql_handle ,
        execText.text ,
		QP.query_plan ,
		'DBCC FREEPROCCACHE (' + CONVERT(VARCHAR(1000),deqs.plan_handle,1) + ');' as DropStatement
FROM    sys.dm_exec_query_stats deqs
        CROSS APPLY sys.dm_exec_sql_text(deqs.plan_handle) AS execText
		cross APPLY sys.dm_exec_query_plan(plan_handle) as QP
WHERE   execText.text LIKE '%SEARCH_STRING%'

--	Use Counts for plans
select	  CP.UseCounts
		, CP.Cacheobjtype
		, CP.Objtype
		, ST.[text]
from	sys.dm_exec_cached_plans as CP
		cross APPLY sys.dm_exec_sql_text(plan_handle) as ST
		cross APPLY sys.dm_exec_query_plan(plan_handle) as QP
where	ST.[text] LIKE '%SEARCH_STRING%'