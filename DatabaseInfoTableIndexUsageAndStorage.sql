--	Execute on your target database

--	Display Table and index information
--	Including Seeks, Scans, look ups, updates, 
--	buffer pages. Still a work in progress.
;with DBTables as (
	select	DB_NAME() as DBName 
			, SCHEMA_NAME(so.schema_id) + '.' +  so.name as TableName
			, so.object_id as TableObjectID
	from	sys.objects as so
	where	so.[type] = 'U'
), ReadStats as (
	SELECT ObjectName      = object_schema_name(idx.object_id) + '.' + object_name(idx.object_id)
		, idx.object_id as  TableObjectID
		, IndexName      = COALESCE(idx.name, 'N/A')
		, IndexType      = CASE 
							WHEN is_unique = 1 THEN 'UNIQUE ' 
							ELSE '' END + idx.type_desc
		,User_Seeks     = us.user_seeks
		,User_Scans     = us.user_scans
		,User_Lookups   = us.user_lookups
		,User_Updates   = us.user_updates
	FROM	sys.indexes idx
			LEFT JOIN sys.dm_db_index_usage_stats us
				ON	idx.object_id = us.object_id
				AND idx.index_id = us.index_id
				AND us.database_id = db_id()
	WHERE	object_schema_name(idx.object_id) != 'sys'
	--ORDER BY us.user_seeks + us.user_scans + us.user_lookups DESC
), src AS
(
   SELECT
       [Object] = o.name,
	   [TableObjectID] = o.object_id,
       [Type] = o.type_desc,
       [Index] = COALESCE(i.name, 'N/A'),
       [Index_Type] = i.type_desc,
       p.[object_id],
       p.index_id,
       au.allocation_unit_id
   FROM
       sys.partitions AS p
   INNER JOIN
       sys.allocation_units AS au
       ON p.hobt_id = au.container_id
   INNER JOIN
       sys.objects AS o
       ON p.[object_id] = o.[object_id]
   INNER JOIN
       sys.indexes AS i
       ON o.[object_id] = i.[object_id]
       AND p.index_id = i.index_id
   WHERE
       au.[type] IN (1,2,3)
       AND o.is_ms_shipped = 0
), Alloc as (
SELECT
   src.[Object],
   src.[TableObjectID],
   src.[Type],
   src.[Index],
   src.Index_Type,
   buffer_pages = COUNT_BIG(b.page_id),
   buffer_mb = COUNT_BIG(b.page_id) / 128
FROM	src
		INNER JOIN sys.dm_os_buffer_descriptors AS b
			ON src.allocation_unit_id = b.allocation_unit_id
WHERE	b.database_id = DB_ID()
GROUP BY src.[Object], src.[TableObjectID], src.[Type], src.[Index],  src.Index_Type
)
select *
from	DBTables as DT
		left join ReadStats as RS
			on DT.TableObjectID = RS.TableObjectID
		left join Alloc as AC
			on AC.TableObjectID = RS.TableObjectID
			AND AC.[Index] = RS.IndexName
ORDER BY buffer_pages DESC