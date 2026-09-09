# Dataset Documentation

## Dataset Overview

This project uses the Brazilian Olist e-commerce dataset as the source dataset for the batch data engineering platform.

The dataset represents an e-commerce order lifecycle and contains multiple related entities used for ingestion, transformation, analytical modeling, and business intelligence.

The original dataset files are intentionally excluded from this repository because of their size.

## Source Entities

The project works with the following major datasets:

| Entity | Description |
|---|---|
| Customers | Customer records and customer identifiers |
| Orders | Order lifecycle and order status information |
| Order Items | Individual items associated with orders |
| Payments | Payment information associated with orders |
| Reviews | Customer review records |
| Products | Product attributes and category information |
| Sellers | Seller information |
| Product Category Translation | Category names and English translations |
| Geolocation | Brazilian location and postal-code information |

These entities are related through order, customer, product, seller, and geographic keys.

## Data Understanding

Initial data understanding and profiling were performed before downstream analytical modeling.

The repository contains the data-understanding notebook:

```text
data-understanding/
    01_data_understanding.ipynb
```

Supporting profiling and quality reports are stored under:

```text
docs/
```

The reports cover:

- Dataset inventory
- Data profiling
- Null values
- Duplicate records
- Referential integrity
- Dataset relationships

## Data Quality Reports

The following reports are maintained in the repository:

```text
dataset_inventory.csv
data_profiling_report.csv
duplicate_report.csv
null_value_report.csv
referential_integrity_report.csv
data_dictionary.md
data_relationships.md
```

These reports provide evidence for the data-quality decisions used during the transformation and analytical modeling stages.

## Important Modeling Decisions

### Customer Identity

The project distinguishes between the source customer identifier and the unique customer identity.

`customer_unique_id` is used when performing unique-customer analysis rather than relying only on `customer_id`.

This prevents customer-level analysis from treating repeated source customer records as separate unique customers.

### Order Item Grain

`order_item_id` is not globally unique across the dataset.

The correct grain for an order-item record is:

```text
(order_id, order_item_id)
```

This composite grain is important when counting or aggregating order items.

### Orders Without Order Items

During validation, 775 orders were identified without corresponding order-item records.

These records are retained rather than automatically deleted because they represent source-level order lifecycle anomalies.

Removing them without investigation could hide meaningful source-data behavior.

### Missing Product Categories

610 products have missing source category names.

The analytical layer handles these missing category values using:

```text
Uncategorized
```

This preserves the affected products while providing a consistent analytical category.

### Category Translation

The product category translation dataset contains categories that do not have an English translation.

13 categories were identified as originally untranslated.

Fallback handling was applied so that the final analytical layer does not contain missing English category values.

## Gold Layer Validation

The validated Gold layer contains the following key fact-table counts:

```text
fact_orders      : 99,441 rows
fact_order_items : 112,650 rows
```

Additional Gold-layer validation confirmed the handling of missing categories and category translations.

The final analytical layer contains:

```text
610 Uncategorized products
0 missing English category values after fallback
```

## Data Quality Philosophy

The project does not treat every anomaly as an error that should be deleted.

Instead, data-quality findings are evaluated according to the business meaning and source-system context.

Examples include:

- Retaining orders without items as source lifecycle anomalies.
- Using `customer_unique_id` for unique-customer analysis.
- Treating `(order_id, order_item_id)` as the order-item grain.
- Preserving products with missing source categories through the `Uncategorized` fallback.
- Applying translation fallback logic rather than discarding untranslated categories.

This approach keeps the analytical model traceable to the source data while making it suitable for downstream reporting.

## Data Flow

The dataset moves through the platform as follows:

```text
Olist Source Dataset
        |
        v
Amazon S3 - Raw Zone
        |
        v
AWS Glue ETL
        |
        v
Amazon S3 - Processed Zone
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

The Gold layer is then used for analytical SQL, dbt transformations, and Apache Superset dashboards.

## Repository Data Policy

The original Olist data files are not committed to GitHub.

This keeps the repository focused on:

- Transformation logic
- Data-quality analysis
- Analytical models
- Infrastructure configuration
- Documentation
- Reproducible project structure

Users reproducing the project should provide the source dataset separately and configure the required AWS and Databricks resources.

## Summary

The Olist dataset provides the source foundation for the complete batch analytics platform.

The project performs structured data understanding and quality analysis before building the Bronze, Silver, and Gold layers. Important source-data characteristics are explicitly documented and incorporated into the analytical model rather than silently discarded.
