#!/bin/bash
# CPSC 436C, B3T1: set up Athena in your AWS account. Run it once, in AWS CloudShell
# (the >_ icon at the top of the AWS console), Region Canada (Central):
#
#   curl -fsSO https://raw.githubusercontent.com/cpsc436c-2026w1/b3-t1-athena-rides/main/setup_athena.sh && bash setup_athena.sh
#
# It does four things:
#   1. creates a bucket for your query results and your copies: 436c-athena-<your account number>
#   2. sets your Athena workgroup `primary` to save results in that bucket, with a Data scanned limit of 2 GB
#   3. adds the course catalog as an Athena data source named `course`
#   4. runs one small query on a course table, to check that you can read it
# Running it again is safe: it creates only what is missing and sets the workgroup again.
# The bucket, the data source and the limit stay after the tutorial: B3T2 and A3 use them too.
set -euo pipefail

REGION=ca-central-1
COURSE_ACCOUNT=940482406111          # the account that owns the course catalog
LIMIT_BYTES=2000000000               # Data scanned limit per query: 2 GB
ACCOUNT=$(aws sts get-caller-identity --query Account --output text)
BUCKET=436c-athena-$ACCOUNT

echo "Account $ACCOUNT, region $REGION"
# If any AWS call below fails, print a STOP line for the TA before the script exits.
trap 'echo "STOP: a setup step failed (the AWS error is above). Send your account number ($ACCOUNT) and that error to your TA."' ERR

# 1. Your bucket
if aws s3api head-bucket --bucket "$BUCKET" >/dev/null 2>&1; then
  echo "bucket  s3://$BUCKET already exists"
else
  aws s3api create-bucket --bucket "$BUCKET" --region "$REGION" \
    --create-bucket-configuration LocationConstraint="$REGION" >/dev/null
  echo "bucket  s3://$BUCKET created"
fi

# 2. The workgroup your queries run in: where results go, and the Data scanned limit
if ! aws athena get-work-group --work-group primary --region "$REGION" >/dev/null 2>&1; then
  echo "STOP: Athena has no workgroup 'primary' in $REGION. Open Athena in the console once, then rerun this script."
  exit 1
fi
aws athena update-work-group --work-group primary --region "$REGION" \
  --configuration-updates "ResultConfigurationUpdates={OutputLocation=s3://$BUCKET/athena-results/},BytesScannedCutoffPerQuery=$LIMIT_BYTES"
echo "workgroup  primary: results in s3://$BUCKET/athena-results/, Data scanned limit 2 GB"

# 3. The course catalog as a data source named `course`
if aws athena get-data-catalog --name course --region "$REGION" >/dev/null 2>&1; then
  echo "data source  course already exists"
else
  aws athena create-data-catalog --name course --type GLUE \
    --parameters catalog-id=$COURSE_ACCOUNT --region "$REGION"
  echo "data source  course added"
fi

# 4. A check: count the rows of a small course table
QID=$(aws athena start-query-execution --region "$REGION" --work-group primary \
  --query-string "SELECT count(*) FROM course.course_rides.zones" \
  --query QueryExecutionId --output text)
for _ in $(seq 60); do        # wait for the query, at most about a minute
  STATE=$(aws athena get-query-execution --region "$REGION" --query-execution-id "$QID" \
    --query QueryExecution.Status.State --output text)
  if [ "$STATE" != QUEUED ] && [ "$STATE" != RUNNING ]; then break; fi
  sleep 1
done

if [ "$STATE" = SUCCEEDED ]; then
  echo "check  course data readable"
  echo
  echo "Done. Your bucket for Step 2 is: $BUCKET"
  echo "In the Athena console: Region Canada (Central), workgroup primary, Data source course."
else
  REASON=$(aws athena get-query-execution --region "$REGION" --query-execution-id "$QID" \
    --query QueryExecution.Status.StateChangeReason --output text)
  echo "STOP: the check query ended $STATE: $REASON"
  echo "Send your account number ($ACCOUNT) and this line to your TA."
  exit 1
fi
