-- This script will delete temp tables
if OBJECT_ID('tempdb..##Replication') is not null
begin
    Truncate table ##Replication
    drop table ##Replication
end
go

create table ##Replication (
	REC_ID	int identity(1,1) primary key clustered
	, Database_Name varchar(64)
	, Publication	varchar(64)
	, Article		varchar(64)
	, Subscriber	varchar(64)
	, DestinationDB	varchar(64)
)

EXEC sp_MSForEachDB 'Use ?;
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

select	@@servername as ServerName
		, *
from	##Replication
--where	Subscriber = 'SubServer'	--	Specify a subscriber server
order by DestinationDB, Subscriber, Article

--	Display the replicated database on the subscriber
--	and the actual name on the publisher
select   distinct DestinationDB
		, Database_Name
from	##Replication
order by DestinationDB

--	Indicate Non replicated on a specific server
select DISTINCT DestinationDB
from	##Replication
where	Subscriber = 'ServerNane'
order by DestinationDB

--	Display the replicated articles 
--	along with publication information,
--	source, and destination databases.
;with Rep as 
( select	@@servername as ServerName
		, *
from	##Replication
)
select distinct Rep.Article
	, Rep.Publication
	, Rep.Database_Name as SourceDB
	, Rep.DestinationDB
from Rep
order by Rep.Article
	, Rep.Publication
	, Rep.Database_Name
	, Rep.DestinationDB
