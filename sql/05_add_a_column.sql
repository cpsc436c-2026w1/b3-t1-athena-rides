-- Step 5: add a column, then look at an old snapshot.

ALTER TABLE tutorial.rides_march ADD COLUMNS (trip_flag string);

UPDATE tutorial.rides_march SET trip_flag = 'zero_miles' WHERE trip_miles = 0;

SELECT trip_flag, count(*) FROM tutorial.rides_march GROUP BY trip_flag;
-- zero_miles 3026 (2954 in March plus 72 on 1 April), the rest NULL

-- Paste the snapshot_id of the FIRST append (from step 3)
SELECT trip_flag, count(*) FROM tutorial.rides_march
FOR VERSION AS OF <snapshot_id of the first append>
GROUP BY trip_flag;
-- fails with COLUMN_NOT_FOUND: an old snapshot is read with the columns the table had then

-- A SELECT * load from the course table now fails with TYPE_MISMATCH (your copy has one column more).
-- A load after a schema change names its columns, or adds the new one:
--   INSERT INTO tutorial.rides_march SELECT *, CAST(NULL AS varchar) FROM course.course_rides.rides WHERE ...
