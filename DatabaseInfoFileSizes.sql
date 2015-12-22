use master
go

--	Drop temp tables
if exists (select * from tempdb.sys.all_objects where name like '%#dbsize%') 
begin
	truncate table #dbsize 
	drop table #dbsize 
end

if exists (select * from tempdb.sys.all_objects where name like '#logsize%') 
begin
	truncate table #logsize 
	drop table #logsize 
end

if exists (select * from tempdb.sys.all_objects where name like '%#dbfreesize%') 
begin
	truncate table #dbfreesize 
	drop table #dbfreesize 
END

if exists (select * from tempdb.sys.all_objects where name like '%#alldbstate%') 
begin
	truncate table #alldbstate  
	drop table #alldbstate  
end
go


--	Data file size

--	Create the table to capture data file size info
create table #dbsize (
		  Dbname			sysname
		, dbstatus			varchar(50)
		, Recovery_Model	varchar(40) default ('NA')
		, File_Size_MB		decimal(30,2) default (0)
		, Space_Used_MB		decimal(30,2) default (0)
		, Free_Space_MB		decimal(30,2) default (0)
) 
go 
  
--	Insert the data into #dbsize
insert into #dbsize(Dbname,dbstatus,Recovery_Model,File_Size_MB,Space_Used_MB,Free_Space_MB) 
exec sp_msforeachdb 
'use [?]; 
  select DB_NAME() AS DbName, 
    CONVERT(varchar(20),DatabasePropertyEx(''?'',''Status'')) ,  
    CONVERT(varchar(20),DatabasePropertyEx(''?'',''Recovery'')),  
sum(size)/128.0 AS File_Size_MB, 
sum(CAST(FILEPROPERTY(name, ''SpaceUsed'') AS INT))/128.0 as Space_Used_MB, 
SUM( size)/128.0 - sum(CAST(FILEPROPERTY(name,''SpaceUsed'') AS INT))/128.0 AS Free_Space_MB  
from sys.database_files  where type=0 group by type' 
go 
  
--	Log size

--	Create the table to capture log file size information
create table #logsize (
		  Dbname			sysname
		, Log_File_Size_MB	decimal(38,2) default (0)
		, Log_Space_Used_MB decimal(30,2) default (0)
		, Log_Free_Space_MB decimal(30,2) default (0)
) 
go 
  
--	Insert log file information into #logsize
insert into #logsize(Dbname,Log_File_Size_MB,Log_Space_Used_MB,Log_Free_Space_MB) 
exec sp_msforeachdb 
'use [?]; 
  select DB_NAME() AS DbName, 
sum(size)/128.0 AS Log_File_Size_MB, 
sum(CAST(FILEPROPERTY(name, ''SpaceUsed'') AS INT))/128.0 as Log_Space_Used_MB, 
SUM( size)/128.0 - sum(CAST(FILEPROPERTY(name,''SpaceUsed'') AS INT))/128.0 AS Log_Free_Space_MB  
from sys.database_files  where type=1 group by type' 
  
  
go 

--	Database Free Size 
--	Create the table to capture free space information
create table #dbfreesize (
	  name			sysname 
	, database_size	varchar(50)
	, Freespace		varchar(50)default (0.00)
) 
  
insert into #dbfreesize(name,database_size,Freespace) 
exec sp_msforeachdb 
'use [?];SELECT database_name = db_name() 
    ,database_size = ltrim(str((convert(DECIMAL(15, 2), dbsize) + convert(DECIMAL(15, 2), logsize)) * 8192 / 1048576, 15, 2) + ''MB'') 
    ,''unallocated space'' = ltrim(str(( 
                CASE  
                    WHEN dbsize >= reservedpages 
                        THEN (convert(DECIMAL(15, 2), dbsize) - convert(DECIMAL(15, 2), reservedpages)) * 8192 / 1048576 
                    ELSE 0 
                    END 
                ), 15, 2) + '' MB'') 
FROM ( 
    SELECT dbsize = sum(convert(BIGINT, CASE  
                    WHEN type = 0 
                        THEN size 
                    ELSE 0 
                    END)) 
        ,logsize = sum(convert(BIGINT, CASE  
                    WHEN type <> 0 
                        THEN size 
                    ELSE 0 
                    END)) 
    FROM sys.database_files 
) AS files 
,( 
    SELECT reservedpages = sum(a.total_pages) 
        ,usedpages = sum(a.used_pages) 
        ,pages = sum(CASE  
                WHEN it.internal_type IN ( 
                        202 
                        ,204 
                        ,211 
                        ,212 
                        ,213 
                        ,214 
                        ,215 
                        ,216 
                        ) 
                    THEN 0 
                WHEN a.type <> 1 
                    THEN a.used_pages 
                WHEN p.index_id < 2 
                    THEN a.data_pages 
                ELSE 0 
                END) 
    FROM sys.partitions p 
    INNER JOIN sys.allocation_units a 
        ON p.partition_id = a.container_id 
    LEFT JOIN sys.internal_tables it 
        ON p.object_id = it.object_id 
) AS partitions' 

--	Get information for all Databases 
--	Create the temp table
create table #alldbstate  (
	  dbname	sysname
	, DBstatus	varchar(55)
	, R_model	varchar(30)
	)    
  
insert into #alldbstate (dbname,DBstatus,R_model) 
select	  name
		, CONVERT(varchar(20),DATABASEPROPERTYEX(name,'status'))
		, recovery_model_desc 
from	sys.databases 
  
insert into #dbsize(Dbname,dbstatus,Recovery_Model) 
select	  dbname
		, dbstatus
		, R_model 
from	#alldbstate 
where	DBstatus <> 'online' 
  
insert into #logsize(Dbname) 
select	dbname 
from	#alldbstate 
where	DBstatus <> 'online' 
  
insert into #dbfreesize(name) 
select	dbname 
from	#alldbstate 
where	DBstatus <> 'online' 

--	Display the results  
select	  d.Dbname as DBName		
		, d.dbstatus as DBStatus
		, d.Recovery_Model
		, (File_Size_MB + log_File_Size_MB) as DBsize
		, d.File_Size_MB
		, d.Space_Used_MB
		, d.Free_Space_MB
		, l.Log_File_Size_MB
		, l.Log_Space_Used_MB
		, l.Log_Free_Space_MB		
		, 100.00 * (l.Log_Space_Used_MB / l.Log_File_Size_MB) as Log_Space_Used_Percent
		, fs.Freespace as DB_Freespace 
from	#dbsize as d 
		join #logsize as l  
			on d.Dbname = l.Dbname 
		join #dbfreesize as fs  
			on d.Dbname=fs.name 
order by d.Free_Space_MB desc
