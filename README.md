# AWS WITH BIG DATA - Olist E-commerce Batch Data Engineering Platform

An end-to-end batch data engineering platform built using AWS, Databricks, Delta Lake, dbt, Terraform, and Apache Superset.

The platform processes the Brazilian Olist e-commerce dataset through a layered data architecture, automated AWS batch orchestration, analytical modeling, data quality validation, and interactive business intelligence dashboards.

---

## Architecture

![System Architecture](screenshots/System%20Architecture.png)

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
Databricks Platform
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
Interactive Analytics Dashboard


Batch Orchestration:

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

---

## Project Overview

This project demonstrates a production-oriented batch data engineering workflow for processing e-commerce data.

The platform separates data into raw, processed, and analytical layers while using Databricks Delta Lake for scalable data transformation and dbt for analytical modeling.

The final Gold layer is exposed through Databricks SQL Warehouse and visualized using Apache Superset.

The batch pipeline is automated using EventBridge Scheduler, AWS Lambda, and AWS Glue. CloudWatch is used for operational monitoring and CloudTrail provides API activity auditing.

---

## Key Objectives

- Build an end-to-end AWS batch data engineering pipeline.
- Store raw and processed datasets in Amazon S3.
- Use AWS Glue for cataloging and ETL processing.
- Implement Bronze, Silver, and Gold data layers using Databricks Delta Lake.
- Build a validated Gold analytical star schema.
- Use Databricks SQL Warehouse for analytical querying.
- Implement dbt staging, intermediate, and mart models.
- Automate daily batch execution using EventBridge Scheduler and AWS Lambda.
- Monitor batch processing using Amazon CloudWatch.
- Build an interactive Apache Superset analytics dashboard.
- Manage selected AWS infrastructure using Terraform.
- Maintain data quality and document important modeling decisions.

---

## Technology Stack

| Category | Technology |
|---|---|
| Cloud Platform | Amazon Web Services |
| Object Storage | Amazon S3 |
| ETL | AWS Glue |
| Data Catalog | AWS Glue Data Catalog |
| Processing | Apache Spark / PySpark |
| Data Lake | Databricks Delta Lake |
| Analytics | Databricks SQL Warehouse |
| Transformation | dbt |
| Orchestration | Amazon EventBridge Scheduler |
| Serverless Compute | AWS Lambda |
| Monitoring | Amazon CloudWatch |
| Auditing | AWS CloudTrail |
| Security | AWS IAM / AWS Secrets Manager |
| Infrastructure as Code | Terraform |
| BI / Visualization | Apache Superset |
| Query Language | SQL |
| Programming | Python / PySpark |

---

## Dataset

The project uses the Brazilian Olist e-commerce dataset.

The dataset contains multiple related entities representing an e-commerce order lifecycle, including:

- Customers
- Orders
- Order items
- Payments
- Reviews
- Products
- Sellers
- Product category translations
- Geolocation

The original dataset is intentionally excluded from this GitHub repository because of its size.

Data profiling and data quality reports are available under `docs/`.

---

## Data Engineering Pipeline

### 1. Raw Data Layer

Original Olist datasets are stored in Amazon S3.

The Raw Zone preserves the source data before transformation.

```text
Olist Dataset
     |
     v
Amazon S3
     |
     +-- raw/
```

S3 security configuration includes:

- Versioning enabled
- Public access blocked
- Server-side encryption using AES256
- Bucket key enabled

### 2. AWS Glue Catalog and ETL

AWS Glue is used for metadata cataloging and batch transformation.

The Glue ETL job `olist-raw-to-processed-etl` reads data from the S3 Raw Zone, performs transformations and cleaning, and writes the resulting datasets to the S3 Processed Zone.

The implementation uses:

- AWS Glue 5.1
- PySpark
- G.1X workers
- Glue Data Catalog
- CloudWatch logging and metrics

### 3. Processed Data Layer

The transformed datasets are stored in the S3 Processed Zone.

```text
S3 Raw
  |
  v
AWS Glue ETL
  |
  v
S3 Processed
```

---

## Databricks Delta Lake

The processed datasets are loaded into Databricks and organized into three logical layers.

```text
Bronze
   |
   v
Silver
   |
   v
Gold
```

### Bronze Layer

The Bronze layer stores data close to the processed source representation.

Primary objectives:

- Preserve source information.
- Establish Delta Lake tables.
- Provide a reliable foundation for downstream transformations.

### Silver Layer

The Silver layer applies cleaning, standardization, and relationship-oriented transformations.

Typical processing includes:

- Data type normalization
- Null handling
- Column standardization
- Dataset relationships
- Business-oriented transformations

The Silver layer becomes the primary source for analytical modeling.

### Gold Layer

The Gold layer contains business-ready analytical tables.

```text
Dimensions
---------
dim_customers
dim_date
dim_products
dim_sellers

Facts
-----
fact_orders
fact_order_items
fact_payments
fact_reviews
```

---

## Gold Layer Validation

Important validation results include:

```text
fact_orders      : 99,441 rows
fact_order_items : 112,650 rows
```

Additional data quality decisions were documented during Gold-layer validation.

### Customer Grain

`customer_unique_id` is used for unique customer analysis rather than relying only on `customer_id`.

### Order Item Grain

`order_item_id` is not globally unique.

The correct order-item grain is:

```text
(order_id, order_item_id)
```

### Orders Without Items

775 orders contain no order items.

These records are retained because they represent source-level lifecycle anomalies rather than records that should automatically be deleted.

### Product Categories

610 products have missing source category names.

Missing categories are handled using:

```text
Uncategorized
```

### Category Translation

The product category translation data contains categories without English translations.

Fallback logic is applied so the final analytical layer does not contain missing English category values.

---

## Star Schema

The Gold analytical model follows a dimensional star-schema design.

```text
                    dim_customers
                          |
                          |
dim_date ------> fact_orders <------ dim_sellers
                    |
                    |
                    v
              fact_order_items
                    |
                    v
                dim_products


Additional facts:

fact_payments
fact_reviews
```

The star schema is designed to support:

- Order analysis
- Revenue analysis
- Customer analysis
- Seller performance
- Product performance
- Payment analysis
- Review analysis
- Time-series analysis

---

## Databricks SQL Warehouse

The Gold analytical tables are exposed through a Databricks SQL Warehouse.

The warehouse provides the SQL layer used for analytical queries and serves as the data source for dbt and Apache Superset.

Gold schema:

```text
workspace.gold
```

---

## dbt Transformation Layer

dbt is used to organize analytical transformations into maintainable models.

```text
dbt/
|
+-- models/
|   +-- staging/
|   +-- intermediate/
|   +-- marts/
+-- tests/
+-- macros/
+-- analyses/
+-- seeds/
+-- snapshots/
+-- dbt_project.yml
```

### Staging Models

Examples:

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

### Intermediate Models

Examples:

```text
int_customer_orders
int_orders_enriched
int_order_items_enriched
int_products_enriched
```

### Mart Models

Examples:

```text
dim_customers
dim_products
dim_sellers
fact_orders
fact_order_items
```

dbt validation was completed using:

```text
dbt debug
dbt run
dbt test
```

---

## Batch Orchestration

The implemented batch orchestration uses AWS-native serverless services.

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
Amazon S3 - Processed Zone
```

### EventBridge Scheduler

The daily schedule triggers the orchestration Lambda.

Schedule:

```text
cron(0 9 * * ? *)
```

Timezone:

```text
Asia/Calcutta
```

Target:

```text
olist-batch-orchestrator
```

### AWS Lambda

Lambda acts as the orchestration entry point.

Function:

```text
olist-batch-orchestrator
```

Its responsibility is to start the AWS Glue ETL job.

The Lambda invocation was manually validated and returned:

```text
GLUE_JOB_STARTED
```

along with the Glue run identifier.

### AWS Glue Batch Processing

The Lambda-triggered Glue job performs the actual batch ETL processing.

The Glue job has been repeatedly validated with successful runs.

The latest validated run completed successfully in approximately:

```text
104 seconds
```

with:

```text
208 DPU seconds
```

---

## Monitoring and Governance

### Amazon CloudWatch

CloudWatch is used to monitor:

- Lambda execution
- Glue job execution
- Batch processing logs
- Operational metrics

### AWS CloudTrail

CloudTrail provides auditing of AWS API activity for the platform.

### IAM

IAM roles provide service-specific permissions for AWS Glue, Lambda, and EventBridge Scheduler.

### AWS Secrets Manager

Sensitive credentials and connection secrets are kept outside source control.

---

## Apache Superset Dashboard

Apache Superset is used as the business intelligence and visualization layer.

Dashboard:

```text
Olist E-Commerce Analytics Dashboard
```

The dashboard contains 14 analytical charts.

### KPI Metrics

- Total Orders
- Total Revenue
- Average Order Value
- Total Customers
- Total Freight Value
- Average Product Price
- Average Freight per Order

### Trend Analysis

- Monthly Orders Trend
- Monthly Revenue Trend
- Monthly Delivered Orders

### Business Analysis

- Orders by Status
- Top 10 Sellers by Revenue
- Top 10 Products by Revenue
- Top 10 Sellers by Freight Cost

### Dashboard Filters

- Order Purchase Date
- Order Status

Dashboard filtering was validated using order status and date-range filters.

---

## Infrastructure as Code

Terraform is used to manage selected AWS infrastructure.

```text
Terraform/
|
+-- main.tf
+-- provider.tf
+-- variables.tf
+-- outputs.tf
+-- versions.tf
+-- .terraform.lock.hcl
```

Managed resources include:

- Amazon S3 bucket
- S3 versioning
- S3 public access block
- S3 server-side encryption
- AWS Glue ETL job

Terraform validation:

```text
terraform validate
```

Terraform planning was also validated with:

```text
No changes. Your infrastructure matches the configuration.
```

Terraform state files and credentials are intentionally excluded from Git.

---

## Data Quality

Data quality analysis was performed before final analytical modeling.

Reports include:

```text
docs/
|
+-- dataset_inventory.csv
+-- data_profiling_report.csv
+-- duplicate_report.csv
+-- null_value_report.csv
+-- referential_integrity_report.csv
+-- data_dictionary.md
+-- data_relationships.md
```

The analysis covered:

- Dataset inventory
- Null values
- Duplicate records
- Referential integrity
- Dataset relationships
- Profiling statistics

Data-quality findings were incorporated into the Gold-layer modeling decisions rather than blindly deleting anomalous records.

---

## Repository Structure

```text
AWS-BIG-DATA/
|
+-- README.md
+-- .gitignore
|
+-- data-understanding/
|   +-- 01_data_understanding.ipynb
|
+-- dbt/
|   +-- dbt_project.yml
|   +-- models/
|   |   +-- staging/
|   |   +-- intermediate/
|   |   +-- marts/
|   +-- macros/
|   +-- tests/
|   +-- analyses/
|   +-- seeds/
|   +-- snapshots/
|
+-- Terraform/
|   +-- main.tf
|   +-- provider.tf
|   +-- variables.tf
|   +-- outputs.tf
|   +-- versions.tf
|   +-- .terraform.lock.hcl
|
+-- docs/
|   +-- dataset_inventory.csv
|   +-- data_profiling_report.csv
|   +-- duplicate_report.csv
|   +-- null_value_report.csv
|   +-- referential_integrity_report.csv
|   +-- data_dictionary.md
|   +-- data_relationships.md
|
+-- screenshots/
```

---

## Security and Repository Hygiene

The repository intentionally excludes:

- Raw Olist datasets
- Large processed datasets
- Terraform state files
- AWS credentials
- Databricks access tokens
- API keys
- Environment secrets
- dbt target artifacts
- dbt logs
- Local virtual environments
- Docker-generated files
- Apache Superset source code

Sensitive configuration must be supplied through environment variables, AWS IAM, AWS Secrets Manager, or local configuration that is excluded from Git.

---

## Project Outcomes

The completed platform demonstrates:

- Cloud-based batch data engineering
- Data lake architecture
- AWS S3 storage
- AWS Glue ETL
- PySpark processing
- Databricks Delta Lake
- Medallion architecture
- Dimensional modeling
- Star schema design
- Databricks SQL analytics
- dbt transformation workflows
- Serverless batch orchestration
- Event-driven scheduling
- CloudWatch monitoring
- Terraform infrastructure management
- Business intelligence with Apache Superset
- Data quality validation

---

## Resume-Relevant Summary

Built an end-to-end AWS batch data engineering platform for the Olist e-commerce dataset using Amazon S3, AWS Glue, Databricks Delta Lake, PySpark, dbt, Terraform, AWS Lambda, EventBridge Scheduler, CloudWatch, and Apache Superset. Implemented Bronze/Silver/Gold data layers, validated a Gold star schema, automated daily ETL orchestration, and developed an interactive analytics dashboard for revenue, orders, customers, products, sellers, and delivery performance.

---

## Status

```text
Data Understanding           COMPLETE
S3 Raw Zone                  COMPLETE
Glue Catalog + ETL           COMPLETE
S3 Processed Zone            COMPLETE
Databricks Bronze            COMPLETE
Databricks Silver            COMPLETE
Databricks Gold              COMPLETE
Delta Lake Features          COMPLETE
SQL Warehouse + Star Schema  COMPLETE
dbt                          COMPLETE
Lambda + EventBridge         COMPLETE
CloudWatch Monitoring        COMPLETE
Apache Superset Dashboard    COMPLETE*
Terraform                    VALIDATED
Documentation                COMPLETE
GitHub Repository             READY FOR SUBMISSION
```

`*` Dashboard construction and filtering were validated; final publication status should be verified before claiming the dashboard is published.

---

## Author

**Adithya Varikuppala**

Data Engineering | AWS | Databricks | SQL | Python | dbt | Analytics
