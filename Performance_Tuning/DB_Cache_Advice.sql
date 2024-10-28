COLUMN size_for_estimate          FORMAT 999,999,999,999 heading 'Cache Size (MB)'
COLUMN size_factor                FORMAT 9.99 heading 'Size Factor'
COLUMN buffers_for_estimate       FORMAT 999,999,999 heading 'Buffers'
COLUMN estd_physical_read_factor  FORMAT 999.90 heading 'Estd Phys|Read Factor'
COLUMN estd_physical_reads        FORMAT 999,999,999,999 heading 'Estd Phys| Reads'
COLUMN ESTD_PCT_OF_DB_TIME_FOR_READS FORMAT 99.99% heading 'Estd % of DB Time for Reads'
SELECT size_for_estimate,
	   size_factor,
       buffers_for_estimate,
       estd_physical_read_factor,
       estd_physical_reads,
	   ESTD_PCT_OF_DB_TIME_FOR_READS
FROM   v$db_cache_advice
WHERE  name          = 'DEFAULT'
AND    block_size    = (SELECT value
                        FROM   v$parameter
                        WHERE  name = 'db_block_size')
AND    advice_status = 'ON';

 Cache Size (MB) Size Factor      Buffers Read Factor            Reads ESTD_PCT_OF_DB_TIME_FOR_READS
---------------- ----------- ------------ ----------- ---------------- -----------------------------
             112         .10       13,706        1.43           39,971                          18.4
             224         .19       27,412        1.05           29,144                          12.2
             336         .29       41,118        1.00           27,885                          10.2
             448         .38       54,824        1.00           27,885                          10.2
             560         .48       68,530        1.00           27,885                          10.2
             672         .58       82,236        1.00           27,885                          10.2
             784         .67       95,942        1.00           27,885                          10.2
             896         .77      109,648        1.00           27,885                          10.2
           1,008         .86      123,354        1.00           27,885                          10.2
           1,120         .96      137,060        1.00           27,885                          10.2
           1,168        1.00      142,934        1.00           27,885                          10.2
           1,232        1.05      150,766        1.00           27,885                          10.2
           1,344        1.15      164,472        1.00           27,885                          10.2
           1,456        1.25      178,178        1.00           27,885                          10.2
           1,568        1.34      191,884        1.00           27,885                          10.2
           1,680        1.44      205,590        1.00           27,885                          10.2
           1,792        1.53      219,296        1.00           27,885                          10.2
           1,904        1.63      233,002        1.00           27,885                          10.2
           2,016        1.73      246,708        1.00           27,885                          10.2
           2,128        1.82      260,414        1.00           27,885                          10.2
           2,240        1.92      274,120        1.00           27,885                          10.2

