# B3T1: Lakehouse/Athena+Glue

New York rides in Athena.

In this tutorial you query the course's rides table in Athena, then copy one month into your own account and change
it: delete rows, look back at the table before the change, load a day twice and repair it, add a column, and join
your copy with a course table. These are L10's moves, done by you. They are also two of A3's four task types, use and
change; B3T2 does build and maintain.

Time: about 8 minutes of setup (do it before the tutorial) and about 40 minutes of steps.
Cost: the steps read about 5 GB in Athena, about 3 cents at $5.50 per TB.

> The rides table here is the table as Athena wrote it. In L11 we redesign its layout. The numbers in this
> tutorial are for the table as it is.

## 1. Set up your account (once)

This creates a bucket for your query results and copies, sets a Data scanned limit of 2 GB on your Athena workgroup,
and adds the course catalog as a data source named `course`.

1. Sign in to your AWS sandbox and check that the Region at the top right is **Canada (Central)**. The course tables
   live there, and Athena only sees the catalogs of the Region it runs in.
2. Open **CloudShell**: the `>_` icon in the top bar. A terminal opens at the bottom of the page.
3. Paste this line and press Enter:

   ```
   curl -fsSO https://raw.githubusercontent.com/cpsc436c-2026w1/b3-t1-athena-rides/main/setup_athena.sh && bash setup_athena.sh
   ```

You should see:

```
bucket  s3://436c-athena-<your account number> created
workgroup  primary: results in s3://436c-athena-<your account number>/athena-results/, Data scanned limit 2 GB
data source  course added
check  course data readable (265 taxi zones)
Done. Your bucket for step 2 is: 436c-athena-<your account number>
```

Write down the bucket name: Step 2 (copy one month) needs it. Rerunning the script is safe.
[`setup_athena.sh`](setup_athena.sh) is in this repository if you want to read what it does first.

If the script stops with `STOP: ...`, send your account number (printed on the first line) and the STOP line to your
TA.

**What the Data scanned limit does.** A query that would read more than 2 GB is cancelled instead of running on. A
cancelled query is still charged for what it read before it stopped (2 GB is about one cent).

## 2. Open the query editor

1. In the AWS console, open **Athena**, then **Query editor**.
2. Check that **Workgroup** (top right of the editor) is `primary`: the setup set the Data scanned limit and the
   result location there.
3. In the **Data source** list on the left, choose `course` to browse the course tables. **From Step 2 on, set Data
   source back to `AwsDataCatalog`**: your own `tutorial` database lives there, and the SQL files name it without a
   catalog. Course tables are always named in full (`course.course_rides.rides`), so they work with either setting.
4. Run one statement at a time: paste it, or select it in the editor, then press **Run**. Under the results, **Data
   scanned** shows what Athena reads, and bills.

The course catalog belongs to the course account `940482406111`. Every account in the course can read it; nobody can
change it from a student account. The tables used here are in the database `course_rides`:

| Table | What is in it |
|---|---|
| `rides` | New York for-hire rides, January 2023 to December 2025: an Iceberg table partitioned by month of `pickup_datetime`, 20.6 GB |
| `rides_flat` | The same rides as the original 36 monthly Parquet files, with no table format over them. Not used here; a query on it opens every file |
| `zones` | The 265 taxi zones |

## 3. The steps

Each step has a file in [`sql/`](sql). Open the file here, copy one statement at a time into the query editor, run it,
and compare with the result written under it in the file.

### Step 1: predict, then query (about 7 minutes)

[`sql/01_predict_and_query.sql`](sql/01_predict_and_query.sql)

Always filter `rides` on `pickup_datetime`. The table has an Iceberg partition per month of pickup, and each data
file's month is kept in the table's manifests, so a filter on `pickup_datetime` lets Athena open only that month's
files. (Manifests are Iceberg's metadata files that list the table's data files with each file's month and column
statistics, L10.)

An Iceberg table also shows its metadata as read-only tables named `"<table>$<what>"`, in double quotes: `$partitions`
sums the files per partition, `$files` has one row per data file, `$snapshots` one row per snapshot. They are
called metadata tables.

1. Look up how big March 2024 is in `"rides$partitions"`. A month shows as the number of months since January 1970,
   counted from 0: March 2024 is (2024 − 1970) × 12 + 3 − 1 = 650.
2. Guess how much data the March query will read and write it down. Then run it and compare with **Data scanned**.
3. Run the two queries over all 36 months: the first runs, the second is cancelled by your Data scanned limit.
4. Your turn: another month with a third column. Predict the data read before you run it.

<details>
<summary>Why does the March query read 38 MB, not March's 508 MB?</summary>

Parquet stores each column separately, and Athena reads only the columns the query names (`pickup_datetime`,
`base_passenger_fare`): projection pushdown. The Iceberg partition in the manifests decides which files are opened;
the columns decide how much of each file is read.
</details>

### Step 2: copy one month into your own account (about 7 minutes)

[`sql/02_copy_one_month.sql`](sql/02_copy_one_month.sql)

`CREATE TABLE ... AS SELECT` (CTAS) writes a query's result as a new table, here an Iceberg table in your own catalog
and bucket. Replace `<your-bucket>` with the bucket name from setup. Your copy is yours to change.

You should see 21,280,788 rows in 12 data files. The course table keeps March in one file; Athena writes the copy
with several writers in parallel, each writing its own files.

### Step 3: change your copy, then look back (about 10 minutes)

[`sql/03_change_and_time_travel.sql`](sql/03_change_and_time_travel.sql)

This is L10's correction: some trips carry a negative fare. Count them (1,080), delete them from your copy, and list
the copy's snapshots: an `append` (the CTAS) and an `overwrite` (the delete). Then read the copy as it was before the
delete with `FOR VERSION AS OF`: time travel to an older snapshot.

`FOR VERSION AS OF` takes a literal number: copy the snapshot id of the `append` from the snapshots query. A subquery
there fails with `EXPRESSION_NOT_CONSTANT`.

### Step 4: load the same day twice, then repair (about 5 minutes)

[`sql/04_load_the_same_day_twice.sql`](sql/04_load_the_same_day_twice.sql)

A load job that runs twice by mistake (a retry, a rerun after a timeout) writes the same rows twice. Load 1 April
2024 into your copy, then run the same `INSERT` again. The day now has 1,122,474 trips, twice the course table's
561,237, and `$snapshots` ends with two appends of 561,237. Repair the copy: delete the day, then load it once.

<details>
<summary>What would make the load itself safe to run twice?</summary>

The job deletes the day before it writes it, in the same run; or it uses `MERGE` on a key (one statement that updates
the rows whose key matches and inserts the rest); or it remembers which input it already loaded.
</details>

### Step 5: add a column (about 4 minutes)

[`sql/05_add_a_column.sql`](sql/05_add_a_column.sql)

Tables gain columns over time. Add a flag column to your copy and fill it for trips with zero miles (3,026). Then read
an old snapshot with the new column (rerun Step 3's snapshots query and take the oldest row's `snapshot_id`): it fails with `COLUMN_NOT_FOUND`, because an old snapshot is read with the
columns the table had then.

A `SELECT *` load from the course table now fails with `TYPE_MISMATCH`, because your copy has one column more. A
load after a schema change names its columns, or adds the new one: `SELECT *, CAST(NULL AS varchar) FROM ...`.

### Step 6: join your copy with a course table (about 5 minutes)

[`sql/06_join_with_a_course_table.sql`](sql/06_join_with_a_course_table.sql)

One query can read your catalog and the course catalog together. You should see Manhattan first, with 8,253,468
trips in March and an average fare of 28.64.

<details>
<summary>Why did the course table still have the negative fares after your delete?</summary>

Your delete changed your copy, a separate table with its own snapshots. The course table is read-only. If the course
team corrected the course table, the delete would add a snapshot there, and a query could still read the uncorrected
table by time travel to the snapshot before it.
</details>

## 4. Extra exercises

[`sql/07_extra_exercises.sql`](sql/07_extra_exercises.sql). Do them after Step 6: they use the column added in Step 5.

**Delete the zero-mile trips and look back.** Count them (3,026), delete them, count again (0), then count them
`FOR VERSION AS OF` the snapshot just before the delete (3,026 again).

**Two writers at once.** Open a second query editor tab. Prepare one statement in each tab, then press Run in both
within a second or two.

- First try, two loads of different days: both succeed, and `$snapshots` shows two appends.
- Second try, two corrections (two `DELETE`s): one succeeds, the other fails with `ICEBERG_COMMIT_ERROR`. Run the
  failed one again and it succeeds.

<details>
<summary>Why the difference?</summary>

Each write prepares a new snapshot, then tries to make it the table's current one. If another write got there first,
Iceberg checks whether the two touch the same data. Two appends add different files, so the second is placed after
the first. Two deletes both add delete files against the same data files, so the second was prepared on a snapshot
that is no longer current: its commit fails and it must run again. Readers always see one whole snapshot, never half
a write.
</details>

## 5. Clean up

[`sql/99_clean_up.sql`](sql/99_clean_up.sql) drops your copy and the `tutorial` database. For an Iceberg table,
`DROP TABLE` also deletes its data files. Delete the `athena-results/` folder in your bucket if you no longer need old
results. Athena bills only for queries, so nothing keeps billing after the tutorial except the few MB left in your
bucket.

## When something fails

| What you see | Why | What to do |
|---|---|---|
| Asked for a query result location, or "No output location provided" | Setup did not run, or ran in another Region | Rerun `setup_athena.sh` in Canada (Central) |
| `SCHEMA_NOT_FOUND` for `tutorial` (Step 2 onwards) | The **Data source** list is on `course` | Choose `AwsDataCatalog` |
| `TABLE_NOT_FOUND` or `SCHEMA_NOT_FOUND` on a course table | Region is not Canada (Central), or the `course` data source is missing | Switch the Region; rerun the setup script |
| Your `tutorial` database is not in the list | The **Data source** list is on `course` | Choose `AwsDataCatalog` |
| "Bytes scanned limit was exceeded" | The query reads more than 2 GB, usually `rides` without a `pickup_datetime` filter | Add a month filter |
| `EXPRESSION_NOT_CONSTANT` | A subquery after `FOR VERSION AS OF` | Paste the snapshot id as a number |
| `COLUMN_NOT_FOUND` on a time-travel query | The column was added after that snapshot | Expected: old snapshots keep their old columns |
| `TYPE_MISMATCH` on `INSERT ... SELECT *` | Your copy has a column the course table lacks | Name the columns, or add `CAST(NULL AS varchar)` |
| `ICEBERG_COMMIT_ERROR` | Another change to the same table committed first | Run the statement again |
| CTAS fails: location not empty, or table already exists | Second run of the same CTAS | `DROP TABLE tutorial.rides_march` first, or use a new location |
| Error when changing a course table | Course tables are read-only for student accounts | Change your copy |

## Files

| File | What it is |
|---|---|
| [`setup_athena.sh`](setup_athena.sh) | One-time setup: bucket, workgroup result location and Data scanned limit, the `course` data source, a check query |
| [`sql/`](sql) | One file per step, in order, with the expected result under each statement |
