col program form a30 heading "Program"
col CPUMins form 99990 heading "CPU in Mins"
select rownum as rank, a.*
from (
SELECT v.sid,sess.Serial# ,program, v.value / (100 * 60) CPUMins
FROM v$statname s , v$sesstat v, v$session sess
WHERE s.name = 'CPU used by this session'
and sess.sid = v.sid
and v.statistic#=s.statistic#
and v.value>0
ORDER BY v.value DESC) a
where rownum < 11;



      RANK        SID    SERIAL# Program                        CPU in Mins
---------- ---------- ---------- ------------------------------ -----------
         1        257      19199 oracle@oraperf (CJQ0)                    0
         2          4      42313 oracle@oraperf (MMON)                    0
         3         16      49704 oracle@oraperf (MMNL)                    0
         4        237      30322 sqlplus@oraperf (TNS V1-V3)              0
         5        283      28660 oracle@oraperf (M000)                    0
         6        281      64423 oracle@oraperf (Q00G)                    0
         7         12      31837 oracle@oraperf (SMON)                    0
         8         30      59907 oracle@oraperf (M002)                    0
         9        270      64534 oracle@oraperf (W006)                    0
        10        252      10149 oracle@oraperf (W001)                    0


-----------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------

col program form a30 heading "Program"
col cpu_usage_sec form 99990 heading "CPU in Seconds"
col MODULE for a18
col OSUSER for a10
col USERNAME for a15
col OSPID for a06 heading "OS PID"
col SID for 99999
col SERIAL# for 999999
col SQL_ID for a15
set linesize 500
select * from (
select p.spid "ospid",
(se.SID),ss.serial#,ss.SQL_ID,ss.username,substr(ss.program,1,30) "program",
ss.module,ss.osuser,ss.MACHINE,ss.status,
se.VALUE/100 cpu_usage_sec
from v$session ss,v$sesstat se,
v$statname sn,v$process p
where
se.STATISTIC# = sn.STATISTIC#
and NAME like '%CPU used by this session%'
and se.SID = ss.SID
and ss.username !='SYS'
and ss.status='ACTIVE'
and ss.username is not null
and ss.paddr=p.addr and value > 0
order by se.VALUE desc);
