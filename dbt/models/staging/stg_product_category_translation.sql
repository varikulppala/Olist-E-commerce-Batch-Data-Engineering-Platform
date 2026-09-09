SELECT
    product_category_name,
    product_category_name_english
FROM {{ source('silver', 'product_category_translation') }}