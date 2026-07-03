# 🛒 Retail Sales SQL Analytics

![SQL](https://img.shields.io/badge/SQL-MySQL-blue?logo=mysql)
![Excel](https://img.shields.io/badge/Excel-Validation-green?logo=microsoftexcel)
![License](https://img.shields.io/badge/License-MIT-green)

A SQL-first analytics project that answers **30+ real business questions** on a seeded synthetic retail dataset — revenue, customer behaviour, and product performance — using JOINs, CTEs, and window functions, with every result cross-validated in Excel PivotTables.

---

## 🎯 Business Questions Answered

| Area | Example Questions |
|---|---|
| **Revenue** | Monthly revenue trend, revenue by region/category, quarter-over-quarter growth |
| **Customers** | Top customers by lifetime value, repeat vs one-time buyers, customers with no orders (LEFT JOIN + IS NULL) |
| **Products** | Top N products per category (DENSE_RANK + PARTITION BY), slow movers, price-band analysis |
| **Trends** | Running revenue totals (SUM OVER), month-over-month change (LAG), rank movement over time |

---

## 🧠 SQL Concepts Demonstrated

- **JOINs** — INNER, LEFT, and anti-joins; row-count checks after every join to catch fan-out
- **CTEs** — readable multi-step logic; aggregate-before-join pattern to avoid inflated sums
- **Window functions** — ROW_NUMBER, RANK, DENSE_RANK, LAG, SUM OVER with PARTITION BY
- **Aggregation** — GROUP BY with HAVING, conditional aggregation with CASE

---

## ✅ Validation Approach

Every key query result was rebuilt independently in **Excel PivotTables** — if SQL reported a region's revenue, the pivot on the same raw data had to agree. This cross-checking habit catches join fan-out and filter mistakes before they reach a stakeholder.

---

## 🚀 Quick Start

```bash
# 1. Clone the repo
git clone https://github.com/Dharshan987/retail-sales-sql-analytics.git
cd retail-sales-sql-analytics

# 2. Load the schema + seed data into MySQL
mysql -u <user> -p < sql/01_schema.sql
mysql -u <user> -p < sql/02_seed_data.sql

# 3. Run the analysis queries
mysql -u <user> -p < sql/03_analysis_queries.sql
```

---

## 📁 Project Structure

```
retail-sales-sql-analytics/
├── sql/
│   ├── 01_schema.sql            # Tables: customers, products, orders, order_items
│   ├── 02_seed_data.sql         # Seeded synthetic data (500 customers, 3,000 orders, 7,400+ line items)
│   └── 03_analysis_queries.sql  # 32 business queries, commented and grouped by theme
├── data/                        # Same data as CSVs (customers, products, orders, order_items)
├── excel/
│   └── validation_pivots.xlsx   # SUMIFS cross-checks of region/category revenue
├── generate_data.py             # Reproducible data generator (seed=42)
└── README.md
```

## 👤 Author

**Dharshan R** — Data Analyst | Python · SQL · Power BI
📧 ramesh.r88442202@gmail.com
🔗 [LinkedIn](https://linkedin.com/in/dharshan-r-42a881246) · [GitHub](https://github.com/Dharshan987)
"# retail-sales-sql-analytics" 
