-- Clean up when you are done. For an Iceberg table, DROP TABLE also deletes its data files.
DROP TABLE IF EXISTS tutorial.rides_march;
DROP DATABASE IF EXISTS tutorial;
