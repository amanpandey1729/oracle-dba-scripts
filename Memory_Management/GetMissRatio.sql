SELECT round((sum(getmisses) / sum(gets) * 100), 2) "Get Miss Ratio %" FROM v$rowcache;
