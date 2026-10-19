-- Extra exercises: do them after Step 6.

-- A. Delete the zero-mile trips and look back.
SELECT count(*) FROM tutorial.rides_march WHERE trip_miles = 0;
-- Note this number.
DELETE FROM tutorial.rides_march WHERE trip_miles = 0;
SELECT count(*) FROM tutorial.rides_march WHERE trip_miles = 0;
-- 0: none remain.
-- Now count them FOR VERSION AS OF the snapshot just before the delete: the number you noted comes back.

-- B. Two writes at about the same time. Open a second query editor tab, put one statement in each tab,
--    and start them as close together as you can.
-- First, two loads of different days, one per tab. Both succeed, and $snapshots shows an append for each.
INSERT INTO tutorial.rides_march
SELECT *, CAST(NULL AS varchar) FROM course.course_rides.rides
WHERE pickup_datetime >= TIMESTAMP '2024-04-02 00:00:00' AND pickup_datetime < TIMESTAMP '2024-04-03 00:00:00';

INSERT INTO tutorial.rides_march
SELECT *, CAST(NULL AS varchar) FROM course.course_rides.rides
WHERE pickup_datetime >= TIMESTAMP '2024-04-03 00:00:00' AND pickup_datetime < TIMESTAMP '2024-04-04 00:00:00';

-- Then two deletes, one per tab. If they overlap, Athena rejects one with ICEBERG_COMMIT_ERROR:
-- run it again and it succeeds. If both succeed, Athena ran them one after the other: try again.
DELETE FROM tutorial.rides_march WHERE tips > 50;

DELETE FROM tutorial.rides_march WHERE driver_pay < 0;
