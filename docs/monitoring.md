# Monitoring and Observability

## Overview

The Olist batch data platform uses AWS monitoring and auditing services to provide operational visibility into the batch pipeline.

The implemented monitoring layer is centered on:

- Amazon CloudWatch
- AWS CloudTrail

CloudWatch provides execution logs and metrics for the batch workloads, while CloudTrail provides AWS API activity auditing.

The project validates the monitoring path without claiming alerting infrastructure that was not configured.

---

## Monitoring Architecture

The operational monitoring flow is:

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
Amazon S3
```

Monitoring and auditing surround this execution path:

```text
                 CloudWatch
                /                         v            v
          Lambda Logs    Glue Logs
               \            /
                \          /
                 v        v
              Pipeline
               Status
                  |
                  v
             Troubleshooting

              CloudTrail
                  |
                  v
          AWS API Activity
```

---

## Amazon CloudWatch

Amazon CloudWatch provides operational visibility into the AWS batch pipeline.

It is used to inspect:

- Lambda execution logs
- Glue job logs
- Glue execution metrics
- Execution status
- Runtime information useful for troubleshooting

CloudWatch is therefore the primary operational observability service for the implemented AWS batch path.

---

## Lambda Monitoring

The `olist-batch-orchestrator` Lambda function produces execution logs in CloudWatch.

The logs were checked during manual orchestration validation.

The validation confirmed:

- Lambda invocation occurred
- The orchestration function executed
- The Glue job start request was issued
- A Glue run identifier was available

The Lambda response included:

```text
GLUE_JOB_STARTED
```

This provided evidence that the orchestration function successfully initiated the downstream Glue workload.

---

## AWS Glue Monitoring

The `olist-raw-to-processed-etl` Glue job provides execution information through CloudWatch and the Glue service interface.

The monitoring information is used to inspect:

- Job execution status
- Execution duration
- Glue run identifiers
- Job logs
- Resource/runtime metrics

The latest validated Glue execution completed successfully.

Earlier successful executions were also checked during pipeline validation.

---

## Glue Execution Metrics

The Glue job configuration and execution metrics were inspected during validation.

The latest verified successful run completed in approximately:

```text
104 seconds
```

with approximately:

```text
208 DPU seconds
```

These measurements provide a baseline for understanding the runtime and resource consumption of the batch ETL job.

---

## End-to-End Monitoring Validation

The orchestration path was validated in multiple stages.

### Lambda validation

The Lambda function was invoked manually.

The response indicated:

```text
GLUE_JOB_STARTED
```

and returned the Glue run identifier.

### Glue validation

The corresponding Glue execution was checked and confirmed to complete successfully.

### CloudWatch validation

CloudWatch logs were inspected to confirm the Lambda execution and Glue job-start sequence.

Together, these checks provide evidence that the scheduled orchestration path can be observed from trigger/orchestration through ETL execution.

---

## Operational Troubleshooting

CloudWatch logs provide the first place to investigate operational failures.

A basic troubleshooting sequence is:

```text
Check EventBridge Scheduler
          |
          v
Check Lambda invocation
          |
          v
Check Lambda CloudWatch logs
          |
          v
Check Glue run status
          |
          v
Check Glue CloudWatch logs
          |
          v
Check S3 output
```

This separates scheduling failures, orchestration failures, ETL failures, and output/storage issues.

---

## AWS CloudTrail

AWS CloudTrail provides auditing of AWS API activity.

CloudTrail is different from CloudWatch:

- CloudWatch focuses on operational logs, metrics, and execution visibility.
- CloudTrail focuses on AWS API activity and auditing.

CloudTrail supports investigation of infrastructure and service changes by providing an audit trail of relevant AWS API activity.

---

## IAM and Monitoring

IAM controls which AWS services and roles can perform actions within the pipeline.

The monitoring architecture works alongside IAM:

```text
IAM
 |
 +--> Controls service permissions
 |
 v
AWS Services
 |
 +--> CloudWatch → operational visibility
 |
 +--> CloudTrail  → API auditing
```

This separation keeps access control, operational monitoring, and API auditing as distinct governance responsibilities.

---

## Monitoring Scope

The current implementation provides monitoring visibility for the core AWS batch execution path.

Implemented/validated:

- Lambda execution logging
- Glue execution logging
- Glue execution metrics
- Lambda → Glue orchestration validation
- Successful Glue run validation
- CloudTrail API auditing

Not represented as implemented:

- CloudWatch alarms
- SNS notification workflows
- Automated incident-management integrations
- Dedicated CloudWatch monitoring dashboards

These would be additional enhancements rather than existing components of the validated implementation.

---

## Relationship to Batch Orchestration

Monitoring is integrated with the AWS-native orchestration architecture:

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

Operational visibility is provided by:

```text
Lambda ──> CloudWatch Logs
Glue   ──> CloudWatch Logs / Metrics
AWS APIs ──> CloudTrail
```

This provides a practical monitoring foundation for the batch platform without coupling monitoring logic to the ETL code.

---

## Relationship to Databricks

The AWS monitoring layer covers the AWS portion of the pipeline.

The downstream Databricks processing layer has its own execution and validation workflow through the `olist_medallion_pipeline` notebook and `olist-sql-warehouse` analytics work.

The overall operational flow is:

```text
AWS Batch Pipeline
       |
       v
S3 Processed
       |
       v
Databricks
       |
       v
Gold / SQL Analytics
       |
       v
Apache Superset
```

AWS CloudWatch and CloudTrail therefore provide monitoring and auditing primarily for the AWS infrastructure and batch-processing portion of the platform.

---

## Current Status

The monitoring and observability layer has been implemented and validated for the core AWS batch pipeline.

Validated evidence includes:

- Successful Lambda invocation
- Successful Lambda → Glue job start
- Glue run identifier
- Successful Glue execution
- CloudWatch Lambda logs
- CloudWatch Glue logs
- Glue runtime/resource metrics
- CloudTrail auditing capability

The monitoring implementation is intentionally documented according to the services and validations actually performed.
