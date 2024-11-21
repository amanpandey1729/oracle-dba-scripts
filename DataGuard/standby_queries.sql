
set lines 1221 pages 999
ALTER SESSION SET NLS_DATE_FORMAT = 'DD-MM-YYYY HH24:MI:SS';
SELECT ARCH.FIRST_TIME as PROD_ARCH_DATE,APPL.FIRST_TIME as APPL_Last_Date,ARCH.THREAD# "Thread", ARCH.SEQUENCE# "Last Sequence Received", APPL.SEQUENCE# "Last Sequence Applied", (ARCH.SEQUENCE# - APPL.SEQUENCE#) "Difference"
FROM (SELECT FIRST_TIME,THREAD# ,SEQUENCE# FROM V$ARCHIVED_LOG WHERE (THREAD#,FIRST_TIME ) IN (SELECT THREAD#,MAX(FIRST_TIME) FROM V$ARCHIVED_LOG GROUP BY THREAD#)) ARCH,
(SELECT FIRST_TIME,THREAD# ,SEQUENCE# FROM V$LOG_HISTORY WHERE (THREAD#,FIRST_TIME ) IN (SELECT THREAD#,MAX(FIRST_TIME) FROM V$LOG_HISTORY GROUP BY THREAD#)) APPL
WHERE ARCH.THREAD# = APPL.THREAD# ORDER BY 1;

set line 200
col HOST_NAME for a15
col "UP TIME" for a25
col DATABASE_STATUS for a10
col name for a10
col INSTANCE_NAME for a10
col OPEN_MODE for a20
col DATABASE_ROLE for a20
col LOGINS for a10
set echo off
set feedback off
set numformat 999999999999999
set trim on
set trims on

column timecol new_value tstamp
column spool_extension new_value suffix
select to_char(sysdate,'Mondd_hhmi') timecol from sys.dual;
column output new_value dbname
select value || '_' output from v$parameter where name = 'db_name';

-- Output the results to this file

spool dg_Standby_diag_&&dbname&&tstamp

show user
select systimestamp from dual;

Prompt ***************************************************************************
Prompt Check Instance Role and uptime ...........
Prompt ***************************************************************************
select name,INSTANCE_NAME,OPEN_MODE,HOST_NAME,DATABASE_STATUS,DATABASE_ROLE,CONTROLFILE_TYPE,logins,PROTECTION_MODE,to_char(STARTUP_TIME,'DD-MON-YYYY HH24:MI:SS') "UP TIME", floor(sysdate-startup_time) DAYS from v$database,v$instance;

select to_char(startup_time, 'DD-MM-YYYY HH24:MI:SS'),floor(sysdate-startup_time) DAYS from v$Instance;

Prompt ***************************************************************************
Prompt Check for standby sync GAP ..........
Prompt ***************************************************************************

SELECT INST_NAME,LOG_ARCHIVED, LOG_APPLIED, TIME_APPLIED,  LOG_ARCHIVED - LOG_APPLIED LOG_GAP FROM
  (SELECT   INST_ID, INSTANCE_NAME INST_NAME, HOST_NAME  FROM GV$INSTANCE ORDER BY INST_ID) NAME,  (SELECT   INST_ID,
  PROTECTION_MODE, SYNCHRONIZATION_STATUS FROM GV$ARCHIVE_DEST_STATUS WHERE DEST_ID = 2 ORDER BY INST_ID) STAT,
             (SELECT   THREAD#, MAX (SEQUENCE#) LOG_ARCHIVED FROM GV$ARCHIVED_LOG WHERE DEST_ID = 1
 AND ARCHIVED = 'YES' AND RESETLOGS_ID = (SELECT MAX (RESETLOGS_ID) FROM GV$ARCHIVED_LOG  WHERE DEST_ID = 1
AND ARCHIVED = 'YES')  GROUP BY THREAD# ORDER BY THREAD#) ARCH, (SELECT   THREAD#,MAX (SEQUENCE#) LOG_APPLIED,
TO_CHAR (MAX (COMPLETION_TIME),  'DD-Mon, HH24:MI:SS') TIME_APPLIED FROM GV$ARCHIVED_LOG  WHERE DEST_ID = 2 AND APPLIED = 'YES'
AND RESETLOGS_ID = (SELECT MAX (RESETLOGS_ID) FROM GV$ARCHIVED_LOG  WHERE DEST_ID = 1 AND ARCHIVED = 'YES') GROUP BY THREAD#
              ORDER BY THREAD#) APPL  WHERE NAME.INST_ID = STAT.INST_ID AND NAME.INST_ID = ARCH.THREAD# AND NAME.INST_ID = APPL.THREAD#;


Prompt ***************************************************************************
Prompt Standby Relogs...........
Prompt ***************************************************************************
set lines 200 pages 999
col member format a70
select st.group#
, st.sequence#
, ceil(st.bytes / 1048576) mb
, lf.member
,TYPE
from v$standby_log st
, v$logfile lf
where st.group# = lf.group#;


Prompt ***************************************************************************
Prompt Relogs and standby redo details..........
Prompt ***************************************************************************
set line 200
col MEMBER for a50
col "In Mb" for 9999999
col GROUP# for 999
col THREAD# for 999
col STATUS for a10
col MEMBERS for 999
select l.GROUP#, l.THREAD#,l.MEMBERS,lf.MEMBER,l.archived,l.bytes/1024/1024 "In Mb",l.STATUS,l.SEQUENCE#,lf.TYPE,lf.STATUS
from  v$log l,v$logfile lf
where l.GROUP#=lf.GROUP#
order by 1;

Prompt ***************************************************************************
Prompt Verify the MRP Process is running
Prompt ***************************************************************************
SELECT PROCESS, STATUS, THREAD#, SEQUENCE#, BLOCK#, BLOCKS FROM V$MANAGED_STANDBY where PROCESS like 'MRP%' or PROCESS like 'RFS%' and SEQUENCE#<>0;

Prompt ***************************************************************************
Prompt Check for apply Lag ..........
Prompt ***************************************************************************
SELECT 'Last Applied : ' Logs,
TO_CHAR(next_time,'DD-MON-YY:HH24:MI:SS') TIME,thread#,sequence#
FROM v$archived_log
WHERE sequence# =
(SELECT MAX(sequence#) FROM v$archived_log WHERE applied='YES'
)
UNION
SELECT 'Last Received : ' Logs,
TO_CHAR(next_time,'DD-MON-YY:HH24:MI:SS') TIME,thread#,sequence#
FROM v$archived_log
WHERE sequence# =
(SELECT MAX(sequence#) FROM v$archived_log );

column name format a12
column lag_time format a20
column datum_time format a20
column time_computed format a20
SELECT NAME, VALUE LAG_TIME, DATUM_TIME, TIME_COMPUTED
from V$DATAGUARD_STATS where name like 'apply lag';

Prompt ***************************************************************************
Prompt Check for apply Lag is reducing..........
Prompt ***************************************************************************
col name for a20
SELECT * FROM V$STANDBY_EVENT_HISTOGRAM WHERE NAME = 'apply lag'  AND COUNT > 0 and trunc(to_date(LAST_TIME_UPDATED,'MM/DD/YYYY HH24:MI:SS'))=trunc(sysdate) order by to_date(LAST_TIME_UPDATED,'MM/DD/YYYY HH24:MI:SS');

Prompt ***************************************************************************************************
Prompt Check Recovery status Apply Rate-Last Applied Redo-Apply Time per Log-Standby Apply Lag
Prompt ***************************************************************************************************
set linesize 400
col Values for a65
col Recover_start for a21

select to_char(START_TIME,'dd.mm.yyyy hh24:mi:ss') "Recover_start",to_char(item)||' = '||to_char(sofar)||' '||to_char(units)||' '|| to_char(TIMESTAMP,'dd.mm.yyyy hh24:mi:ss') "Values" from
v$recovery_progress
where start_time=(select max(start_time) from v$recovery_progress);

Prompt ***************************************************************************
Prompt Check for Archive GAP ..........
Prompt ***************************************************************************
 select * from v$archive_gap;

Prompt ***************************************************************************
Prompt Check for transport and apply Lag ..........
Prompt ***************************************************************************
col value for a18
set line 200
col name for a30
SELECT NAME, VALUE, DATUM_TIME FROM V$DATAGUARD_STATS;

Prompt ***************************************************************************
Prompt Recovery issues in alert log
Prompt ***************************************************************************
col message for a90
col ERROR_CODE for 99999
col SEVERITY for a20
col TIMESTAMP for a20
set line 200
select * from (select to_char(TIMESTAMP,'DD-MON-YY HH24:MI:SS') TIMESTAMP,MESSAGE,SEVERITY,ERROR_CODE
                from v$dataguard_status
                order by TIMESTAMP desc )
where rownum<=10
order by 1;

Prompt ***************************************************************************
Prompt Recovery issues Error and Fatal
Prompt ***************************************************************************
select MESSAGE, TIMESTAMP
from v$dataguard_status
where SEVERITY in ('Error','Fatal')
order by TIMESTAMP;

Prompt ***************************************************************************
Prompt Verify its using LGWR and ASYNCHRONOUS ...........
Prompt ***************************************************************************
column destination format a35 wrap
column process format a7
column archiver format a8
column dest_id format 99999999

select DEST_ID,DESTINATION,STATUS,TARGET,ARCHIVER,PROCESS,REGISTER,TRANSMIT_MODE
from v$archive_dest
where DESTINATION IS NOT NULL;


SELECT RECOVERY_MODE , PROTECTION_MODE ,SRL , ERROR FROM V$ARCHIVE_DEST_STATUS ;

Prompt ***************************************************************************
Prompt System Event for LNS -LGWR .................
Prompt ***************************************************************************
select EVENT, TOTAL_WAITS, TOTAL_TIMEOUTS, TIME_WAITED, AVERAGE_WAIT
from v$system_event
  where event like '%LNS%'
  or event like '%LGWR%' order by 4 desc;

Prompt ***************************************************************************
Prompt Verify Active Dataguard usage .................
Prompt ***************************************************************************
SELECT 'Using Active Data Guard' ADG FROM V$MANAGED_STANDBY M,
V$DATABASE D WHERE M.PROCESS LIKE 'MRP%' AND D.OPEN_MODE like 'READ ONLY%';

Prompt ***************************************************************************
Prompt Check for any error on Primary and standby ............
Prompt ***************************************************************************
col DEST_NAME for a25
col DESTINATION for a30
col ERROR for a30
select dest_id,dest_name,target,destination,status,error,db_unique_name from v$archive_dest where destination is not null;

Prompt ***************************************************************************
Prompt Verify Dataguard Parameters.................
Prompt ***************************************************************************
col value for a98
col name for a30

select name, value
from v$parameter
where name in ('db_name','db_unique_name','cluster_database','dg_broker_start','dg_broker_config_file1','dg_broker_config_file2','log_archive_config','log_archive_dest_1',
'log_archive_dest_2','log_archive_dest_state_1','log_archive_dest_state_2','fal_client',
'fal_server','db_file_name_convert','log_file_name_convert','standby_file_management',
'log_archive_trace','log_archive_max_processes','archive_lag_target','remote_login_password_file','redo_transport_user'
) order by name;

Prompt ***************************************************************************
Prompt check this on primary for Redo Destinations
Prompt ***************************************************************************
column name format a22
column value format a100
select NAME,VALUE from v$parameter where NAME like 'log_archive_dest%' and upper(VALUE) like 'SERVICE%';

Prompt ***************************************************************************
Prompt check this on primary and validate till what SEQ its applied to all DRs
Prompt ***************************************************************************
col DESTINATION for A30
select b.destination,a.dest_id,max(a.FIRST_TIME)"Date",max(a.sequence#)"Applied"
from v$archived_log a, v$archive_dest_status b
where (a.dest_id='1' or a.applied ='YES')
and a.dest_id=b.dest_id group by a.dest_id, b.destination order by a.dest_id;

spool off



----------------DR DRILL------------------

SELECT RECOVERY_MODE FROM V$ARCHIVE_DEST_STATUS WHERE DEST_ID=2;


[oracle@upidrgb-db-rac1 ~]$ cat drstat.sql

PROMPT---------------------------------------------------DATAGUARD_SEQUENCE_APPLY_STATUS-------------------------------------------

SET LINES 333 PAGES 3333
col STATUS for a12
SELECT INST_ID,PROCESS,STATUS,THREAD#,SEQUENCE# FROM GV$MANAGED_STANDBY;

PROMPT---------------------------------------------------DATAGUARD_DIFFERENCE_STATUS-------------------------------------------

SELECT ARCH.THREAD# "THREAD", ARCH.SEQUENCE# "LAST SEQUENCE RECEIVED", APPL.SEQUENCE# "LAST SEQUENCE APPLIED", (ARCH.SEQUENCE#-APPL.SEQUENCE#) 
"DIFFERENCE" FROM (SELECT THREAD#,SEQUENCE# FROM V$ARCHIVED_LOG WHERE (THREAD#,FIRST_TIME) IN (SELECT THREAD#,MAX(FIRST_TIME) 
FROM V$ARCHIVED_LOG GROUP BY THREAD#)) ARCH, (SELECT THREAD#,SEQUENCE# FROM V$LOG_HISTORY WHERE (THREAD#,FIRST_TIME) IN (SELECT THREAD#,MAX(FIRST_TIME) 
FROM V$LOG_HISTORY GROUP BY THREAD#)) APPL WHERE ARCH.THREAD# = APPL.THREAD# ORDER BY 1;

PROMPT--------------------------------------------------Apply Rate-------------------------------------------------------

select to_char(start_time, 'DD-MON-YYYY HH24:MI:SS') start_time, item, sofar, units
from v$recovery_progress
where (item = 'Active Apply Rate' or item = 'Average Apply Rate' or item = 'Redo Applied');


PROMPT-------------------------------------------------Check Lag--------------------------------------------------------

col name for a13
col value for 999999999
col unit for a30
set lines 200 pages 999
SELECT NAME,VALUE,UNIT,TIME_COMPUTED
FROM V$DATAGUARD_STATS
WHERE NAME IN('transport lag','apply lag');

[oracle@upidrgb-db-rac1 ~]$



 Rolling Forward a Physical Standby Using Recover From Service Command in 12c (Note:1987763.1)
Rolling a Standby Forward using an RMAN Incremental Backup To Fix The Nologging Changes (Note:958181.1)

12c Data guard Switchover Best Practices using SQLPLUS (Doc ID 1578787.1)

https://mallik034.blogspot.com/2021/06/12c-dataguard-switch-over-steps-2-nodes.html --with restore point
 
set lines 500
set pages 1000
SELECT ARCH.THREAD# "Thread", ARCH.SEQUENCE# "Last Sequence Received", APPL.SEQUENCE# "Last Sequence Applied", (ARCH.SEQUENCE# - APPL.SEQUENCE#) "Difference"
FROM
(SELECT THREAD# ,SEQUENCE# FROM V$ARCHIVED_LOG WHERE (THREAD#,FIRST_TIME ) IN (SELECT THREAD#,MAX(FIRST_TIME) FROM V$ARCHIVED_LOG GROUP BY THREAD#)) ARCH,
(SELECT THREAD# ,SEQUENCE# FROM V$LOG_HISTORY WHERE (THREAD#,FIRST_TIME ) IN (SELECT THREAD#,MAX(FIRST_TIME) FROM V$LOG_HISTORY GROUP BY THREAD#)) APPL
WHERE
ARCH.THREAD# = APPL.THREAD#
ORDER BY 1;


select 'Last applied  : ' Logs, to_char(next_time,'DD-MON-YY:HH24:MI:SS') Time, sequence# as SEQUENCE
from gv$archived_log where sequence# = (select max(sequence#) from gv$archived_log where applied='YES') union
select 'Last received : ' Logs, to_char(next_time,'DD-MON-YY:HH24:MI:SS') Time, sequence# as SEQUENCE from gv$archived_log
where sequence# = (select max(sequence#) from gv$archived_log);

select 'Last applied  : ' Logs, to_char(next_time,'DD-MON-YY:HH24:MI:SS') Time, sequence# as SEQUENCE
from gv$archived_log where sequence# = (select max(sequence#) from gv$archived_log where applied='YES') union
select 'Last received : ' Logs, to_char(next_time,'DD-MON-YY:HH24:MI:SS') Time, sequence# as SEQUENCE from gv$archived_log
where sequence# = (select max(sequence#) from gv$archived_log);


select max(to_char(checkpoint_time, 'DD-MON-YYYY')) as checkpoint_time  from v$datafile_header where to_char(checkpoint_time, 'DD-MON-YYYY') < to_char(sysdate+1, 'DD-MON-YYYY');

SELECT THREAD# ,SEQUENCE#,to_char(FIRST_TIME, 'DD-MON-RR HH24:MI:SS')"DATE" FROM V$LOG_HISTORY WHERE (THREAD#,FIRST_TIME ) IN (SELECT THREAD#,MAX(FIRST_TIME) FROM V$LOG_HISTORY GROUP BY THREAD#);

delete force archivelog all completed before 'sysdate-1';
sandered
==============CHECK POINT CHECK =================
select status, checkpoint_change#,
 to_char(checkpoint_time, 'DD-MON-YYYY HH24:MI:SS')
 as checkpoint_time, count(*) from v$datafile_header
 group by status, checkpoint_change#, checkpoint_time
 order by status, checkpoint_change#, checkpoint_time;

 SELECT COUNT ( DISTINCT module ) AS "Number of module" FROM CBSPRODUBS.ACTB_HISTORY;
 
 set echo off
col time for a20
select to_char(sysdate,'dd-Mon-rr hh24:mi:ss') tdate from dual;
select thread#, max(sequence#),to_char(FIRST_TIME,'dd-mon-rr hh24:mi:ss') ttime from v$log_history
where sequence# in (select max(sequence#) from v$log_history group by thread#)
group by thread#,to_char(FIRST_TIME,'dd-mon-rr hh24:mi:ss');


SELECT THREAD#, MAX(SEQUENCE#) AS "LAST_APPLIED_LOG" FROM gV$LOG_HISTORY GROUP BY THREAD#;

run
{
allocate channel for maintenance device type disk;
delete archivelog until time 'sysdate -6';
}

run
{
allocate channel for maintenance device type disk;
delete archivelog until sequence=3541;
}
**************************************************************************************************************************

PROD -

select b.dest_id,a.thread#,a.log_archived,b.log_applied,(a.log_archived-b.log_applied) log_gap
from
(
select thread#,max(sequence#)log_archived from gv$archived_log where archived='YES' group by thread#
)a,
(
select thread#,dest_id,max(sequence#)log_applied from gv$archived_log where applied='YES' and dest_id >1 group by dest_id,thread#
)b
where a.thread#=b.thread#
order by dest_id,thread#
/
REP_MONITOR

**************************************************************************************************************************
select name,open_mode,db_unique_name,database_role,switchover_status,GUARD_STATUS,controlfile_type,PROTECTION_MODE from gv$database;
select name from v$archived_log where SEQUENCE#='233564';

select name, FIRST_CHANGE#, NEXT_CHANGE#, block_size from v$archived_log where SEQUENCE#='1188297';

SELECT  PROCESS, STATUS,SEQUENCE#,BLOCK#,BLOCKS, DELAY_MINS,inst_id FROM gv$MANAGED_STANDBY;

ALTER DATABASE RECOVER MANAGED STANDBY DATABASE DISCONNECT FROM SESSION;

recover managed standby database cancel;

alter database recover managed standby database nodelay; 

recover managed standby database using current logfile disconnect;

recover managed standby database using current logfile disconnect PARALLEL 4;

select to_char(start_time,'dd-mon-yyyy HH:MI:SS') start_time, type, item, units, sofar, total, to_char(timestamp,'dd-mon-yyyy HH:MI:SS') timestamp
from gv$recovery_progress where item like '%Apply Rate';


restore point check

select name,scn,time,guarantee_flashback_database,storage_size from v$restore_point;
select thread#,max(sequence#) from v$archived_log group by thread# order by 1;

ALTER DATABASE RECOVER MANAGED STANDBY DATABASE DISCONNECT FROM SESSION PARALLEL 10;
ALTER DATABASE RECOVER MANAGED STANDBY DATABASE parallel 20 DISCONNECT FROM SESSION;

rman target sys/Abbott1234 auxiliary sys/"Abbott1234"@pei_pri.WORLD
recover database from service pei_pri noredo;
'sys/"Abbott1234"@pei_pri.WORLD as sysdba'



 cp /home/grid/thread_1_seq_39435.1505.1061029823 +FRA/DRDLMS/ARCHIVELOG/2021_01_05/thread_1_seq_39435

 
 +FRA/DRDLMS/ARCHIVELOG/2021_01_05/thread_2_seq_39986
set lines 200 pages 500

select name,open_mode,database_role,protection_mode,switchover_status from gv$database;
select name,open_mode,database_role,protection_mode,switchover_status from v$database;
show parameter spfile;

select db_unique_name from v$dataguard_config

select * from v$dataguard_status;

Select * from v$archive_processes;

## On Primary database:

select thread#,max(sequence#) from v$archived_log group by thread#;

select max(sequence#) from v$archived_log where recid =(select max(recid) from v$archived_log);

## On Standby database:

select thread#,max(sequence#) from v$archived_log where applied='YES' group by thread#;

select max(sequence#) from v$log_history where recid =(select max(recid) from v$log_history);

select * from v$archive_gap;
select process, client_process, sequence#, status from v$managed_standby;
select sequence#, first_time, next_time, applied from v$archived_log;
select archived_thread#, archived_seq#, applied_thread#, applied_seq# from v$archive_dest_status;
select thread#, max (sequence#) from v$log_history group by thread#;
select thread#, max (sequence#) from v$archived_log where APPLIED='YES' group by thread#;

#dr.sql
 
set lines 200 pages 2000
col dest_name for a20
select DEST_NAME,STATUS,DELAY_MINS,NET_TIMEOUT,TARGET,ERROR from V$ARCHIVE_DEST where status <> 'INACTIVE';

set lines 200 pages 2000
col dest_name for a20
select DEST_NAME,STATUS,DELAY_MINS,NET_TIMEOUT,TARGET,ERROR from V$ARCHIVE_DEST;

If the shut down is in progress check the database tracefile , auditlog and archive location

SELECT timestamp, gvi.thread#, message FROM gv$dataguard_status gvds, gv$instance gvi WHERE gvds.inst_id = gvi.inst_id AND severity in ('Error','Fatal') ORDER BY timestamp, thread#;
Check on primery also

select inst_id,error from gv$archive_Dest_status where dest_id=4;

 
set lines 200 pages 2000
col STATUS for a25
SELECT process,status,sequence#,thread#,block#,INST_ID  FROM gv$managed_standby ORDER BY thread#, process;

set lines 200 pages 2000
col STATUS for a25
SELECT process,status,sequence#,block#  FROM v$managed_standby ORDER BY thread#, process;

v$archive_managed_standby

 ########################check archive generation datae on prod
 
 select sequence#, name,creator, to_char(first_time,'dd-mm-yyyy hh24:mi:ss'), to_char(completion_time,'dd-mm-yyyy hh24:mi:ss')
from v$archived_log
where sequence#='113841';
 
 
 ###### check the last archive apply time
select status, checkpoint_change#,
to_char(checkpoint_time, 'DD-MON-YYYY HH24:MI:SS')
as checkpoint_time, count(*) from v$datafile_header
group by status, checkpoint_change#, checkpoint_time
order by status, checkpoint_change#, checkpoint_time;

 
set lines 200 pages 2000
SELECT process,status,sequence#,thread#,block# ,pid,client_process, client_pid, active_agents, known_agents FROM gv$managed_standby ORDER BY thread#, process;
 
 Delay check in standby server
SELECT sequence#,first_time,substr(name,instr(name,'/',-1)+1) name,aldly delay FROM v$archived_log, x$kccal
WHERE recid = alrid AND first_time > sysdate - 90/1440 ORDER BY resetlogs_change#, sequence#;
 
 
select to_char(start_time, 'DD-MON-RR HH24:MI:SS') start_time,item, round(sofar/1024,2) "MB/Sec" from v$recovery_progress where (item='Active Apply Rate' or item='Average Apply Rate');
 
 
 
set time on
set timing on
    set lines 500
    set pages 1000
    SELECT ARCH.THREAD# "Thread", ARCH.SEQUENCE# "Last Sequence Received", APPL.SEQUENCE# "Last Sequence Applied", (ARCH.SEQUENCE# - APPL.SEQUENCE#) "Difference"
    FROM
    (SELECT THREAD# ,SEQUENCE# FROM V$ARCHIVED_LOG WHERE (THREAD#,FIRST_TIME ) IN (SELECT THREAD#,MAX(FIRST_TIME) FROM V$ARCHIVED_LOG GROUP BY THREAD#)) ARCH,
    (SELECT THREAD# ,SEQUENCE# FROM V$LOG_HISTORY WHERE (THREAD#,FIRST_TIME ) IN (SELECT THREAD#,MAX(FIRST_TIME) FROM V$LOG_HISTORY GROUP BY THREAD#)) APPL
    WHERE
    ARCH.THREAD# = APPL.THREAD#
    ORDER BY 1;
 
 
set lines 500
set pages 1000


SELECT al.thrd "Thread", almax "Last Seq Received", lhmax "Last Seq Applied" FROM (select thread# thrd, MAX(sequence#) almax  FROM v$archived_log WHERE resetlogs_change#=(SELECT resetlogs_change# FROM v$database) GROUP BY thread#) al, (SELECT thread# thrd,MAX(sequence#) lhmax FROM v$log_history WHERE resetlogs_change#=(SELECT resetlogs_change# FROM v$database) GROUP BY thread#) lh WHERE al.thrd = lh.thrd;
 
 
SELECT THREAD#, SEQUENCE#,archived,APPLIED FROM gV$ARCHIVED_LOG where applied='NO' ORDER BY SEQUENCE#;

rman policy

production

CONFIGURE ARCHIVELOG DELETION POLICY TO APPLIED ON ALL STANDBY BACKED UP 1 TIMES TO 'SBT_TAPE';


On Primery

CONFIGURE ARCHIVELOG DELETION POLICY TO APPLIED ON ALL STANDBY;

###################switch Over ######################
ALTER DATABASE SWITCHOVER TO PRORSLDB VERIFY;

@primary,

alter system set log_archive_dest_state_2=defer;

alter system set log_Archive_dest_state_2=enable;

alter system switch logfile;

select dest_id,error,status from v$archive_dest where dest_id=<your remote log_archive_dest_<n>>;

archive log list;

select max(sequence#),thread# from v$log_history group by thread#;

@standby,

select process,sequence#,thread#,status from v$managed_standby;

select max(sequence#),thread# from v$archived_log group by thread#;




=========================Network chekc

select name,value,time_computed,datum_time from v$dataguard_stats where name=’transport lag’;

SELECT THREAD#, SEQUENCE#,
        BLOCKS*BLOCK_SIZE/1024/1024 MB,
       (NEXT_TIME-FIRST_TIME)*86400 SEC,
       (BLOCKS*BLOCK_SIZE/1024/1024)/((NEXT_TIME-FIRST_TIME)*86400) "MB/S"
   FROM V$ARCHIVED_LOG
WHERE ((NEXT_TIME-FIRST_TIME)*86400<>0)
    AND FIRST_TIME BETWEEN TO_DATE('2015/01/15 08:00:00','YYYY/MM/DD HH24:MI:SS')
    AND TO_DATE('2015/01/15 11:00:00','YYYY/MM/DD HH24:MI:SS')
    AND DEST_ID=2
  ORDER BY FIRST_TIME;
 
 =============================================
Creation:-

******************* PRIMARY

 

ALTER SYSTEM SET LOG_ARCHIVE_DEST_1='location=/backup/MMMPROD_ARCH VALID_FOR=(ALL_LOGFILES,ALL_ROLES) DB_UNIQUE_NAME=MMMPROD' SCOPE=both;
ALTER SYSTEM SET LOG_ARCHIVE_DEST_2='SERVICE=MMMPRODDR NOAFFIRM ASYNC VALID_FOR=(ONLINE_LOGFILES,PRIMARY_ROLE) DB_UNIQUE_NAME=MMMPRODDR' SCOPE=both;
ALTER SYSTEM SET LOG_ARCHIVE_DEST_STATE_2=ENABLE;
ALTER SYSTEM SET fal_server='MMMPRODDR' SCOPE=both;
ALTER SYSTEM SET fal_client='MMMPROD' SCOPE=both;
ALTER SYSTEM SET STANDBY_FILE_MANAGEMENT=AUTO;
ALTER SYSTEM SET LOG_ARCHIVE_CONFIG='DG_CONFIG=(MMMPROD,MMMPRODDR)';

 

******************* STANDBY

 

ALTER SYSTEM SET LOG_ARCHIVE_DEST_1='location=/u01/MMMPROD_ARCHIVE VALID_FOR=(ALL_LOGFILES,ALL_ROLES) DB_UNIQUE_NAME=MMMPRODDR' SCOPE=both;
ALTER SYSTEM SET LOG_ARCHIVE_DEST_2='SERVICE=MMMPROD NOAFFIRM ASYNC VALID_FOR=(ONLINE_LOGFILES,PRIMARY_ROLE) DB_UNIQUE_NAME=MMMPROD' SCOPE=both;
ALTER SYSTEM SET LOG_ARCHIVE_DEST_STATE_2=ENABLE;
ALTER SYSTEM SET fal_server='MMMPROD' SCOPE=both;
ALTER SYSTEM SET fal_client='MMMPRODDR' SCOPE=both;
ALTER SYSTEM SET STANDBY_FILE_MANAGEMENT=AUTO;
ALTER SYSTEM SET LOG_ARCHIVE_CONFIG='DG_CONFIG=(MMMPRODDR,MMMPROD)';


================SCN====================

SELECT to_char(CURRENT_SCN) FROM V$DATABASE;

SQL> select current_scn from v$database;

-- If no READ ONLY Tablespaces/datafiles in database use
SQL> select min(fhscn) from x$kcvfh;

-- If READ ONLY tablespaced/datafiles in database use
select min(f.fhscn) from x$kcvfh f, v$datafile d
where f.hxfil =d.file# and d.enabled != 'READ ONLY' ;
================================================SWITCHOVER and FAILOVER

SQL>archive log list
SQL>select name,instance_name,open_mode,database_role,switchover_status from v$database,v$instance;

 

select switchover_status from v$database;

 

SWITCHOVER_STATUS
——————–
TO STANDBY

 

need to be --TO STANDBY state then procced further---FOR BII server need to check cluser status (Oracle fail safe)

 


SQL>alter database commit to switchover to physical standby with session shutdown;
SQL>shutdown immediate
SQL>startup nomount
SQL>alter database mount standby database;

 

SQL>alter system set log_archive_dest_state_2=defer scope=both;
SQL>select name,open_mode,database_role,switchover_status from v$database;
SQL>show parameter log_archive_dest_state_2;

 


STANDBY
-------
SQL>archive log list
SQL>select name,instance_name,open_mode,database_role,switchover_status from v$database,v$instance;
SQL>alter database commit to switchover to primary;
SQL>shutdown immediate
SQL>startup



=================================================
[oracle@EWSMLMDRDB02 admin]$ telnet 10.189.12.183 1589
Trying 10.189.12.183...
telnet: connect to address 10.189.12.183: No route to host
[oracle@EWSMLMDRDB02 admin]$ telnet 10.189.12.183 1588
Trying 10.189.12.183...
telnet: connect to address 10.189.12.183: No route to host
[oracle@EWSMLMDRDB02 admin]$ telnet 10.189.12.182 1589
Trying 10.189.12.182...
telnet: connect to address 10.189.12.182: No route to host
[oracle@EWSMLMDRDB02 admin]$ hostname -i
10.176.50.119
[oracle@EWSMLMDRDB02 admin]$ ip route
default via 10.176.50.1 dev ens192 proto static metric 101
default via 10.176.120.1 dev ens256 proto static metric 102
default via 10.176.124.1 dev ens161 proto static metric 103
10.176.50.0/23 dev ens192 proto kernel scope link src 10.176.50.119 metric 101
10.176.120.0/23 dev ens256 proto kernel scope link src 10.176.120.191 metric 102
10.176.124.0/23 dev ens161 proto kernel scope link src 10.176.125.53 metric 103
10.189.12.0/24 via 10.176.124.4 dev ens161 proto static metric 103
169.254.0.0/19 dev ens256 proto kernel scope link src 169.254.18.83
192.168.122.0/24 dev virbr0 proto kernel scope link src 192.168.122.1 linkdown
[oracle@EWSMLMDRDB02 admin]$ ip route add 10.189.12.183/24 via 10.176.124.1 dev ens161
RTNETLINK answers: Operation not permitted
[oracle@EWSMLMDRDB02 admin]$ logout
[root@EWSMLMDRDB02 ~]# ip route add 10.189.12.183/24 via 10.176.124.1 dev ens161
Error: Invalid prefix for given prefix length.
[root@EWSMLMDRDB02 ~]# ip route add 10.189.12.183/32 via 10.176.124.1 dev ens161
[root@EWSMLMDRDB02 ~]# telnet 10.189.12.183 1589





SYNC 


select PROCESS,status,sequence# from v$managed_standby;  
alter database recover managed standby database cancel;
alter database recover automatic standby database;
alter database recover standby database;
alter database recover managed standby database disconnect from session;
select max(sequence#) from v$archived_log;
select max(sequence#) from v$log_history;
ALTER DATABASE RECOVER MANAGED STANDBY DATABASE PARALLEL 6 DISCONNECT FROM SESSION;
alter system set log_archive_dest_state_2=DEFER;    --rk10
select max(sequence#),applied from v$archived_log group by applied;
select FLASHBACK_ON from v$database;
select DEST_ID,DEST_NAME,STATUS,ERROR from v$archive_dest where DEST_ID in (1,2,3,4);
select rownum,t.* from v$controlfile_record_section t;

SELECT ARCH.THREAD# "Thread", ARCH.SEQUENCE# "Last Sequence Received", APPL.SEQUENCE# "Last Sequence Applied", (ARCH.SEQUENCE# - APPL.SEQUENCE#) "Difference" FROM (SELECT THREAD# ,SEQUENCE# FROM V$ARCHIVED_LOG WHERE (THREAD#,FIRST_TIME ) IN (SELECT THREAD#,MAX(FIRST_TIME) FROM V$ARCHIVED_LOG GROUP BY THREAD#)) ARCH, (SELECT THREAD# ,SEQUENCE# FROM V$LOG_HISTORY WHERE (THREAD#,FIRST_TIME ) IN (SELECT THREAD#,MAX(FIRST_TIME) FROM V$LOG_HISTORY GROUP BY THREAD#)) APPL
WHERE ARCH.THREAD# = APPL.THREAD#;

set lines 1221 pages 999
ALTER SESSION SET NLS_DATE_FORMAT = 'DD-MM-YYYY HH24:MI:SS';
SELECT ARCH.FIRST_TIME as PROD_ARCH_DATE,APPL.FIRST_TIME as APPL_Last_Date,ARCH.THREAD# "Thread", ARCH.SEQUENCE# "Last Sequence Received", APPL.SEQUENCE# "Last Sequence Applied", (ARCH.SEQUENCE# - APPL.SEQUENCE#) "Difference"
FROM (SELECT FIRST_TIME,THREAD# ,SEQUENCE# FROM V$ARCHIVED_LOG WHERE (THREAD#,FIRST_TIME ) IN (SELECT THREAD#,MAX(FIRST_TIME) FROM V$ARCHIVED_LOG GROUP BY THREAD#)) ARCH,
(SELECT FIRST_TIME,THREAD# ,SEQUENCE# FROM V$LOG_HISTORY WHERE (THREAD#,FIRST_TIME ) IN (SELECT THREAD#,MAX(FIRST_TIME) FROM V$LOG_HISTORY GROUP BY THREAD#)) APPL
WHERE ARCH.THREAD# = APPL.THREAD# ORDER BY 1;
       

select name,open_mode,log_mode,database_role from v$database;
select max(sequence#) from v$archived_log;
archive log list;	
     
select max(sequence#) from v$log_history;
28665


select name,open_mode,log_mode,database_role from v$database;
select max(sequence#) from v$archived_log where APPLIED='YES';
archive log list;
         

SO		 
alter db commit to SW to standby->SHUT IMM->alter db mount standby db->Start MRP		 
alter db commit to SW to primary->shu imm-> startup

FO PROCESS
alter db recover mnged standby db finish -> alter db activate standby db

FLASHBACK_ON
db_recover_fle_dest_size->check flashback mode ->stop MRP->alter db flashback on->create restore point gaurentee flashback db->alter db convert to snapshot stndby
check details from v$restore_point->shut imm->startup
shut imm->startup->alter db convert to physical stndby->S1->S2->start MRP->alter db flashback off->drop restore point 

select thread#,max(sequence#) from gv$archived_log where APPLIED='YES' group by thread#;
select thread#,max(SEQUENCE#) from gv$archived_log  group by thread#;

col scn format 999999999999999
set linesize 180 
col name for a65 
select scn, storage_size, time, name from v$restore_point;



ORACLE_HOME=/oracle/app/oracle/product/11.2.0/dbhome_1;export ORACLE_HOME;
ORACLE_SID=ESBSBIDB;export ORACLE_SID;
DATE=`/bin/date '+%A_%d_%B_%Y'`
/oracle/app/oracle/product/11.2.0/dbhome_1/bin/rman target / <<EOF log /backup/incr/rman_Sbil_backup_$DATE.log
run
{
CONFIGURE DEFAULT DEVICE TYPE TO disk;
configure controlfile autobackup format for device type disk to '/backup/rman_bkp/ctrl_$DATE';
allocate channel c1 type disk format '/backup/incr/for_standby_%U';
allocate channel c2 type disk format '/backup/incr/for_standby_%U';
allocate channel c3 type disk format '/backup/incr/for_standby_%U';
allocate channel c4 type disk format '/backup/incr/for_standby_%U';
backup incremental from scn 15375548100 database tag 'FORSTANDBY_25032022';
backup current controlfile for standby format '/backup/incr/control_$DATE.ctl';
release channel c1;
release channel c2;
release channel c3;
release channel c4;
}
exit;


select thread#,max(sequence#) from gv$archived_log where APPLIED='YES' group by thread#;

select thread#,max(SEQUENCE#) from gv$archived_log  group by thread#;


ORACLE_HOME=/oracle/app/oracle/product/11.2.0/dbhome_1;export ORACLE_HOME;
ORACLE_SID=imagedb;export ORACLE_SID;
DATE=`/bin/date '+%A_%d_%B_%Y'`
/oracle/app/oracle/product/11.2.0/dbhome_1/bin/rman target / <<EOF log /NEW_NFS_BACKUP/image_07112019/rman_image_incribackup_$DATE.log
run
{
CONFIGURE DEFAULT DEVICE TYPE TO DISK;
allocate channel c1 type disk format '/NEW_NFS_BACKUP/image_07112019/for_standby_%U';
allocate channel c2 type disk format '/NEW_NFS_BACKUP/image_07112019/for_standby_%U';
allocate channel c3 type disk format '/NEW_NFS_BACKUP/image_07112019/for_standby_%U';
allocate channel c4 type disk format '/NEW_NFS_BACKUP/image_07112019/for_standby_%U';
allocate channel c5 type disk format '/NEW_NFS_BACKUP/image_07112019/for_standby_%U';
allocate channel c6 type disk format '/NEW_NFS_BACKUP/image_07112019/for_standby_%U';
backup incremental from scn 2335699630700 database tag 'feb_new_11022022';
BACKUP CURRENT CONTROLFILE FOR STANDBY;
COPY CURRENT CONTROLFILE FOR STANDBY TO '/NEW_NFS_BACKUP/image_07112019/control_new_$DATE.ctl';
release channel c1;
release channel c2;
release channel c3;
release channel c4;
release channel c5;
release channel c6;
CONFIGURE DEFAULT DEVICE TYPE TO SBT_TAPE;
}
exit;





4306166

scp arch_1_430616* oracle@172.17.131.22:/arch/indigo/archive


scp arch_1_430616* oracle@172.17.131.22:/arch/indigo/archive





LISTENER =
  (DESCRIPTION_LIST =
    (DESCRIPTION =
      (ADDRESS_LIST =
        (ADDRESS = (PROTOCOL = IPC)(KEY = EXTPROC))
      )
      (ADDRESS_LIST =
        (ADDRESS = (PROTOCOL = TCP)(HOST = 172.19.0.52)(PORT = 1521))
      )
    )
  )

SID_LIST_LISTENER =
  (SID_LIST =
    (SID_DESC =
      (GLOBAL_DBNAME = channel)
      (ORACLE_HOME = /oracle/app/oracle/product/11.2.0/dbhome_1)
      (SID_NAME = channel)
    )
    (SID_DESC =
      (GLOBAL_DBNAME = imagedb)
      (ORACLE_HOME = /oracle/app/oracle/product/11.2.0/dbhome_1)
      (SID_NAME = imagedb)
    )
  )


ADR_BASE_LISTENER = /oracle/app/oracle/product/11.2.0


#----ADDED BY TNSLSNR 21-JUN-2013 19:26:38---
PASSWORDS_LISTENER = 2E03D0527A37EA5C
#--------------------------------------------

ADMIN_RESTRICTIONS_LISTENER=ON

######################################################

SECURE_PROTOCOL_LISTENER=(TCP,IPC)
SECURE_REGISTER_LISTENER=(TCP,IPC)
SECURE_CONTROL_LISTENER=(TCPS,IPC)
DYNAMIC_RESTORATION_LISTENER=OFF
EXTPROC_DLLS=ONLY

#####################################################


/backup_Huawei/datafile_bkp/initsbil.ora


The cache buffer chains latch is acquired when a process needs to search the buffer cache.

Its purpose then is to prevent changes from occurring to the underlying buffer cache structure during the search. The search of the buffer cache is via a linked list (cache buffer chains).






 select PKG_NAME,STATUS_DESC ,JOBSTARTTIME,JOBENDTIME FROM ING_MIS.MIS_JOBDETAIL_MASTER
 WHERE PKG_NAME IN ('PKG_POLICY_STG','PKG_ALLOCATION_STG','PKG_PREMIUM_TRANSACTIONS_STG','PKG_PAYMENT_STG',
                   'PKG_REFUND','PKG_SERIES_STG') order by  JOBSTARTTIME
				   
				   
				   
				  
				  
				  COPY CURRENT CONTROLFILE FOR STANDBY TO '/RMAN_BKP/sby_control01.ctl';
				  
				  
set lines 280 pages 199
col INST_ID for 99
col ch for a30
col FILENAME for a50
select s.inst_id, a.sid, CLIENT_INFO Ch, a.STATUS,
open_time, round(BYTES/1024/1024,2) "SOFAR Mb" , round(total_bytes/1024/1024,2)
TotMb, io_count,
round(BYTES/TOTAL_BYTES*100,2) "% Complete" , a.type, filename
from gv$backup_async_io a, gv$session s
where not a.STATUS in ('UNKNOWN') and s.status='ACTIVE' and a.STATUS <> 'FINISHED'
and a.sid=s.sid order by 6 desc,7;


				  
				  
				  
				  
				  
SCRIPTS


[oracle@CPCLNXDB103 rmanbkp]$ cat /oracle/script/rman_backup.sh
ORACLE_HOME=/oracle/app/oracle/product/11.2.0.2.0/dbhome_1/;export ORACLE_HOME;
ORACLE_SID=webdb8;export ORACLE_SID;
/bin/rm -f /rmanbkp/rman/*.bak /rmanbkp/rman/controlfile_*
DATE=`/bin/date '+%A_%d_%B_%Y'`
/oracle/app/oracle/product/11.2.0.2.0/dbhome_1/bin/rman target / <<EOF log /rmanbkp/rman/rman_backup_$DATE.log
run
{ CONFIGURE DEFAULT DEVICE TYPE TO disk;
CONFIGURE DEVICE TYPE DISK PARALLELISM 2 BACKUP TYPE TO COMPRESSED BACKUPSET;
BACKUP DATABASE FORMAT '/rmanbkp/rman/%U.bak';
BACKUP AS COMPRESSED BACKUPSET CURRENT CONTROLFILE FORMAT '/rmanbkp/rman/controlfile_%U';
crosscheck archivelog all;
BACKUP ARCHIVELOG from time 'sysdate';
CONFIGURE DEFAULT DEVICE TYPE TO SBT_TAPE;
}
exit;




[oracle@CPCLNXDB103 rmanbkp]$ cat /oracle/script/export_full_webdb8.sh
ORACLE_HOME=/oracle/app/oracle/product/11.2.0.2.0/dbhome_1;export ORACLE_HOME;
ORACLE_SID=webdb8;export ORACLE_SID;
rm -rf /rmanbkp/export/metadata_ESHIELD_PORTAL*
dat=`date +%d_%b_%Y`
export=dat
/oracle/app/oracle/product/11.2.0.2.0/dbhome_1/bin/expdp \'/ as sysdba\' directory=export dumpfile=metadata_ESHIELD_PORTAL_${dat}.dmp logfile=metadata_ESHIELD_PORTAL_${dat}.log full=y compression=all



[oracle@CPCLNXDB103 rmanbkp]$ cat /oracle/script/analyzeimagedb.sh
ORACLE_HOME=/oracle/app/oracle/product/11.2.0.2.0/dbhome_1;export ORACLE_HOME;
ORACLE_SID=webdb8;export ORACLE_SID;
$ORACLE_HOME/bin/sqlplus "/as sysdba" @/oracle/script/analyzewebdb8.sql
exit;



[oracle@CPCLNXDB103 rmanbkp]$ cat /oracle/script/rman_backup_monthend.sh
#!/usr/bin/ksh
#export PATH
ORACLE_HOME=/oracle/app/oracle/product/11.2.0.2.0/dbhome_1;export ORACLE_HOME;
ORACLE_SID=webdb8;export ORACLE_SID;
/bin/rm -f /rmanbkp/rman/*.bak /backup/rmanbkp/snapcf.ctl /rmanbkp/rman/ctrl_c-*
DATE=`/bin/date '+%A_%d_%B_%Y'`
/oracle/app/oracle/product/11.2.0.2.0/dbhome_1/bin/rman target / <<EOF log /rmanbkp/rman/rman_Monthend_backup_$DATE.log
run
{ CONFIGURE DEFAULT DEVICE TYPE TO disk;
configure controlfile autobackup format for device type disk to '/rmanbkp/rman/ctrl_%F';
CONFIGURE CONTROLFILE AUTOBACKUP ON;
CONFIGURE COMPRESSION ALGORITHM 'MEDIUM';
CONFIGURE DEVICE TYPE DISK PARALLELISM 5 BACKUP TYPE TO COMPRESSED BACKUPSET;
CONFIGURE SNAPSHOT CONTROLFILE NAME TO  '/rmanbkp/rman/snapcf.ctl';
BACKUP DATABASE FORMAT '/rmanbkp/rman/%U.bak';
CONFIGURE DEFAULT DEVICE TYPE TO SBT_TAPE;
}
exit;






ORACLE_HOME=/oracle/app/oracle/product/11.2.0.2.0/dbhome_1;export ORACLE_HOME;
ORACLE_SID=webdb8;export ORACLE_SID;
rm -rf /rmanbkp/export/metadata_ESHIELD_PORTAL*
dat=`date +%d_%b_%Y`
export=dat
/oracle/app/oracle/product/11.2.0.2.0/dbhome_1/bin/expdp \'/ as sysdba\' directory=export dumpfile=metadata_ESHIELD_PORTAL_${dat}.dmp logfile=metadata_ESHIELD_PORTAL_${dat}.log full=y compression=all




#!/usr/bin/ksh
#export PATH
ORACLE_HOME=/oracle/app/oracle/product/11.2.0.2.0/dbhome_1;export ORACLE_HOME;
ORACLE_SID=webdb8;export ORACLE_SID;
/bin/rm -f /rmanbkp/rman/*.bak /backup/rmanbkp/snapcf.ctl /rmanbkp/rman/ctrl_c-*
DATE=`/bin/date '+%A_%d_%B_%Y'`
/oracle/app/oracle/product/11.2.0.2.0/dbhome_1/bin/rman target / <<EOF log /rmanbkp/rman/rman_Monthend_backup_$DATE.log
run
{ CONFIGURE DEFAULT DEVICE TYPE TO disk;
configure controlfile autobackup format for device type disk to '/rmanbkp/rman/ctrl_%F';
CONFIGURE CONTROLFILE AUTOBACKUP ON;
CONFIGURE COMPRESSION ALGORITHM 'MEDIUM';
CONFIGURE DEVICE TYPE DISK PARALLELISM 5 BACKUP TYPE TO COMPRESSED BACKUPSET;
CONFIGURE SNAPSHOT CONTROLFILE NAME TO  '/rmanbkp/rman/snapcf.ctl';
BACKUP DATABASE FORMAT '/rmanbkp/rman/%U.bak';
CONFIGURE DEFAULT DEVICE TYPE TO SBT_TAPE;
}
exit;



ORACLE_HOME=/oracle/app/oracle/product/11.2.0.2.0/dbhome_1;export ORACLE_HOME;
ORACLE_SID=webdb8;export ORACLE_SID;
$ORACLE_HOME/bin/sqlplus "/as sysdba" @/oracle/script/analyzewebdb8.sql
exit;


set timing on
set echo on
spool /oracle/script/analyze.log;
alter session set sort_area_size=100000000;
alter session set sort_area_retained_size=100000000;
select to_char(sysdate,'DD-MM-YYYY:HH24:MI:SS') from dual;
exec dbms_stats.gather_schema_stats('PORTALINDIVIDUAL',estimate_percent => 30,method_opt => 'FOR ALL COLUMNS SIZE 1',granularity=>'ALL',cascade =>TRUE,DEGREE=>4);
exec dbms_stats.gather_schema_stats('PORTALMASTER',estimate_percent => 30,method_opt => 'FOR ALL COLUMNS SIZE 1',granularity=>'ALL',cascade =>TRUE,DEGREE=>4);
exec dbms_stats.gather_schema_stats('PORTALINDIVIDUAL',estimate_percent => 30,method_opt => 'FOR ALL COLUMNS SIZE 1',granularity=>'ALL',cascade =>TRUE,DEGREE=>4);
select to_char(sysdate,'DD-MM-YYYY:HH24:MI:SS') from dual;
spool off;
exit;




ORACLE_BASE=/oracle/app/oracle/product/11.2.0.2.0
ORACLE_HOME=/oracle/app/oracle/product/11.2.0.2.0/dbhome_1
ORACLE_SID=webdb8
LD_LIBRARY_PATH=/oracle/app/oracle/product/11.2.0.2.0/dbhome_1/lib
$ORACLE_HOME/bin/sqlplus "/as sysdba" @/oracle/script/arch_zip_1.sql >/oracle/script/arch_zip_1.log
exit


host gzip /arch/eshield/archive/*.ARC &

alter system switch logfile ;

alter system switch logfile ;

alter system switch logfile ;

exit

find /backup/audit -name "*.aud" -mtime +3 > /oracle/clover/scripts/audit_removal/aud_removed.log
find /backup/audit -name "*.aud" -mtime +3 -exec rm {} \;

				  
MRP slowness 				 
col KSPPINM for a40
col KSPPSTVL for a30
SELECT
ksppinm,
ksppstvl
FROM
x$ksppi a,
x$ksppsv b
WHERE
a.indx=b.indx
AND
ksppinm in ('_log_read_buffers','_log_read_buffer_size','_change_vector_buffers','parallel_execution_message_size','_media_recovery_read_batch')

set lines 1000 pages 5000
set echo on time on
col COMMENTS for a30
col type for a20
col inst_id format 99
col value for a20
alter session set nls_date_format='DD-MM-YYYY HH24:MI:SS';
select sysdate from dual;
Select * from v$recovery_progress where START_TIME in (select max(START_TIME) from v$recovery_progress);
select /*+ rule */ * from v$dataguard_stats;
select INST_ID,NAME,ROLE,THREAD#,SEQUENCE#,DEST_ID,ACTION,BLOCK# from gv$dataguard_process where name='PR00' order by 1;


Increase log read buffer parameters
alter system set "_log_read_buffers"=256 scope=spfile sid='*';
alter system set "_log_read_buffer_size"=256 scope=spfile sid='*';
Hi,

Please increase the following parameter and restart MRP and let us know if this helps with apply performance. Database restart is required.
Alter system set "_change_vector_buffers"=4 scope=spfile sid='*';
Additionally increase db_writer_process in Standby


Please note we need database bounce post setting parameter 

alter system set "_mira_num_receive_buffers"=500 scope=spfile sid='*';
alter system set "_mira_num_local_buffers"=500 scope=spfile sid='*';
alter system set "_mira_rcv_max_buffers"=5000 scope=spfile sid='*';
alter system set "_change_vector_buffers"=4 scope=spfile sid='*';
alter system set "_log_read_buffers"=32 scope=spfile sid='*';

This parameter specifies the size of messages used for parallel execution
alter system set "parallel_execution_message_size"=65535 scope=spfile sid='*';

SELECT gvi.thread#, timestamp, message FROM gv$dataguard_status gvds, gv$instance gvi 
WHERE gvds.inst_id = gvi.inst_id AND severity in ('Error','Fatal') ORDER BY timestamp, thread#;

Please try the below steps and let us know the status

alter system set db_writer_processes=12 scope=spfile;
alter system set "_time_based_rcv_ckpt_target"=900 scope=spfile;
alter database recover managed standby database cancel;
startup mount;
alter database recover managed standby database disconnect;


While MRP running get the IO stat details
$iostat -xd 3 100 > iostat.lst


SQL> select a.ksppinm "Parameter",
 b.ksppstvl "Session Value",
 c.ksppstvl "Instance Value"
 from sys.x$ksppi a, sys.x$ksppcv b, sys.x$ksppsv c
 where a.indx = b.indx
 and a.indx = c.indx
 and a.ksppinm in ('__shared_pool_size',
 'shared_pool_size',
 '__db_cache_size',
 'db_cache_size',
 '__large_pool_size',
 'large_pool_size',
 '__java_pool_size',
 '__streams_pool_size',
 'streams_pool_size',
 '__sga_target',
 'sga_target',
 'sga_max_size',
 'memory_target',
 'memory_max_target',
 'pga_aggregate_target',
 '__pga_aggregate_target'); 
 
 
 
 
 On Primary:

set pages 999 lines 999
col MESSAGE for a100
select to_char(timestamp,'YYYY-MON-DD HH24:MI:SS')||' '||message||severity from gv$dataguard_status where severity in ('Error','Fatal') order by timestamp;




set lines 1221 pages 999
ALTER SESSION SET NLS_DATE_FORMAT = 'DD-MM-YYYY HH24:MI:SS';
SELECT ARCH.FIRST_TIME as PROD_ARCH_DATE,APPL.FIRST_TIME as APPL_Last_Date,ARCH.THREAD# "Thread", ARCH.SEQUENCE# "Last Sequence Received", APPL.SEQUENCE# "Last Sequence Applied", (ARCH.SEQUENCE# - APPL.SEQUENCE#) "Difference"
FROM (SELECT FIRST_TIME,THREAD# ,SEQUENCE# FROM V$ARCHIVED_LOG WHERE (THREAD#,FIRST_TIME ) IN (SELECT THREAD#,MAX(FIRST_TIME) FROM V$ARCHIVED_LOG GROUP BY THREAD#)) ARCH,
(SELECT FIRST_TIME,THREAD# ,SEQUENCE# FROM V$LOG_HISTORY WHERE (THREAD#,FIRST_TIME ) IN (SELECT THREAD#,MAX(FIRST_TIME) FROM V$LOG_HISTORY GROUP BY THREAD#)) APPL
WHERE ARCH.THREAD# = APPL.THREAD# ORDER BY 1;
       
set lines 1000 pages 5000
set echo on time on
col COMMENTS for a30
col type for a20
col inst_id format 99
col value for a20
alter session set nls_date_format='DD-MM-YYYY HH24:MI:SS';
select sysdate from dual;
Select * from gv$recovery_progress where START_TIME in (select max(START_TIME) from gv$recovery_progress);
select /*+ rule */ * from v$dataguard_stats;
select INST_ID,NAME,ROLE,THREAD#,SEQUENCE#,DEST_ID,ACTION,BLOCK# from gv$dataguard_process where name='PR00' order by 1;
	   
	   
- get the below query o/p at the interval of 5 for 5times

set lines 180
select systimestamp from dual;
select name,value,time_computed,datum_time from v$dataguard_stats where name like '%lag';
select to_char(START_TIME,'DD-MON-YYYY HH24:MI'),ITEM,UNITS,SOFAR from v$recovery_progress;
select PROCESS,STATUS,THREAD#,SEQUENCE#,BLOCK# from v$managed_Standby;
column name format a40 tru
column total_time_waited format 9999999999999999
select * from (
select a.event_id, e.name, sum(a.time_waited) total_time_waited
from v$active_session_history a, v$event_name e
where a.event_id = e.event_id and a.SAMPLE_TIME>=(sysdate-60/(24*60))
group by a.event_id, e.name order by 3 desc)
where rownum < 11;
select * from (
select a.event_id, e.name, sum(a.time_waited) total_time_waited
from v$active_session_history a, v$event_name e
where a.event_id = e.event_id and a.program like '%(PR%' and a.SAMPLE_TIME>=(sysdate-60/(24*60))
group by a.event_id, e.name order by 3 desc)
where rownum < 11;
select * from (
select a.event_id, e.name, sum(a.time_waited) total_time_waited
from v$active_session_history a, v$event_name e
where a.event_id = e.event_id and a.program like '%(DBW%' and a.SAMPLE_TIME>=(sysdate-60/(24*60))
group by a.event_id, e.name order by 3 desc)
where rownum < 11;	   
