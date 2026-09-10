-- 1. Total orders
SELECT COUNT(*) AS total_orders
FROM orders;

-- 2. Total geolocation rows
SELECT COUNT(*) AS total_rows
FROM geolocation;

-- 3. Orders by status
SELECT
    order_status,
    COUNT(*) AS order_count
FROM olist_processed_db.orders
GROUP BY order_status
ORDER BY order_count DESC;

-- 4. Monthly order trend
SELECT
    DATE_FORMAT(order_purchase_timestamp, '%Y-%m') AS order_month,
    COUNT(*) AS order_count
FROM olist_processed_db.orders
GROUP BY DATE_FORMAT(order_purchase_timestamp, '%Y-%m')
ORDER BY order_month;

-- 5. Payment type analysis
SELECT
    payment_type,
    COUNT(*) AS total_payments,
    ROUND(SUM(CAST(payment_value AS DOUBLE)), 2) AS total_payment_value
FROM order_payments
GROUP BY payment_type
ORDER BY total_payment_value DESC;

-- 6. Average order value
SELECT
    ROUND(
        SUM(CAST(payment_value AS DOUBLE))
        / COUNT(DISTINCT order_id),
        2
    ) AS average_order_value
FROM order_payments;

-- 7. Customers by state
SELECT
    customer_state,
    COUNT(DISTINCT customer_id) AS total_customers
FROM customers
GROUP BY customer_state
ORDER BY total_customers DESC;

-- 8. Top sellers by revenue
SELECT
    s.seller_id,
    ROUND(SUM(CAST(oi.price AS DOUBLE)), 2) AS total_revenue,
    COUNT(DISTINCT oi.order_id) AS total_orders
FROM sellers s
JOIN order_items oi
    ON s.seller_id = oi.seller_id
GROUP BY s.seller_id
ORDER BY total_revenue DESC
LIMIT 10;

-- 9. Monthly delivered revenue
SELECT
    DATE_TRUNC(
        'month',
        CAST(o.order_purchase_timestamp AS TIMESTAMP)
    ) AS month,
    ROUND(SUM(CAST(oi.price AS DOUBLE)), 2) AS total_revenue
FROM orders o
JOIN order_items oi
    ON o.order_id = oi.order_id
WHERE o.order_status = 'delivered'
GROUP BY 1
ORDER BY 1;

-- 10. Top product categories by revenue
SELECT
    p.product_category_name,
    ROUND(SUM(CAST(oi.price AS DOUBLE)), 2) AS total_revenue
FROM products p
JOIN order_items oi
    ON p.product_id = oi.product_id
GROUP BY p.product_category_name
ORDER BY total_revenue DESC
LIMIT 10;

-- 11. Top product categories by units sold
SELECT
    p.product_category_name,
    COUNT(oi.order_id) AS total_items_sold
FROM products p
JOIN order_items oi
    ON p.product_id = oi.product_id
GROUP BY p.product_category_name
ORDER BY total_items_sold DESC
LIMIT 10;

-- 12. Orders by customer state
SELECT
    c.customer_state,
    COUNT(DISTINCT o.order_id) AS total_orders
FROM customers c
JOIN orders o
    ON c.customer_id = o.customer_id
GROUP BY c.customer_state
ORDER BY total_orders DESC
LIMIT 10;

-- 13. Total customers
SELECT COUNT(*) AS total_customers
FROM customers;

-- 14. Total products
SELECT COUNT(*) AS total_products
FROM products;