use master
go

--	Display back up information for a database server
--	https://www.mssqltips.com/sqlservertip/1601/script-to-retrieve-sql-server-database-backup-history-and-no-backups/ 
select  convert(char(100), serverproperty('Servername')) as Server
      , msdb.dbo.backupset.database_name
      , convert(varchar(10), msdb.dbo.backupset.backup_start_date, 120) as BACKUP_Date
      , msdb.dbo.backupset.backup_start_date
      , msdb.dbo.backupset.backup_finish_date
      , msdb.dbo.backupset.expiration_date
      , case msdb..backupset.type
          when 'D' then 'Database'
          when 'L' then 'Log'
        end as backup_type
      , msdb.dbo.backupset.backup_size
      , msdb.dbo.backupmediafamily.logical_device_name
      , msdb.dbo.backupmediafamily.physical_device_name
      , msdb.dbo.backupset.name as backupset_name
      , msdb.dbo.backupset.description
from    msdb.dbo.backupmediafamily
        inner join msdb.dbo.backupset
            on msdb.dbo.backupmediafamily.media_set_id = msdb.dbo.backupset.media_set_id
where   ( convert(datetime, msdb.dbo.backupset.backup_start_date, 102) >= getdate() - 700 )
        and msdb..backupset.type = 'D'
--	and	msdb.dbo.backupset.database_name = 'TCA'	--	Uncomment for specific database
--	and	msdb.dbo.backupset.backup_start_date > '2014-04-01'	--	Uncomment for date ranges
order by msdb.dbo.backupset.database_name
      , msdb.dbo.backupset.backup_finish_date desc