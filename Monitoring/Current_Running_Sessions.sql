set lines 199 pages 100
col username for a25
col sql_text for a65
select sess.sid, sess.username, optimizer_mode, sess.sql_id, cpu_time, elapsed_time, sql_text 
from v$sqlarea sqlarea, v$session sess 
where sess.sql_hash_value=sqlarea.hash_value 
and sess.sql_address=sqlarea.address 
and sess.username is not null;