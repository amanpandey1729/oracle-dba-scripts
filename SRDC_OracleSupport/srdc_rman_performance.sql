Rem
Rem $Header: tfa/src/v2/tfa_home/resources/sql/srdc_rman_performance.sql /main/10 2024/02/15 20:29:03 smuthuku Exp $
Rem
Rem srdc_rman_performance.sql
Rem
Rem Copyright (c) 2018, 2024, Oracle and/or its affiliates. 
Rem All rights reserved.
Rem
Rem    NAME
Rem      srdc_rman_performance.sql
Rem
Rem    DESCRIPTION
Rem      Called by dbrmanperf SRDC
Rem
Rem    NOTES
Rem      None
Rem
Rem    BEGIN SQL_FILE_METADATA
Rem    SQL_SOURCE_FILE: tfa/src/v2/tfa_home/resources/sql/srdc_rman_performance.sql
Rem    SQL_SHIPPED_FILE:
Rem    SQL_PHASE:
Rem    SQL_STARTUP_MODE: NORMAL
Rem    SQL_IGNORABLE_ERRORS: NONE
Rem    END SQL_FILE_METADATA
Rem
Rem    MODIFIED   (MM/DD/YY)
Rem    smuthuku    02/06/24 - ER 35214017
Rem    bvongray    08/05/21 - bug 32988384
Rem    bvongray    11/06/20 - SRDC Script updates
Rem    bvongray    09/25/20 - Script updates
Rem    xiaodowu    06/04/20 - Update script
Rem    xiaodowu    04/30/20 - Update script
Rem    xiaodowu    04/22/20 - Update script for RMAN related SRDC collections
Rem    xiaodowu    10/05/18 - Update script
Rem    xiaodowu    09/17/18 - Implement Enh 28659747: MODIFY SQL SCRIPT
Rem    xiaodowu    01/18/18 - For dbrmanperf SRDC collection
Rem    xiaodowu    01/18/18 - Created
Rem

@@?/rdbms/admin/sqlsessstart.sql

set echo off;
define SRDCNAME='RMAN_PERFORMANCE'
set markup html on spool on

set TERMOUT off;

COLUMN SRDCSPOOLNAME NOPRINT NEW_VALUE SRDCSPOOLNAME
select 'SRDC_'||upper('&&SRDCNAME')||'_'||upper(value)||'_'||
      to_char(sysdate,'YYYYMMDD_HH24MISS') SRDCSPOOLNAME from 
v$parameter where lower(name)='instance_name';
REM
spool &&SRDCSPOOLNAME..htm
Set heading off;
set feedback off;
select '+----------------------------------------------------+' from dual
union all
select '| Script version:  '||'01-Mar-2021' from dual
union all
select '| Diagnostic-Name: '||'&&SRDCNAME' from dual
union all
select '| Timestamp: '||
to_char(systimestamp,'YYYY-MM-DD HH24:MI:SS TZH:TZM') from dual
union all
select '| Machine: '||host_name from v$instance
union all
select '| Version: '||version from v$instance
union all
select '| DBName: '||name from v$database
union all
select '| Instance: '||instance_name from v$instance
union all
select '+----------------------------------------------------+' from dual
/
set heading on;
set pagesize 50000;
set echo on;
set feedback on;
Column session_id format 999999999 heading "SESS|ID"
Column session_serial# format 99999999 heading "SESS|SER|#"
Column event format a40
Column total_waits format 9,999,999,999 heading "TOTAL|TIME|WAITED|MICRO"
alter session set NLS_DATE_FORMAT='DD-MON-YYYY HH24MISS';

select sysdate from dual;
select decode(count(cell_path),0,'Non-Exadata','Exadata') "System" from v$cell;

SELECT sid, spid, client_info
FROM v$process p, v$session s
WHERE p.addr = s.paddr
AND client_info LIKE '%id=rman%';
select SID, START_TIME,TOTALWORK, sofar, (sofar/totalwork) * 100 done,
sysdate + TIME_REMAINING/3600/24 end_at
from v$session_longops
where totalwork > sofar
AND opname NOT LIKE '%aggregate%';

select inst_id, sid, CLIENT_INFO ch, seq#, event, state, wait_time_micro/1000000 seconds
from gv$session where program like '%rman%' and
wait_time = 0 and
not action is null;

Select session_id, session_serial#, Event, sum(time_waited) total_waits
From v$active_session_history
Where sample_time > sysdate - 1
And program like '%rman%'
And session_state='WAITING' And time_waited > 0
Group by session_id, session_serial#, Event
Order by session_id, session_serial#, total_waits desc;

SELECT set_count, device_type, type, filename,
buffer_size, buffer_count, open_time, close_time
FROM v$backup_async_io
where type != 'AGGREGATE'
ORDER BY set_count,type, open_time, close_time;

select device_type "Device", type, filename, 
open_time open, 
close_time close,
elapsed_time Elapsed, effective_bytes_per_second 
from v$backup_async_io
where close_time > sysdate-7
and type != 'AGGREGATE'
order by close_time desc;

SELECT set_count, device_type, type, filename, 
buffer_size, buffer_count, open_time, close_time 
FROM v$backup_sync_io
ORDER BY set_count,type, open_time, close_time;

select device_type "Device", type, filename, 
open_time open, 
close_time close,
elapsed_time Elapsed, effective_bytes_per_second 
from v$backup_sync_io
where close_time > sysdate-7
and type != 'AGGREGATE'
order by close_time desc;

REM Controlfile:
REM ==============

show parameter control_file_record_keep_time;
select * from v$controlfile_record_section;
REM This query gives the total records, used count and size of each controlfile section
select rownum, type, records_total, records_used, (record_size*records_total/1024/1024) "TOTAL-Mb" from v$controlfile_record_section;

COL in_sec FORMAT a10
COL out_sec FORMAT a10
COL TIME_TAKEN_DISPLAY FORMAT a10
COL in_size FORMAT a10
COL out_size FORMAT a10
SELECT SESSION_KEY,
OPTIMIZED,
COMPRESSION_RATIO,
INPUT_BYTES_PER_SEC_DISPLAY in_sec,
OUTPUT_BYTES_PER_SEC_DISPLAY out_sec,
TIME_TAKEN_DISPLAY
FROM V$RMAN_BACKUP_JOB_DETAILS
ORDER BY SESSION_KEY;

REM Incremental backups:
REM ====================

REM TO NOTE:
REM High %READ:Low %WRTN indicates a disk bottleneck - we are scanning many more blocks then we are writing: 
REM If this is an incremental backup use Block Change Tracking if available otherwise, a high filesperset value (use fewer channels), allowing many more files to be scanned in parallel by a single channel may give better throughput
REM %READ=%WRTN means we are writing out what we read in and this should be enough to stream the tape output. 
REM If not, how many channels have been allocated? Too many channels may result in fewer files processed per channel and this may not be enough to keep the tape streaming especially if the disk transfer rate is much lower than tape.

set numwidth 30;
select file# fno, used_change_tracking BCT, incremental_level INCR,
 datafile_blocks BLKS, block_size blksz, blocks_read READ,
 round((blocks_read/datafile_blocks) * 100,2) "%READ",
blocks WRTN, round((blocks/datafile_blocks)*100,2) "%WRTN", used_change_tracking,
completion_time
 from v$backup_datafile
 where incremental_level > 0 and file# != 0 and
completion_time >= (select max(completion_time)
 from v$backup_datafile
 where incremental_level=0)
 order by file#, completion_time;

select file#, avg(datafile_blocks), avg(blocks_read), (avg(blocks_read/datafile_blocks) * 100)
as "% read for backup"
from v$backup_datafile
where incremental_level > 0 and used_change_tracking = 'YES'
group by file# order by file#;

select b.file# fno,
 t.name TBS,
 b.completion_time,
 b.used_change_tracking BCT,
 b.incremental_level INCR,
 b.datafile_blocks BLKS,
 b.block_size blksz,
 b.blocks_read READ,
 round((b.blocks_read/b.datafile_blocks)* 100,2) "%READ",
 b.blocks WRTN,
 round((b.blocks/b.datafile_blocks)*100,2) "%WRTN"
 from v$backup_datafile b, v$datafile d, v$tablespace t
 where b.file# = d.file# and d.ts#=t.ts#
 order by b.file#, b.completion_time; 

select file#, incremental_level, incremental_change#, checkpoint_change#, completion_time
from v$backup_datafile where file# != 0 and
completion_time >= ((select max(completion_time) 
                    from v$backup_datafile 
                    where incremental_level=0)-1)
order by file#,completion_time;

SELECT a.ksppinm "Parameter", b.KSPPSTDF "Default Value",
       b.ksppstvl "Session Value", 
       c.ksppstvl "Instance Value",
       decode(bitand(a.ksppiflg/256,1),1,'TRUE','FALSE') IS_SESSION_MODIFIABLE, 
       decode(bitand(a.ksppiflg/65536,3),1,'IMMEDIATE',2,'DEFERRED',3,'IMMEDIATE','FALSE') IS_SYSTEM_MODIFIABLE
FROM   x$ksppi a,
       x$ksppcv b,
       x$ksppsv c
WHERE  a.indx = b.indx
AND    a.indx = c.indx
AND    a.ksppinm in ('_disable_primary_bitmap_switch','_bct_bitmaps_per_file');

REM Summary of backup jobs and the time it took.
REM =========================

COL STATUS FORMAT a9
COL hrs    FORMAT 999.99

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
where j.start_time > trunc(sysdate)-30
order by j.start_time;

set markup html off 
spool off
@?/rdbms/admin/sqlsessend.sql
exit;
