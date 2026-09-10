SELECT
    current_timestamp() AS warehouse_test_timestamp;
    SHOW TABLES IN gold;
    SELECT 'dim_sellers' AS table_name, COUNT(*) AS record_count
FROM gold.dim_sellers

UNION ALL

SELECT 'dim_date', COUNT(*)
FROM gold.dim_date

UNION ALL

SELECT 'fact_orders', COUNT(*)
FROM gold.fact_orders

UNION ALL

SELECT 'fact_order_items', COUNT(*)
FROM gold.fact_order_items

UNION ALL

SELECT 'fact_payments', COUNT(*)
FROM gold.fact_payments

UNION ALL

SELECT 'fact_reviews', COUNT(*)
FROM gold.fact_reviews;
-- ============================================================
-- STEP 10.2.1 — GOLD STAR SCHEMA COLUMN INSPECTION
-- ============================================================

SELECT
    table_name,
    column_name,
    data_type,
    ordinal_position
FROM system.information_schema.columns
WHERE table_schema = 'gold'
  AND table_name IN (
      'dim_customers',
      'dim_products',
      'dim_sellers',
      'dim_date',
      'fact_orders',
      'fact_order_items',
      'fact_payments',
      'fact_reviews'
  )
ORDER BY table_name, ordinal_position;
-- ============================================================
-- STEP 10.2.2 — STAR SCHEMA KEY COLUMN VALIDATION
-- ============================================================

SELECT
    table_name,
    column_name,
    data_type,
    ordinal_position
FROM system.information_schema.columns
WHERE table_schema = 'gold'
  AND table_name IN (
      'dim_customers',
      'dim_products',
      'dim_sellers',
      'dim_date',
      'fact_orders',
      'fact_order_items',
      'fact_payments',
      'fact_reviews'
  )
  AND (
      LOWER(column_name) LIKE '%id%'
      OR LOWER(column_name) LIKE '%key%'
      OR LOWER(column_name) LIKE '%date%'
  )
ORDER BY table_name, ordinal_position;
-- ============================================================
-- STEP 10.2.3 — STAR SCHEMA RELATIONSHIP VALIDATION
-- ============================================================

WITH relationship_checks AS (

    -- 1. fact_orders → dim_customers
    SELECT
        'Orders → Customers' AS relationship,
        COUNT(*) AS total_records,
        SUM(CASE WHEN d.customer_id IS NULL THEN 1 ELSE 0 END) AS orphan_records
    FROM gold.fact_orders f
    LEFT JOIN gold.dim_customers d
        ON f.customer_id = d.customer_id

    UNION ALL

    -- 2. fact_orders → dim_date
    SELECT
        'Orders → Date' AS relationship,
        COUNT(*) AS total_records,
        SUM(CASE WHEN d.date_key IS NULL THEN 1 ELSE 0 END) AS orphan_records
    FROM gold.fact_orders f
    LEFT JOIN gold.dim_date d
        ON f.order_purchase_date_key = d.date_key

    UNION ALL

    -- 3. fact_order_items → fact_orders
    SELECT
        'Order Items → Orders' AS relationship,
        COUNT(*) AS total_records,
        SUM(CASE WHEN o.order_id IS NULL THEN 1 ELSE 0 END) AS orphan_records
    FROM gold.fact_order_items oi
    LEFT JOIN gold.fact_orders o
        ON oi.order_id = o.order_id

    UNION ALL

    -- 4. fact_order_items → dim_products
    SELECT
        'Order Items → Products' AS relationship,
        COUNT(*) AS total_records,
        SUM(CASE WHEN p.product_id IS NULL THEN 1 ELSE 0 END) AS orphan_records
    FROM gold.fact_order_items oi
    LEFT JOIN gold.dim_products p
        ON oi.product_id = p.product_id

    UNION ALL

    -- 5. fact_order_items → dim_sellers
    SELECT
        'Order Items → Sellers' AS relationship,
        COUNT(*) AS total_records,
        SUM(CASE WHEN s.seller_id IS NULL THEN 1 ELSE 0 END) AS orphan_records
    FROM gold.fact_order_items oi
    LEFT JOIN gold.dim_sellers s
        ON oi.seller_id = s.seller_id

    UNION ALL

    -- 6. fact_payments → fact_orders
    SELECT
        'Payments → Orders' AS relationship,
        COUNT(*) AS total_records,
        SUM(CASE WHEN o.order_id IS NULL THEN 1 ELSE 0 END) AS orphan_records
    FROM gold.fact_payments p
    LEFT JOIN gold.fact_orders o
        ON p.order_id = o.order_id

    UNION ALL

    -- 7. fact_reviews → fact_orders
    SELECT
        'Reviews → Orders' AS relationship,
        COUNT(*) AS total_records,
        SUM(CASE WHEN o.order_id IS NULL THEN 1 ELSE 0 END) AS orphan_records
    FROM gold.fact_reviews r
    LEFT JOIN gold.fact_orders o
        ON r.order_id = o.order_id
)

SELECT
    relationship,
    total_records,
    orphan_records,
    CASE
        WHEN orphan_records = 0 THEN 'SUCCESS'
        ELSE 'FAILED'
    END AS status
FROM relationship_checks
ORDER BY relationship;
-- ============================================================
-- STEP 10.2.4 — FIND ORPHAN REVIEW RECORD
-- ============================================================

SELECT
    r.review_id,
    r.order_id,
    r.review_score,
    r.review_comment_title,
    r.review_comment_message
FROM gold.fact_reviews r
LEFT JOIN gold.fact_orders o
    ON r.order_id = o.order_id
WHERE o.order_id IS NULL;
-- ============================================================
-- STEP 10.2.5 — INSPECT SUSPICIOUS REVIEW RECORD
-- ============================================================

SELECT
    *
FROM gold.fact_reviews
WHERE review_id = 'Conforme outros sites';
-- Check the column definition/order
SELECT
    column_name,
    data_type,
    ordinal_position
FROM system.information_schema.columns
WHERE table_schema = 'gold'
  AND table_name = 'fact_reviews'
ORDER BY ordinal_position;
-- ============================================================
-- STEP 10.2.4.A — inspect the actual orphan record
-- ============================================================
SELECT
    review_id,
    order_id,
    review_score,
    review_comment_title,
    review_comment_message,
    review_creation_date,
    review_answer_timestamp,
    _source_file,
    _dataset_name,
    _silver_dataset_name,
    _silver_transformation_timestamp,
    _gold_transformation_timestamp
FROM gold.fact_reviews
WHERE review_id = 'Conforme outros sites';
SELECT
    review_id,
    order_id,
    review_score,
    review_comment_title,
    review_comment_message
FROM gold.fact_reviews
WHERE review_id NOT LIKE 'review_%'
   OR LENGTH(review_id) < 20
ORDER BY review_id
LIMIT 20;
-- ============================================================
-- STEP 10.2.6 — TRACE ORPHAN REVIEW INTO SILVER
-- ============================================================

SELECT
    review_id,
    order_id,
    review_score,
    review_comment_title,
    review_comment_message,
    review_creation_date,
    review_answer_timestamp,
    _source_file,
    _dataset_name,
    _silver_transformation_timestamp
FROM silver.order_reviews
WHERE review_id = 'Conforme outros sites'
   OR order_id = 'poderia ser livre acima de 100';
   -- ============================================================
-- STEP 10.2.7 — CHECK BRONZE ORDER REVIEWS
-- ============================================================

SHOW TABLES IN bronze;
-- ============================================================
-- STEP 10.2.7.1 — FIND THE MALFORMED RECORD IN BRONZE
-- ============================================================

SELECT *
FROM bronze.order_reviews
WHERE review_id = 'Conforme outros sites'
   OR order_id = 'poderia ser livre acima de 100';
-- ============================================================
-- STEP 10.2.8 — RAW SOURCE VALIDATION
-- ============================================================

SELECT
    review_id,
    order_id,
    review_score,
    review_comment_title,
    review_comment_message
FROM bronze.order_reviews
WHERE review_id = 'Conforme outros sites'
   OR order_id = 'poderia ser livre acima de 100';
-- ============================================================
-- STEP 10.2.9 — Check Raw CSV
-- ============================================================
SELECT *
FROM read_files(
  's3://olist-aws-batch-data-platform-adhi-2026/raw/order_reviews/olist_order_reviews_dataset.csv',
  format => 'csv',
  header => true
)
WHERE review_id = 'Conforme outros sites'
   OR order_id = 'poderia ser livre acima de 100';
-- ============================================================
-- STEP 10.2.10 — CONFIRM ORPHAN REVIEW
-- ============================================================

SELECT
    r.review_id,
    r.order_id,
    r.review_score,
    o.order_id AS matched_order_id
FROM gold.fact_reviews r
LEFT JOIN gold.fact_orders o
    ON r.order_id = o.order_id
WHERE o.order_id IS NULL
LIMIT 20;
-- ============================================================
-- STEP 10.2.11 — QUANTIFY ORPHAN REVIEWS
-- ============================================================

SELECT
    COUNT(*) AS total_reviews,
    COUNT(o.order_id) AS matched_reviews,
    COUNT(*) - COUNT(o.order_id) AS orphan_reviews,
    ROUND(
        100.0 * (COUNT(*) - COUNT(o.order_id)) / COUNT(*),
        4
    ) AS orphan_percentage
FROM gold.fact_reviews r
LEFT JOIN gold.fact_orders o
    ON r.order_id = o.order_id;
-- ============================================================
-- STEP 10.3.1 — REVENUE BY PRODUCT CATEGORY
-- ============================================================

SELECT
    p.product_category_name_english AS product_category,
    COUNT(DISTINCT oi.order_id) AS total_orders,
    COUNT(*) AS total_items,
    ROUND(SUM(oi.price), 2) AS product_revenue,
    ROUND(SUM(oi.freight_value), 2) AS freight_revenue,
    ROUND(SUM(oi.price + oi.freight_value), 2) AS total_revenue
FROM gold.fact_order_items oi
JOIN gold.dim_products p
    ON oi.product_id = p.product_id
GROUP BY
    p.product_category_name_english
ORDER BY
    total_revenue DESC
LIMIT 20;
-- ============================================================
-- STEP 10.3.2 — MONTHLY REVENUE TREND
-- ============================================================

SELECT
    d.year,
    d.month,
    d.month_name,
    COUNT(DISTINCT o.order_id) AS total_orders,
    ROUND(SUM(oi.price), 2) AS product_revenue,
    ROUND(SUM(oi.freight_value), 2) AS freight_revenue,
    ROUND(SUM(oi.price + oi.freight_value), 2) AS total_revenue
FROM gold.fact_orders o
JOIN gold.fact_order_items oi
    ON o.order_id = oi.order_id
JOIN gold.dim_date d
    ON o.order_purchase_date_key = d.date_key
GROUP BY
    d.year,
    d.month,
    d.month_name
ORDER BY
    d.year,
    d.month;
-- ============================================================
-- STEP 10.3.3 — SELLER PERFORMANCE
-- ============================================================

SELECT
    s.seller_id,
    s.seller_city,
    s.seller_state,
    COUNT(DISTINCT oi.order_id) AS total_orders,
    COUNT(*) AS total_items,
    ROUND(SUM(oi.price), 2) AS product_revenue,
    ROUND(SUM(oi.freight_value), 2) AS freight_revenue,
    ROUND(SUM(oi.price + oi.freight_value), 2) AS total_revenue
FROM gold.fact_order_items oi
JOIN gold.dim_sellers s
    ON oi.seller_id = s.seller_id
GROUP BY
    s.seller_id,
    s.seller_city,
    s.seller_state
ORDER BY
    total_revenue DESC
LIMIT 20;
-- ============================================================
-- STEP 10.3.4 — PRODUCT CATEGORY PERFORMANCE
-- ============================================================

SELECT
    p.product_category_name_english AS product_category,
    COUNT(DISTINCT oi.order_id) AS total_orders,
    COUNT(*) AS total_items,
    ROUND(SUM(oi.price), 2) AS product_revenue,
    ROUND(SUM(oi.freight_value), 2) AS freight_revenue,
    ROUND(SUM(oi.price + oi.freight_value), 2) AS total_revenue
FROM gold.fact_order_items oi
JOIN gold.dim_products p
    ON oi.product_id = p.product_id
GROUP BY
    p.product_category_name_english
ORDER BY
    total_revenue DESC
LIMIT 20;
-- ============================================================
-- STEP 10.3.5 — CUSTOMER PERFORMANCE BY STATE
-- ============================================================

SELECT
    c.customer_state,
    COUNT(DISTINCT o.order_id) AS total_orders,
    COUNT(DISTINCT c.customer_unique_id) AS unique_customers,
    ROUND(SUM(oi.price), 2) AS product_revenue,
    ROUND(SUM(oi.freight_value), 2) AS freight_revenue,
    ROUND(SUM(oi.price + oi.freight_value), 2) AS total_revenue,
    ROUND(
        SUM(oi.price + oi.freight_value)
        / COUNT(DISTINCT o.order_id),
        2
    ) AS avg_order_value
FROM gold.fact_orders o
JOIN gold.dim_customers c
    ON o.customer_id = c.customer_id
JOIN gold.fact_order_items oi
    ON o.order_id = oi.order_id
GROUP BY
    c.customer_state
ORDER BY
    total_revenue DESC;
-- ============================================================
-- STEP 10.3.6 — PRODUCT PERFORMANCE BY CUSTOMER STATE
-- ============================================================

SELECT
    c.customer_state,
    p.product_category_name_english AS product_category,
    COUNT(DISTINCT o.order_id) AS total_orders,
    COUNT(*) AS total_items,
    ROUND(SUM(oi.price), 2) AS product_revenue,
    ROUND(SUM(oi.freight_value), 2) AS freight_revenue,
    ROUND(SUM(oi.price + oi.freight_value), 2) AS total_revenue
FROM gold.fact_orders o
JOIN gold.dim_customers c
    ON o.customer_id = c.customer_id
JOIN gold.fact_order_items oi
    ON o.order_id = oi.order_id
JOIN gold.dim_products p
    ON oi.product_id = p.product_id
GROUP BY
    c.customer_state,
    p.product_category_name_english
ORDER BY
    total_revenue DESC
LIMIT 20;
-- ============================================================
-- STEP 10.3.7 — SELLER PERFORMANCE BY CUSTOMER STATE
-- ============================================================

SELECT
    c.customer_state,
    s.seller_state,
    COUNT(DISTINCT o.order_id) AS total_orders,
    COUNT(*) AS total_items,
    COUNT(DISTINCT o.customer_id) AS unique_customers,
    ROUND(SUM(oi.price), 2) AS product_revenue,
    ROUND(SUM(oi.freight_value), 2) AS freight_revenue,
    ROUND(SUM(oi.price + oi.freight_value), 2) AS total_revenue
FROM gold.fact_orders o
JOIN gold.dim_customers c
    ON o.customer_id = c.customer_id
JOIN gold.fact_order_items oi
    ON o.order_id = oi.order_id
JOIN gold.dim_sellers s
    ON oi.seller_id = s.seller_id
GROUP BY
    c.customer_state,
    s.seller_state
ORDER BY
    total_revenue DESC
LIMIT 20;
-- ============================================================
-- STEP 10.3.8 — ORDER STATUS ANALYSIS
-- ============================================================

SELECT
    o.order_status,
    COUNT(DISTINCT o.order_id) AS total_orders,
    COUNT(DISTINCT o.customer_id) AS unique_customers,
    ROUND(SUM(oi.price), 2) AS product_revenue,
    ROUND(SUM(oi.freight_value), 2) AS freight_revenue,
    ROUND(SUM(oi.price + oi.freight_value), 2) AS total_revenue
FROM gold.fact_orders o
JOIN gold.fact_order_items oi
    ON o.order_id = oi.order_id
GROUP BY
    o.order_status
ORDER BY
    total_orders DESC;
-- ============================================================
-- STEP 10.3.9 — DELIVERY PERFORMANCE ANALYSIS
-- ============================================================

SELECT
    YEAR(o.order_purchase_timestamp) AS purchase_year,
    COUNT(DISTINCT o.order_id) AS total_orders,

    COUNT(
        CASE
            WHEN o.order_delivered_customer_date IS NOT NULL
            THEN o.order_id
        END
    ) AS delivered_orders,

    ROUND(
        AVG(
            CASE
                WHEN o.order_delivered_customer_date IS NOT NULL
                THEN DATEDIFF(
                    o.order_delivered_customer_date,
                    o.order_purchase_timestamp
                )
            END
        ),
        2
    ) AS avg_delivery_days,

    ROUND(
        AVG(
            CASE
                WHEN o.order_delivered_customer_date IS NOT NULL
                     AND o.order_estimated_delivery_date IS NOT NULL
                THEN DATEDIFF(
                    o.order_delivered_customer_date,
                    o.order_estimated_delivery_date
                )
            END
        ),
        2
    ) AS avg_delivery_variance_days

FROM gold.fact_orders o
GROUP BY
    YEAR(o.order_purchase_timestamp)
ORDER BY
    purchase_year;
-- ============================================================
-- STEP 10.3.10 — STAR SCHEMA JOIN INTEGRITY CHECK (CORRECTED)
-- ============================================================

SELECT
    COUNT(*) AS joined_rows,

    COUNT(DISTINCT o.order_id) AS unique_orders,

    COUNT(DISTINCT o.customer_id) AS unique_customers,

    COUNT(
        DISTINCT STRUCT(
            oi.order_id,
            oi.order_item_id
        )
    ) AS unique_order_items,

    COUNT(DISTINCT oi.product_id) AS unique_products,

    COUNT(DISTINCT oi.seller_id) AS unique_sellers

FROM gold.fact_orders o

JOIN gold.fact_order_items oi
    ON o.order_id = oi.order_id

JOIN gold.dim_customers c
    ON o.customer_id = c.customer_id

JOIN gold.dim_products p
    ON oi.product_id = p.product_id

JOIN gold.dim_sellers s
    ON oi.seller_id = s.seller_id;
-- ============================================================
-- STEP 10.3.11 — IDENTIFY ORDERS LOST THROUGH DIMENSION JOINS
-- ============================================================

SELECT
    COUNT(DISTINCT o.order_id) AS total_fact_orders,

    COUNT(DISTINCT CASE
        WHEN c.customer_id IS NULL
        THEN o.order_id
    END) AS missing_customer_dimension,

    COUNT(DISTINCT CASE
        WHEN oi.order_id IS NULL
        THEN o.order_id
    END) AS missing_order_items

FROM gold.fact_orders o

LEFT JOIN gold.dim_customers c
    ON o.customer_id = c.customer_id

LEFT JOIN gold.fact_order_items oi
    ON o.order_id = oi.order_id;
    -- ============================================================
-- STEP 10.3.12 — INVESTIGATE ORDERS WITHOUT ORDER ITEMS
-- ============================================================

SELECT
    o.order_status,
    COUNT(*) AS orders_without_items
FROM gold.fact_orders o
LEFT JOIN gold.fact_order_items oi
    ON o.order_id = oi.order_id
WHERE oi.order_id IS NULL
GROUP BY o.order_status
ORDER BY orders_without_items DESC;
-- ============================================================
-- STEP 10.3.13 — ORPHAN ORDER-ITEM VALIDATION
-- ============================================================

SELECT
    COUNT(*) AS total_order_items,

    COUNT(DISTINCT oi.order_id) AS orders_referenced_by_items,

    COUNT(
        DISTINCT CASE
            WHEN o.order_id IS NULL
            THEN oi.order_id
        END
    ) AS orphan_order_ids

FROM gold.fact_order_items oi

LEFT JOIN gold.fact_orders o
    ON oi.order_id = o.order_id;
-- ============================================================
-- STEP 10.3.14 — INVESTIGATE NON-CANCELED ORDERS WITHOUT ITEMS
-- ============================================================

SELECT
    o.order_id,
    o.customer_id,
    o.order_status,
    o.order_purchase_timestamp,
    o.order_approved_at,
    o.order_delivered_carrier_date,
    o.order_delivered_customer_date,
    o.order_estimated_delivery_date
FROM gold.fact_orders o
LEFT JOIN gold.fact_order_items oi
    ON o.order_id = oi.order_id
WHERE oi.order_id IS NULL
  AND o.order_status NOT IN ('unavailable', 'canceled')
ORDER BY o.order_status, o.order_purchase_timestamp;
-- ============================================================
-- STEP 10.3.15 — PRODUCT CATEGORY PERFORMANCE
-- ============================================================

SELECT
    p.product_category_name_english AS product_category,

    COUNT(DISTINCT o.order_id) AS total_orders,

    COUNT(*) AS total_items,

    ROUND(SUM(oi.price), 2) AS product_revenue,

    ROUND(SUM(oi.freight_value), 2) AS freight_revenue,

    ROUND(
        SUM(oi.price + oi.freight_value),
        2
    ) AS total_revenue,

    ROUND(
        SUM(oi.price + oi.freight_value)
        / COUNT(DISTINCT o.order_id),
        2
    ) AS avg_order_value

FROM gold.fact_orders o

JOIN gold.fact_order_items oi
    ON o.order_id = oi.order_id

JOIN gold.dim_products p
    ON oi.product_id = p.product_id

GROUP BY
    p.product_category_name_english

ORDER BY
    total_revenue DESC;
-- ============================================================
-- STEP 10.3.15A — INVESTIGATE NULL PRODUCT CATEGORIES
-- ============================================================

SELECT
    COUNT(*) AS null_category_items,
    COUNT(DISTINCT oi.order_id) AS null_category_orders,
    COUNT(DISTINCT oi.product_id) AS affected_products
FROM gold.fact_order_items oi
LEFT JOIN gold.dim_products p
    ON oi.product_id = p.product_id
WHERE p.product_category_name_english IS NULL;
-- Find whether the problem is missing products
SELECT
    COUNT(DISTINCT oi.product_id) AS missing_product_dimension
FROM gold.fact_order_items oi
LEFT JOIN gold.dim_products p
    ON oi.product_id = p.product_id
WHERE p.product_id IS NULL;
-- ============================================================
-- STEP 10.3.15B — INSPECT PRODUCTS WITH NULL CATEGORY
-- ============================================================

SELECT
    p.product_id,
    p.product_category_name,
    p.product_category_name_english
FROM gold.dim_products p
WHERE p.product_category_name_english IS NULL
ORDER BY p.product_category_name;
-- ============================================================
-- STEP 10.3.15C — NULL CATEGORY ROOT-CAUSE SUMMARY
-- ============================================================

SELECT
    COUNT(*) AS affected_products,

    COUNT(CASE
        WHEN product_category_name IS NULL
        THEN 1
    END) AS null_original_category,

    COUNT(CASE
        WHEN product_category_name IS NOT NULL
         AND product_category_name_english IS NULL
        THEN 1
    END) AS missing_english_translation

FROM gold.dim_products
WHERE product_category_name_english IS NULL;
-- ============================================================
-- STEP 10.3.15D — Check Gold product category distribution
-- ============================================================
SELECT
    product_category_name,
    product_category_name_english,
    COUNT(*) AS product_count
FROM gold.dim_products
WHERE product_category_name IS NULL
   OR product_category_name_english IS NULL
GROUP BY
    product_category_name,
    product_category_name_english
ORDER BY product_count DESC;
-- ============================================================
-- trace the 610 products upstream / check whether the 610 NULL categories already exist in Silver.
-- ============================================================
SHOW TABLES IN silver;
SHOW TABLES IN bronze;
DESCRIBE gold.dim_products;
DESCRIBE silver.products;
SELECT
    COUNT(*) AS total_products,
    COUNT(product_category_name) AS products_with_category,
    COUNT(*) - COUNT(product_category_name) AS products_without_category
FROM silver.products;
SELECT
    product_id,
    product_category_name
FROM silver.products
WHERE product_category_name IS NULL
LIMIT 20;
SELECT
    COUNT(*) AS total_products,
    COUNT(product_category_name) AS products_with_category,
    COUNT(*) - COUNT(product_category_name) AS products_without_category
FROM bronze.products;
SELECT
    COUNT(DISTINCT s.product_id) AS silver_null_products,
    COUNT(DISTINCT b.product_id) AS also_null_in_bronze
FROM silver.products s
JOIN bronze.products b
    ON s.product_id = b.product_id
WHERE s.product_category_name IS NULL
  AND b.product_category_name IS NULL;
-- ============================================================
-- Next step — investigate the 13
-- ============================================================
SELECT
    p.product_category_name,
    t.product_category_name_english,
    COUNT(*) AS product_count
FROM silver.products p
LEFT JOIN silver.product_category_translation t
    ON p.product_category_name = t.product_category_name
WHERE p.product_category_name IS NOT NULL
  AND t.product_category_name_english IS NULL
GROUP BY
    p.product_category_name,
    t.product_category_name_english
ORDER BY product_count DESC;
SELECT
    p.product_category_name,
    COUNT(*) AS product_count
FROM silver.products p
LEFT JOIN bronze.product_category_translation t
    ON p.product_category_name = t.product_category_name
WHERE p.product_category_name IS NOT NULL
  AND t.product_category_name IS NULL
GROUP BY p.product_category_name
ORDER BY product_count DESC;
-- ============================================================
-- Final verification
-- ============================================================
SELECT
    p.product_category_name AS silver_category,
    t.product_category_name AS bronze_category,
    t.product_category_name_english,
    COUNT(*) AS product_count
FROM silver.products p
LEFT JOIN bronze.product_category_translation t
    ON LOWER(TRIM(p.product_category_name))
       = LOWER(TRIM(t.product_category_name))
WHERE p.product_category_name IS NOT NULL
  AND p.product_category_name IN (
      'portateis_cozinha_e_preparadores_de_alimentos',
      'pc_gamer'
  )
GROUP BY
    p.product_category_name,
    t.product_category_name,
    t.product_category_name_english
ORDER BY product_count DESC;
-- ============================================================
-- Final verification
-- ============================================================
SELECT
    COUNT(DISTINCT p.product_id) AS total_products,

    COUNT(DISTINCT CASE
        WHEN p.product_category_name IS NOT NULL
        THEN p.product_id
    END) AS categorized_products,

    COUNT(DISTINCT CASE
        WHEN p.product_category_name IS NULL
        THEN p.product_id
    END) AS missing_original_category,

    COUNT(DISTINCT CASE
        WHEN p.product_category_name IS NOT NULL
         AND t.product_category_name IS NULL
        THEN p.product_id
    END) AS missing_translation_mapping

FROM silver.products p

LEFT JOIN bronze.product_category_translation t
    ON LOWER(TRIM(p.product_category_name))
     = LOWER(TRIM(t.product_category_name));

-- STEP 10.3.16 - Identify categories without English translation

SELECT
    p.product_category_name,
    COUNT(*) AS product_count
FROM silver.products p
LEFT JOIN bronze.product_category_translation t
    ON LOWER(TRIM(p.product_category_name))
     = LOWER(TRIM(t.product_category_name))
WHERE p.product_category_name IS NOT NULL
  AND t.product_category_name IS NULL
GROUP BY p.product_category_name
ORDER BY product_count DESC;

-- STEP 10.3.17 - Inspect translation mappings

SELECT
    product_category_name,
    product_category_name_english
FROM bronze.product_category_translation
ORDER BY product_category_name;

-- STEP 10.3.18 - Test final category handling

SELECT
    COUNT(*) AS total_products,

    COUNT(
        CASE
            WHEN p.product_category_name IS NULL
            THEN 1
        END
    ) AS uncategorized_products,

    COUNT(
        CASE
            WHEN p.product_category_name IS NOT NULL
             AND t.product_category_name IS NULL
            THEN 1
        END
    ) AS untranslated_products,

    COUNT(
        CASE
            WHEN p.product_category_name IS NOT NULL
             AND t.product_category_name IS NOT NULL
            THEN 1
        END
    ) AS translated_products,

    COUNT(
        CASE
            WHEN p.product_category_name IS NULL
                THEN 1
        END
    ) AS null_original_category

FROM silver.products p

LEFT JOIN bronze.product_category_translation t
    ON LOWER(TRIM(p.product_category_name))
     = LOWER(TRIM(t.product_category_name));

-- STEP 10.3.19 - Preview final category values

SELECT
    p.product_id,
    p.product_category_name AS original_category,

    CASE
        WHEN p.product_category_name IS NULL
            THEN 'Uncategorized'

        WHEN t.product_category_name IS NULL
            THEN 'Untranslated'

        ELSE t.product_category_name_english
    END AS final_category

FROM silver.products p

LEFT JOIN bronze.product_category_translation t
    ON LOWER(TRIM(p.product_category_name))
     = LOWER(TRIM(t.product_category_name))

WHERE p.product_category_name IS NULL
   OR t.product_category_name IS NULL

LIMIT 50;

-- STEP 10.3.20 - Inspect untranslated categories

SELECT
    p.product_id,
    p.product_category_name AS original_category,
    t.product_category_name_english AS translated_category

FROM silver.products p

LEFT JOIN bronze.product_category_translation t
    ON LOWER(TRIM(p.product_category_name))
     = LOWER(TRIM(t.product_category_name))

WHERE p.product_category_name IS NOT NULL
  AND t.product_category_name IS NULL

ORDER BY p.product_category_name;
DESCRIBE gold.dim_products;
SELECT *
FROM gold.dim_products
LIMIT 5;
SELECT COUNT(*) AS gold_product_count
FROM gold.dim_products;

-- validate the current Gold category quality
SELECT
    COUNT(*) AS total_products,

    COUNT(
        CASE
            WHEN product_category_name IS NULL
            THEN 1
        END
    ) AS missing_original_category,

    COUNT(
        CASE
            WHEN product_category_name IS NOT NULL
             AND product_category_name_english IS NULL
            THEN 1
        END
    ) AS missing_translation,

    COUNT(
        CASE
            WHEN product_category_name_english = 'Uncategorized'
            THEN 1
        END
    ) AS uncategorized,

    COUNT(
        CASE
            WHEN product_category_name_english = 'Untranslated'
            THEN 1
        END
    ) AS untranslated

FROM gold.dim_products;

SELECT
    product_id,
    product_category_name,
    product_category_name_english
FROM gold.dim_products
WHERE product_category_name IS NULL
   OR product_category_name_english IS NULL
   OR product_category_name_english IN ('Uncategorized', 'Untranslated')
LIMIT 50;

-- Preview the final transformation
SELECT
    p.product_id,
    p.product_category_name AS original_category,

    CASE
        WHEN p.product_category_name IS NULL
            THEN 'Uncategorized'

        WHEN t.product_category_name_english IS NULL
            THEN 'Untranslated'

        ELSE t.product_category_name_english
    END AS final_category

FROM silver.products p

LEFT JOIN bronze.product_category_translation t
    ON LOWER(TRIM(p.product_category_name))
     = LOWER(TRIM(t.product_category_name))

WHERE p.product_category_name IS NULL
   OR t.product_category_name_english IS NULL

ORDER BY final_category, p.product_id
LIMIT 50;

--Check that the translation table doesn't create duplicates
SELECT
    LOWER(TRIM(product_category_name)) AS category_key,
    COUNT(*) AS mapping_count
FROM bronze.product_category_translation
GROUP BY LOWER(TRIM(product_category_name))
HAVING COUNT(*) > 1;

-- Rebuild gold.dim_products
CREATE OR REPLACE TABLE gold.dim_products AS

SELECT
    p.product_id,
    p.product_category_name,

    CASE
        WHEN p.product_category_name IS NULL
            THEN 'Uncategorized'

        WHEN t.product_category_name_english IS NULL
            THEN 'Untranslated'

        ELSE t.product_category_name_english
    END AS product_category_name_english,

    p.product_name_lenght,
    p.product_description_lenght,
    p.product_photos_qty,
    p.product_weight_g,
    p.product_length_cm,
    p.product_height_cm,
    p.product_width_cm,

    current_timestamp() AS _gold_transformation_timestamp

FROM silver.products p

LEFT JOIN bronze.product_category_translation t
    ON LOWER(TRIM(p.product_category_name))
     = LOWER(TRIM(t.product_category_name));

--Immediately validate Gold
SELECT
    COUNT(*) AS total_products,

    COUNT(
        CASE
            WHEN product_category_name IS NULL
            THEN 1
        END
    ) AS missing_original_category,

    COUNT(
        CASE
            WHEN product_category_name_english IS NULL
            THEN 1
        END
    ) AS missing_english_category,

    COUNT(
        CASE
            WHEN product_category_name_english = 'Uncategorized'
            THEN 1
        END
    ) AS uncategorized,

    COUNT(
        CASE
            WHEN product_category_name_english = 'Untranslated'
            THEN 1
        END
    ) AS untranslated

FROM gold.dim_products;

--5. Validate category distribution
SELECT
    product_category_name,
    product_category_name_english,
    COUNT(*) AS product_count
FROM gold.dim_products
GROUP BY
    product_category_name,
    product_category_name_english
ORDER BY product_count DESC;

-- ============================================================
-- STEP 10.4.1 — DIMENSION UNIQUENESS VALIDATION
-- ============================================================

-- dim_customers
SELECT
    'dim_customers' AS table_name,
    'customer_id' AS key_column,
    COUNT(*) AS duplicate_groups
FROM (
    SELECT customer_id
    FROM gold.dim_customers
    GROUP BY customer_id
    HAVING COUNT(*) > 1
);

-- dim_products
SELECT
    'dim_products' AS table_name,
    'product_id' AS key_column,
    COUNT(*) AS duplicate_groups
FROM (
    SELECT product_id
    FROM gold.dim_products
    GROUP BY product_id
    HAVING COUNT(*) > 1
);

-- dim_sellers
SELECT
    'dim_sellers' AS table_name,
    'seller_id' AS key_column,
    COUNT(*) AS duplicate_groups
FROM (
    SELECT seller_id
    FROM gold.dim_sellers
    GROUP BY seller_id
    HAVING COUNT(*) > 1
);

-- dim_date
SELECT
    'dim_date' AS table_name,
    'date_key' AS key_column,
    COUNT(*) AS duplicate_groups
FROM (
    SELECT date_key
    FROM gold.dim_date
    GROUP BY date_key
    HAVING COUNT(*) > 1
);

-- ============================================================
-- STEP 10.4.2 — FACT GRAIN UNIQUENESS VALIDATION
-- ============================================================

-- fact_orders
-- Grain: one row per order
SELECT
    'fact_orders' AS table_name,
    'order_id' AS grain,
    COUNT(*) AS duplicate_groups
FROM (
    SELECT order_id
    FROM gold.fact_orders
    GROUP BY order_id
    HAVING COUNT(*) > 1
);

-- fact_order_items
-- Grain: one row per order item
SELECT
    'fact_order_items' AS table_name,
    'order_id + order_item_id' AS grain,
    COUNT(*) AS duplicate_groups
FROM (
    SELECT
        order_id,
        order_item_id
    FROM gold.fact_order_items
    GROUP BY order_id, order_item_id
    HAVING COUNT(*) > 1
);

-- fact_payments
-- Grain: one row per payment sequence within an order
SELECT
    'fact_payments' AS table_name,
    'order_id + payment_sequential' AS grain,
    COUNT(*) AS duplicate_groups
FROM (
    SELECT
        order_id,
        payment_sequential
    FROM gold.fact_payments
    GROUP BY order_id, payment_sequential
    HAVING COUNT(*) > 1
);

-- fact_reviews
-- Grain: one row per review
SELECT
    'fact_reviews' AS table_name,
    'review_id' AS grain,
    COUNT(*) AS duplicate_groups
FROM (
    SELECT review_id
    FROM gold.fact_reviews
    GROUP BY review_id
    HAVING COUNT(*) > 1
);

-- ============================================================
-- STEP 10.4.3 — FINAL STAR SCHEMA VALIDATION
-- ============================================================

SELECT
    'DIMENSIONS' AS object_type,
    'dim_customers' AS table_name,
    COUNT(*) AS row_count
FROM gold.dim_customers

UNION ALL

SELECT
    'DIMENSIONS',
    'dim_products',
    COUNT(*)
FROM gold.dim_products

UNION ALL

SELECT
    'DIMENSIONS',
    'dim_sellers',
    COUNT(*)
FROM gold.dim_sellers

UNION ALL

SELECT
    'DIMENSIONS',
    'dim_date',
    COUNT(*)
FROM gold.dim_date

UNION ALL

SELECT
    'FACTS',
    'fact_orders',
    COUNT(*)
FROM gold.fact_orders

UNION ALL

SELECT
    'FACTS',
    'fact_order_items',
    COUNT(*)
FROM gold.fact_order_items

UNION ALL

SELECT
    'FACTS',
    'fact_payments',
    COUNT(*)
FROM gold.fact_payments

UNION ALL

SELECT
    'FACTS',
    'fact_reviews',
    COUNT(*)
FROM gold.fact_reviews

ORDER BY object_type, table_name;

-- STEP 10 — INVESTIGATE fact_reviews DUPLICATES

SELECT
    review_id,
    COUNT(*) AS row_count
FROM gold.fact_reviews
GROUP BY review_id
HAVING COUNT(*) > 1
ORDER BY row_count DESC
LIMIT 20;

-- Compare total rows vs distinct review IDs

SELECT
    COUNT(*) AS total_rows,
    COUNT(DISTINCT review_id) AS distinct_review_ids,
    COUNT(*) - COUNT(DISTINCT review_id) AS duplicate_rows
FROM gold.fact_reviews;

-- STEP 10 — Check duplicate review IDs in Silver

SELECT
    review_id,
    COUNT(*) AS row_count
FROM silver.order_reviews
GROUP BY review_id
HAVING COUNT(*) > 1
ORDER BY row_count DESC
LIMIT 20;
-- STEP 10 — Silver review uniqueness summary

SELECT
    COUNT(*) AS total_rows,
    COUNT(DISTINCT review_id) AS distinct_review_ids,
    COUNT(*) - COUNT(DISTINCT review_id) AS duplicate_rows
FROM silver.order_reviews;

SELECT *
FROM silver.order_reviews
WHERE review_id = '38821b5c496b678cf91acc34892805ad';

-- STEP 10: Validate candidate fact grain
-- Candidate grain: one row per order_id + review_id

SELECT
    order_id,
    review_id,
    COUNT(*) AS row_count
FROM silver.order_reviews
GROUP BY
    order_id,
    review_id
HAVING COUNT(*) > 1
ORDER BY row_count DESC
LIMIT 20;

SELECT
    COUNT(*) AS total_rows,
    COUNT(DISTINCT CONCAT(order_id, '|', review_id)) AS distinct_order_review_pairs,
    COUNT(*) - COUNT(DISTINCT CONCAT(order_id, '|', review_id)) AS duplicate_rows
FROM silver.order_reviews;

-- STEP 10: Final Gold fact_reviews grain validation

SELECT
    order_id,
    review_id,
    COUNT(*) AS row_count
FROM gold.fact_reviews
GROUP BY
    order_id,
    review_id
HAVING COUNT(*) > 1
ORDER BY row_count DESC
LIMIT 20;

-- STEP 10: Final fact_reviews grain summary

SELECT
    COUNT(*) AS total_rows,
    COUNT(DISTINCT CONCAT(order_id, '|', review_id)) AS distinct_order_review_pairs,
    COUNT(*) -
        COUNT(DISTINCT CONCAT(order_id, '|', review_id)) AS duplicate_rows
FROM gold.fact_reviews;

-- Grain: one row per order_id + review_id