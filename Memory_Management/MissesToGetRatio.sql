SELECT round((sum(misses) / (sum(gets) + 0.00000000001) * 100), 2) AS "Misses to Gets Ratio %"
FROM v$latch;
