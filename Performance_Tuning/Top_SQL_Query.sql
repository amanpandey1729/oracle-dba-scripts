set echo off verify off
set lines 160
set pages 200
clear screen
Col Session_Info   heading 'Session Info' format a16 wrapped
Col Memory_MB 	heading 'Mem. in MB' format 99999999
col sql_text 	heading 'SQL Text' format a100 wrapped
select * from (select q.SQL_id, s.username, s.sid||','||s.serial# Session_Info, q.sql_text, q.CPU_TIME, q.RUNTIME_MEM/1048576 Memory_MB 
 from v$sql q, v$session s
 where s.sql_id=q.sql_id order by q.CPU_TIME desc, q.RUNTIME_MEM desc) where rownum <= &Number_of_Sessions; 
