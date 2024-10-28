--DG Commands:

--OS Process Level Check:
ps -ef| grep smon;
ps -ef| grep tns;
ps -ef| grep mrp; [Stdby]

--DB STATUS-
--------------
select name, open_mode, database_role from v$database;

--MRP [START/STOP]-
-----------------
--[STOP]
alter database recover managed standby database cancel; 
--[START]
alter database recover managed standby database disconnect;

--DATAGUARD STATUS [Prim/Standby] -
----------------

set lines 199 pages 50
col MESSAGE for a80
col DESTINATION for a40
select * from v$dataguard_status order by timestamp;
select dest_id,status,destination,error from v$archive_dest where dest_id<=2;

--Primary:
select sequence#, first_time, next_time, applied,archived from v$archived_log where name='test_s' order by first_time;
select status, gap_status from v$archive_dest_status where dest_id=2;

--Standby:
select process, status, sequence# from v$managed_standby;
--Standby LogGap
SELECT ARCH.THREAD# "Thread", ARCH.SEQUENCE# "Last Sequence Received", APPL.SEQUENCE# "Last Sequence Applied", 
(ARCH.SEQUENCE# - APPL.SEQUENCE#) "Difference" FROM (SELECT THREAD# ,SEQUENCE# FROM V$ARCHIVED_LOG 
WHERE (THREAD#,FIRST_TIME ) IN (SELECT THREAD#,MAX(FIRST_TIME) FROM V$ARCHIVED_LOG GROUP BY THREAD#)) ARCH,
(SELECT THREAD# ,SEQUENCE# FROM V$LOG_HISTORY WHERE (THREAD#,FIRST_TIME ) IN (SELECT THREAD#,MAX(FIRST_TIME) 
FROM V$LOG_HISTORY GROUP BY THREAD#)) APPL WHERE ARCH.THREAD# = APPL.THREAD# ORDER BY 1;