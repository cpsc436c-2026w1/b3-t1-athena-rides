-- Step 6: one query reads your catalog and the course catalog together.

SELECT z.borough, count(*) AS trips, round(avg(r.base_passenger_fare), 2) AS avg_fare
FROM tutorial.rides_march r
JOIN course.course_rides.zones z ON r.pulocationid = z.locationid
WHERE r.pickup_datetime < TIMESTAMP '2024-04-01 00:00:00'     -- March only, not the April day
GROUP BY z.borough
ORDER BY trips DESC;
-- Manhattan first, then Brooklyn and Queens

-- The course table still has the negative fares you deleted from your copy:
SELECT count(*) FROM course.course_rides.rides
WHERE pickup_datetime >= TIMESTAMP '2024-03-01 00:00:00'
  AND pickup_datetime <  TIMESTAMP '2024-04-01 00:00:00'
  AND base_passenger_fare < 0;
-- the same number you counted in your copy before the delete
