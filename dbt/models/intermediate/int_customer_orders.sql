WITH order_item_metrics AS (

    SELECT
        order_id,
        COUNT(*) AS item_count,
        SUM(price) AS total_product_value,
        SUM(freight_value) AS total_freight_value

    FROM {{ ref('stg_order_items') }}

    GROUP BY order_id

),

payment_metrics AS (

    SELECT
        order_id,
        SUM(payment_value) AS total_payment_value

    FROM {{ ref('stg_order_payments') }}

    GROUP BY order_id

),

customer_orders AS (

    SELECT
        o.customer_id,
        c.customer_unique_id,

        COUNT(DISTINCT o.order_id) AS order_count,

        COALESCE(SUM(oi.item_count), 0) AS item_count,

        COALESCE(SUM(oi.total_product_value), 0) AS total_product_value,

        COALESCE(SUM(oi.total_freight_value), 0) AS total_freight_value,

        COALESCE(SUM(pm.total_payment_value), 0) AS total_payment_value,

        MIN(o.order_purchase_timestamp) AS first_order_timestamp,

        MAX(o.order_purchase_timestamp) AS last_order_timestamp

    FROM {{ ref('stg_orders') }} AS o

    LEFT JOIN {{ ref('stg_customers') }} AS c
        ON o.customer_id = c.customer_id

    LEFT JOIN order_item_metrics AS oi
        ON o.order_id = oi.order_id

    LEFT JOIN payment_metrics AS pm
        ON o.order_id = pm.order_id

    GROUP BY
        o.customer_id,
        c.customer_unique_id
)

SELECT *
FROM customer_orders