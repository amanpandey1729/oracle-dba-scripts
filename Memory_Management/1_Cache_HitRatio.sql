SELECT ROUND(((1 - (phy.value-lob.value-dir.value)/ ses.value) * 100),2)
"Cache Hit Ratio"
  FROM   v$sysstat phy, v$sysstat lob, v$sysstat dir, v$sysstat ses
  WHERE  phy.name = 'physical reads'
  AND    lob.name = 'physical reads direct (lob)'
  AND    dir.name = 'physical reads direct'
  AND  ses.name = 'session logical reads';
