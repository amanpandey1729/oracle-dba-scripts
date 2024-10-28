-- Completed Incremental Backup Status for last 90 days

set lines 199 pages 999
col SESSION_KEY for a40
        col INPUT_TYPE for a20
        col STATUS for a20
        col START_TIME for a20
        col END_TIME for a20
        col OUTPUT_BYTES_DISPLAY for a30
        col TIME_TAKEN_DISPLAY for a30
        select
                   input_type,
                   status,
                   to_char(start_time,'yyyy-mm-dd hh24:mi') start_time,
                   to_char(end_time,'yyyy-mm-dd hh24:mi')   end_time,
                   output_bytes_display,
                   time_taken_display
        from v$rman_backup_job_details where status='COMPLETED' AND START_TIME >= sysdate -90 and INPUT_TYPE ='DB INCR'
        order by session_key asc;
		
-----------------------------------------------------------------------------------------------------------------------------------------------------------		
-----------------------------------------------------------------------------------------------------------------------------------------------------------		
-- Completed Archivelog Backup Status for last 90 days

set lines 199 pages 999
col SESSION_KEY for a40
        col INPUT_TYPE for a20
        col STATUS for a20
        col START_TIME for a20
        col END_TIME for a20
        col OUTPUT_BYTES_DISPLAY for a30
        col TIME_TAKEN_DISPLAY for a30
        select
                   input_type,
                   status,
                   to_char(start_time,'yyyy-mm-dd hh24:mi') start_time,
                   to_char(end_time,'yyyy-mm-dd hh24:mi')   end_time,
                   output_bytes_display,
                   time_taken_display
        from v$rman_backup_job_details where status='COMPLETED' AND START_TIME >= sysdate -90 and INPUT_TYPE ='ARCHIVELOG'
        order by session_key asc;

-----------------------------------------------------------------------------------------------------------------------------------------------------------		
-----------------------------------------------------------------------------------------------------------------------------------------------------------		


-- Completed Backups in last 30 days
		
set lines 199 pages 999
col SESSION_KEY for a40
        col INPUT_TYPE for a20
        col STATUS for a20
        col START_TIME for a20
        col END_TIME for a20
        col OUTPUT_BYTES_DISPLAY for a30
        col TIME_TAKEN_DISPLAY for a30
        select
                   input_type,
                   status,
                   to_char(start_time,'yyyy-mm-dd hh24:mi') start_time,
                   to_char(end_time,'yyyy-mm-dd hh24:mi')   end_time,
                   output_bytes_display,
                   time_taken_display
        from v$rman_backup_job_details where status='COMPLETED' and START_TIME >= sysdate - 30 
        order by session_key asc;		
		
-----------------------------------------------------------------------------------------------------------------------------------------------------------		
-----------------------------------------------------------------------------------------------------------------------------------------------------------		

-- Time Estimate for RMAN Backup Completion

SELECT SID, SERIAL#, CONTEXT, SOFAR, TOTALWORK,
ROUND(SOFAR/TOTALWORK*100,2) "%_COMPLETE", TIME_REMAINING
FROM V$SESSION_LONGOPS
WHERE OPNAME LIKE '%RMAN%'
AND TOTALWORK != 0
AND SOFAR <> TOTALWORK;

-----------------------------------------------------------------------------------------------------------------------------------------------------------		
-----------------------------------------------------------------------------------------------------------------------------------------------------------		

-- Detailed info on Backup Jobs

set lines 220
set pages 1000
col cf for 9,999
col df for 9,999
col elapsed_seconds heading "ELAPSED|SECONDS"
col i0 for 9,999
col i1 for 9,999
col l for 9,999
col output_mbytes for 9,999,999 heading "OUTPUT|MBYTES"
col session_recid for 999999 heading "SESSION|RECID"
col session_stamp for 99999999999 heading "SESSION|STAMP"
col status for a10 trunc
col time_taken_display for a10 heading "TIME|TAKEN"
col output_instance for 9999 heading "OUT|INST"
select
j.session_recid, j.session_stamp,
to_char(j.start_time, 'yyyy-mm-dd hh24:mi:ss') start_time,
to_char(j.end_time, 'yyyy-mm-dd hh24:mi:ss') end_time,
(j.output_bytes/1024/1024) output_mbytes, j.status, j.input_type,
decode(to_char(j.start_time, 'd'), 1, 'Sunday', 2, 'Monday',
3, 'Tuesday', 4, 'Wednesday',
5, 'Thursday', 6, 'Friday',
7, 'Saturday') dow,
j.elapsed_seconds, j.time_taken_display,
x.cf, x.df, x.i0, x.i1, x.l,
ro.inst_id output_instance
from V$RMAN_BACKUP_JOB_DETAILS j
left outer join (select
d.session_recid, d.session_stamp,
sum(case when d.controlfile_included = 'YES' then d.pieces else 0 end) CF,
sum(case when d.controlfile_included = 'NO'
and d.backup_type||d.incremental_level = 'D' then d.pieces else 0 end) DF,
sum(case when d.backup_type||d.incremental_level = 'D0' then d.pieces else 0 end) I0,
sum(case when d.backup_type||d.incremental_level = 'I1' then d.pieces else 0 end) I1,
sum(case when d.backup_type = 'L' then d.pieces else 0 end) L
from
V$BACKUP_SET_DETAILS d
join V$BACKUP_SET s on s.set_stamp = d.set_stamp and s.set_count = d.set_count
where s.input_file_scan_only = 'NO'
group by d.session_recid, d.session_stamp) x
on x.session_recid = j.session_recid and x.session_stamp = j.session_stamp
left outer join (select o.session_recid, o.session_stamp, min(inst_id) inst_id
from GV$RMAN_OUTPUT o
group by o.session_recid, o.session_stamp)
ro on ro.session_recid = j.session_recid and ro.session_stamp = j.session_stamp
where j.start_time > trunc(sysdate)-&NUMBER_OF_DAYS
order by j.start_time;

/* Few More Details for the above shared query:
	- CF = ControlFile
	- DF = Datafile
	- L0 = l0 backup
	- L1 = l1 backup
	- L  = Archivelog 
*/
