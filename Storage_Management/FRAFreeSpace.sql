SELECT NAME, SPACE_LIMIT/1048576 "Total MB", SPACE_USED/1048576 "Used MB", (SPACE_LIMIT-SPACE_USED)/1048576 "Available MB", 
(SPACE_LIMIT-SPACE_USED)/SPACE_LIMIT "Available %" FROM  V$RECOVERY_FILE_DEST;

-- FRA Utilization for each file type
break on report
compute sum of percent_space_used on report
compute sum of percent_space_reclaimable on report
select file_type, percent_space_used, percent_space_reclaimable, number_of_files,con_id
from v$recovery_area_usage
order by 1;
