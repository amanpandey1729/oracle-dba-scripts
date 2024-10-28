SELECT STATUS, STATE, COUNT(*) FROM V$SESSION GROUP BY ROLLUP (STATUS, STATE);

STATUS STATE                 COUNT(*)
------ ------------------- ----------
ACTIVE WAITING                     51
ACTIVE WAITED SHORT TIME            1
ACTIVE                             52
INACTI WAITING                      1
INACTI                              1
                                   53

SELECT STATUS, COUNT(*) FROM V$SESSION GROUP BY ROLLUP (STATUS);

select username, status, count(*) from v$session where username is not null group by username, status order by 1,2;

USERNAME STATUS   COUNT(*)
-------- ------ ----------
SYS      ACTIVE          2
SYS      INACTI          1

------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------


set echo off
set linesize 95
set head on
set feedback on
set pages 100
col sid head "Sid" form 9999 trunc
col serial# form 99999 trunc head "Ser#"
col username form a8 trunc
col osuser form a7 trunc
col machine form a20 trunc head "Client|Machine"
col program form a15 trunc head "Client|Program"
col login form a11
col "last call" form 9999999 trunc head "Last Call|In Secs"
col status form a6 trunc
select sid,serial#,substr(username,1,10) username,substr(osuser,1,10) osuser,
substr(program||module,1,15) program,substr(machine,1,22) machine,
to_char(logon_time,'ddMon hh24:mi') login,
last_call_et "last call",status
from gv$session where status='ACTIVE'
order by 1
/


------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------

--Displays SQL statements for the current database sessions

SET VERIFY OFF
SET LINESIZE 255
COL SID FORMAT 999
COL STATUS FORMAT A8
COL PROCESS FORMAT A10
COL SCHEMANAME FORMAT A16
COL OSUSER  FORMAT A16
COL SQL_TEXT FORMAT A75 HEADING 'SQL QUERY'
COL PROGRAM	FORMAT A30

SELECT s.sid,
       s.status,
       s.process,
       s.schemaname,
       s.osuser,
       a.sql_text,
       p.program
FROM   v$session s,
       v$sqlarea a,
       v$process p
WHERE  s.SQL_HASH_VALUE = a.HASH_VALUE
AND    s.SQL_ADDRESS = a.ADDRESS
AND    s.PADDR = p.ADDR
/

SET VERIFY ON
SET LINESIZE 255