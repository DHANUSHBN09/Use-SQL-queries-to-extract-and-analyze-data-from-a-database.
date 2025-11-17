-- 1. Simple SELECT with WHERE and ORDER BY: Recent completed orders
SELECT o.order_id, o.order_date, c.first_name || ' ' || c.last_name AS customer, o.status
FROM orders o
JOIN customers c ON o.customer_id = c.customer_id
WHERE o.status = 'Completed'
ORDER BY o.order_date DESC
LIMIT 10;

-- 2. GROUP BY with aggregate functions: Sales by product (total revenue)
SELECT p.product_name, p.category, SUM(oi.quantity * oi.unit_price) AS total_revenue, SUM(oi.quantity) AS total_quantity_sold
FROM order_items oi
JOIN products p ON oi.product_id = p.product_id
GROUP BY p.product_id, p.product_name, p.category
ORDER BY total_revenue DESC;

-- 3. JOINs (INNER, LEFT): Customer orders with possible missing items (LEFT JOIN example)
SELECT o.order_id, o.order_date, c.email, oi.item_id, oi.quantity, oi.unit_price
FROM orders o
LEFT JOIN order_items oi ON o.order_id = oi.order_id
LEFT JOIN customers c ON o.customer_id = c.customer_id
ORDER BY o.order_date DESC
LIMIT 15;

-- 4. Subquery: Customers with average order value greater than overall average
SELECT customer_id, customer_name, avg_order_value FROM (
    SELECT c.customer_id, c.first_name || ' ' || c.last_name AS customer_name,
           AVG(sub.total_order_value) AS avg_order_value
    FROM customers c
    JOIN (
        SELECT o.order_id, o.customer_id, SUM(oi.quantity * oi.unit_price) AS total_order_value
        FROM orders o JOIN order_items oi ON o.order_id = oi.order_id
        GROUP BY o.order_id
    ) sub ON c.customer_id = sub.customer_id
    GROUP BY c.customer_id
) t
WHERE avg_order_value > (
    SELECT AVG(total_order_value) FROM (
        SELECT o.order_id, SUM(oi.quantity * oi.unit_price) AS total_order_value
        FROM orders o JOIN order_items oi ON o.order_id = oi.order_id
        GROUP BY o.order_id
    )
);

-- 5. HAVING vs WHERE: Products with more than X quantity sold
SELECT p.category, p.product_name, SUM(oi.quantity) AS qty_sold
FROM order_items oi JOIN products p ON oi.product_id = p.product_id
GROUP BY p.product_id
HAVING SUM(oi.quantity) > 5
ORDER BY qty_sold DESC;

-- 6. Create a view for monthly metrics (example)
CREATE VIEW IF NOT EXISTS monthly_metrics AS
SELECT strftime('%Y-%m', o.order_date) AS year_month,
       SUM(oi.quantity * oi.unit_price) AS total_sales,
       SUM(oi.quantity * oi.unit_price) - 0.2 * SUM(oi.quantity * oi.unit_price) AS est_profit -- example
FROM orders o JOIN order_items oi ON o.order_id = oi.order_id
GROUP BY year_month;

-- 7. Index creation to optimize queries (example)
CREATE INDEX IF NOT EXISTS idx_orders_order_date ON orders(order_date);

-- 8. Window function example (SQLite supports limited window funcs) - rank products by revenue
SELECT product_name, category, total_revenue,
       RANK() OVER (ORDER BY total_revenue DESC) AS revenue_rank
FROM (
    SELECT p.product_name, p.category, SUM(oi.quantity * oi.unit_price) AS total_revenue
    FROM order_items oi JOIN products p ON oi.product_id = p.product_id
    GROUP BY p.product_id
);

-- 9. Example of a correlated subquery: check if an order has any expensive item (>500)
SELECT o.order_id, o.order_date,
       EXISTS(SELECT 1 FROM order_items oi JOIN products p ON oi.product_id=p.product_id WHERE oi.order_id=o.order_id AND p.price>500) AS has_expensive_item
FROM orders o
LIMIT 20;

-- 10. Analytical query: top customers by total spend
SELECT c.customer_id, c.first_name || ' ' || c.last_name AS customer, SUM(oi.quantity * oi.unit_price) AS total_spent
FROM customers c
JOIN orders o ON c.customer_id = o.customer_id
JOIN order_items oi ON o.order_id = oi.order_id
GROUP BY c.customer_id
ORDER BY total_spent DESC;

