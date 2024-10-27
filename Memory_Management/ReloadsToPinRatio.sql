SELECT sum(pins) "Executions", sum(reloads) "Cache Misses",
ROUND((sum(reloads)/sum(pins) * 100),2) "Reloads to Pin Ratio" FROM v$librarycache;
