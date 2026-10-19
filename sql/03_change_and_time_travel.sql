-- Step 3: change your copy, then look back with time travel.

SELECT count(*) FROM tutorial.rides_march
WHERE base_passenger_fare < 0;
-- note the number

DELETE FROM tutorial.rides_march WHERE base_passenger_fare < 0;

SELECT snapshot_id, committed_at, operation
FROM tutorial."rides_march$snapshots"
ORDER BY committed_at;
-- append, then overwrite: copy the snapshot_id of the append

SELECT count(*) FROM tutorial.rides_march
WHERE base_passenger_fare < 0;
-- 0

-- Paste the append's snapshot_id (a number; a subquery here fails with EXPRESSION_NOT_CONSTANT)
SELECT count(*) FROM tutorial.rides_march
FOR VERSION AS OF <snapshot_id of the append>
WHERE base_passenger_fare < 0;
-- the number you noted before the delete

-- The same by time: any time between the two snapshots' committed_at values
-- SELECT count(*) FROM tutorial.rides_march FOR TIMESTAMP AS OF TIMESTAMP '<time>' WHERE base_passenger_fare < 0;
