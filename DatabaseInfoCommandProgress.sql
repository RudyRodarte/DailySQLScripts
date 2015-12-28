--	http://www.codewrecks.com/blog/index.php/2012/02/07/check-progress-of-dbcc-checkdb/
--	Check the progress of a command

select  session_id
        , request_id
        , percent_complete
        , estimated_completion_time
        , dateadd(ms, estimated_completion_time, getdate()) as EstimatedEndTime
        , start_time
        , [status]
        , command
from    sys.dm_exec_requests
--where	session_id = 91	--	For a particular SPID	
--where	database_id = db_id()	--	For a particular database