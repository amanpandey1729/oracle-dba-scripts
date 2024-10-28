REM srdc_db_undo_config.sql 
REM collect Undo parameters,segment and transaction details for troubleshooting high Undo space usage issues
define SRDCNAME='DB_Undo_Space'
set pagesize 200 verify off sqlprompt "" term off entmap off echo off
set markup html on spool on
COLUMN SRDCSPOOLNAME NOPRINT NEW_VALUE SRDCSPOOLNAME
select 'SRDC_'||upper('&&SRDCNAME')||'_'||upper(instance_name)||'_'|| to_char(sysdate,'YYYYMMDD_HH24MISS') SRDCSPOOLNAME from v$instance;
spool &&SRDCSPOOLNAME..htm
select 'Diagnostic-Name : ' "Diagnostic-Name ", '&&SRDCNAME' "Report Info" from dual
union all
select 'Time : ' , to_char(systimestamp, 'YYYY-MM-DD HH24MISS TZHTZM' ) from dual
union all
select 'Machine : ' , host_name from v$instance
union all
select 'Version : ',version from v$instance
union all
select 'DBName : ',name from v$database
union all
select 'Instance : ',instance_name from v$instance
/
set echo on


--***********************Run Time**********************

select sysdate from dual;

-- ********************** Parameters **********************

select a.inst_id, a.ksppinm "Parameter",
b.ksppstvl "Session Value",
c.ksppstvl "Instance Value"
from x$ksppi a, x$ksppcv b, x$ksppsv c
where a.indx = b.indx and a.indx = c.indx
and a.inst_id=b.inst_id and b.inst_id=c.inst_id
and a.ksppinm in ('_undo_autotune', '_smu_debug_mode',
'_highthreshold_undoretention',
'undo_tablespace','undo_retention','undo_management') order by 2
/
-- ********************** Undo Segments **********************

select count(*),status,tablespace_name from dba_rollback_segs group by status,tablespace_name
/

set echo off
set sqlprompt "SQL> " term on
set verify on
spool off
set markup html off spool off
