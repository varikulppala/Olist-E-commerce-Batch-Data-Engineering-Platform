# Batch Orchestration

## Overview

The Olist batch data platform uses AWS-native services for scheduled batch orchestration.

The implemented execution path is:

```text
EventBridge Scheduler
        |
        v
AWS Lambda
        |
        v
AWS Glue ETL
        |
        v
Amazon S3 Processed
```

This separates the scheduled trigger, lightweight orchestration logic, and data-processing workload.

---

## EventBridge Scheduler

Amazon EventBridge Scheduler provides the scheduled trigger for the batch pipeline.

### Schedule

- Name: `olist-batch-daily-schedule`
- State: Enabled
- Schedule expression: `cron(0 9 * * ? *)`
- Time zone: `Asia/Calcutta`
- Target: `olist-batch-orchestrator`

The schedule invokes the orchestration Lambda every day at 09:00 in the configured time zone.

### Scheduler Target Configuration

The Scheduler target is:

`olist-batch-orchestrator`

The configured target input is:

```json
{}
```

The configured retry behavior uses:

- Maximum retry attempts: `0`
- Maximum event age: `86400` seconds

The Scheduler uses its configured AWS service role to invoke Lambda.

---

## AWS Lambda Orchestrator

AWS Lambda provides the lightweight orchestration layer between EventBridge Scheduler and AWS Glue.

### Function

- Name: `olist-batch-orchestrator`
- Runtime: Python 3.14
- Handler: `lambda_function.lambda_handler`
- Memory: 128 MB
- Timeout: 3 seconds
- Architecture: x86_64

The Lambda function does not perform the main ETL workload itself.

Its role is to start the configured AWS Glue ETL job.

This keeps the orchestration function small and allows Glue to handle the data-processing workload.

---

## AWS Glue ETL

The Glue job started by the Lambda orchestrator is:

`olist-raw-to-processed-etl`

The job performs the batch transformation from the raw S3 layer to the processed S3 layer.

Validated Glue configuration includes:

- Glue version: 5.1
- Worker type: G.1X
- Workers: 2
- Execution mode: STANDARD
- Maximum concurrent runs: 1
- Timeout: 480 minutes
- Maximum retries: 0
- ETL implementation: PySpark

The Glue script is stored in:

`s3://aws-glue-assets-970722351160-ap-south-1/scripts/olist-raw-to-processed-etl.py`

---

## End-to-End Execution

The scheduled execution proceeds as follows.

### Step 1 — Scheduled Trigger

EventBridge Scheduler reaches the configured daily execution time.

```text
olist-batch-daily-schedule
          |
          v
09:00 Asia/Calcutta
```

### Step 2 — Lambda Invocation

The Scheduler invokes:

```text
olist-batch-orchestrator
```

The Lambda handler starts the Glue ETL job.

### Step 3 — Glue Execution

AWS Glue executes:

```text
olist-raw-to-processed-etl
```

The ETL job reads raw Olist data, performs the configured transformations, and writes processed output to S3.

### Step 4 — Downstream Processing

The processed S3 data is then available for the Databricks Medallion processing layer.

```text
S3 Processed
      |
      v
Databricks Bronze
      |
      v
Databricks Silver
      |
      v
Databricks Gold
```

---

## Manual Validation

The orchestration path was manually validated by invoking the Lambda function.

The invocation returned a successful response indicating:

```text
GLUE_JOB_STARTED
```

The response also included the Glue run identifier.

This confirmed that Lambda could successfully start the configured Glue job.

---

## CloudWatch Validation

CloudWatch logs were checked during orchestration testing.

The logs confirmed:

- Lambda invocation
- Lambda orchestration execution
- Glue job start
- Glue run identification

Glue execution logs and metrics were also validated separately.

---

## IAM

The orchestration path uses AWS service roles rather than embedding personal AWS credentials in the workload.

The relevant services use their configured roles for:

- EventBridge Scheduler → Lambda invocation
- Lambda → Glue job start
- Glue → required data-processing resources

IAM controls these service-to-service permissions.

---

## Failure and Retry Configuration

The implemented configuration keeps retries explicit at the service level.

EventBridge Scheduler:

```text
Maximum retry attempts: 0
Maximum event age: 86400 seconds
```

Glue:

```text
Maximum retries: 0
Maximum concurrent runs: 1
```

This avoids automatically creating multiple overlapping Glue executions from the configured orchestration path.

Operational failures can be investigated through CloudWatch logs and Glue execution status.

---

## Separation of Responsibilities

| Component | Responsibility |
|---|---|
| EventBridge Scheduler | Daily scheduled trigger |
| AWS Lambda | Start the Glue batch job |
| AWS Glue | Execute PySpark ETL |
| Amazon S3 | Store raw and processed data |
| CloudWatch | Logs and operational monitoring |
| IAM | Service permissions |

This design keeps scheduling and orchestration independent from the ETL processing workload.

---

## Relationship to the Overall Platform

The complete batch path is:

```text
Olist Dataset
      |
      v
Amazon S3 - Raw
      |
      v
AWS Glue ETL
      |
      v
Amazon S3 - Processed
      |
      v
Databricks Medallion
      |
      +--> Bronze
      +--> Silver
      +--> Gold
              |
              v
        Databricks SQL
              |
              v
             dbt
              |
              v
       Apache Superset
```

The scheduling path is:

```text
EventBridge Scheduler
        |
        v
AWS Lambda
        |
        v
AWS Glue
        |
        v
S3 Processed
```

---

## Implementation Status

The AWS batch orchestration path has been implemented and validated.

Validated components include:

- Enabled EventBridge Scheduler
- Daily 09:00 schedule
- `olist-batch-orchestrator` Lambda
- Lambda → Glue invocation
- `olist-raw-to-processed-etl` Glue job
- Successful manual Lambda invocation
- Glue run creation
- CloudWatch execution logs

The implemented architecture uses EventBridge Scheduler, Lambda, and Glue for orchestration and batch processing. MWAA is not part of the final implemented orchestration architecture.
