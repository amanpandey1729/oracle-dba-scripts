PROMPT ########################################
PROMPT ####Check if Plan changed for sql_id####
PROMPT ########################################

set pagesize 1000
set linesize 200
col begin_interval_time for a20
col milliseconds_per_execution for 999999990.999
col rows_per_execution for 999999990.9
col buffer_gets_per_execution for 999999990.9
col disk_reads_per_execution for 999999990.9
break on begin_interval_time skip 1

select to_char(sysdate,'HH24-MI-MON-DD-YY') "Date" from v$instance;
spool sql_id_history..&Date.log

select distinct sql_id, plan_hash_value
from dba_hist_sqlstat dhs,
	( 
	select /*+ NO_MERGE */ MIN(snap_id) min_snap, MAX(snap_id) max_snap
	from dba_hist_snapshot ss
	where ss.begin_interval_time BETWEEN (sysdate - &No_of_Days) AND sysdate
	) s
where dhs.snap_id BETWEEN s.min_snap AND s.max_snap
and dhs.sql_id in ('&sql_id');


SELECT	
	to_char(s.begin_interval_time,'mm/dd hh24:mi') as begin_interval_time,
	ss.plan_hash_value,
	ss.execution_delta,
	CASE
	WHEN ss.execution_delta > 0
	THEN ss.elapsed_time_delta/ss.execution_delta/1000
	ELSE ss.elapsed_time_delta
	END AS milliseconds_per_execution,
	
	CASE 
	WHEN ss.execution_delta > 0
	THEN ss.rows_processed_delta/ss.execution_delta
	ELSE ss.rows_processed_delta
	END AS rows_per_execution,
	
	CASE
	WHEN ss.execution_delta > 0
	THEN ss.buffer_gets_delta/ss.execution_delta
	ELSE ss.buffer_gets_delta
	END AS buffer_gets_per_execution,
	
	CASE
	WHEN ss.execution_delta > 0
	THEN ss.disk_reads_delta/ss.execution_delta
	ELSE ss.disk_reads_delta
	END AS disk_reads_per_execution
FROM wrh$sqlstat ss
INNER JOIN wrm$_snapshot s ON s.snap_id=ss.snap_id
WHERE ss.sql_id='&sql_id'
AND ss.buffer_gets_delta > 0 
AND s.begin_interval_time between (sysdate - &No_of_Days) and sysdate
ORDER BY s.snap_id, ss.plan_hash_value;