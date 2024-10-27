SELECT to_char(disk.value, '9999999999.99') AS "Sorts on Disk", to_char(mem.value,'9999999999.99') AS "Sorts in Memory",
   ROUND(disk.value/mem.value*100,2) AS "Disk to Memory Sort Ratio %"
   FROM v$sysstat mem, v$sysstat disk
   WHERE mem.name='sorts (memory)'
   AND disk.name='sorts (disk)';
