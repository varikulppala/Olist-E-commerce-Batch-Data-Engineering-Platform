# dbt

## Overview

dbt (data build tool) is the SQL transformation and testing layer used with Databricks in the Olist batch data platform.

The dbt project is located at:

```text
C:\Users\varik\olist_aws_batch_data_platform_adhi_2026
```

The implementation uses dbt with the Databricks adapter.

Validated versions used during the project include:

- Python: 3.12.4
- dbt-core: 1.12.0
- dbt-databricks: 1.12.4

---

## dbt and Databricks

dbt operates on the Databricks analytical environment and provides a structured transformation layer over the project data.

The overall flow is:

```text
AWS S3 Processed Data
        |
        v
Databricks Medallion Pipeline
        |
        v
Gold Analytical Layer
        |
        v
dbt
        |
        v
Databricks SQL Analytics
        |
        v
Apache Superset
```

dbt is used as a separate transformation and modelling layer alongside the Databricks Medallion implementation.

---

## Project Structure

The dbt project contains:

```text
dbt/
├── analyses/
├── macros/
├── models/
├── seeds/
├── snapshots/
├── tests/
└── dbt_project.yml
```

The main transformation logic is organized under `models`.

---

## Model Layers

The dbt models are organized into three logical layers:

```text
Sources
   |
   v
Staging
   |
   v
Intermediate
   |
   v
Marts
```

### Staging

Implemented staging models include:

- `stg_customers`
- `stg_orders`
- `stg_order_items`
- `stg_order_payments`
- `stg_order_reviews`
- `stg_products`
- `stg_sellers`
- `stg_geolocation`
- `stg_product_category_translation`

The staging layer prepares source entities for downstream transformations.

---

## Intermediate Models

The intermediate layer contains reusable business-oriented transformations.

Implemented models include:

- `int_customer_orders`
- `int_orders_enriched`
- `int_order_items_enriched`
- `int_products_enriched`

These models provide transformation steps between staged entities and the final analytical marts.

---

## Mart Models

The marts layer contains the analytical models exposed for downstream consumption.

Implemented dimension models include:

- `dim_customers`
- `dim_products`
- `dim_sellers`

Implemented fact models include:

- `fact_orders`
- `fact_order_items`

The marts configuration materializes the analytical models as tables.

---

## Materialization Strategy

The project configures:

- Staging models as views
- Intermediate models as views
- Mart models as tables

This keeps reusable transformation layers lightweight while materializing final analytical models for downstream querying.

---

## Databricks Adapter

The project uses `dbt-databricks` to connect dbt with Databricks.

This allows dbt models and tests to execute against the Databricks analytical environment.

The adapter was installed and validated during the project setup.

---

## dbt Validation

The dbt project was validated using the standard workflow.

### `dbt debug`

`dbt debug` was executed successfully, confirming that the dbt project configuration and Databricks connection were working correctly.

### `dbt run`

`dbt run` was executed successfully and built the configured models in the Databricks environment.

### `dbt test`

`dbt test` was executed successfully and validated the configured dbt data-quality and relationship tests.

Together, these checks confirm that the dbt project can connect, build its models, and execute its validation tests successfully.

---

## dbt Transformation Flow

The model dependencies follow a layered approach:

```text
Staging Models
      |
      v
Intermediate Models
      |
      v
Mart Models
      |
      v
Databricks Analytics
```

For example:

```text
stg_customers
       |
       v
int_customer_orders
       |
       v
dim_customers / fact_orders
```

This structure keeps source preparation, reusable transformations, and analytical outputs separated.

---

## Analytical Consumption

The dbt mart models form part of the analytical layer used for querying and reporting.

The broader project also maintains a Gold star schema through the Databricks Medallion pipeline.

The two approaches serve complementary purposes:

- Databricks Medallion processing establishes the Bronze, Silver, and Gold data layers.
- dbt provides SQL-based transformation, model organization, and testing.

The resulting analytical data can be consumed by Databricks SQL and Apache Superset.

---

## Testing and Data Quality

dbt testing provides an additional validation layer after model construction.

The project uses dbt tests to verify configured data-quality expectations and model relationships.

This complements the broader data-quality validation performed during the Databricks Medallion and Gold-layer work.

---

## Relationship to the Final Architecture

The relevant transformation path is:

```text
AWS Glue
    |
    v
S3 Processed
    |
    v
Databricks Medallion
    |
    +--> Bronze
    +--> Silver
    +--> Gold
              |
              v
             dbt
              |
              v
       Analytical Models
              |
              v
   Databricks SQL Analytics
              |
              v
       Apache Superset
```

dbt is part of the analytical transformation and testing layer rather than the AWS ingestion/orchestration layer.

---

## Project Status

The dbt implementation has been validated for the configured project:

```text
dbt debug  ✓
dbt run    ✓
dbt test   ✓
```

The successful validation confirms that the configured dbt project can connect to Databricks, execute its models, and run its tests.
