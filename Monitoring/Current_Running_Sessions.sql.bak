set lines 199 pages 100
col username for a25
col sql_text for a65
select session.sid, session.username, optimizer_mode, session.sql_id, cpu_time, elapsed_time, sql_text
from v$sqlarea sqlarea, v$session session
where session.sql_hash_value = sqlarea.hash_value
and session.sql_address = sqlarea.address
session.username is not null;