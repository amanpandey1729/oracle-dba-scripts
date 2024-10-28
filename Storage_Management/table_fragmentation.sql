select 
	owner,
	table_name,
	avg_row_len,
	round(((blocks*16/1024/1024)),2) || 'GB' "TOTAL_SIZE",
	round((num_rows*avg_row_len/1024/1024/1024),2) || 'GB' "ACTUAL_SIZE",
	round(((blocks*16/1024/1024) - (num_rows*avg_row_len/1024/1024/1024)),2) || 'GB' "FRAGMENTED_SPACE",
	round(((round(((blocks*16/1024) - (num_rows*avg_row_len/1024/1024)),2) / round(((blocks*16/1024)),2))*100),2) || '%' "PERCENTAGE"
from
	dba_tables
where
	round(((blocks*16/1024)),2) >1000
	and owner = '&owner'
order by 5 desc;