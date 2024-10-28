Rem srdc_dbparameters.sql
Rem
Rem Copyright (c) 2006, 2015 Oracle. All rights reserved.
Rem
Rem    NAME
Rem      srdc_dbparameters.sql - script to collect  diagnostic details required for  
Rem                              troubleshooting database parameters and related issues.
Rem
Rem    NOTES
Rem      * This script collects the diagnostic data related to initialization
Rem	parameters , for both multitenant and non-multitenant architecture.
Rem      * The checks here might not be enough for troubleshooting issues  on RAC or Dataguard. 
Rem         Check the respective SRDC document for the complete set of data.
Rem      * The script creates a spool output. Upload it to the Service Request
Rem      * This script contains some checks which might not be relevant for all versions.
Rem      * This script will *not* update any data.
Rem      * This script must be run using SQL*PLUS.
Rem      * You must be connected AS SYSDBA to run this script.
Rem
Rem
Rem
Rem    MODIFIED   (MM/DD/YY)
Rem       08/22/19  - Updated header
Rem       04/23/19  - updated the script
Rem       04/17/19  - created the script
Rem
Rem
Rem
Rem
Rem   
set pagesize 200 verify off sqlprompt "" term off entmap off echo off
set markup html on spool on
define SRDCNAME='DB_PARAMETERS'
COLUMN SRDCSPOOLNAME NOPRINT NEW_VALUE SRDCSPOOLNAME
select 'SRDC_'||upper('&&SRDCNAME')||'_'||upper(instance_name)||'_'|| to_char(sysdate,'YYYYMMDD_HH24MISS') SRDCSPOOLNAME from v$instance;
spool &&SRDCSPOOLNAME..htm
select '+----------------------------------------------------+' "HEADER" from dual
union all
select '| Diagnostic-Name: '||'&&SRDCNAME' from dual
union all
select '| Timestamp: '||to_char(systimestamp,'YYYY-MM-DD HH24:MI:SS TZH:TZM') from dual
union all
select '| Machine:         '||host_name from v$instance
union all
select '| Version:         '||version from v$instance
union all
select '| DBName:          '||name from v$database
union all
select '| Instance:        '||instance_name from v$instance
union all
select '+----------------------------------------------------+' from dual 
/
set echo on
set serveroutput on
REM === -- end of standard header -- ===

alter session set nls_date_format = 'DD-MON-YYYY HH24:MI:SS'
/
set echo off
prompt
prompt ============================================================================================
prompt                         ++ Database Details ++
prompt ============================================================================================
prompt
set echo on
select * from v$instance
/
select * from v$database
/
set echo off
prompt
prompt ============================================================================================
prompt                         ++ Resource Limit and License++
prompt ============================================================================================
prompt
set echo on
select * from v$resource_limit
/
select * from v$license
/
select sessions_max,sessions_warning,sessions_current,sessions_highwater  from v$license
/
set echo off
prompt
prompt ============================================================================================
prompt                         ++ CPU related parameters ++
prompt ============================================================================================
prompt
set echo on
SELECT kvitval, kvittag FROM x$kvit WHERE kvittag LIKE '%cpu%'
/
--Refer Doc ID 43711.1
SELECT a.ksppinm "Parameter",b.ksppstvl "Session Value",c.ksppstvl "Instance Value" FROM sys.x$ksppi a,sys.x$ksppcv b,sys.x$ksppsv c WHERE a.indx = b.indx AND a.indx = c.indx AND a.ksppinm ='_cpu_eff_thread_count'
/

select cpu_count as cpu#,cpu_core_count as core#,cpu_socket_count as socket#,cpu_count_hwm as cpu_hwm,cpu_core_count_hwm as core_hwm,cpu_socket_count_hwm as socket_hwm from x$ksull
/
show parameter cpu 
select stat_name, value from v$osstat where stat_name like '%CPU%'
/
set echo off
prompt
prompt ============================================================================================
prompt                         ++ Sessions and related parameters ++
prompt ============================================================================================
prompt
set echo on
select count(*) from x$ksuse where bitand(ksspaflg,1) !=0 
/ 
select count(*) from v$session
/
show parameter session
set echo off
prompt
prompt ============================================================================================
prompt                         ++ Database parameters ++
prompt ============================================================================================
prompt
set echo on
show parameter spfile
select name,value from v$parameter where isdefault='FALSE'
/
select * from sys.v$parameter
/
 select * from sys.v$spparameter
/
select * from dba_registry
/
SELECT action_time, action, namespace, version, id, comments FROM dba_registry_history ORDER by action_time desc
/
set echo off
prompt
prompt ============================================================================================
prompt                         ++ PDB status and parameters - 12c specific++
prompt ============================================================================================
prompt
set echo on
SHOW con_id
SHOW con_name
select NAME,CDB from v$database
/
SELECT NAME, OPEN_MODE, RESTRICTED, OPEN_TIME FROM V$PDBS
/
select * from v$pdbs
/
select * from pdb_spfile$
/
select p.CON_ID , p.name , s.NAME, s.VALUE$ from v$pdbs p ,  pdb_spfile$ s where  s.PDB_UID=p.DBID
/
SELECT PDB, NETWORK_NAME, CON_ID FROM CDB_SERVICES   WHERE PDB IS NOT NULL AND CON_ID > 2 ORDER BY PDB
/
SELECT DB_NAME, CON_ID, PDB_NAME, OPERATION, OP_TIMESTAMP, CLONED_FROM_PDB_NAME  FROM CDB_PDB_HISTORY  WHERE CON_ID > 2  ORDER BY CON_ID
/
select cause, type, message from PDB_PLUG_IN_VIOLATIONS where status='PENDING' 
/
select * from PDB_PLUG_IN_VIOLATIONS
/
set echo off
prompt
prompt ============================================================================================
prompt                         ++ Undocumented parameters++
prompt ============================================================================================
prompt
set echo on
SELECT a.ksppinm "Parameter",b.ksppstvl "Session Value",c.ksppstvl "Instance Value" FROM sys.x$ksppi a, sys.x$ksppcv b, sys.x$ksppsv c WHERE a.indx = b.indx AND a.indx = c.indx AND a.ksppinm LIKE '/_%' escape '/'
/
set echo off
prompt
prompt ============================================================================================
prompt            +++++++++++++++++++++End of SRDC Data Collection+++++++++++++ 
prompt ============================================================================================
prompt
spool off
set markup html off spool off
set sqlprompt "SQL> " term on  echo off
PROMPT======================================================================================================================================
PROMPT
PROMPT
PROMPT REPORT GENERATED : &SRDCSPOOLNAME..htm
set verify on echo on
Rem======================================================================================================================================