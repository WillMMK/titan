#!/bin/bash
set -euo pipefail

# 1. Pull job env vars (example: SNOWFLAKE_ACCOUNT, USER, etc.)
export SNOWFLAKE_ACCOUNT=${SNOWFLAKE_ACCOUNT:-}
export SNOWFLAKE_USER=${SNOWFLAKE_USER:-}
export SNOWFLAKE_PASSWORD=${SNOWFLAKE_PASSWORD:-}
export SNOWFLAKE_ROLE=${SNOWFLAKE_ROLE:-}
export SNOWFLAKE_WAREHOUSE=${SNOWFLAKE_WAREHOUSE:-}
export POLICY_PATH=${POLICY_PATH:-/app/policy.yaml}
export S3_BUCKET=${S3_BUCKET:-}
export JOB_ID=${JOB_ID:-}
export DRY_RUN=${DRY_RUN:-0}

# 2. Clone S3 creds file (simulate for now)
export AWS_ACCESS_KEY_ID=${AWS_ACCESS_KEY_ID:-}
export AWS_SECRET_ACCESS_KEY=${AWS_SECRET_ACCESS_KEY:-}
export AWS_DEFAULT_REGION=${AWS_DEFAULT_REGION:-us-east-1}

# 3. Main job logic with 8-min timeout
main_job() {
    if [ "$DRY_RUN" = "1" ]; then
        echo "[DRY_RUN] Would run: titan export, titan plan, upload plan.json to S3."
        echo "[DRY_RUN] S3 URL: s3://$S3_BUCKET/$JOB_ID/plan.json"
        exit 0
    fi

    # Export Snowflake baseline
    titan export snowflake://$SNOWFLAKE_ACCOUNT > baseline.yaml

    # Merge policy (append policy.yaml to baseline.yaml)
    cat "$POLICY_PATH" >> baseline.yaml

    # Plan
    titan plan -f baseline.yaml -o plan.json

    # Upload to S3 (requires awscli)
    aws s3 cp plan.json s3://$S3_BUCKET/$JOB_ID/plan.json

    # Echo S3 URL
    echo "s3://$S3_BUCKET/$JOB_ID/plan.json"
}

# Run with timeout (8 min = 480s)
if ! timeout 480 bash -c main_job; then
    echo "Job timed out after 8 minutes." >&2
    exit 124
fi 