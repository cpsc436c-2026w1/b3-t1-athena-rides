-- Step 2: copy March 2024 into an Iceberg table in your own account.
-- First change Data source (left of the editor) to AwsDataCatalog.
-- Replace <your-bucket> with the bucket name that setup_athena.sh printed.

CREATE DATABASE IF NOT EXISTS tutorial;

CREATE TABLE tutorial.rides_march
WITH (table_type = 'ICEBERG',
      location = 's3://<your-bucket>/tutorial/rides_march/',
      is_external = false)
AS SELECT * FROM course.course_rides.rides
WHERE pickup_datetime >= TIMESTAMP '2024-03-01 00:00:00'
  AND pickup_datetime <  TIMESTAMP '2024-04-01 00:00:00';

SELECT count(*) FROM tutorial.rides_march;
-- The same as the March 2024 row count you noted in Step 1.

SELECT count(*) AS files, sum(record_count) AS rows
FROM tutorial."rides_march$files";
-- The rows match the count above. Athena wrote the copy as several files.
