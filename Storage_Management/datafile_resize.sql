select * from 
(select file_name, 
ceil( (nvl(hwm,1)*&&blksize)/1024/1024 ) smallest, 
ceil( blocks*&&blksize/1024/1024) currsize, 
ceil( blocks*&&blksize/1024/1024) - 
ceil( (nvl(hwm,1)*&&blksize)/1024/1024 ) savings, 
'alter  database datafile ''' || file_name || ''' resize ' || ceil( (nvl(hwm,1)*&&blksize)/1024/1024 ) || 'M;'  sql 
from dba_data_files a, 
( select file_id, max(block_id+blocks-1) hwm 
from dba_extentsgroup by file_id ) b 
where a.file_id = b.file_id(+)
) 
where savings > 0 
order by savings desc;
