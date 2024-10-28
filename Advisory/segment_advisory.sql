DECLARE
   TSK_ID          NUMBER;
   TSK_NAME        VARCHAR2(100);
   TSK_DESCRIPTION VARCHAR2(500);
   OBJ_ID          NUMBER;
BEGIN
   TSK_NAME        := 'ANALYZE_TEST_TABLE_TASK1';
   TSK_DESCRIPTION := 'Segment advice for TEST_TABLE';
   
   -- 1. Create a Task
   DBMS_ADVISOR.CREATE_TASK(
      ADVISOR_NAME => 'Segment Advisor',
      TASK_ID      => TSK_ID,
      TASK_NAME    => TSK_NAME,
      TASK_DESC    => TSK_DESCRIPTION);
      
   -- 2. Assign the object to the task 
   DBMS_ADVISOR.CREATE_OBJECT(
      TASK_NAME    => TSK_NAME,
      OBJECT_TYPE  => 'TABLE',
      ATTR1        => 'FRAG_USER',
      ATTR2        => 'TEST_TABLE',
      ATTR3        => NULL,
      ATTR4        => NULL,
      ATTR5        => NULL,
      OBJECT_ID    => OBJ_ID);

   -- 3. Set the task parameters
   DBMS_ADVISOR.SET_TASK_PARAMETER(
      TASK_NAME    => TSK_NAME,
      PARAMETER    => 'recommend_all',
      VALUE        => 'TRUE');

   -- 4. Execute the task 
   DBMS_ADVISOR.EXECUTE_TASK(TSK_NAME);
   
END;
/

----------------------------------------------------------------

SET SERVEROUTOUT ON
DECLARE
   TSK_ID          NUMBER;
   TSK_NAME        VARCHAR2(100);
   TSK_DESCRIPTION VARCHAR2(500);
   OBJ_ID          NUMBER;
BEGIN
   TSK_NAME        := 'ANALYZE_TEST_INDEX_TASK';
   TSK_DESCRIPTION := 'Segment advice for TEST_INDEX';
   
   -- 1. Create a Task
   DBMS_ADVISOR.CREATE_TASK(
      ADVISOR_NAME => 'Segment Advisor',
      TASK_ID      => TSK_ID,
      TASK_NAME    => TSK_NAME,
      TASK_DESC    => TSK_DESCRIPTION);
      
   -- 2. Assign the object to the task 
   DBMS_ADVISOR.CREATE_OBJECT(
      TASK_NAME    => TSK_NAME,
      OBJECT_TYPE  => 'INDEX',
      ATTR1        => 'SYS',
      ATTR2        => 'TEST_INDEX',
      ATTR3        => NULL,
      ATTR4        => NULL,
      ATTR5        => NULL,
      OBJECT_ID    => OBJ_ID);

   -- 3. Set the task parameters
   DBMS_ADVISOR.SET_TASK_PARAMETER(
      TASK_NAME    => TSK_NAME,
      PARAMETER    => 'recommend_all',
      VALUE        => 'TRUE');

   -- 4. Execute the task 
   DBMS_ADVISOR.EXECUTE_TASK(TSK_NAME);
   
END;
/

-----------------------------------------
SET LINES 300
SET PAGES 999
COL SEGNAME FOR A15
COL PARTITION FOR A10
COL TYPE FOR A10
COL MESSAGE FOR A60
SELECT DAO.ATTR2 SEGNAME, 
       DAO.ATTR3 PARTITION, 
       DAO.TYPE, 
       DAF.MESSAGE 
FROM   DBA_ADVISOR_FINDINGS DAF, 
       DBA_ADVISOR_OBJECTS DAO 
WHERE  DAO.TASK_ID = DAF.TASK_ID AND 
       DAO.OBJECT_ID = DAF.OBJECT_ID AND 
       DAF.TASK_NAME IN ('ANALYZE_TEST_TABLE_TASK1','ANALYZE_TEST_INDEX_TASK');
	   
	   
-------------------------------------------

EXEC DBMS_ADVISOR.DELETE_TASK(TASK_NAME => 'ANALYZE_TEST_TABLE_TASK1');
EXEC DBMS_ADVISOR.DELETE_TASK(TASK_NAME => 'ANALYZE_TEST_INDEX_TASK');