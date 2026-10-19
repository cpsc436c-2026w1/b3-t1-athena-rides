-- Step 1: predict, then query the course table.
-- Run one statement at a time: select it in the query editor, then Run.

-- How big is March 2024? (partition 650 = (2024 - 1970) * 12 + 3 - 1)
SELECT partition, record_count, file_count, total_size
FROM course.course_rides."rides$partitions"
WHERE partition.pickup_datetime_month = 650;
-- 21280788 rows, 1 file, 508032483 bytes (508 MB)

-- Write down how much you expect this query to read, then run it and compare with "Data scanned":
SELECT count(*) AS trips, round(avg(base_passenger_fare), 2) AS avg_fare
FROM course.course_rides.rides
WHERE pickup_datetime >= TIMESTAMP '2024-03-01 00:00:00'
  AND pickup_datetime <  TIMESTAMP '2024-04-01 00:00:00';
-- 21280788 trips, 25.55. Compare Data scanned with your guess; the README's step 1 box explains it.

-- Now leave out 1 March. Guess first: more or less than the March query?
SELECT count(*) AS trips, round(avg(base_passenger_fare), 2) AS avg_fare
FROM course.course_rides.rides
WHERE pickup_datetime >= TIMESTAMP '2024-03-02 00:00:00'
  AND pickup_datetime <  TIMESTAMP '2024-04-01 00:00:00';
-- 20519713 trips, 25.56. Check Data scanned against your guess (README, step 1 box).

-- The Data scanned limit from setup: one column over all 36 months stays under 2 GB and runs ...
SELECT round(avg(base_passenger_fare), 2) FROM course.course_rides.rides;
-- 25.94

-- ... three columns over all months read past 2 GB and are cancelled ("Bytes scanned limit was exceeded")
SELECT round(avg(base_passenger_fare), 2), round(sum(trip_miles)), count(DISTINCT dispatching_base_num)
FROM course.course_rides.rides;

-- Your turn: another month with a third column, e.g. July 2024 (partition 654) with avg(trip_miles).
-- Predict the data read first.
SELECT count(*) AS trips, round(avg(base_passenger_fare), 2) AS avg_fare, round(avg(trip_miles), 2) AS avg_miles
FROM course.course_rides.rides
WHERE pickup_datetime >= TIMESTAMP '2024-07-01 00:00:00'
  AND pickup_datetime <  TIMESTAMP '2024-08-01 00:00:00';
-- 19182934 trips, 25.65, 5.15. Check Data scanned against your guess (README, step 1 box).
