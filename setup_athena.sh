#!/bin/bash
# Block 3, tutorial 1: set up Athena in your sandbox account (run once, in CloudShell, Region Canada (Central)).
# What it does, in order:
#   1. creates a bucket 436c-athena-<your account number> for query results and your copies (skipped if it exists)
#   2. sets the primary workgroup's query result location to that bucket and its Data scanned limit to 2 GB
#   3. adds the course catalog (account 940482406111) as an Athena data source named `course` (skipped if it exists)
#   4. runs one small query on a course table to check that you can read it
# Rerunning it is safe.
set -uo pipefail
R=ca-central-1
ACC=$(aws sts get-caller-identity --query Account --output text) || { echo "STOP: no AWS credentials here; run this in CloudShell"; exit 1; }
B=436c-athena-$ACC
echo "account $ACC, region $R"

if aws s3api head-bucket --bucket "$B" 2>/dev/null; then echo "bucket  s3://$B exists"
else aws s3api create-bucket --bucket "$B" --region $R --create-bucket-configuration LocationConstraint=$R >/dev/null \
  && echo "bucket  s3://$B created" || { echo "STOP: could not create s3://$B"; exit 1; }; fi

aws athena update-work-group --work-group primary --region $R --configuration-updates \
  "ResultConfigurationUpdates={OutputLocation=s3://$B/athena-results/},BytesScannedCutoffPerQuery=2000000000" \
  && echo "workgroup  primary: results in s3://$B/athena-results/, Data scanned limit 2 GB" \
  || { echo "STOP: could not update the primary workgroup"; exit 1; }

if aws athena get-data-catalog --name course --region $R >/dev/null 2>&1; then echo "data source  course exists"
else aws athena create-data-catalog --name course --type GLUE --parameters catalog-id=940482406111 --region $R \
  && echo "data source  course added" || { echo "STOP: could not add the course data source"; exit 1; }; fi

QID=$(aws athena start-query-execution --region $R --work-group primary \
  --query-string "SELECT count(*) FROM course.course_rides.zones" --query QueryExecutionId --output text)
while :; do
  S=$(aws athena get-query-execution --region $R --query-execution-id "$QID" --query QueryExecution.Status.State --output text)
  case $S in QUEUED|RUNNING) sleep 1;; *) break;; esac
done
if [ "$S" = SUCCEEDED ]; then
  N=$(aws athena get-query-results --region $R --query-execution-id "$QID" --query 'ResultSet.Rows[1].Data[0].VarCharValue' --output text)
  echo "check  course data readable ($N taxi zones)"
  echo "Done. Your bucket for step 2 is: $B"
else
  echo "STOP: the check query ended $S: $(aws athena get-query-execution --region $R --query-execution-id "$QID" --query QueryExecution.Status.StateChangeReason --output text)"
  echo "Send your account number ($ACC) and this line to the teaching team."; exit 1
fi
