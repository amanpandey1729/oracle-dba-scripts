select round((sum(decode(name, 'free memory', bytes, 0)) / sum(bytes))* 100,2) || '%' as "SGA Free Memory" from v$sgastat;
