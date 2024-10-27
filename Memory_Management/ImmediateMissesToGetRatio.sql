SELECT round((sum(immediate_misses) / 
(sum(immediate_misses + immediate_gets)+0.00000000001) * 100), 2)
AS "Imm. Misses to Gets Ratio %"
FROM v$latch;
