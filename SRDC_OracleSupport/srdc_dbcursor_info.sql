Rem srdc_dbcursor_info.sql
Rem
Rem Copyright (c) 2006, 2015 Oracle. All rights reserved.
Rem
Rem    NAME
Rem      srdc_dbcursor_info.sql - script to collect  diagnostic details required for  
Rem                       troubleshooting ORA-1000 and other Open cursors related issues.
Rem
Rem    NOTES
Rem      * This script collects the diagnostic data related to single instance 
Rem		   shutdown , for both multitenant and non-multitenant architecture.
Rem		 * The checks here might not be enough for troubleshooting issues . 
Rem		   on RAC or Dataguard. Check the respective SRDC document for 
Rem		   the complete set of data.
Rem		 * The script creates a spool output. Upload it to the Service Request
Rem      * This script contains some checks which might not be relevant for
Rem        all versions.
Rem      * This script will *not* update any data.
Rem      * This script must be run using SQL*PLUS.
Rem      * You must be connected AS SYSDBA to run this script.
Rem
Rem
Rem
Rem    MODIFIED   (MM/DD/YY)
Rem       04/26/19  - created the script
Rem
Rem
Rem
Rem
Rem   
set pagesize 200 verify off sqlprompt "" term off entmap off echo off
set markup html on spool on
define SRDCNAME='DB_CURSORINFO'
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
select * from dba_registry
/
SELECT action_time, action, namespace, version, id, comments FROM dba_registry_history ORDER by action_time desc
/
select * from v$resource_limit
/
select * from v$license
/
set echo off
prompt
prompt ============================================================================================
prompt                         ++ Sessions++
prompt ============================================================================================
prompt
set echo on
select count(*) from v$session
/
select username,count(*) from v$session group by username
/
show parameter sessions
show parameter processes
show parameter open_cursors
set echo off
prompt
prompt ============================================================================================
prompt                         ++ Cursor Configuration and Usage ++
prompt ============================================================================================
prompt
set echo on
SELECT  max(a.value) as highest_open_cur, p.value as max_open_cur FROM v$sesstat a, v$statname b, v$parameter p WHERE  a.statistic# = b.statistic#  and b.name = 'opened cursors current' and p.name= 'open_cursors' group by p.value
/

select count(*) from v$open_cursor
/

select value, name from v$sysstat where statistic# in (2,3)
/

select value from v$sysstat sy , gv$statname st where sy.statistic# = st.statistic# and st.name = 'opened cursors current'
/
select 'Sessions_with_high_openCursors' "CHECK_NAME",a.value, s.username, s.sid, s.serial# from v$sesstat a, v$statname b, v$session s where a.statistic# = b.statistic#  and s.sid=a.sid and b.name = 'opened cursors current' and s.username is not null
/
select  'Details_of_Opencursors' "CHECK_NAME",sid ,sql_text, USER_NAME , count(*) as "OPEN CURSORS"from v$open_cursor where sid in (select sid from (select s.sid from v$sesstat a, v$statname b, v$session s where a.statistic# = b.statistic#  and s.sid=a.sid and b.name = 'opened cursors current' and s.username is not null order by a.value) where rownum <25) group by sid,sql_text,USER_NAME 
/

set serveroutput on
declare 
   cursor opencur is select * from v$open_cursor; 
   ccount number; 
begin 
   select count(*) into ccount from v$open_cursor; 
   dbms_output.put_line(' Num cursors open is '||ccount); 
   ccount := 0; 
   -- get text of open/parsed cursors 
   for vcur in opencur loop 
      ccount := ccount + 1; 
      dbms_output.put_line(' Cursor #'||ccount); 
      dbms_output.put_line(' text: '|| vcur.sql_text); 
   end loop; 
end; 
/
set echo off
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