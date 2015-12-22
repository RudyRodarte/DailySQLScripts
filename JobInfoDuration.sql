use msdb
go

--	Declare some variables
declare @StartDateChar varchar(10)
declare @EndDateChar varchar(10)
declare @StartDate datetime
declare @EndDate datetime

--	Declare date and time variables
--	For first query, the dates must be in the format yyyymmdd
set @StartDateChar = '20151214'
set @EndDateChar = '20151215'

--	For the second query, the dates are a standard datetime
set @StartDate = '2015-12-14'
set @EndDate = '2015-12-15'

--	Display job execution history and overall run time
select  j.name as 'JobName'
      , run_date
      , run_time
      , msdb.dbo.agent_datetime(run_date, run_time) as 'RunDateTime'
      , run_duration
      , ( ( run_duration / 10000 * 3600 + ( run_duration / 100 ) % 100 * 60 + run_duration % 100 + 31 ) / 60 ) as 'RunDurationMinutes'
from    msdb.dbo.sysjobs j
        inner join msdb.dbo.sysjobhistory h
            on j.job_id = h.job_id
where   j.enabled = 1  --Only Enabled Jobs
and		run_date >= @StartDateChar
and		run_date < @EndDateChar
order by JobName, RunDateTime desc


--	Display job execution history and detailed run time
--	broken down by steps. YoOu can also look up a specific job
select  j.name as 'JobName'
      , s.step_id as 'Step'
      , s.step_name as 'StepName'
      , msdb.dbo.agent_datetime(run_date, run_time) as 'RunDateTime'
      , ( ( run_duration / 10000 * 3600 + ( run_duration / 100 ) % 100 * 60 + run_duration % 100 + 31 ) / 60 ) as 'RunDurationMinutes'
from    msdb.dbo.sysjobs j
        inner join msdb.dbo.sysjobsteps s
            on j.job_id = s.job_id
        inner join msdb.dbo.sysjobhistory h
            on s.job_id = h.job_id
               and s.step_id = h.step_id
               and h.step_id <> 0
where   j.enabled = 1   --Only Enabled Jobs
--and		j.name = 'TestJob' --Uncomment to search for a single job
and		msdb.dbo.agent_datetime(run_date, run_time) >= @StartDate
and		msdb.dbo.agent_datetime(run_date, run_time) < @EndDate
order by JobName, s.step_id, RunDateTime desc
