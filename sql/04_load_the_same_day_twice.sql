-- Step 4: load the same day twice, then repair.

-- Load 1 April 2024 into your copy. Run this statement TWICE.
INSERT INTO tutorial.rides_march
SELECT * FROM course.course_rides.rides
WHERE pickup_datetime >= TIMESTAMP '2024-04-01 00:00:00'
  AND pickup_datetime <  TIMESTAMP '2024-04-02 00:00:00';

-- Compare the day in your copy with the day in the course table.
SELECT 'your copy' AS source, count(*) AS trips
FROM tutorial.rides_march
WHERE pickup_datetime >= TIMESTAMP '2024-04-01 00:00:00'
  AND pickup_datetime <  TIMESTAMP '2024-04-02 00:00:00'
UNION ALL
SELECT 'course table' AS source, count(*) AS trips
FROM course.course_rides.rides
WHERE pickup_datetime >= TIMESTAMP '2024-04-01 00:00:00'
  AND pickup_datetime <  TIMESTAMP '2024-04-02 00:00:00';
-- Your copy has twice the course table's count.

SELECT operation, summary['added-records'] AS added
FROM tutorial."rides_march$snapshots"
ORDER BY committed_at;
-- The last two appends show the same added value.

-- Repair: remove the day, then load it once.
DELETE FROM tutorial.rides_march
WHERE pickup_datetime >= TIMESTAMP '2024-04-01 00:00:00'
  AND pickup_datetime <  TIMESTAMP '2024-04-02 00:00:00';

INSERT INTO tutorial.rides_march
SELECT * FROM course.course_rides.rides
WHERE pickup_datetime >= TIMESTAMP '2024-04-01 00:00:00'
  AND pickup_datetime <  TIMESTAMP '2024-04-02 00:00:00';
-- Run the comparison query again: the two counts now match.
