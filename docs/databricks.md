# Databricks

## Overview

Databricks is the transformation and analytical processing layer of the Olist batch data platform.

The implementation is organized around two actual Databricks artifacts:

1. `olist_medallion_pipeline` — the notebook used for the Medallion architecture and Delta Lake processing/validation.
2. `olist-sql-warehouse` — the Databricks SQL analytics/query artifact used to inspect and analyze the Gold layer.

The Databricks processing flow is:

```text
S3 Processed Data
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
Databricks SQL Analytics
       |
       v
Apache Superset
```

---

## `olist_medallion_pipeline`

`olist_medallion_pipeline` is the Databricks notebook implementing the Medallion data-processing workflow.

### Bronze Layer

The Bronze layer represents the raw/processed source data brought into Databricks for downstream transformation.

The notebook uses the Medallion structure to separate ingestion from progressively refined analytical data.

### Silver Layer

The Silver layer contains transformed and cleaned data prepared for analytical modelling.

Transformations in this stage support the construction of reliable Gold-layer entities and facts.

### Gold Layer

The Gold layer contains the analytical tables used by the SQL analytics layer.

The validated Gold tables include:

- `gold.dim_sellers`
- `gold.dim_date`
- `gold.fact_orders`
- `gold.fact_order_items`
- `gold.fact_payments`
- `gold.fact_reviews`

The broader Gold model also contains the customer and product dimensions used by the project's star schema.

---

## Delta Lake Implementation

The Medallion notebook also validates Delta Lake functionality on the Gold layer.

The implemented and validated Delta operations include:

- Delta format validation
- Delta transaction-history inspection
- Time Travel
- MERGE / UPSERT testing
- Restoration after MERGE testing
- OPTIMIZE
- VACUUM dry-run validation
- Final Delta validation

These operations demonstrate that the Gold analytical layer is maintained as Delta tables rather than being treated as static files.

---

## Gold Star Schema

The Gold layer is organized for analytical querying using fact and dimension tables.

### Dimensions

The project uses dimensions including:

- `dim_customers`
- `dim_date`
- `dim_products`
- `dim_sellers`

### Facts

The project uses fact tables including:

- `fact_orders`
- `fact_order_items`
- `fact_payments`
- `fact_reviews`

This structure separates descriptive entities from measurable business events and supports analytical queries without repeatedly rebuilding the underlying transformations.

---

## `olist-sql-warehouse`

`olist-sql-warehouse` is the Databricks SQL analytics/query component used against the Gold layer.

Its SQL work focuses on validating and analyzing the Gold star schema.

### Validation Queries

The SQL artifact includes validation and inspection of:

- Gold table structures
- Key columns
- Fact/dimension relationships
- Orphan records
- Gold-layer data integrity

These checks help confirm that the analytical model is suitable for downstream reporting.

### Analytical Queries

The SQL artifact also performs business analysis against the Gold data, including:

- Revenue and category analysis
- Monthly revenue trends
- Seller performance
- Customer/state analysis

The resulting Gold-layer data provides the analytical source for the dashboard layer.

---

## Relationship Between the Two Databricks Artifacts

The two artifacts have separate responsibilities:

```text
olist_medallion_pipeline
        |
        |  Bronze → Silver → Gold
        |  Delta Lake processing
        |  Delta validation
        v
Gold Star Schema
        |
        v
olist-sql-warehouse
        |
        |  Validation queries
        |  Business analytics
        v
Apache Superset
```

The notebook is responsible for **data engineering and Delta Lake processing**, while `olist-sql-warehouse` is responsible for **SQL-based analytical querying and validation**.

---

## Data Quality and Validation

The Databricks work incorporates validation at the analytical layer rather than assuming that successful transformation alone guarantees correct data.

The project validates:

- Gold table availability
- Key columns
- Relationships between facts and dimensions
- Orphan records
- Delta table state
- Delta transaction history
- Results after MERGE testing and restoration

Known project-level data-quality decisions are documented separately in the dataset and data-quality documentation.

---

## Integration with the Overall Platform

Databricks receives the processed data produced by the AWS layer and creates the analytical Gold model.

The complete downstream flow is:

```text
Amazon S3 - Processed
        |
        v
Databricks Medallion Pipeline
        |
        +--> Bronze
        |
        +--> Silver
        |
        +--> Gold
                 |
                 v
          Gold Star Schema
                 |
                 v
       olist-sql-warehouse
                 |
                 v
          Apache Superset
```

Databricks therefore forms the core data-engineering and analytical modelling layer between AWS batch processing and the BI dashboard.
