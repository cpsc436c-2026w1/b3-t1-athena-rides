-- Step 1: predict, then query the course table.
-- Run one statement at a time: select it in the query editor, then Run.

-- March 2024 in the metadata (partition 650 = (2024 - 1970) * 12 + 3 - 1)
SELECT partition, record_count, file_count, total_size
FROM course.course_rides."rides$partitions"
WHERE partition.pickup_datetime_month = 650;
-- one file holds all of March 2024; note its row count

-- Predict first (README, step 1): the whole table, all of March's file, or a small part of it? Then run it.
SELECT count(*) AS trips, round(avg(base_passenger_fare), 2) AS avg_fare
FROM course.course_rides.rides
WHERE pickup_datetime >= TIMESTAMP '2024-03-01 00:00:00'
  AND pickup_datetime <  TIMESTAMP '2024-04-01 00:00:00';
-- the trip count equals the row count above. Look at Data scanned and check your prediction in the README box.

-- Now leave out 1 March. Guess first: more or less than the March query?
SELECT count(*) AS trips, round(avg(base_passenger_fare), 2) AS avg_fare
FROM course.course_rides.rides
WHERE pickup_datetime >= TIMESTAMP '2024-03-02 00:00:00'
  AND pickup_datetime <  TIMESTAMP '2024-04-01 00:00:00';
-- fewer trips than March, but does it read more or less? Check in the README box.

-- The Data scanned limit from setup: predict which of the next two queries it stops. This one runs ...
SELECT round(avg(base_passenger_fare), 2) FROM course.course_rides.rides;
-- an average fare, about the same as March's

-- ... three columns over all months read past your limit and are cancelled ("Bytes scanned limit was exceeded")
SELECT round(avg(base_passenger_fare), 2), round(sum(trip_miles)), count(DISTINCT dispatching_base_num)
FROM course.course_rides.rides;

-- Your turn: another month with a third column, e.g. July 2024 (partition 654) with avg(trip_miles).
-- Predict first: more or less than the March query?
SELECT count(*) AS trips, round(avg(base_passenger_fare), 2) AS avg_fare, round(avg(trip_miles), 2) AS avg_miles
FROM course.course_rides.rides
WHERE pickup_datetime >= TIMESTAMP '2024-07-01 00:00:00'
  AND pickup_datetime <  TIMESTAMP '2024-08-01 00:00:00';
-- more or less than the March query? Check in the README box.
