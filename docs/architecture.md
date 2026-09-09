# System Architecture

## Overview

The Olist E-commerce Batch Data Engineering Platform is an end-to-end batch analytics architecture that combines AWS, Databricks, Delta Lake, dbt, Terraform, and Apache Superset.

The platform separates ingestion, processing, analytical modeling, orchestration, monitoring, and visualization into distinct layers.

## End-to-End Data Flow

```text
Olist E-commerce Dataset
          |
          v
Amazon S3 - Raw Zone
          |
          v
AWS Glue Catalog + ETL
          |
          v
Amazon S3 - Processed Zone
          |
          v
Databricks Delta Lake
          |
    +-----+-----+
    |     |     |
    v     v     v
 Bronze Silver Gold
    |     |     |
    +-----+-----+
          |
          v
Databricks SQL Warehouse
          |
          v
Gold Star Schema
          |
          v
dbt
          |
          v
Apache Superset
          |
          v
Analytics Dashboard
```

## Batch Orchestration Flow

The implemented batch orchestration uses AWS EventBridge Scheduler, AWS Lambda, and AWS Glue.

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
Amazon S3 - Processed Zone
```

The EventBridge Scheduler triggers the Lambda function on the configured daily schedule.

The Lambda function starts the AWS Glue ETL job.

AWS Glue performs the batch transformation and writes the processed output to Amazon S3.

## Storage Layer

Amazon S3 provides the object-storage layer for the pipeline.

### Raw Zone

The Raw Zone stores the source Olist datasets before transformation.

```text
Olist Dataset
     |
     v
Amazon S3
     |
     +-- raw/
```

### Processed Zone

The Processed Zone contains datasets produced by the AWS Glue ETL process.

```text
Amazon S3
     |
     +-- processed/
```

The S3 bucket is configured with versioning, public-access blocking, and server-side encryption.

## AWS Processing Layer

AWS Glue provides the cataloging and ETL capabilities.

The Glue job `olist-raw-to-processed-etl` uses PySpark to process the raw datasets and produce the processed data layer.

The Glue Data Catalog provides metadata management for the datasets used by the AWS processing workflow.

## Databricks Data Lakehouse Layer

Databricks provides the analytical data processing environment.

The data is organized using a three-layer medallion architecture:

```text
Bronze
   |
   v
Silver
   |
   v
Gold
```

### Bronze

The Bronze layer provides the foundational Delta Lake representation of the processed source data.

### Silver

The Silver layer applies cleaning, standardization, data-type normalization, null handling, and relationship-oriented transformations.

### Gold

The Gold layer contains business-ready analytical tables used for downstream SQL analytics and BI.

The Gold layer includes:

```text
Dimensions
- dim_customers
- dim_date
- dim_products
- dim_sellers

Facts
- fact_orders
- fact_order_items
- fact_payments
- fact_reviews
```

## Analytical Layer

The Gold data is exposed through a Databricks SQL Warehouse.

The Gold schema is:

```text
workspace.gold
```

The analytical model follows a dimensional star-schema design.

```text
                    dim_customers
                          |
                          |
dim_date ------> fact_orders <------ dim_sellers
                    |
                    v
              fact_order_items
                    |
                    v
                dim_products
```

Additional analytical facts include:

```text
fact_payments
fact_reviews
```

## dbt Layer

dbt provides a structured transformation and modeling layer on top of the analytical data.

The dbt project is organized into:

```text
dbt/
|
+-- models/
|   +-- staging/
|   +-- intermediate/
|   +-- marts/
|
+-- tests/
+-- macros/
+-- analyses/
+-- seeds/
+-- snapshots/
```

The staging layer standardizes source datasets.

The intermediate layer contains reusable transformation logic.

The marts layer contains analytical dimensions and fact models.

## Business Intelligence Layer

Apache Superset provides the visualization and dashboard layer.

Superset connects to the Databricks SQL Warehouse and presents the Gold analytical data through an interactive dashboard.

The dashboard contains KPI, trend, seller, product, order-status, and freight-analysis visualizations.

Dashboard filters include:

- Order Purchase Date
- Order Status

## Monitoring and Governance

Operational monitoring is provided through Amazon CloudWatch.

CloudWatch is used for:

- Lambda execution monitoring
- Glue job monitoring
- Batch processing logs
- Operational metrics

AWS CloudTrail provides auditing of AWS API activity.

IAM roles provide service-specific permissions for the AWS services used by the platform.

Sensitive credentials are kept outside source control.

## Infrastructure as Code

Terraform manages selected AWS infrastructure.

The current Terraform configuration manages:

- Amazon S3 bucket
- S3 versioning
- S3 public access block
- S3 server-side encryption
- AWS Glue ETL job

Terraform configuration is maintained separately under:

```text
Terraform/
```

## Architecture Summary

The complete platform can be viewed as six major layers:

```text
1. Storage
   Amazon S3

2. AWS Processing
   AWS Glue + Glue Data Catalog

3. Lakehouse
   Databricks + Delta Lake
   Bronze -> Silver -> Gold

4. Analytical Modeling
   Databricks SQL Warehouse + Star Schema + dbt

5. Orchestration and Operations
   EventBridge Scheduler -> Lambda -> Glue
   CloudWatch + CloudTrail + IAM

6. Business Intelligence
   Apache Superset
```

This architecture provides a clear separation between source storage, batch processing, analytical transformation, orchestration, monitoring, and business intelligence.
