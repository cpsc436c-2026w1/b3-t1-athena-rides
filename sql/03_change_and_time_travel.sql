-- Step 3: change your copy, then look back with time travel.

SELECT count(*) FROM tutorial.rides_march
WHERE base_passenger_fare < 0;
-- Note this number: you compare with it twice later.

DELETE FROM tutorial.rides_march WHERE base_passenger_fare < 0;

SELECT snapshot_id, committed_at, operation
FROM tutorial."rides_march$snapshots"
ORDER BY committed_at;
-- An append (the copy) and an overwrite (the delete). Copy the snapshot_id of the append.

SELECT count(*) FROM tutorial.rides_march
WHERE base_passenger_fare < 0;
-- 0: none remain.

-- Paste the append's snapshot_id as a number. A subquery here fails with EXPRESSION_NOT_CONSTANT.
SELECT count(*) FROM tutorial.rides_march
FOR VERSION AS OF <snapshot_id of the append>
WHERE base_passenger_fare < 0;
-- The number you noted before the delete.

-- The same by time: use any time between the two snapshots' committed_at values.
-- SELECT count(*) FROM tutorial.rides_march FOR TIMESTAMP AS OF TIMESTAMP '<time>' WHERE base_passenger_fare < 0;
