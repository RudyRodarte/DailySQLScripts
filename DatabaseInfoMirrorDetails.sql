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
	SELECT    db_name(sd.[database_id])              AS [Database_Name]
			, sd.mirroring_state                  AS [Mirror_State]
			, sd.mirroring_state_desc             AS [Mirror_State_Desc] 
			, sd.mirroring_partner_name           AS [Partner_Name]
			, sd.mirroring_role_desc              AS [Mirror_Role]  
			, sd.mirroring_safety_level_desc      AS [Safety_Level]
			, sd.mirroring_witness_name           AS [Witness]
			, sd.mirroring_connection_timeout AS [Timeout(sec)]
	FROM	sys.database_mirroring AS sd
	WHERE	mirroring_guid IS NOT null
)
--	Display all databases that have some mirroring component and the
--	partner information
select	db.[Database_Name]
		, M.[Partner_Name] as [Mirroring_Partner_Name]
		, M.[Mirror_State] 
		, M.[Mirror_Role]  
		, M.[Safety_Level]
		, M.[Witness]
		, M.[Timeout(sec)]
from	DB_Names as db
		inner join Mirroring as M
			on db.[Database_Name] = M.[Database_Name]			
order by db.Database_Name			