use [master]
go

--	If a backup and/or restore is running, the script displays the estimated time to complete
--	the backup and/or restore operation on the server.
select  r.session_id
      , r.command
      , convert(numeric(6, 2), r.percent_complete) as [Percent Complete]
      , convert(varchar(20), dateadd(ms, r.estimated_completion_time, getdate()), 20) as [ETA Completion Time]
      , convert(numeric(10, 2), r.total_elapsed_time / 1000.0 / 60.0) as [Elapsed Min]
      , convert(numeric(10, 2), r.estimated_completion_time / 1000.0 / 60.0) as [ETA Min]
      , convert(numeric(10, 2), r.estimated_completion_time / 1000.0 / 60.0 / 60.0) as [ETA Hours]
      , convert(varchar(1000), ( select substring(text, r.statement_start_offset / 2, case when r.statement_end_offset = -1 then 1000
                                                                                           else ( r.statement_end_offset - r.statement_start_offset ) / 2
                                                                                      end)
                                 from   sys.dm_exec_sql_text(sql_handle)
                               ))
from    sys.dm_exec_requests r
where   command in ( 'RESTORE DATABASE', 'BACKUP DATABASE', 'BACKUP LOG' )