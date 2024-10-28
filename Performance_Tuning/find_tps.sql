/*
 * Purpose: Shows TPS history captured in AWR
 */
 
 
set echo off
set feedback off
set serverout on
set termout on

set linesize 100
set pagesize 0
set pause off
set long 80

set heading on
set headsep on
set underline on
set colsep " "

set define on
set verify off
set escape off
set embedded on

col sno for 9999 heading "#"
col snid for 999999 heading "SnapID"
col time for a15 heading "Begin Time"
col name for a45 heading "Name"
col aval for 99,999,999 heading "Average"
col mval for 99,999,999 heading "Maximum"

accept p_bsnap prompt "Enter Begin Snap Id: "
accept p_esnap prompt "Enter End Snap Id: "
accept p_order prompt "Enter sort order [asc|desc]: "

spool tps_hist.log

select
		row_number() over(order by snap_id &&p_order)		sno,
		snap_id												snid,
		to_char(begin_interval_time,'yyyymmdd hh24:mi')		time,
		metric_name											name,
		avalue												aval,
		mvalue												mval
from
		(
				select 
						s.snap_id,
						s.begin_interval_time,
						t.metric_name,
						avg(value) avalue,
						max(value) mvalue
				from
						dba_hist_snapshot s, dba_hist,sysmetric_history t
				where
						s.snap_id=t.snap_id
				and		s.instance_number=t.instance_number
				and		s.dbid=t.dbid
				and		s.instance_number=(select instance_number from v$instance)
				and		s.dbid=(select dbid from v$database)
				and		t.metric_name='User Transaction Per Sec'
				and		s.snap_id between &p_bsnap and &p_esnap
				group by
						s.snap_id,
						s.begin_interval_time,
						t.metric_name
				order by
						s.snap_id desc
);

spool off

clear coloumns

set embedded off
set escape off
set verify on
set define on

set colsep " "
set underline on
set headsep on
set heading on

set pause off
set pagesize 24
set linesize 80
set long 80

set termout on
set serverout off
set feedback on
set echo off					