# Deployment Guide

## Overview

This document describes the validated deployment and setup state of the Olist e-commerce batch data platform.

The platform combines AWS services, Databricks, dbt, and Apache Superset.

The deployment architecture is:

```text
Olist Dataset
      |
      v
Amazon S3 Raw
      |
      v
AWS Glue Data Catalog / ETL
      |
      v
Amazon S3 Processed
      |
      v
Databricks Bronze
      |
      v
Databricks Silver
      |
      v
Databricks Gold
      |
      v
Databricks SQL Warehouse
      |
      v
dbt
      |
      v
Apache Superset
```

The AWS batch execution path is orchestrated by:

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
Amazon S3
```

Monitoring and auditing are provided through CloudWatch and CloudTrail.

---

## Deployment Scope

The project has been deployed and validated across several environments.

| Component | Environment | Status |
|---|---|---|
| S3 | AWS | Deployed and validated |
| Glue Data Catalog | AWS | Deployed and validated |
| Glue ETL | AWS | Deployed and validated |
| Lambda orchestrator | AWS | Deployed and validated |
| EventBridge Scheduler | AWS | Enabled and validated |
| CloudWatch | AWS | Logs/metrics validated |
| CloudTrail | AWS | Auditing capability validated |
| Databricks | Databricks Free Edition | Configured and validated |
| Databricks SQL Warehouse | Databricks | Configured and validated |
| dbt | Windows local environment | Configured and validated |
| Apache Superset | Windows + Docker Desktop | Configured and validated |
| Terraform | Windows local environment | Validated for managed AWS subset |

The project documentation intentionally distinguishes deployment from full infrastructure-as-code coverage.

---

## AWS Deployment

### AWS Region

The project uses:

```text
ap-south-1
```

This is the Mumbai AWS region.

The primary S3 data platform resources and Glue workload were validated in this region.

---

## Amazon S3

The primary project bucket is:

```text
olist-aws-batch-data-platform-adhi-2026
```

The bucket provides storage for the AWS portion of the batch data pipeline.

Validated configuration includes:

```text
Region: ap-south-1
Versioning: Enabled
Public access block: Enabled
Server-side encryption: AES256
Bucket key: Enabled
```

The raw dataset is stored in S3 as the starting point for the AWS batch workflow.

Processed output is also written to S3.

---

## AWS Glue Data Catalog

The AWS Glue Data Catalog is used to register and describe the data available to the analytics/query workflow.

The catalog layer supports discovery of the S3-backed dataset and provides metadata for downstream processing and validation.

The project also used Athena during the AWS catalog/query validation stage.

---

## AWS Glue ETL

The main Glue job is:

```text
olist-raw-to-processed-etl
```

The validated configuration includes:

```text
Glue version: 5.1
Worker type: G.1X
Workers: 2
Execution class: STANDARD
Maximum concurrent runs: 1
Timeout: 480 minutes
Maximum retries: 0
```

The Glue script is stored at:

```text
s3://aws-glue-assets-970722351160-ap-south-1/scripts/olist-raw-to-processed-etl.py
```

The job transforms the raw Olist data and writes the processed data to S3.

---

## Glue IAM Role

The Glue job uses:

```text
AWSGlueServiceRole-OlistDataPlatform
```

ARN:

```text
arn:aws:iam::970722351160:role/AWSGlueServiceRole-OlistDataPlatform
```

The role is part of the deployed AWS configuration.

It is not claimed as a Terraform-created IAM resource in the current Terraform implementation.

---

## Lambda Orchestrator

The AWS batch workflow uses the Lambda function:

```text
olist-batch-orchestrator
```

Validated configuration:

```text
Runtime: Python 3.14
Handler: lambda_function.lambda_handler
Memory: 128 MB
Timeout: 3 seconds
Architecture: x86_64
```

The Lambda function starts the Glue ETL job.

The manual invocation returned a successful response containing:

```text
GLUE_JOB_STARTED
```

and a Glue run identifier.

This validated the Lambda-to-Glue orchestration path.

---

## EventBridge Scheduler

The batch workflow is scheduled through:

```text
olist-batch-daily-schedule
```

The schedule is:

```text
cron(0 9 * * ? *)
```

with timezone:

```text
Asia/Calcutta
```

The schedule runs at 09:00 according to the configured timezone.

The target is:

```text
olist-batch-orchestrator
```

The scheduler is enabled.

The configured retry behavior uses:

```text
Maximum retry attempts: 0
Event maximum age: 86400 seconds
```

The scheduler therefore triggers Lambda, which starts the Glue ETL workload.

---

## AWS Monitoring

CloudWatch is used for operational visibility.

Validated monitoring includes:

- Lambda execution logs
- Glue execution logs
- Glue execution metrics
- Lambda-to-Glue execution validation
- Successful Glue run validation

The latest verified successful Glue execution completed in approximately:

```text
104 seconds
```

with approximately:

```text
208 DPU seconds
```

CloudTrail provides AWS API activity auditing.

The project does not claim CloudWatch alarms, SNS workflows, or dedicated CloudWatch dashboards because these were not part of the validated implementation.

---

## AWS Security

The deployment follows basic AWS security controls.

Validated controls include:

- S3 public access blocking
- S3 server-side encryption
- IAM service roles
- AWS service-to-service permissions
- CloudTrail API auditing
- Secrets Manager as the intended managed secret-storage mechanism

Sensitive credentials are not stored in the project repository.

---

## Databricks Deployment

Databricks is used as the downstream data-engineering and analytical processing environment.

The project uses a Databricks Free Edition workspace.

The main processing notebook is:

```text
olist_medallion_pipeline
```

The pipeline implements:

```text
Bronze
   |
   v
Silver
   |
   v
Gold
```

The Gold layer provides the curated analytical star schema.

---

## Databricks Gold Layer

The Gold layer contains:

```text
dim_customers
dim_date
dim_products
dim_sellers

fact_orders
fact_order_items
fact_payments
fact_reviews
```

Validated key counts include:

```text
fact_orders:      99,441 rows
fact_order_items: 112,650 rows
```

The Gold model supports downstream SQL analytics and Superset visualization.

---

## Delta Lake Validation

The Databricks implementation uses Delta Lake for the medallion processing workflow.

The project validated:

- Delta table format
- Transaction history
- Time Travel
- MERGE/UPSERT behavior
- Restore after MERGE testing
- OPTIMIZE
- VACUUM dry-run validation

These checks establish that the deployed Databricks processing layer is using Delta Lake capabilities rather than treating the data as plain files only.

---

## Databricks SQL Warehouse

The analytical SQL warehouse is:

```text
olist-sql-warehouse
```

The Gold schema is:

```text
workspace.gold
```

The SQL layer is used for analytical queries over the Gold star schema.

The SQL work also supports the Superset connection.

---

## dbt Deployment

dbt is configured in the Windows development environment.

Validated versions are:

```text
Python:       3.12.4
dbt-core:     1.12.0
dbt-databricks: 1.12.4
```

The dbt project contains:

```text
staging
intermediate
marts
```

Representative staging models include:

```text
stg_customers
stg_orders
stg_order_items
stg_order_payments
stg_order_reviews
stg_products
stg_sellers
stg_geolocation
stg_product_category_translation
```

Intermediate models include:

```text
int_customer_orders
int_orders_enriched
int_order_items_enriched
int_products_enriched
```

Marts include dimensions and facts used for analytical modeling.

The following dbt validation steps passed:

```text
dbt debug
dbt run
dbt test
```

---

## Apache Superset Deployment

Apache Superset is the BI layer.

Superset was deployed locally using Docker Desktop on Windows.

The Superset environment was configured with:

```text
apache-superset[databricks]
```

and the Databricks driver was installed and validated.

A direct database connectivity test using:

```sql
SELECT 1
```

returned:

```text
1
```

This confirmed connectivity between Superset and the Databricks SQL backend.

---

## Superset Dashboard

The main dashboard is:

```text
Olist E-Commerce Analytics Dashboard
```

It contains 14 charts:

1. Total Orders
2. Total Revenue
3. Average Order Value
4. Total Customers
5. Total Freight Value
6. Monthly Orders Trend
7. Monthly Revenue Trend
8. Orders by Status
9. Top 10 Sellers by Revenue
10. Top 10 Products by Revenue
11. Monthly Delivered Orders
12. Average Product Price
13. Average Freight per Order
14. Top 10 Sellers by Freight Cost

Dashboard filters include:

```text
Order Purchase Date
Order Status
```

The filters were tested using actual dashboard interactions.

The publication state of the dashboard should be verified directly in Superset before describing it as publicly or formally published.

---

## Terraform Deployment

Terraform is used for a selected subset of AWS infrastructure.

The current managed resources are:

```text
Amazon S3
AWS Glue
```

Terraform configuration includes S3 settings for:

- Versioning
- Public access blocking
- Encryption

and the Glue ETL job configuration.

The AWS provider version is:

```text
6.63.0
```

The final Terraform validation reported:

```text
No changes.
```

This confirms that the Terraform-managed subset was aligned with the deployed infrastructure.

Terraform does not currently manage every service in the overall architecture.

In particular, the current Terraform configuration does not claim management of:

- Lambda
- EventBridge Scheduler
- CloudWatch
- CloudTrail
- Databricks
- Superset

---

## End-to-End Deployment Flow

The deployed platform can be viewed as two connected sections.

### AWS Batch Section

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
S3 Processed
```

### Analytics Section

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
      |
      v
Databricks SQL Warehouse
      |
      v
dbt
      |
      v
Apache Superset
```

The complete logical platform is therefore:

```text
Olist Dataset
      |
      v
S3 Raw
      |
      v
Glue ETL
      |
      v
S3 Processed
      |
      v
Databricks
      |
      v
Gold Star Schema
      |
      v
SQL Warehouse
      |
      v
dbt
      |
      v
Superset
```

---

## Deployment Validation Checklist

The following deployment checks have been completed.

### AWS

- S3 bucket available
- S3 security configuration validated
- Glue Data Catalog validated
- Glue ETL job available
- Glue ETL execution successful
- Lambda orchestrator available
- Lambda manual invocation successful
- Lambda-to-Glue start validated
- EventBridge Scheduler enabled
- CloudWatch logs inspected
- Glue runtime metrics inspected
- CloudTrail auditing capability validated

### Databricks

- Databricks workspace configured
- Medallion pipeline available
- Bronze layer validated
- Silver layer validated
- Gold layer validated
- Delta Lake features validated
- Gold star schema validated
- SQL Warehouse configured

### dbt

- dbt environment configured
- `dbt debug` passed
- `dbt run` passed
- `dbt test` passed

### Superset

- Docker-based Superset deployment available
- Databricks driver configured
- Databricks connectivity validated
- 14 dashboard charts created
- Date filter tested
- Order-status filter tested
- Dashboard analytics validated

### Terraform

- Terraform initialized
- Provider lock file present
- Formatting validated
- Configuration validated
- Infrastructure plan validated
- Final plan reported no changes

---

## Deployment Limitations

The project is a validated engineering implementation rather than a claim of complete one-command infrastructure provisioning.

Important boundaries are:

1. The complete Olist dataset is not stored in Git.
2. The full Superset source repository is not stored in the final project repository.
3. Databricks workspace configuration is not fully reproduced through Terraform.
4. Lambda and EventBridge are deployed but are outside the current Terraform-managed subset.
5. Monitoring validation does not include configured alarm/SNS infrastructure.
6. Superset publication status requires direct UI verification.

These boundaries are documented deliberately to keep the repository aligned with the actual implementation.

---

## Operational Deployment Model

The intended recurring AWS execution model is:

```text
Daily at 09:00
       |
       v
EventBridge Scheduler
       |
       v
Lambda
       |
       v
Glue ETL
       |
       v
S3 Processed
```

The downstream analytical and BI components then operate over the processed/curated data:

```text
S3 Processed
       |
       v
Databricks
       |
       v
Gold
       |
       v
SQL Warehouse
       |
       v
dbt
       |
       v
Superset
```

CloudWatch and CloudTrail provide operational visibility and auditing for the AWS portion of this deployment.

---

## Repository Deployment Artifacts

The final repository is organized around reproducible project documentation and configuration.

Relevant directories include:

```text
AWS-BIG-DATA/
├── data-understanding/
│   └── 01_data_understanding.ipynb
│
├── dbt/
│   ├── dbt_project.yml
│   ├── models/
│   ├── macros/
│   ├── analyses/
│   ├── seeds/
│   ├── snapshots/
│   └── tests/
│
├── docs/
│   ├── architecture.md
│   ├── dataset.md
│   ├── aws-services.md
│   ├── databricks.md
│   ├── delta-lake.md
│   ├── star-schema.md
│   ├── dbt.md
│   ├── orchestration.md
│   ├── monitoring.md
│   ├── superset.md
│   ├── terraform.md
│   └── deployment.md
│
├── screenshots/
├── Terraform/
├── README.md
└── .gitignore
```

Large datasets, local environments, secrets, and generated working directories are excluded from version control.

---

## Deployment Status

The platform's major implementation stages have been completed and validated:

```text
Data Understanding          COMPLETE
S3 Raw Storage              COMPLETE
Glue Catalog / Athena       COMPLETE
Glue ETL                    COMPLETE
Databricks Setup            COMPLETE
Bronze Layer                COMPLETE
Silver Layer                COMPLETE
Gold Layer                  COMPLETE
Delta Lake Features         COMPLETE
SQL Warehouse / Star Schema COMPLETE
dbt                         COMPLETE
AWS Batch Orchestration     COMPLETE
CloudWatch Monitoring       COMPLETE
Superset Analytics          COMPLETE
Terraform Subset            COMPLETE
Documentation               IN PROGRESS
```

The remaining project work is primarily repository finalization, screenshot collection where required, final documentation review, and GitHub publication.

---

## Summary

The Olist e-commerce batch data platform is deployed across AWS, Databricks, dbt, and Apache Superset.

AWS provides:

```text
S3
Glue
Lambda
EventBridge Scheduler
CloudWatch
CloudTrail
IAM
Secrets Manager
```

Databricks provides:

```text
Bronze
Silver
Gold
Delta Lake
SQL Warehouse
```

dbt provides analytical transformation and testing, while Apache Superset provides the business-facing visualization layer.

Terraform provides infrastructure-as-code coverage for the validated S3 and Glue subset.

The deployment has been validated through actual service execution, database connectivity, ETL runs, orchestration tests, dashboard interactions, dbt validation, and Terraform planning.

The documentation intentionally distinguishes between deployed components and components currently managed by Terraform so that the final repository accurately represents the implemented platform.
