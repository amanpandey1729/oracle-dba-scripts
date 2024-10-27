SQL> SELECT round((sum(DECODE(name, 'free memory', bytes, 0)) / sum(bytes)) * 100, 2) || '%' AS "SGA Free Memory%" FROM v$sgastat;

SGA Free Memory%
-----------------------------------------
9.79%

----------------------------------------------------------------------------
----------------------------------------------------------------------------

SQL> select * from v$sgainfo;

NAME                                  BYTES RES     CON_ID
-------------------------------- ---------- --- ----------
Fixed SGA Size                      8940664 No           0
Redo Buffers                        7835648 No           0
Buffer Cache Size                1291845632 Yes          0
In-Memory Area Size                       0 No           0
Shared Pool Size                  335544320 Yes          0
Large Pool Size                    16777216 Yes          0
Java Pool Size                    100663296 Yes          0
Streams Pool Size                  33554432 Yes          0
Shared IO Pool Size                50331648 Yes          0
Data Transfer Cache Size                  0 Yes          0
Granule Size                       16777216 No           0
Maximum SGA Size                 1795161208 No           0
Startup overhead in Shared Pool   196476024 No           0
Free SGA Memory Available                 0              0

----------------------------------------------------------------------------
----------------------------------------------------------------------------
SET LINESIZE 200
SET PAGESIZE 50
COLUMN component FORMAT A28
COLUMN current_size FORMAT 999,999,999,999
COLUMN min_size FORMAT 999,999,999,999
COLUMN max_size FORMAT 999,999,999,999
COLUMN user_specified_size FORMAT 999,999,999,999
COLUMN oper_count FORMAT 999
COLUMN last_oper_typ FORMAT A10
COLUMN last_oper FORMAT A10
COLUMN granule_size FORMAT 999,999,999
COLUMN con_id FORMAT 999

SQL> select * from v$sga_dynamic_components;

COMPONENT                        CURRENT_SIZE         MIN_SIZE         MAX_SIZE USER_SPECIFIED_SIZE OPER_COUNT LAST_OPER_TYP LAST_OPER LAST_OPER GRANULE_SIZE CON_ID
---------------------------- ---------------- ---------------- ---------------- ------------------- ---------- ------------- --------- --------- ------------ ------
shared pool                       335,544,320      335,544,320      335,544,320                   0          0 STATIC                              16,777,216      0
large pool                         16,777,216       16,777,216       16,777,216                   0          0 STATIC                              16,777,216      0
java pool                         100,663,296      100,663,296      100,663,296                   0          0 STATIC                              16,777,216      0
streams pool                       33,554,432       33,554,432       33,554,432                   0          0 STATIC                              16,777,216      0
unified pga pool                            0                0                0                   0          0 STATIC                              16,777,216      0
memoptimize buffer cache                    0                0                0                   0          0 STATIC                              16,777,216      0
DEFAULT buffer cache            1,241,513,984    1,241,513,984    1,241,513,984                   0          0 INITIALIZING                        16,777,216      0
KEEP buffer cache                           0                0                0                   0          0 STATIC                              16,777,216      0
RECYCLE buffer cache                        0                0                0                   0          0 STATIC                              16,777,216      0
DEFAULT 2K buffer cache                     0                0                0                   0          0 STATIC                              16,777,216      0
DEFAULT 4K buffer cache                     0                0                0                   0          0 STATIC                              16,777,216      0
DEFAULT 8K buffer cache                     0                0                0                   0          0 STATIC                              16,777,216      0
DEFAULT 16K buffer cache                    0                0                0                   0          0 STATIC                              16,777,216      0
DEFAULT 32K buffer cache                    0                0                0                   0          0 STATIC                              16,777,216      0
Shared IO Pool                     50,331,648       50,331,648       50,331,648          50,331,648          0 STATIC                              16,777,216      0
Data Transfer Cache                         0                0                0                   0          0 STATIC                              16,777,216      0
In-Memory Area                              0                0                0                   0          0 STATIC                              16,777,216      0
In Memory RW Extension Area                 0                0                0                   0          0 STATIC                              16,777,216      0
In Memory RO Extension Area                 0                0                0                   0          0 STATIC                              16,777,216      0
ASM Buffer Cache                            0                0                0                   0          0 STATIC                              16,777,216      0

20 rows selected.

----------------------------------------------------------------------------
----------------------------------------------------------------------------

SQL> Select POOL, Round(bytes/1024/1024,0) Free_Memory_In_MB From V$sgastat Where Name Like '%free memory%';

POOL           FREE_MEMORY_IN_MB
-------------- -----------------
shared pool                   34
large pool                    16
java pool                     96
streams pool                  32

----------------------------------------------------------------------------
----------------------------------------------------------------------------
SQL> SELECT sum(value)/1024/1024 "TOTAL SGA (MB)" FROM v$sga;

TOTAL SGA (MB)
--------------
    1711.99914

----------------------------------------------------------------------------
----------------------------------------------------------------------------
SQL> select round(used.bytes /1024/1024 ,2) used_mb, round(free.bytes /1024/1024 ,2) free_mb, 
round(tot.bytes /1024/1024 ,2) total_mb
from (select sum(bytes) bytes from v$sgastat where name != 'free memory') used
, (select sum(bytes) bytes from v$sgastat where name = 'free memory') free
, (select sum(bytes) bytes from v$sgastat) tot ;  2    3    4    5    6    7    8    9   10   11

   USED_MB    FREE_MB   TOTAL_MB
---------- ---------- ----------
   1534.74     177.26       1712


----------------------------------------------------------------------------
----------------------------------------------------------------------------
select * from v$sgastat;

POOL           NAME                            BYTES CON_ID
-------------- -------------------------- ---------- ------
               fixed_sga                     8940664      0
               buffer_cache               1241513984      0
               log_buffer                    7835648      0
               shared_io_pool               50331648      0
			   
select pool, sum(bytes/1024/1024) "MB" from v$sgastat group by pool;	
		   
POOL           							          MB
-------------- 							  ----------
shared pool    							         320
java pool      							          96
streams pool   							          32
										  1247.99914
large pool     							          16


SQL> select pool, sum(bytes/1024/1024) "MB" from v$sgastat where name = 'free memory' group by pool;

POOL                   MB
-------------- ----------
shared pool    29.3595123
java pool              96
streams pool   31.9866333
large pool       15.53125

----------------------------------------------------------------------------
----------------------------------------------------------------------------