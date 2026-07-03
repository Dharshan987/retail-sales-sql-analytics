-- ============================================================
-- Retail Sales SQL Analytics — 32 business questions
-- Tables: customers, products, orders, order_items
-- Note: revenue analysis counts Completed orders unless stated.
-- ============================================================
USE retail_sales;

-- ---------- A. REVENUE ----------

-- 1. Total revenue (Completed orders only)
SELECT SUM(oi.line_revenue) AS total_revenue
FROM orders o
JOIN order_items oi ON o.order_id = oi.order_id
WHERE o.status = 'Completed';

-- 2. Monthly revenue trend
SELECT DATE_FORMAT(o.order_date, '%Y-%m') AS month,
       SUM(oi.line_revenue) AS revenue
FROM orders o
JOIN order_items oi ON o.order_id = oi.order_id
WHERE o.status = 'Completed'
GROUP BY month
ORDER BY month;

-- 3. Revenue by region
SELECT c.region, SUM(oi.line_revenue) AS revenue
FROM orders o
JOIN customers c   ON o.customer_id = c.customer_id
JOIN order_items oi ON o.order_id  = oi.order_id
WHERE o.status = 'Completed'
GROUP BY c.region
ORDER BY revenue DESC;

-- 4. Revenue by category
SELECT p.category, SUM(oi.line_revenue) AS revenue
FROM order_items oi
JOIN products p ON oi.product_id = p.product_id
JOIN orders o   ON oi.order_id  = o.order_id
WHERE o.status = 'Completed'
GROUP BY p.category
ORDER BY revenue DESC;

-- 5. Quarter-over-quarter revenue with growth % (LAG)
WITH q AS (
  SELECT CONCAT(YEAR(o.order_date), '-Q', QUARTER(o.order_date)) AS yq,
         MIN(o.order_date) AS q_start,
         SUM(oi.line_revenue) AS revenue
  FROM orders o
  JOIN order_items oi ON o.order_id = oi.order_id
  WHERE o.status = 'Completed'
  GROUP BY yq
)
SELECT yq, revenue,
       LAG(revenue) OVER (ORDER BY q_start) AS prev_q,
       ROUND(100 * (revenue - LAG(revenue) OVER (ORDER BY q_start))
                 / LAG(revenue) OVER (ORDER BY q_start), 1) AS qoq_growth_pct
FROM q
ORDER BY q_start;

-- 6. Running (cumulative) revenue by month — SUM OVER
WITH m AS (
  SELECT DATE_FORMAT(o.order_date, '%Y-%m') AS month,
         SUM(oi.line_revenue) AS revenue
  FROM orders o
  JOIN order_items oi ON o.order_id = oi.order_id
  WHERE o.status = 'Completed'
  GROUP BY month
)
SELECT month, revenue,
       SUM(revenue) OVER (ORDER BY month) AS running_revenue
FROM m;

-- 7. Average order value (aggregate-before-join pattern — avoids fan-out)
WITH order_totals AS (
  SELECT order_id, SUM(line_revenue) AS order_total
  FROM order_items
  GROUP BY order_id
)
SELECT ROUND(AVG(ot.order_total), 2) AS avg_order_value
FROM orders o
JOIN order_totals ot ON o.order_id = ot.order_id
WHERE o.status = 'Completed';

-- 8. Revenue share % of each region (window over total)
WITH r AS (
  SELECT c.region, SUM(oi.line_revenue) AS revenue
  FROM orders o
  JOIN customers c    ON o.customer_id = c.customer_id
  JOIN order_items oi ON o.order_id   = oi.order_id
  WHERE o.status = 'Completed'
  GROUP BY c.region
)
SELECT region, revenue,
       ROUND(100 * revenue / SUM(revenue) OVER (), 2) AS revenue_share_pct
FROM r
ORDER BY revenue DESC;

-- ---------- B. CUSTOMERS ----------

-- 9. Top 10 customers by lifetime revenue
SELECT c.customer_id, c.customer_name, SUM(oi.line_revenue) AS lifetime_revenue
FROM customers c
JOIN orders o       ON c.customer_id = o.customer_id
JOIN order_items oi ON o.order_id   = oi.order_id
WHERE o.status = 'Completed'
GROUP BY c.customer_id, c.customer_name
ORDER BY lifetime_revenue DESC
LIMIT 10;

-- 10. Customers who have NEVER placed an order (LEFT JOIN + IS NULL)
SELECT c.customer_id, c.customer_name, c.region
FROM customers c
LEFT JOIN orders o ON c.customer_id = o.customer_id
WHERE o.order_id IS NULL;

-- 11. Repeat vs one-time buyers
WITH counts AS (
  SELECT customer_id, COUNT(*) AS n_orders
  FROM orders
  GROUP BY customer_id
)
SELECT CASE WHEN n_orders = 1 THEN 'One-time' ELSE 'Repeat' END AS buyer_type,
       COUNT(*) AS customers
FROM counts
GROUP BY buyer_type;

-- 12. Top 3 customers per region by revenue (DENSE_RANK + PARTITION BY)
WITH cust_rev AS (
  SELECT c.region, c.customer_id, c.customer_name,
         SUM(oi.line_revenue) AS revenue
  FROM customers c
  JOIN orders o       ON c.customer_id = o.customer_id
  JOIN order_items oi ON o.order_id   = oi.order_id
  WHERE o.status = 'Completed'
  GROUP BY c.region, c.customer_id, c.customer_name
),
ranked AS (
  SELECT *, DENSE_RANK() OVER (PARTITION BY region ORDER BY revenue DESC) AS rnk
  FROM cust_rev
)
SELECT * FROM ranked WHERE rnk <= 3 ORDER BY region, rnk;

-- 13. Each customer's first and most recent order date
SELECT customer_id, MIN(order_date) AS first_order, MAX(order_date) AS last_order,
       DATEDIFF(MAX(order_date), MIN(order_date)) AS active_days
FROM orders
GROUP BY customer_id;

-- 14. Customers whose latest order was Returned (ROW_NUMBER to pick latest)
WITH latest AS (
  SELECT o.*, ROW_NUMBER() OVER (PARTITION BY customer_id ORDER BY order_date DESC) AS rn
  FROM orders o
)
SELECT customer_id, order_id, order_date
FROM latest
WHERE rn = 1 AND status = 'Returned';

-- 15. Average days between orders per customer (LAG on dates)
WITH gaps AS (
  SELECT customer_id,
         DATEDIFF(order_date,
                  LAG(order_date) OVER (PARTITION BY customer_id ORDER BY order_date)) AS gap_days
  FROM orders
)
SELECT customer_id, ROUND(AVG(gap_days), 1) AS avg_gap_days
FROM gaps
WHERE gap_days IS NOT NULL
GROUP BY customer_id
ORDER BY avg_gap_days;

-- 16. New customers acquired per month (based on first order)
WITH first_orders AS (
  SELECT customer_id, MIN(order_date) AS first_order
  FROM orders
  GROUP BY customer_id
)
SELECT DATE_FORMAT(first_order, '%Y-%m') AS month, COUNT(*) AS new_customers
FROM first_orders
GROUP BY month
ORDER BY month;

-- ---------- C. PRODUCTS ----------

-- 17. Top 10 products by revenue
SELECT p.product_name, p.category, SUM(oi.line_revenue) AS revenue
FROM order_items oi
JOIN products p ON oi.product_id = p.product_id
JOIN orders o   ON oi.order_id  = o.order_id
WHERE o.status = 'Completed'
GROUP BY p.product_id, p.product_name, p.category
ORDER BY revenue DESC
LIMIT 10;

-- 18. Top 2 products per category (classic interview question)
WITH prod_rev AS (
  SELECT p.category, p.product_name, SUM(oi.line_revenue) AS revenue
  FROM order_items oi
  JOIN products p ON oi.product_id = p.product_id
  JOIN orders o   ON oi.order_id  = o.order_id
  WHERE o.status = 'Completed'
  GROUP BY p.category, p.product_id, p.product_name
)
SELECT * FROM (
  SELECT *, DENSE_RANK() OVER (PARTITION BY category ORDER BY revenue DESC) AS rnk
  FROM prod_rev
) t
WHERE rnk <= 2
ORDER BY category, rnk;

-- 19. Products never ordered (anti-join)
SELECT p.product_id, p.product_name
FROM products p
LEFT JOIN order_items oi ON p.product_id = oi.product_id
WHERE oi.item_id IS NULL;

-- 20. Second most expensive product per category (DENSE_RANK, not LIMIT/OFFSET)
SELECT category, product_name, unit_price
FROM (
  SELECT *, DENSE_RANK() OVER (PARTITION BY category ORDER BY unit_price DESC) AS rnk
  FROM products
) t
WHERE rnk = 2;

-- 21. Price-band analysis (CASE bucketing)
SELECT CASE
         WHEN unit_price < 1000  THEN 'Budget (<1k)'
         WHEN unit_price < 10000 THEN 'Mid (1k-10k)'
         ELSE 'Premium (10k+)'
       END AS price_band,
       COUNT(*) AS products,
       ROUND(AVG(unit_price), 2) AS avg_price
FROM products
GROUP BY price_band;

-- 22. Category performance: revenue, units, distinct buyers
SELECT p.category,
       SUM(oi.line_revenue)          AS revenue,
       SUM(oi.quantity)              AS units_sold,
       COUNT(DISTINCT o.customer_id) AS distinct_buyers
FROM order_items oi
JOIN products p ON oi.product_id = p.product_id
JOIN orders o   ON oi.order_id  = o.order_id
WHERE o.status = 'Completed'
GROUP BY p.category
ORDER BY revenue DESC;

-- ---------- D. ORDERS & OPERATIONS ----------

-- 23. Order status split with percentages
SELECT status, COUNT(*) AS orders,
       ROUND(100 * COUNT(*) / SUM(COUNT(*)) OVER (), 2) AS pct
FROM orders
GROUP BY status;

-- 24. Return rate by category (conditional aggregation)
SELECT p.category,
       ROUND(100 * SUM(o.status = 'Returned') / COUNT(*), 2) AS return_rate_pct
FROM orders o
JOIN order_items oi ON o.order_id = oi.order_id
JOIN products p     ON oi.product_id = p.product_id
GROUP BY p.category
ORDER BY return_rate_pct DESC;

-- 25. Orders with more than 3 line items (HAVING)
SELECT oi.order_id, COUNT(*) AS n_items, SUM(oi.line_revenue) AS order_total
FROM order_items oi
GROUP BY oi.order_id
HAVING COUNT(*) > 3
ORDER BY order_total DESC;

-- 26. Busiest day of week by order count
SELECT DAYNAME(order_date) AS weekday, COUNT(*) AS orders
FROM orders
GROUP BY weekday
ORDER BY orders DESC;

-- 27. FAN-OUT DEMO — why SUM after a 1-to-many join inflates
--     (a) WRONG: joins orders to items then counts orders — inflated
SELECT COUNT(o.order_id) AS inflated_order_count      -- counts one per ITEM
FROM orders o
JOIN order_items oi ON o.order_id = oi.order_id;
--     (b) RIGHT: aggregate items first, then join — correct
WITH per_order AS (
  SELECT order_id, SUM(line_revenue) AS order_total
  FROM order_items GROUP BY order_id
)
SELECT COUNT(*) AS correct_order_count, SUM(order_total) AS correct_revenue
FROM orders o JOIN per_order p ON o.order_id = p.order_id;

-- 28. Month-over-month revenue change (LAG)
WITH m AS (
  SELECT DATE_FORMAT(o.order_date, '%Y-%m') AS month,
         SUM(oi.line_revenue) AS revenue
  FROM orders o JOIN order_items oi ON o.order_id = oi.order_id
  WHERE o.status = 'Completed'
  GROUP BY month
)
SELECT month, revenue,
       revenue - LAG(revenue) OVER (ORDER BY month) AS mom_change
FROM m;

-- 29. Rank regions by revenue within each quarter
WITH rq AS (
  SELECT CONCAT(YEAR(o.order_date), '-Q', QUARTER(o.order_date)) AS yq,
         c.region, SUM(oi.line_revenue) AS revenue
  FROM orders o
  JOIN customers c    ON o.customer_id = c.customer_id
  JOIN order_items oi ON o.order_id   = oi.order_id
  WHERE o.status = 'Completed'
  GROUP BY yq, c.region
)
SELECT yq, region, revenue,
       RANK() OVER (PARTITION BY yq ORDER BY revenue DESC) AS region_rank
FROM rq
ORDER BY yq, region_rank;

-- 30. Duplicate detection: same customer, same date, same product
SELECT o.customer_id, o.order_date, oi.product_id, COUNT(*) AS occurrences
FROM orders o
JOIN order_items oi ON o.order_id = oi.order_id
GROUP BY o.customer_id, o.order_date, oi.product_id
HAVING COUNT(*) > 1;

-- 31. Contribution of top-20% products to revenue (Pareto check)
WITH prod_rev AS (
  SELECT oi.product_id, SUM(oi.line_revenue) AS revenue
  FROM order_items oi
  JOIN orders o ON oi.order_id = o.order_id
  WHERE o.status = 'Completed'
  GROUP BY oi.product_id
),
ranked AS (
  SELECT *, NTILE(5) OVER (ORDER BY revenue DESC) AS quintile
  FROM prod_rev
)
SELECT ROUND(100 * SUM(CASE WHEN quintile = 1 THEN revenue END)
                 / SUM(revenue), 1) AS top20pct_share
FROM ranked;

-- 32. Region x category revenue matrix (pivot-style)
SELECT c.region,
       SUM(CASE WHEN p.category = 'Electronics'    THEN oi.line_revenue ELSE 0 END) AS electronics,
       SUM(CASE WHEN p.category = 'Clothing'       THEN oi.line_revenue ELSE 0 END) AS clothing,
       SUM(CASE WHEN p.category = 'Home & Kitchen' THEN oi.line_revenue ELSE 0 END) AS home_kitchen,
       SUM(CASE WHEN p.category = 'Sports'         THEN oi.line_revenue ELSE 0 END) AS sports,
       SUM(CASE WHEN p.category = 'Books'          THEN oi.line_revenue ELSE 0 END) AS books
FROM orders o
JOIN customers c    ON o.customer_id = c.customer_id
JOIN order_items oi ON o.order_id   = oi.order_id
JOIN products p     ON oi.product_id = p.product_id
WHERE o.status = 'Completed'
GROUP BY c.region;
