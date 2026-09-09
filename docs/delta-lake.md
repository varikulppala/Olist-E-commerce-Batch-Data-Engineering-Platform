# Delta Lake

## Overview

Delta Lake is the table-storage format and reliability layer used in the Databricks Medallion architecture.

The Delta Lake work is implemented and validated through the `olist_medallion_pipeline` notebook.

The project uses Delta tables across the Bronze, Silver, and Gold processing layers, with the Gold layer serving the analytical model.

---

## Delta Lake in the Medallion Architecture

The Databricks processing flow is:

```text
S3 Processed Data
       |
       v
Bronze Delta Tables
       |
       v
Silver Delta Tables
       |
       v
Gold Delta Tables
       |
       v
Databricks SQL Analytics
```

The Medallion structure separates the stages of data refinement while Delta Lake provides transactional table management for the Databricks layers.

---

## Gold Delta Tables

The `olist_medallion_pipeline` notebook validates Delta tables in the Gold layer.

The validated analytical tables include:

- `gold.dim_sellers`
- `gold.dim_date`
- `gold.fact_orders`
- `gold.fact_order_items`
- `gold.fact_payments`
- `gold.fact_reviews`

The Gold model also contains customer and product dimensions used by the project's star schema.

---

## Delta Format Validation

The notebook explicitly validates that the relevant Gold tables are stored in Delta format.

This confirms that the analytical tables are managed as Delta tables rather than being treated as ordinary static files.

---

## Delta Transaction History

The pipeline inspects Delta transaction history to verify table operations and table state.

Transaction history provides an operational record of changes made to Delta tables and supports investigation of table modifications.

---

## Time Travel

The notebook validates Delta Lake Time Travel.

Time Travel allows a previous table state to be queried using the Delta table's transaction history.

This is useful for:

- Inspecting historical table states
- Verifying changes
- Recovering from unintended modifications
- Auditing table evolution

The project uses Time Travel as part of its Delta Lake validation workflow.

---

## MERGE / UPSERT

The notebook performs a MERGE / UPSERT test against a Delta table.

MERGE is used to demonstrate how existing records can be updated while new records can be inserted into a Delta table.

The test is followed by validation and restoration so that the analytical data remains in its intended final state.

---

## Restore After MERGE Testing

After testing MERGE behavior, the notebook restores the affected table to the required state.

This prevents the demonstration/test operation from leaving unintended changes in the final analytical dataset.

The restoration step is part of the notebook's Delta Lake validation process.

---

## OPTIMIZE

The notebook validates the Delta Lake `OPTIMIZE` operation.

OPTIMIZE is used to improve the physical organization of Delta table data for more efficient access.

The project includes OPTIMIZE as part of its Delta Lake feature validation.

---

## VACUUM

The notebook performs a VACUUM dry-run validation.

The dry run allows the project to inspect which files would be eligible for cleanup without immediately deleting them.

This provides a safer way to validate VACUUM behavior during the project.

---

## Final Delta Validation

The notebook performs final validation after the Delta Lake feature tests.

The validation covers:

- Delta table format
- Transaction history
- Time Travel behavior
- MERGE / UPSERT behavior
- Restoration after testing
- OPTIMIZE
- VACUUM dry run
- Final Gold table state

The purpose is to demonstrate the Delta Lake capabilities used by the project while preserving the correctness of the final analytical dataset.

---

## Delta Lake and the Gold Star Schema

Delta Lake supports the Gold star schema used by the analytical layer.

```text
                 dim_customers
                       |
                       |
dim_products ---- fact_orders ---- dim_date
                       |
                       |
                 fact_order_items
                       |
              +--------+--------+
              |        |        |
       fact_payments fact_reviews
              |
        dim_sellers
```

The exact relationships are validated separately through the Databricks SQL analytics work.

---

## Integration with Databricks SQL

After the Medallion pipeline produces the Gold Delta tables, the `olist-sql-warehouse` SQL artifact queries those tables for validation and business analysis.

```text
olist_medallion_pipeline
          |
          v
    Gold Delta Tables
          |
          v
  olist-sql-warehouse
          |
          v
     SQL Analytics
          |
          v
   Apache Superset
```

This separates Delta-based data engineering from SQL-based analytical consumption.

---

## Why Delta Lake Is Used

Within this project, Delta Lake provides the table-management capabilities required for a reliable analytical layer, including:

- Transaction history
- Historical table-state access through Time Travel
- MERGE / UPSERT operations
- Restoration after controlled changes
- OPTIMIZE
- VACUUM validation

These features were not only documented conceptually; they were exercised and validated through the Databricks Medallion notebook.
