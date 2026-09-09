# Gold Star Schema

## Overview

The Olist analytical model uses a Gold-layer star schema in Databricks.

The Gold layer separates descriptive business entities into dimension tables and measurable business events into fact tables. This structure is consumed by `olist-sql-warehouse` for SQL analytics and by Apache Superset for reporting.

The implemented Gold model contains:

- 4 dimension tables
- 4 fact tables

---

## Gold Schema

```text
                         dim_date
                            |
                            |
dim_customers ------ fact_orders ------ dim_sellers
                            |
                            |
                     fact_order_items
                            |
                    +-------+-------+
                    |       |       |
                    v       v       v
               dim_products
                    |
               fact_payments
                    |
               fact_reviews
```

The diagram is a conceptual representation of the analytical model. The exact join and relationship checks are performed in the Databricks SQL validation work.

---

## Dimension Tables

### `dim_customers`

`dim_customers` contains customer-level descriptive information used for customer and geographic analysis.

The project distinguishes the source `customer_id` from `customer_unique_id`. `customer_unique_id` is used when unique-customer analysis is required.

Typical analytical uses include:

- Customer analysis
- Customer counts
- Geographic analysis
- Customer-to-order analysis

---

### `dim_date`

`dim_date` provides calendar attributes used to analyze business events over time.

It supports time-based analysis such as:

- Monthly trends
- Order timing
- Revenue trends
- Delivered-order trends

---

### `dim_products`

`dim_products` contains product-level descriptive information used to analyze product performance and categories.

The Gold model accounts for missing source product category names by using `Uncategorized` where appropriate.

Product analysis supports:

- Product revenue analysis
- Category analysis
- Product performance comparisons

---

### `dim_sellers`

`dim_sellers` contains seller-level descriptive information used for seller performance analysis.

Seller analysis supports:

- Seller revenue
- Seller order activity
- Seller freight cost
- Seller performance comparisons

---

## Fact Tables

### `fact_orders`

`fact_orders` represents order-level business events.

The validated Gold table contains **99,441 orders**.

It supports analysis such as:

- Total orders
- Revenue
- Average order value
- Order status
- Order dates
- Delivered-order trends

Orders without corresponding order items are retained as source lifecycle anomalies rather than being silently removed.

The project identified **775 orders with no order items**.

---

### `fact_order_items`

`fact_order_items` represents individual product lines within orders.

The validated Gold table contains **112,650 order-item records**.

The correct source grain is:

```text
(order_id, order_item_id)
```

`order_item_id` is unique only within an order and therefore should not be treated as a globally unique key.

This fact supports:

- Product revenue
- Product price analysis
- Seller performance
- Freight analysis
- Order-item level analysis

---

### `fact_payments`

`fact_payments` contains payment-level information associated with orders.

It supports analysis of payment amounts and payment-related order metrics.

The table is part of the Gold analytical model and is validated through the Databricks SQL layer.

---

### `fact_reviews`

`fact_reviews` contains customer review-level information associated with orders.

It supports review-related analytical queries and is part of the Gold analytical model.

The source contains duplicate `review_id` values. The project does not blindly remove these records because the duplicate behavior is inherited from the source data and must be interpreted at the appropriate grain.

---

## Key Relationships

The Gold model connects facts to their descriptive dimensions so that business events can be analyzed by customer, product, seller, and date.

Conceptually:

```text
Customer Dimension
       |
       v
   Order Facts
       |
       +------> Date Dimension
       |
       +------> Seller Dimension
       |
       +------> Order Item Facts
                    |
                    v
              Product Dimension
```

Payment and review facts are also associated with the order-level analytical model.

The exact relationships and orphan-record checks are validated in `olist-sql-warehouse`.

---

## Fact Table Grain

Correct grain is important for avoiding double counting.

### Order grain

`fact_orders` is at the order level.

```text
1 row = 1 order
```

### Order-item grain

`fact_order_items` is at:

```text
1 row = 1 (order_id, order_item_id)
```

This distinction is important because an order can contain multiple items.

---

## Customer Identity

The source contains both `customer_id` and `customer_unique_id`.

The project uses:

- `customer_id` for the order/customer relationship where appropriate
- `customer_unique_id` for unique-customer analysis

This prevents multiple customer records associated with the same real customer from being counted as separate unique customers when the analysis requires customer uniqueness.

---

## Product Category Handling

The product data contains missing source category names.

The Gold model contains:

- **32,951 products**
- **610 products with missing source category names**
- Missing categories represented as `Uncategorized`

There were also **13 products/categories without an English translation** in the source translation data. The final Gold model applies the project's fallback handling so that the final English category field has no remaining missing values.

---

## Analytical Queries

The Gold star schema is queried through `olist-sql-warehouse`.

The SQL analytics work includes:

- Gold table inspection
- Key-column validation
- Fact/dimension relationship validation
- Orphan-record investigation
- Revenue analysis
- Category analysis
- Monthly revenue trends
- Seller performance
- Customer/state analysis

This confirms that the Gold model is not only a storage layer but is structured for downstream analytical workloads.

---

## Integration with Apache Superset

The Gold star schema provides the analytical source for the Superset dashboard.

The flow is:

```text
Databricks Medallion Pipeline
          |
          v
      Gold Tables
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

Superset uses the Gold analytical model to produce KPI, trend, status, seller, product, and freight-related visualizations.

---

## Data Quality Considerations

The star schema incorporates documented source-data quality decisions rather than hiding anomalies.

Important decisions include:

- `customer_unique_id` is used for unique-customer analysis.
- `order_item_id` is not assumed to be globally unique.
- 775 orders without order items are retained as source lifecycle anomalies.
- Duplicate `review_id` values are not blindly deduplicated.
- Missing product categories are represented as `Uncategorized`.
- Source category translation gaps are handled using the project's fallback logic.

These decisions preserve traceability to the source data while keeping the Gold layer usable for analytics.

---

## Gold Model Purpose

The Gold star schema is the final structured analytical model of the Databricks transformation layer.

It provides:

- Consistent business entities
- Defined fact-table grains
- Dimension-based analysis
- Reusable analytical tables
- SQL-friendly querying
- A stable source for the BI dashboard

The model therefore connects the data-engineering layers in Databricks with the SQL analytics and visualization layers of the platform.
