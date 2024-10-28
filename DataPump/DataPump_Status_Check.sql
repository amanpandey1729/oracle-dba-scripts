-- Query to check the Job information to attach via EXPDP/IMPDP

SET LINESIZE 150

COLUMN owner_name FORMAT A20
COLUMN job_name FORMAT A30
COLUMN operation FORMAT A10
COLUMN job_mode FORMAT A10
COLUMN state FORMAT A12

SELECT owner_name,
       job_name,
       TRIM(operation) AS operation,
       TRIM(job_mode) AS job_mode,
       state,
       degree,
       attached_sessions,
       datapump_sessions
FROM   dba_datapump_jobs
ORDER BY 1, 2;

OWNER_NAME           JOB_NAME                       OPERATION  JOB_MODE   STATE            DEGREE ATTACHED_SESSIONS DATAPUMP_SESSIONS
-------------------- ------------------------------ ---------- ---------- ------------ ---------- ----------------- -----------------
DUMMY_DBA            SYS_EXPORT_SCHEMA_01           EXPORT     SCHEMA     EXECUTING             4                 1                 6

-------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------

-- Attach the client to the running job

expdp user/password@service attach=SYS_EXPORT_SCHEMA_01 -- if export job is running
--OR
impdp user/password@service attach=SYS_IMPORT_SCHEMA_01 -- if import job is running

-
Export> status
 
Job: SYS_EXPORT_FULL_01
  Operation: EXPORT
  Mode: FULL
  State: EXECUTING
  Bytes Processed: 0
  Current Parallelism: 1
  Job Error Count: 0
  Dump File: /u01/app/oracle/dpump/admin.dmp
    bytes written: 4,096
 
Worker 1 Status:
  Process Name: DW00
  State: EXECUTING
  Object Schema: ADMIN
  Object Name: TEST_01
  Object Type: DATABASE_EXPORT/SCHEMA/PACKAGE_BODIES/PACKAGE/PACKAGE_BODY
  Completed Objects: 78
  Worker Parallelism: 1

-------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------

-- Queries to check the status of the jobs and completion time

select * from dba_datapump_jobs;


SELECT sl.sid, sl.serial#, sl.sofar, sl.totalwork, dp.owner_name, dp.state, dp.job_mode
     FROM v$session_longops sl, v$datapump_job dp
     WHERE sl.opname = dp.job_name
     AND sl.sofar != sl.totalwork;
	 
	 
-- For any errors:

select name, sql_text, error_msg from dba_resumable;