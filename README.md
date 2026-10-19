# B3T1: Lakehouse/Athena+Glue

This tutorial follows our L10 and goes in parallel with L11: you will learn to query a course data lakehouse with a more recent New York rides dataset (but still similar to taxi rides)
from a serverless distributed query engine (Amazon Athena) and will learn to copy some subset into your own AWS account.

You will try some features we had on data lake with spark with the new engine (adding a column, joining across different sources) and see how lakehouse features can help us to solve simple data lake limitations (deleting unnecessary rows, reading the table as it was before the delete, repairing an operation that ran twice by error).

This will prepare you for Assignment 3 (which will use different data -- we are *not* a course about taxis after all), and will help you to understand better pros and cons of lakehouse vs lake structure.
The next tutorial (B3T2) will cover more lakehouse maintenance operations -- we will use Spark/Glue to make our lakehouse more efficient. 

In L11 we will *redesign* our data to improve table layout, but in this tutorial we use it as is.

In our setup I cap every query using Data scanned limit, that should keep the total costs of the queries from the tutorial under a few cents in total. 
I suggest exploring the annotated setup script on your own, some settings (e.g. imposing caps and checks like our Data scanned limit) are good practices to bear in mind for your own setup.

We do this part of operations in Athena and Glue (serverless/managed services) vs Trino and Spark on EMR cluster for simplicity, but in the lectures we will discuss when would we switch to using Spark and Trino on a cluster.

All course tutorials are listed on the [Tutorials page](https://cpsc436c-2026w1.github.io/lecture-reviews/tutorials.html).

## 1. Set up your account (once)

The setup script creates a bucket for your query results and your copies, sets a Data scanned limit of 2 GB on your
Athena workgroup, and adds the course catalog as a data source named `course`.

1. Sign in to your AWS sandbox and check that the Region at the top right is **Canada (Central)**. The course tables
   live there, and Athena only sees the catalogs of the Region it runs in.
2. Open **CloudShell** with the `>_` icon in the top bar. A terminal opens at the bottom of the page.
3. Paste this line and press Enter:

   ```
   curl -fsSO https://raw.githubusercontent.com/cpsc436c-2026w1/b3-t1-athena-rides/main/setup_athena.sh && bash setup_athena.sh
   ```

The script prints one line for each thing it set up (the bucket, the workgroup, the `course` data source) and a line
saying it could read course data. Near the end it gives your bucket name, which looks like
`436c-athena-<your account number>`. Write it down: you need it in Step 2. You can safely rerun the script.
[`setup_athena.sh`](setup_athena.sh) is in this repository if you want to read it first.

If the script stops with a line starting `STOP:`, send that line and your account number (printed on the first line)
to your TA.

**What the Data scanned limit does.** A query that would read more than the limit is cancelled instead of running on.
Athena still charges for what the query read before it stopped.

## 2. Open the query editor

1. In the AWS console, open **Athena**, then **Query editor**.
2. Check that **Workgroup**, at the top right of the editor, is `primary`. The setup put the Data scanned limit and the
   result location on that workgroup.
3. In the **Data source** list on the left, choose `course` for Step 1, and the `course_rides` database appears. Before
   you run the first statement of Step 2, change **Data source** to `AwsDataCatalog`: your `tutorial` database is
   created there. The SQL files always name course tables in full (`course.course_rides.rides`), so they keep working
   after you change the data source.
4. Run one statement at a time. Paste it into the editor, or select it if the editor holds several statements, and
   press **Run**. The results appear below the editor, next to **Data scanned**: how much data Athena read, which is
   what Athena charges for.

The course catalog belongs to the course account `940482406111`. Every account in the course can read it, and nobody
can change it from a student account. The tables used here are in the database `course_rides`:

| Table | What is in it |
|---|---|
| `rides` | New York for-hire rides from January 2023 to December 2025, stored as an Iceberg table partitioned by the month of `pickup_datetime` |
| `rides_flat` | The same rides as the original monthly Parquet files, with no table format over them. This tutorial does not use it |
| `zones` | A lookup from taxi location ids to zone and borough names |

## 3. The steps

Each step links to a file in [`sql/`](sql). Open the file in a second browser tab, copy one statement at a time into
Athena's query editor, run it, and read the comment under the statement: it says what you should see.

### Step 1: predict, then query (about 7 minutes)

[`sql/01_predict_and_query.sql`](sql/01_predict_and_query.sql)

Always filter `rides` on `pickup_datetime`. The table has an Iceberg partition for each month of pickup, and the
table's manifests record each data file's month, so a filter on `pickup_datetime` lets Athena open only that month's
files. (Manifests are Iceberg's metadata files that list the table's data files with each file's month and column
statistics, L10.)

Athena also shows an Iceberg table's metadata as read-only tables. Their names have the form `"<table>$<metadata>"`
and need the double quotes. `$partitions` summarizes each partition, `$files` has one row per data file, and
`$snapshots` has one row per snapshot. These are called metadata tables.

1. Find March 2024 in `"rides$partitions"`. Note how many files hold it and how many rows it has. A month shows as the
   number of months since January 1970, counted from 0: March 2024 is (2024 − 1970) × 12 + 3 − 1 = 650.
2. Before you run the March query, decide what you expect Athena to read: the whole table, all of March 2024's file,
   or only part of that file. Then run the query and look at **Data scanned** under the results.
3. Change the query so that it starts on 2 March 2024 instead of 1 March 2024. Do you expect Athena to read more data
   than for the March 2024 query, or less? Run it and compare.
4. The next two queries have no date filter, so they cover all 36 months. Decide which one your Data scanned limit
   will stop, then run both.
5. Run the July 2024 query, and note **Data scanned**. Then run it again with `avg(trip_miles)` added. Do you expect
   the second run to read more data than the first, or less?

<details>
<summary>Check your predictions (open after you ran the queries)</summary>

- **March 2024:** only part of March's file. Parquet stores each column separately, and Athena reads only the
  columns it needs (projection pushdown). The filter covers the whole March 2024 partition, so the manifests settle
  it and Athena never reads `pickup_datetime`: it reads only the fare column.
- **Starting on 2 March 2024:** more, even though there are fewer trips. The filter no longer covers the whole month,
  so Athena has to read `pickup_datetime` as well, to check each row.
- **All 36 months:** the query with one average runs. The query with three columns reads past your limit and is
  cancelled.
- **July 2024 with `avg(trip_miles)`:** more than the first July query, because it reads one more column from the
  same files.

The Iceberg partition in the manifests decides which files are opened, and the columns decide how much of each file
is read.
</details>

### Step 2: copy one month into your own account (about 7 minutes)

[`sql/02_copy_one_month.sql`](sql/02_copy_one_month.sql)

`CREATE TABLE ... AS SELECT` (CTAS) writes a query's result as a new table, here an Iceberg table in your own catalog
and bucket. Replace `<your-bucket>` with the bucket name from setup. The copy is yours to change.

Your copy should have as many rows as March 2024 has in the course table, the row count you noted in Step 1.

### Step 3: change your copy, then look back (about 10 minutes)

[`sql/03_change_and_time_travel.sql`](sql/03_change_and_time_travel.sql)

Some trips have a negative fare. Count them in your copy and note the number. Delete them, then count again: none
should remain.

Next, list your copy's snapshots. You should see an `append`, made by the CTAS, and an `overwrite`, made by the
delete. Copy the `snapshot_id` of the `append` and use it with `FOR VERSION AS OF` to read the table as it was before
the delete (time travel). The count should match the number you noted at the start.

`FOR VERSION AS OF` needs the snapshot id as a number: paste it into the query. Athena rejects a subquery there with
`EXPRESSION_NOT_CONSTANT`.

### Step 4: load the same day twice, then repair (about 5 minutes)

[`sql/04_load_the_same_day_twice.sql`](sql/04_load_the_same_day_twice.sql)

A load job can write the same rows twice when someone reruns it by mistake or retries it after a timeout. Run the
`INSERT` for 1 April 2024 twice, then run the comparison query: your copy should have twice as many trips for that
day as the course table. In `$snapshots`, the last two appends should show the same `added` value.

Repair your copy: delete 1 April 2024 and run the `INSERT` once. Run the comparison query again: the two counts should
now match.

<details>
<summary>What would make the load itself safe to run twice?</summary>

The job deletes the day before it writes it, in the same run. Or it uses `MERGE` on a key: one statement that updates
the rows whose key matches and inserts the rest. Or it remembers which input it already loaded.
</details>

### Step 5: add a column (about 4 minutes)

[`sql/05_add_a_column.sql`](sql/05_add_a_column.sql)

Tables gain columns over time. Add a flag column to your copy and fill it for the trips with zero miles. Then read an
old snapshot with the new column: rerun Step 3's snapshots query, take the oldest row's `snapshot_id`, and run the
time-travel query. Athena rejects it with `COLUMN_NOT_FOUND`, because an old snapshot is read with the columns the
table had then.

The file then tries to load another day with `SELECT *`. Athena rejects it with `TYPE_MISMATCH`, because your copy now
has one column more than the course table. The next statement loads the same day and supplies `NULL` for the new
column, and it succeeds. The check after it should show that none of the rows it loaded has a flag.

### Step 6: join your copy with a course table (about 5 minutes)

[`sql/06_join_with_a_course_table.sql`](sql/06_join_with_a_course_table.sql)

The join reads your table from `AwsDataCatalog` and the zones table from the `course` catalog. The result is sorted by
the number of trips, and Manhattan should come first.

Then run the query on the course table below the join. Its count should match the number of negative fares you noted
in Step 3, before you changed your copy.

<details>
<summary>Why does the course table still have the negative fares after your delete?</summary>

Your delete changed your copy, a separate table with its own snapshots. The course table is read-only. If the course
team corrected the course table, the delete would add a snapshot there, and a query could still read the uncorrected
table by time travel to the snapshot before it.
</details>

## 4. Extra exercises

[`sql/07_extra_exercises.sql`](sql/07_extra_exercises.sql). Do them after Step 6, because they use the column added in
Step 5.

**Delete the zero-mile trips and look back.** Count the zero-mile trips and note the number. Delete them, then count
again: none should remain. Then count them `FOR VERSION AS OF` the snapshot just before the delete: the count should
match the number you noted.

**Run two writes at about the same time.** Open a second query editor tab. Put one statement in each tab and start
them as close together as you can.

- Start with the two loads of different days. Both should succeed, and `$snapshots` should show an append for each.
- Then run the two `DELETE` statements. If they overlap, Athena rejects one of them with `ICEBERG_COMMIT_ERROR`. Run
  the rejected one again and it succeeds. If both succeed, Athena ran them one after the other: try again.

<details>
<summary>Why can two loads both succeed while two deletes conflict?</summary>

Each write prepares a new snapshot, then tries to make it the table's current one. If another write got there first,
Iceberg checks whether the two touch the same data. Two appends add different files, so the second is placed after
the first. Two deletes both add delete files against the same data files, so the second was prepared on a snapshot
that is no longer current: its commit fails and it must run again. Readers always see one whole snapshot, never half
a write.
</details>

## 5. Clean up

Open [`sql/99_clean_up.sql`](sql/99_clean_up.sql) and run its two statements. Refresh the `AwsDataCatalog` list: the
`tutorial` database should be gone. For an Iceberg table, `DROP TABLE` also deletes its data files. If you no longer
need your old query results, delete the `athena-results/` folder in your bucket. Athena charges only for queries, so
after the tutorial nothing keeps charging except the small files left in your bucket. Keep the bucket, the `course`
data source and the Data scanned limit: B3T2 and A3 use them.

## When something fails

| What you see | Why | What to do |
|---|---|---|
| Asked for a query result location, or "No output location provided" | Setup did not run, or ran in another Region | Rerun `setup_athena.sh` in Canada (Central) |
| `SCHEMA_NOT_FOUND` for `tutorial` (Step 2 onwards) | The **Data source** list is on `course` | Choose `AwsDataCatalog` |
| `TABLE_NOT_FOUND` or `SCHEMA_NOT_FOUND` on a course table | The Region is not Canada (Central), or the `course` data source is missing | Switch the Region, or rerun the setup script |
| Your `tutorial` database is not in the list | The **Data source** list is on `course` | Choose `AwsDataCatalog` |
| "Bytes scanned limit was exceeded" | The query reads more than your limit, usually `rides` without a `pickup_datetime` filter | Add a month filter |
| `EXPRESSION_NOT_CONSTANT` | A subquery after `FOR VERSION AS OF` | Paste the snapshot id as a number |
| `COLUMN_NOT_FOUND` on a time-travel query | The snapshot is older than the column | This is expected in Step 5. To read the column, use a snapshot made after you added it |
| `TYPE_MISMATCH` on `INSERT ... SELECT *` | Your copy has a column the course table lacks | Name the columns, or add `CAST(NULL AS varchar)` |
| `ICEBERG_COMMIT_ERROR` | Another change to the same table committed first | Run the statement again |
| CTAS fails because the location is not empty or the table already exists | The same CTAS ran a second time | `DROP TABLE tutorial.rides_march` first, or use a new location |
| Error when changing a course table | Course tables are read-only for student accounts | Change your copy |

## Files

| File | What it is |
|---|---|
| [`setup_athena.sh`](setup_athena.sh) | One-time setup: bucket, workgroup result location and Data scanned limit, the `course` data source, a check query |
| [`sql/`](sql) | One file per step, in order, with what you should see under each statement |
