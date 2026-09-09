# Apache Superset Analytics

## Overview

Apache Superset is the business intelligence and dashboard layer of the Olist e-commerce batch data platform.

Superset connects to the analytical data exposed through the Databricks SQL Warehouse and provides interactive charts, dashboard filters, and business-facing analytics.

The implemented analytics flow is:

```text
Olist Dataset
      |
      v
AWS S3 Raw
      |
      v
AWS Glue ETL
      |
      v
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
Apache Superset
```

Superset was selected instead of AWS QuickSight so the analytics layer could use an open-source, self-hosted BI platform.

---

## Why Apache Superset

Apache Superset provides the dashboard and visualization layer without requiring the project to depend on a paid AWS BI subscription.

The project uses Superset for:

- Interactive dashboard visualization
- KPI reporting
- Trend analysis
- Product and seller analysis
- Order-status analysis
- Date-based filtering
- Business-facing exploration of Gold-layer data

Superset is therefore positioned after the Databricks SQL analytics layer rather than inside the AWS ingestion or ETL path.

---

## Superset Deployment

Superset was run locally using Docker Desktop on Windows.

The local deployment provides the application environment required to:

- Run the Superset web interface
- Configure the Databricks database connection
- Create datasets and charts
- Assemble the Olist analytics dashboard
- Test dashboard filters and visualizations

The Superset source repository itself is not part of the final project repository.

The final repository contains project documentation and configuration-related artifacts rather than the complete Superset application source tree.

---

## Databricks Connection

Superset connects to the Databricks SQL Warehouse used for the analytical layer.

The configured warehouse is:

```text
olist-sql-warehouse
```

The analytical Gold schema is:

```text
workspace.gold
```

The connection was validated with a direct SQL engine test:

```sql
SELECT 1
```

The test returned:

```text
1
```

This confirmed that the Superset environment could communicate with the Databricks SQL backend.

---

## Analytical Data Source

The primary analytical source is the Databricks Gold layer.

The Gold layer contains the star-schema dimensions and facts used for dashboard analytics.

Core Gold tables include:

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

These tables provide the business-level data required for order, customer, product, seller, payment, and review analysis.

The dashboard is therefore built on curated analytical data rather than directly querying the raw Olist source files.

---

## Olist E-Commerce Analytics Dashboard

The main Superset dashboard is:

```text
Olist E-Commerce Analytics Dashboard
```

The dashboard contains 14 charts covering high-level KPIs, trends, order status, seller performance, product performance, and freight analysis.

The implemented chart set is:

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

---

## KPI Charts

### Total Orders

Shows the number of orders represented in the analytical dataset.

The Gold `fact_orders` data contains:

```text
99,441 orders
```

before dashboard filtering.

---

### Total Revenue

Shows the aggregated order payment/revenue measure used by the dashboard.

This KPI provides a high-level view of the commercial value represented in the analytical dataset.

---

### Average Order Value

Shows average revenue per order.

Conceptually:

```text
Average Order Value
=
Total Revenue / Total Orders
```

The KPI can change when dashboard filters are applied.

---

### Total Customers

The customer KPI uses distinct customer identity from the order facts.

The analytical design uses `customer_unique_id` for unique customer analysis rather than treating every source `customer_id` as a separate customer.

---

### Total Freight Value

Shows aggregated freight value associated with the order data.

This KPI supports analysis of logistics-related cost alongside sales metrics.

---

## Trend Charts

### Monthly Orders Trend

Displays order volume over time using the order purchase date.

This allows the dashboard to show changes in order activity across the available Olist timeline.

---

### Monthly Revenue Trend

Displays revenue over time using the order purchase date.

The visualization provides a time-series view of commercial performance.

---

### Monthly Delivered Orders

Shows delivered-order volume by month.

This provides a focused view of completed deliveries rather than total order volume.

---

## Order Status Analysis

### Orders by Status

Shows the distribution of orders across their lifecycle statuses.

This allows users to compare states such as:

```text
delivered
shipped
canceled
unavailable
invoiced
processing
created
approved
```

The actual values depend on the records and filters present in the analytical data.

---

## Seller Analysis

### Top 10 Sellers by Revenue

Ranks sellers based on the revenue represented in the analytical order-item data.

This identifies sellers with the highest contribution to the measured sales value.

---

### Top 10 Sellers by Freight Cost

Ranks sellers using associated freight values.

This provides a logistics-oriented complement to the seller revenue ranking.

---

## Product Analysis

### Top 10 Products by Revenue

Ranks products according to their associated revenue.

This supports identification of products with the strongest commercial contribution.

The dashboard uses the curated Gold product and order-item analytical data rather than raw source files.

---

### Average Product Price

Shows the average product price represented in the analytical product/order-item data.

This provides a high-level view of product pricing.

---

## Dashboard Filters

The dashboard includes interactive filters for:

- Order Purchase Date
- Order Status

These filters apply to the dashboard charts and allow users to inspect specific time periods and order-status subsets.

---

## Filter Validation

The dashboard filters were tested using actual dashboard interactions.

For example, applying the `delivered` order-status filter changed the Total Orders KPI from approximately:

```text
99.4K
```

to approximately:

```text
96.5K
```

This demonstrated that the dashboard filter was affecting the underlying analytical queries.

A year-based date filter was also tested.

For the 2017 period, the dashboard showed approximately:

```text
Total Orders: 14.5K
Revenue:      1.94M
AOV:          141.45
```

These values demonstrate that the date filter changed the dashboard metrics according to the selected period.

---

## Dashboard Design

The dashboard is organized around several analytical categories:

```text
Executive KPIs
      |
      +--> Orders
      +--> Revenue
      +--> AOV
      +--> Customers
      +--> Freight

Trends
      |
      +--> Monthly Orders
      +--> Monthly Revenue
      +--> Monthly Delivered Orders

Operational Analysis
      |
      +--> Order Status

Seller Analysis
      |
      +--> Revenue Ranking
      +--> Freight Ranking

Product Analysis
      |
      +--> Revenue Ranking
      +--> Average Price
```

This structure provides a progression from high-level KPIs to detailed business analysis.

---

## Relationship to Databricks SQL

Databricks provides the analytical computation layer while Superset provides the visualization layer.

The separation is:

```text
Databricks Gold
      |
      v
Databricks SQL Warehouse
      |
      |  SQL queries
      v
Apache Superset
      |
      v
Charts + Dashboard + Filters
```

This keeps business visualization separate from the underlying data-engineering transformations.

---

## Relationship to dbt

dbt is part of the analytical transformation workflow.

The broader analytical path is:

```text
AWS / S3
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
dbt Models
    |
    v
Databricks SQL Analytics
    |
    v
Superset
```

The project therefore combines data engineering, analytical modeling, and BI visualization rather than using Superset as an isolated dashboard tool.

---

## Dashboard Validation

The Superset layer was validated through:

- Successful local Superset deployment
- Successful Databricks driver setup
- Successful `SELECT 1` connection test
- Access to the Databricks analytical backend
- Creation of the 14-chart dashboard
- Successful KPI visualization
- Successful trend visualization
- Successful seller/product analysis charts
- Successful order-status visualization
- Successful date filtering
- Successful order-status filtering

These checks establish that the BI layer is connected to the analytical platform and can query the project data.

---

## Publication Status

The dashboard has been built and tested in Superset.

The final publication state should be verified directly in the Superset interface before documenting the dashboard as published.

This documentation therefore does not claim a published/public dashboard state unless that state has been explicitly verified.

---

## Security Considerations

Superset connects to the analytical backend using database connection credentials.

Credentials and secrets should not be committed to Git.

The project follows these principles:

- Do not store passwords in source files
- Do not commit API keys
- Do not commit Databricks tokens
- Keep local secrets outside version control
- Use environment variables or secret-management mechanisms where appropriate

The repository `.gitignore` excludes common local secret and environment files.

---

## Operational Position

Superset is the final visualization layer of the platform.

The complete analytical path is:

```text
EventBridge Scheduler
        |
        v
Lambda
        |
        v
AWS Glue
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
Databricks SQL Warehouse
        |
        v
dbt
        |
        v
Apache Superset
```

AWS CloudWatch and CloudTrail provide operational monitoring and auditing around the AWS batch-processing portion of this architecture.

---

## Current Status

The Apache Superset analytics layer has been implemented and validated as the project's BI layer.

Completed work includes:

- Local Superset deployment on Windows
- Databricks SQL connectivity
- Gold-layer analytical data access
- 14 dashboard charts
- Date filtering
- Order-status filtering
- KPI validation
- Trend validation
- Seller analysis
- Product analysis
- Freight analysis

The dashboard publication state remains intentionally subject to direct UI verification.

---

## Summary

Apache Superset provides the final business-facing analytics layer for the Olist e-commerce batch data platform.

It consumes curated analytical data through Databricks SQL and presents the results through an interactive dashboard containing 14 charts and two dashboard filters.

The implementation demonstrates the complete progression from batch data ingestion and transformation to analytical modeling and BI visualization while avoiding dependence on a paid AWS-native BI subscription.
