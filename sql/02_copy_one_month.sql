-- Step 2: copy one month into your own account (CTAS).
-- Replace <your-bucket> with your bucket's name (setup_athena.sh printed it).

CREATE DATABASE IF NOT EXISTS tutorial;

CREATE TABLE tutorial.rides_march
WITH (table_type = 'ICEBERG',
      location = 's3://<your-bucket>/tutorial/rides_march/',
      is_external = false)
AS SELECT * FROM course.course_rides.rides
WHERE pickup_datetime >= TIMESTAMP '2024-03-01 00:00:00'
  AND pickup_datetime <  TIMESTAMP '2024-04-01 00:00:00';
-- reads about 510 MB, takes about 10 seconds

SELECT count(*) FROM tutorial.rides_march;
-- 21280788

SELECT count(*) AS files, sum(record_count) AS rows
FROM tutorial."rides_march$files";
-- 12 files
