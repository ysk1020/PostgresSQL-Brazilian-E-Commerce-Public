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

**Query:** [`sql/05_seller_performance_analysis.sql`](../sql/05_seller_performance_analysis.sql)

### Sub-question A: which sellers are consistently top-ranked vs. one-hit wonders?

For each month, sellers were ranked against each other by revenue (`RANK() OVER (PARTITION BY order_month ORDER BY revenue DESC)`), then counted by how many separate months they landed in the top 5:

| months_in_top_5 | num_sellers |
|---|---|
| 10 | 1 |
| 9 | 1 |
| 7 | 2 |
| 6 | 2 |
| 5 | 2 |
| 4 | 1 |
| 3 | 4 |
| 2 | 7 |
| 1 | 25 |

**Takeaway:** across about 25 months of data, 45 different sellers made the top 5 at least once. But most of them (25 sellers, over half) only did it one time. That was a one-time spike, not steady performance. Only 8 sellers made the top 5 in 5 or more separate months, and one seller stands out clearly, making the top 5 in 10 different months. The best performance in this marketplace comes from a small group of steady sellers, not from many sellers spread evenly.

*Open question, not yet checked:* whether these steady top sellers sell in specific product categories, or whether their consistency comes from something else, like pricing or how many items they list. The current query only looks at seller-level revenue, not product data. This is a guess for future work, not a confirmed finding.

### Sub-question B: which categories have the best revenue-per-order but the worst review scores?

Categories were ranked separately by average revenue-per-order and by average review score (worst first), then compared side by side:

| product_category_name | avg_revenue_per_order | revenue_rank | avg_review_score | worst_review_rank |
|---|---|---|---|---|
| pcs | 1231.84 | 1 | 4.18 | 57 |
| portateis_cozinha_e_preparadores_de_alimentos | 283.47 | 7 | 3.27 | 3 |
| moveis_escritorio | 215.21 | 11 | 3.49 | 5 |
| pc_gamer | 193.24 | 15 | 3.33 | 4 |

(out of ~71 total categories)

**Takeaway:** `pcs` has both high revenue and a good review score (rank 57 of 71, nowhere near the worst). No tension there. But **kitchen and food-prep appliances, office furniture, and gaming PCs** all combine solid to strong revenue per order with review scores among the worst 5 categories in the whole dataset. This is a real quality/margin tension worth noting.

*Known caveat:* the review-score side of this join can double-count a review (a multi-item order's single review can be counted once per item), and this hasn't been fixed with a dedup step yet. The categories found are still real, large gaps, but the exact average scores may shift a little once that's fixed.

### Sub-question C: does shipping speed relate to review scores?

Orders were bucketed by how their delivery date compared to the seller's shipping deadline (`order_delivered_customer_date - shipping_limit_date`):

| shipment_status | avg_review_score | num_orders |
|---|---|---|
| on time | 4.38 | 8,105 |
| early | 4.38 | 16,554 |
| late | 4.07 | 71,701 |

**Caveat:** most orders (74%) fall into "late" by this measure. But `shipping_limit_date` is the seller's deadline to hand the package to the carrier, not an estimated delivery date. So this mostly shows normal transit time, not the seller being slow. Even so, there's a real, moderate effect: orders that miss the seller's own deadline average 0.3 points lower in reviews (4.07 vs. 4.38) than those that don't. This suggests fulfillment speed does relate to customer satisfaction, even with the measurement quirk taken into account.