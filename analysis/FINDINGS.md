# Findings

## Question 1 - Repeat buyers vs. one-time buyers

**Query:** [`sql/03_custome_order_patterns_analysis.sql`](../sql/03_custome_order_patterns_analysis.sql)

Customers were split into three buckets by how many orders they've placed:

| buyer_type | num_customers | avg_order_value |
|---|---|---|
| one-time buyer | 93,099 | $138.62 |
| two-time buyer | 2,745 | $124.47 |
| repeat buyer | 252 | $127.79 |

**Takeaway:** one-time buyers vastly outnumber repeat buyers (93K vs. ~3K combined, repeat purchasing is rare in this dataset, under 4% of customers). Because of that sheer volume, one-time buyers drive the majority of total revenue, not because each one spends more, in fact the opposite is true: two-time and repeat buyers have a *slightly lower* average order value ($124-128) than one-time buyers ($138.62). So "repeat buyer" here isn't a bigger-spender segment, it's a more-frequent, slightly-smaller-basket segment.

---

## Question 2 - Monthly revenue trend (growth over time)

**Query:** [`sql/04_revenue_analysis.sql`](../sql/04_revenue_analysis.sql)

*Status: only the growth-trend sub-question is answered so far. The freight-vs-product-price split and the top-10%-of-customers (Pareto) sub-questions from the original plan are still open.*

Monthly revenue, cumulative total, and a 3-month rolling average were computed from Sept 2016 through Sept 2018.

**Takeaway:**
- **2016 (Sept–Dec) was a pilot/test period**, not representative of real business volume - revenue was in the low hundreds/thousands, and **November 2016 has zero orders at all** (no row for that month; the marketplace wasn't really running yet).
- **2017 saw strong, real growth** - revenue climbed from ~$120K (Jan) to a peak of ~$1.01M (Nov), roughly 8x growth over the year.
- **2018 growth flattened.** Revenue plateaus in the $845K–$996K/month range through August — still healthy, but no longer climbing the way it did in 2017. Growth **decelerated**, it didn't keep accelerating.
- **September 2018's drop to $145 is a data-truncation artifact**, not a real collapse - the dataset appears to cut off mid-month. It should not be read as "revenue crashed."

**Overall:** cumulative revenue is monotonically increasing (as it must be, by definition of a running total) — the more meaningful read is the *rate* of growth, which was steep in 2017 and has since leveled off.

---

## Question 3 - Seller performance

*Not yet started.*
