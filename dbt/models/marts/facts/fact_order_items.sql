SELECT
    order_id,
    order_item_id,
    product_id,
    seller_id,

    product_category_name,
    product_category_name_english,

    shipping_limit_date,
    price,
    freight_value

FROM {{ ref('int_order_items_enriched') }}