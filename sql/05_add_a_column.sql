-- Step 5: add a column, then look at an old snapshot.

ALTER TABLE tutorial.rides_march ADD COLUMNS (trip_flag string);

UPDATE tutorial.rides_march SET trip_flag = 'zero_miles' WHERE trip_miles = 0;

SELECT trip_flag, count(*) FROM tutorial.rides_march GROUP BY trip_flag;
-- zero_miles for the trips with no miles, NULL for all the others.

-- Rerun Step 3's snapshots query and paste the oldest row's snapshot_id here.
SELECT trip_flag, count(*) FROM tutorial.rides_march
FOR VERSION AS OF <snapshot_id of the first append>
GROUP BY trip_flag;
-- Athena rejects it with COLUMN_NOT_FOUND: an old snapshot is read with the columns the table had then.

-- A load with SELECT * from the course table. Your copy has one column more now.
INSERT INTO tutorial.rides_march
SELECT * FROM course.course_rides.rides
WHERE pickup_datetime >= TIMESTAMP '2024-04-05 00:00:00'
  AND pickup_datetime <  TIMESTAMP '2024-04-06 00:00:00';
-- Athena rejects it with TYPE_MISMATCH.

-- The same load, supplying NULL for the new column.
INSERT INTO tutorial.rides_march
SELECT *, CAST(NULL AS varchar) FROM course.course_rides.rides
WHERE pickup_datetime >= TIMESTAMP '2024-04-05 00:00:00'
  AND pickup_datetime <  TIMESTAMP '2024-04-06 00:00:00';

SELECT count(*) AS loaded_rows, count_if(trip_flag IS NULL) AS rows_without_flag
FROM tutorial.rides_march
WHERE pickup_datetime >= TIMESTAMP '2024-04-05 00:00:00'
  AND pickup_datetime <  TIMESTAMP '2024-04-06 00:00:00';
-- The two numbers match: none of the loaded rows has a flag.
