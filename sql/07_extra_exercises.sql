-- Extra exercises (after the tutorial, or if you finish early).

-- A. Delete the zero-mile trips and look back
SELECT count(*) FROM tutorial.rides_march WHERE trip_miles = 0;          -- 3026
DELETE FROM tutorial.rides_march WHERE trip_miles = 0;
SELECT count(*) FROM tutorial.rides_march WHERE trip_miles = 0;          -- 0
-- then count them FOR VERSION AS OF the snapshot just before the delete: 3026 again

-- B. Two writers at once: open a second query editor tab, prepare one statement in each, press Run in both
--    within a second or two.
-- First try, two loads of different days (one per tab): both succeed, two appends in $snapshots.
INSERT INTO tutorial.rides_march
SELECT *, CAST(NULL AS varchar) FROM course.course_rides.rides
WHERE pickup_datetime >= TIMESTAMP '2024-04-02 00:00:00' AND pickup_datetime < TIMESTAMP '2024-04-03 00:00:00';

INSERT INTO tutorial.rides_march
SELECT *, CAST(NULL AS varchar) FROM course.course_rides.rides
WHERE pickup_datetime >= TIMESTAMP '2024-04-03 00:00:00' AND pickup_datetime < TIMESTAMP '2024-04-04 00:00:00';

-- Second try, two corrections (one per tab): one succeeds, the other fails with ICEBERG_COMMIT_ERROR.
-- Run the failed one again and it succeeds.
DELETE FROM tutorial.rides_march WHERE tips > 50;

DELETE FROM tutorial.rides_march WHERE driver_pay < 0;
