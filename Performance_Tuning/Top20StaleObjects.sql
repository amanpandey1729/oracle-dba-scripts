WITH stale_objects AS (
    SELECT owner, table_name
    FROM dba_tab_statistics
    WHERE stale_stats = 'YES'
),
dml_breakdown AS (
    SELECT 
        m.table_owner AS owner, 
        m.table_name, 
        m.inserts AS insert_count, 
        m.updates AS update_count, 
        m.deletes AS delete_count
    FROM dba_tab_modifications m
    JOIN dba_tables t 
        ON m.table_name = t.table_name 
       AND m.table_owner = t.owner
    WHERE m.inserts + m.updates + m.deletes > 0
),
select_activity AS (
    SELECT 
        p.object_owner AS owner, 
        p.object_name AS table_name,
        SUM(s.executions_delta) AS select_count
    FROM dba_hist_sqlstat s
    JOIN dba_hist_sql_plan p 
        ON s.sql_id = p.sql_id
    WHERE p.object_type = 'TABLE'
      AND p.object_owner NOT IN ('SYS', 'SYSTEM')
      AND s.snap_id BETWEEN 
            (SELECT MAX(snap_id) - 1 FROM dba_hist_snapshot)
        AND 
            (SELECT MAX(snap_id) FROM dba_hist_snapshot)
    GROUP BY p.object_owner, p.object_name
),
combined AS (
    SELECT 
        COALESCE(s.owner, d.owner, sel.owner) AS owner,
        COALESCE(s.table_name, d.table_name, sel.table_name) AS table_name,
        'YES' AS stale_stats,
        NVL(d.insert_count, 0) AS insert_count,
        NVL(d.update_count, 0) AS update_count,
        NVL(d.delete_count, 0) AS delete_count,
        NVL(sel.select_count, 0) AS select_count,
        NVL(d.insert_count, 0) + NVL(d.update_count, 0) + NVL(d.delete_count, 0) + NVL(sel.select_count, 0) AS total_activity
    FROM stale_objects s
    FULL OUTER JOIN dml_breakdown d 
        ON s.owner = d.owner AND s.table_name = d.table_name
    FULL OUTER JOIN select_activity sel 
        ON COALESCE(s.owner, d.owner) = sel.owner 
       AND COALESCE(s.table_name, d.table_name) = sel.table_name
)
SELECT DISTINCT
    owner,
    table_name,
    stale_stats,
    insert_count,
    update_count,
    delete_count,
    select_count,
    total_activity
FROM combined
ORDER BY total_activity DESC
FETCH FIRST 20 ROWS ONLY;