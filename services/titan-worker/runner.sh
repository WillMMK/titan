#!/bin/bash
set -euo pipefail

# Trap SIGTERM for graceful shutdown
trap 'echo "{\"level\":\"warning\",\"msg\":\"Received SIGTERM, exiting...\"}"; exit 137' SIGTERM

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

# 2. AWS credentials: use env-injected or AWS_WEB_IDENTITY_TOKEN_FILE (no file copy)
export AWS_ACCESS_KEY_ID=${AWS_ACCESS_KEY_ID:-}
export AWS_SECRET_ACCESS_KEY=${AWS_SECRET_ACCESS_KEY:-}
export AWS_DEFAULT_REGION=${AWS_DEFAULT_REGION:-us-east-1}
export AWS_WEB_IDENTITY_TOKEN_FILE=${AWS_WEB_IDENTITY_TOKEN_FILE:-}

# 3. Main job logic with 8-min timeout
main_job() {
    if [ "$DRY_RUN" = "1" ]; then
        echo "{\"level\":\"info\",\"msg\":\"[DRY_RUN] Would run: titan export, titan plan, upload plan.json to S3.\"}"
        echo "{\"level\":\"info\",\"msg\":\"[DRY_RUN] S3 URL: s3://$S3_BUCKET/$JOB_ID/plan.json\"}"
        if [ "${TEST_SIGTERM:-0}" = "1" ]; then
            echo "{\"level\":\"info\",\"msg\":\"[DRY_RUN] Sleeping for SIGTERM test...\"}"
            sleep 15
        fi
        exit 0
    fi

    # Export Snowflake baseline
    echo "{\"level\":\"info\",\"msg\":\"Running titan export...\"}"
    titan export snowflake://$SNOWFLAKE_ACCOUNT > baseline.yaml

    # Merge policy (append policy.yaml to baseline.yaml)
    echo "{\"level\":\"info\",\"msg\":\"Appending policy to baseline...\"}"
    cat "$POLICY_PATH" >> baseline.yaml

    # Plan
    echo "{\"level\":\"info\",\"msg\":\"Running titan plan...\"}"
    titan plan -f baseline.yaml -o plan.json

    # Upload to S3 (requires awscli or boto3)
    echo "{\"level\":\"info\",\"msg\":\"Uploading plan.json to S3...\"}"
    aws s3 cp plan.json s3://$S3_BUCKET/$JOB_ID/plan.json

    # Echo S3 URL as JSON
    echo "{\"level\":\"info\",\"s3_url\":\"s3://$S3_BUCKET/$JOB_ID/plan.json\"}"
}

# Run with timeout (8 min = 480s)
if ! timeout 480 bash -c "$(declare -f main_job); main_job"; then
    echo "{\"level\":\"error\",\"msg\":\"Job timed out after 8 minutes.\"}" >&2
    exit 124
fi 