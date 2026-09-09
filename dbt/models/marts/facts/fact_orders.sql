SELECT
    o.order_id,
    o.customer_id,

    o.order_status,

    o.order_purchase_timestamp,
    o.order_approved_at,
    o.order_delivered_carrier_date,
    o.order_delivered_customer_date,
    o.order_estimated_delivery_date,

    COALESCE(oi.item_count, 0) AS item_count,
    COALESCE(oi.total_product_value, 0) AS total_product_value,
    COALESCE(oi.total_freight_value, 0) AS total_freight_value,
    COALESCE(pm.total_payment_value, 0) AS total_payment_value

FROM {{ ref('int_orders_enriched') }} AS o

LEFT JOIN (
    SELECT
        order_id,
        COUNT(*) AS item_count,
        SUM(price) AS total_product_value,
        SUM(freight_value) AS total_freight_value
    FROM {{ ref('stg_order_items') }}
    GROUP BY order_id
) AS oi
    ON o.order_id = oi.order_id

LEFT JOIN (
    SELECT
        order_id,
        SUM(payment_value) AS total_payment_value
    FROM {{ ref('stg_order_payments') }}
    GROUP BY order_id
) AS pm
    ON o.order_id = pm.order_id