
sqlplus / as sysdba

drop user frag_user cascade;
DROP TABLESPACE frag_ts INCLUDING CONTENTS AND DATAFILES;
alter system flush shared_pool;
alter system flush buffer_cache;

--------------------------------------------------------------------------------------------------------------------------------
-- 1. Create a tablespace and a user for the demo
CREATE TABLESPACE frag_ts DATAFILE '/u01/app/oracle/oradata/ORCL/frag_ts.dbf' SIZE 500M AUTOEXTEND ON NEXT 100M MAXSIZE 2G;

CREATE USER frag_user IDENTIFIED BY password DEFAULT TABLESPACE frag_ts QUOTA UNLIMITED ON frag_ts;
GRANT CONNECT, RESOURCE TO frag_user;

-- 2. Create a table that we will fragment and defragment
CREATE TABLE frag_user.test_table (
  id NUMBER PRIMARY KEY,
  data VARCHAR2(4000)
) TABLESPACE frag_ts;

-- 3. Insert initial data to fill up the table
DECLARE
  v_data VARCHAR2(4000);
BEGIN
  FOR i IN 1..50000 LOOP
    v_data := DBMS_RANDOM.STRING('A', 4000);
    INSERT INTO frag_user.test_table (id, data) VALUES (i, v_data);
    IF MOD(i, 1000) = 0 THEN
      COMMIT;
    END IF;
  END LOOP;
  COMMIT;
END;
/

-- 4. Create index on the table and analyze the table and index
CREATE INDEX frag_user.test_index ON frag_user.test_table(data) tablespace frag_ts;


analyze table frag_user.test_table compute statistics;
analyze index frag_user.test_index compute statistics;

-- 5. Check space using dba_segments for the table and index
set lines 999;
col segment_name for a20;
SELECT SEGMENT_TYPE, SEGMENT_NAME, ROUND(BYTES/1024/1024,1) MB, BLOCKS, 
EXTENTS FROM   DBA_SEGMENTS 
WHERE  SEGMENT_NAME IN ('TEST_TABLE','TEST_INDEX');


-- 6. Delete some data to simulate fragmentation
DELETE FROM frag_user.test_table WHERE MOD(id, 2) = 0;
COMMIT;

-- 7. Check the extent and fragmentation details
SELECT segment_name, COUNT(*) AS extents
FROM dba_extents
WHERE owner = 'FRAG_USER' AND segment_name = 'TEST_TABLE'
GROUP BY segment_name;

-- 8. Defragmentation using SHRINK SPACE
ALTER TABLE frag_user.test_table ENABLE ROW MOVEMENT;
ALTER TABLE frag_user.test_table SHRINK SPACE CASCADE;

ALTER TABLE frag_user.test_table DISABLE ROW MOVEMENT;

-- 9. Defragmentation using ALTER TABLE MOVE (Offline)
ALTER TABLE frag_user.test_table MOVE;

-- 10. Defragmentation using ALTER TABLE MOVE ONLINE
ALTER TABLE frag_user.test_table MOVE ONLINE;


-- 10. Query to evaluate space usage before and after defragmentation
SELECT segment_name, SUM(bytes)/1024/1024 AS mb_used
FROM dba_segments
WHERE owner = 'FRAG_USER' AND segment_name = 'TEST_TABLE'
GROUP BY segment_name;

-- 11. Check which method was the most efficient by querying extents and space usage
SELECT segment_name, COUNT(*) AS extents, SUM(bytes)/1024/1024 AS mb_used
FROM dba_extents
WHERE owner = 'FRAG_USER'
GROUP BY segment_name;

-- 12. Cleanup: Drop the user and tablespace to remove the test environment
drop user frag_user cascade;
DROP TABLESPACE frag_ts INCLUDING CONTENTS AND DATAFILES;
alter system flush shared_pool;
alter system flush buffer_cache;
