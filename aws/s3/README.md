# Amazon S3 - Data Lake Storage

Amazon S3 is the primary data lake storage layer for the Olist batch data engineering platform.

## Storage Architecture

```text
Olist E-commerce Dataset
        |
        v
Amazon S3 - Raw Zone
        |
        | AWS Glue ETL
        v
Amazon S3 - Processed Zone
        |
        v
Databricks
        |
        v
Delta Lake
        |
        v
Gold Analytical Tables
```

## S3 Zones

### Raw Zone

Stores the original Olist datasets in their source format.

Purpose:
- Landing zone for incoming data
- Preserve original source data
- Partition data by ingestion/date where applicable
- Enable repeatable ETL processing

### Processed Zone

Stores data after AWS Glue ETL processing.

Purpose:
- Cleaned and standardized datasets
- Schema-normalized data
- Data-quality processing
- Prepared for downstream Databricks processing

## Integration

Amazon S3 integrates with:

- AWS Glue Data Catalog
- AWS Glue ETL
- Databricks
- Delta Lake
- AWS Lambda
- EventBridge Scheduler
- Apache Superset through the downstream analytical layer

## Security

The project does not commit AWS credentials, access keys, Terraform state, or other secrets to GitHub.

S3 access is controlled through AWS IAM and bucket policies.
