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

**Query:** [`sql/05_seller_performance_analysis.sql`](/sql/05_seller_performance_analysis.sql)

| shipment_status | avg_review_score | num_orders |
|---|---|---|
| on time | 4.38 | 8,105 |
| late | 4.07 | 71,701 |
| early | 4.38 | 16,554 |

**74% of all orders show as "late."** That's suspicious enough to interpret carefully before writing it down: `shipping_limit_date` is the deadline for the *seller* to hand the package to the carrier — not the estimated delivery date to the customer. So `order_delivered_customer_date - shipping_limit_date` isn't really measuring "was the seller late," it's measuring "seller handoff deadline + however many days of carrier transit time across Brazil" — which will almost always be a large positive number, since delivery necessarily happens well after the shipping deadline, not around the same time. So "late" here doesn't mean "the seller missed their deadline" — it's largely just transit time being longer than half a day, which is expected for basically every order.

**What the data does actually support, worth writing down:** despite that measurement quirk, there's still a real, modest pattern — `on time`/`early` orders average **4.38**, while `late` orders average **4.07** — about a third of a point lower on a 5-point scale. So faster fulfillment (relative to the seller's own deadline) is associated with meaningfully better reviews, even though most orders technically land in the "late" bucket by this specific measure.

Suggested wording for `FINDINGS.md`:

> **Sub-question C: does shipping speed relate to review scores?**
>
> Orders were bucketed by how their delivery date compared to the seller's shipping deadline (`order_delivered_customer_date - shipping_limit_date`).
>
> | shipment_status | avg_review_score | num_orders |
> |---|---|---|
> | on time | 4.38 | 8,105 |
> | early | 4.38 | 16,554 |
> | late | 4.07 | 71,701 |
>
> **Caveat:** most orders (74%) fall into "late" by this measure — but `shipping_limit_date` is the seller's carrier-handoff deadline, not an estimated delivery date, so this largely reflects normal transit time rather than seller tardiness. Despite that, there's a real, moderate effect: orders that miss the seller's own deadline average 0.3 points lower in reviews (4.07 vs. 4.38) than those that don't — suggesting fulfillment speed does meaningfully relate to customer satisfaction, even accounting for the measurement quirk.

Want me to write this into `analysis/FINDINGS.md` now, alongside the existing Question 3 entry (sub-questions A and B)?