-- This script will delete temp tables
if OBJECT_ID('tempdb..##Replication') is not null
begin
    Truncate table ##Replication
    drop table ##Replication
end
go

--	Create a table to store replication information
create table ##Replication (
	REC_ID	int identity(1,1) primary key clustered
	, Database_Name varchar(128)
	, Publication	varchar(128)
	, Article		varchar(128)
	, Subscriber	varchar(128)
	, DestinationDB	varchar(128)
)

--	Query all of the databases for replicated articles
--	Insert the article details in a temp table
EXEC sp_MSForEachDB 'Use [?];
if exists(select 1 from sys.objects where object_id = object_id(''dbo.syssubscriptions''))
begin
	insert into ##Replication
	SELECT	  DB_NAME() 
			, pub.name AS [Publication]
			, art.name as [Article]
			, serv.name as [Subsriber]
			, sub.dest_db as [DestinationDB]
	FROM	dbo.syssubscriptions sub
			INNER JOIN sys.servers serv
				ON serv.server_id = sub.srvid
			INNER JOIN dbo.sysarticles art
				ON art.artid = sub.artid
			INNER JOIN dbo.syspublications pub
				ON pub.pubid = art.pubid
end
' ;

; with DB_NAMES
as (
	--	Get a list of all the database names
	--	Filter out Admin and system dbs
	select  name as [Database_Name]
	from	sys.[databases]
	where	database_id > 4
	AND		name <> 'Admin'
), Mirroring as (

	--	Get mirroring information
	SELECT   db_name(sd.[database_id])              AS [Database_Name]
          ,sd.mirroring_state                  AS [Mirror State]
          ,sd.mirroring_state_desc             AS [Mirror State Desc] 
          ,sd.mirroring_partner_name           AS [Partner_Name]
          ,sd.mirroring_role_desc              AS [Mirror Role]  
          ,sd.mirroring_safety_level_desc      AS [Safety Level]
          ,sd.mirroring_witness_name           AS [Witness]
          ,sd.mirroring_connection_timeout AS [Timeout(sec)]
    FROM sys.database_mirroring AS sd
    WHERE mirroring_guid IS NOT null
), Repl as (

	--	Get replicated database names
	--	Though a database objects can be replicated to 
	--	multiple locations, we only want to see if any 
	--	object is replicated
	select  distinct Database_Name
	from	##Replication
)
--	Display the database name
--	If the database is mirrored, display a 1 in [Mirrored]
--	If the database is replicated, display a 1 in [Replicated]
select	db.[Database_Name]
		, case when M.[Partner_Name] is not null
			then 1
			else 0 
			end as [Mirrored]
		, case when R.Database_Name is not null
			then 1
			else 0
			end as [Replicated]
from	DB_Names as db
		left join Mirroring as M
			on db.[Database_Name] = M.[Database_Name]
		left join Repl as R
			on db.[Database_Name] = R.[Database_Name]
order by db.Database_Name