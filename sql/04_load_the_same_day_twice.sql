-- Step 4: load the same day twice, then repair.

-- Load 1 April 2024 into your copy. Run this statement TWICE.
INSERT INTO tutorial.rides_march
SELECT * FROM course.course_rides.rides
WHERE pickup_datetime >= TIMESTAMP '2024-04-01 00:00:00'
  AND pickup_datetime <  TIMESTAMP '2024-04-02 00:00:00';

SELECT count(*) FROM tutorial.rides_march
WHERE pickup_datetime >= TIMESTAMP '2024-04-01 00:00:00'
  AND pickup_datetime <  TIMESTAMP '2024-04-02 00:00:00';
-- 1122474: twice the course table's 561237

SELECT operation, summary['added-records'] AS added
FROM tutorial."rides_march$snapshots"
ORDER BY committed_at;
-- two appends of 561237 at the end

-- Repair: remove the day, then load it once
DELETE FROM tutorial.rides_march
WHERE pickup_datetime >= TIMESTAMP '2024-04-01 00:00:00'
  AND pickup_datetime <  TIMESTAMP '2024-04-02 00:00:00';

INSERT INTO tutorial.rides_march
SELECT * FROM course.course_rides.rides
WHERE pickup_datetime >= TIMESTAMP '2024-04-01 00:00:00'
  AND pickup_datetime <  TIMESTAMP '2024-04-02 00:00:00';
-- run the count again: 561237
