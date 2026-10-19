-- Step 1: predict, then query the course table.
-- Run one statement at a time: select it in the query editor, then press Run.

-- Find March 2024 in the metadata (partition 650 = (2024 - 1970) * 12 + 3 - 1).
SELECT partition, record_count, file_count, total_size
FROM course.course_rides."rides$partitions"
WHERE partition.pickup_datetime_month = 650;
-- One file holds all of March 2024. Note its row count.

-- Before you run this: will Athena read the whole table, all of March's file, or only part of that file?
SELECT count(*) AS trips, round(avg(base_passenger_fare), 2) AS avg_fare
FROM course.course_rides.rides
WHERE pickup_datetime >= TIMESTAMP '2024-03-01 00:00:00'
  AND pickup_datetime <  TIMESTAMP '2024-04-01 00:00:00';
-- The trip count should match the row count above. Look at Data scanned under the results.

-- The same query, starting on 2 March 2024.
-- Before you run it: will Athena read more data than for the March query, or less?
SELECT count(*) AS trips, round(avg(base_passenger_fare), 2) AS avg_fare
FROM course.course_rides.rides
WHERE pickup_datetime >= TIMESTAMP '2024-03-02 00:00:00'
  AND pickup_datetime <  TIMESTAMP '2024-04-01 00:00:00';
-- Fewer trips than the March query. Compare Data scanned with the March query.

-- The next two queries have no date filter, so they cover all 36 months.
-- Before you run them: which one will your Data scanned limit stop?
SELECT round(avg(base_passenger_fare), 2) FROM course.course_rides.rides;

SELECT round(avg(base_passenger_fare), 2), round(sum(trip_miles)), count(DISTINCT dispatching_base_num)
FROM course.course_rides.rides;
-- Check your answer in the README's Step 1 box.

-- Your turn: July 2024 (partition 654). Run this one and note Data scanned.
SELECT count(*) AS trips, round(avg(base_passenger_fare), 2) AS avg_fare
FROM course.course_rides.rides
WHERE pickup_datetime >= TIMESTAMP '2024-07-01 00:00:00'
  AND pickup_datetime <  TIMESTAMP '2024-08-01 00:00:00';

-- The same July query with the average trip distance added.
-- Before you run it: will Athena read more data than for the first July query, or less?
SELECT count(*) AS trips, round(avg(base_passenger_fare), 2) AS avg_fare, round(avg(trip_miles), 2) AS avg_miles
FROM course.course_rides.rides
WHERE pickup_datetime >= TIMESTAMP '2024-07-01 00:00:00'
  AND pickup_datetime <  TIMESTAMP '2024-08-01 00:00:00';
-- Check your answers in the README's Step 1 box.
