# PostgreSQL Brazilian E-Commerce Analysis

A SQL portfolio project analyzing the Olist Brazilian E-Commerce dataset using PostgreSQL,
with a focus on window functions (ranking, offset, and running/rolling aggregates) to answer
real business questions: customer order patterns, revenue trends, and seller/category performance.

This project was built to practice advanced SQL techniques (CTEs, window functions, frame
clauses) on a realistic, messy, multi-table dataset rather than toy examples.

## Dataset

The [Olist Brazilian E-Commerce dataset](https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce)
from Kaggle. Download it and place the 9 CSV files in a `data/` folder at the repo root
(already gitignored, not tracked).

## Setup

Requires a running PostgreSQL server (tested on Postgres 14).

```bash
createdb olist_ecommerce
psql -d olist_ecommerce -f sql/00_schema.sql
psql -d olist_ecommerce -f sql/01_load_data.sql
psql -d olist_ecommerce -f sql/02_verify.sql
```

Run these from the repo root, since `\copy` in `01_load_data.sql` resolves file paths
relative to the current directory.

## Project structure

```
sql/
  00_schema.sql                              table definitions and indexes
  01_load_data.sql                           loads the 9 CSVs into the tables
  02_verify.sql                              row-count checks after loading
  03_custome_order_patterns_analysis.sql     Question 1: repeat vs. one-time buyers
  04_revenue_analysis.sql                    Question 2: monthly revenue trend
  05_seller_performance_analysis.sql         Question 3: seller and category performance
analysis/
  FINDINGS.md                                write-up of results and takeaways
```

## Findings

See [`analysis/FINDINGS.md`](analysis/FINDINGS.md) for the results and takeaways from
each analysis question.
