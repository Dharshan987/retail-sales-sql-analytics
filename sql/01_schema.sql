-- Retail Sales SQL Analytics: schema
CREATE DATABASE IF NOT EXISTS retail_sales;
USE retail_sales;

DROP TABLE IF EXISTS order_items, orders, products, customers;

CREATE TABLE customers (
  customer_id   VARCHAR(12) PRIMARY KEY,
  customer_name VARCHAR(100),
  region        VARCHAR(20),
  signup_date   DATE
);

CREATE TABLE products (
  product_id   VARCHAR(12) PRIMARY KEY,
  product_name VARCHAR(100),
  category     VARCHAR(40),
  unit_price   DECIMAL(10,2)
);

CREATE TABLE orders (
  order_id    VARCHAR(12) PRIMARY KEY,
  customer_id VARCHAR(12),
  order_date  DATE,
  status      VARCHAR(12),
  FOREIGN KEY (customer_id) REFERENCES customers(customer_id)
);

CREATE TABLE order_items (
  item_id      VARCHAR(14) PRIMARY KEY,
  order_id     VARCHAR(12),
  product_id   VARCHAR(12),
  quantity     INT,
  unit_price   DECIMAL(10,2),
  line_revenue DECIMAL(12,2),
  FOREIGN KEY (order_id) REFERENCES orders(order_id),
  FOREIGN KEY (product_id) REFERENCES products(product_id)
);
