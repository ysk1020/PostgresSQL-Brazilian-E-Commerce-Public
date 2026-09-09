/*
Thirdly, we can analyze the seller performance:
    Which sellers are consistently top-ranked across multiple  months vs one hit wonders?

    Which product categories have the best revenue-per-order but the worst review scores — i.e., where's the quality/margin tension?
    (join order_items → products → translation → order_reviews, RANK by revenue and separately by avg review_score, compare)

    Do sellers with faster shipping (order_delivered_customer_date - shipping_limit_date) get measurably better review scores?
    (this is a real correlation question, not just a window function — good for showing you go beyond mechanical technique practice)
*/

-- SUB-QUESTION A: which sellers are consistently top-ranked
-- across multiple months, vs. one-hit wonders?
-- ============================================================

-- STEP A1 — seller revenue per month, flat, no ranking yet.
SELECT 
    oi.seller_id,
    date_trunc('month', o.order_purchase_timestamp) as order_month,
    sum(oi.price) as seller_monthly_revenue
FROM order_items AS oi
INNER JOIN orders as o on oi.order_id= o.order_id
group by oi.seller_id, date_trunc('month', o.order_purchase_timestamp)
limit 20;

-- STEP A2 — wrap A1 in a CTE, rank sellers WITHIN each month by revenue.

WITH seller_monthly_revenue AS (
    SELECT 
        oi.seller_id,
        date_trunc('month', o.order_purchase_timestamp) AS order_month,
        sum(oi.price) AS seller_monthly_revenue
    FROM order_items AS oi
    INNER JOIN orders AS o ON oi.order_id= o.order_id
    GROUP BY  oi.seller_id, date_trunc('month', o.order_purchase_timestamp)
)

SELECT 
    seller_id,
    order_month,
    seller_monthly_revenue,
RANK() OVER(PARTITION BY order_month ORDER BY seller_monthly_revenue DESC) AS monthly_ranks
FROM seller_monthly_revenue
limit 20;

-- STEP A3 — final: collapse down to one row per seller, counting how many

WITH seller_monthly_revenue AS (
    SELECT 
        oi.seller_id,
        date_trunc('month', o.order_purchase_timestamp) AS order_month,
        sum(oi.price) AS seller_monthly_revenue
    FROM order_items AS oi
    INNER JOIN orders AS o ON oi.order_id= o.order_id
    GROUP BY  oi.seller_id, date_trunc('month', o.order_purchase_timestamp)
),
ranked as (
    SELECT 
    seller_id,
    order_month,
    seller_monthly_revenue,
    RANK() OVER(PARTITION BY order_month ORDER BY seller_monthly_revenue DESC) AS monthly_ranks
    FROM seller_monthly_revenue
)

SELECT 
    seller_id,
    count(*) as months_in_top_5
FROM ranked
WHERE monthly_ranks <= 5
GROUP BY seller_id
ORDER BY months_in_top_5 DESC;

-- SUB-QUESTION B: which categories have the best revenue-per-order
-- but the worst review scores? (quality/margin tension)
-- ============================================================
-- STEP B1 — revenue per category, flat, no ranking, no reviews yet.

SELECT
    p.product_category_name,
    sum(oi.price) as category_revenue,
    count(DISTINCT oi.order_id) as num_orders,
    sum(oi.price) / count(DISTINCT oi.order_id) as avg_revenue_per_order
FROM order_items AS oi  
JOIN products as p
    ON  p.product_id = oi.product_id
GROUP BY p.product_category_name
LIMIT 20;

-- STEP B2 — separately, average review score per category.
-- This needs its own join path: order_items -> order_reviews on order_id,
-- then back to products for the category. Different CTE, not tacked onto B1 —
-- combining them directly would double-count price across multiple reviews
-- per order, or double-count reviews across multiple items per order.
SELECT
    p.product_category_name,
    Round(avg(orv.review_score),2) as avg_review_score
FROM order_items AS oi
left join products as p
    ON oi.product_id = p.product_id
left join order_reviews as orv 
    ON oi.order_id= orv.order_id

GROUP BY p.product_category_name
LIMIT 20;

-- STEP B3 — rank both metrics separately, then join them together.
with revenue_ranked as (
    SELECT
        p.product_category_name,
        sum(oi.price) as category_revenue,
        count(DISTINCT oi.order_id) as num_orders,
        round(sum(oi.price) / count(DISTINCT oi.order_id),2) as avg_revenue_per_order,
        rank() over( order by round(sum(oi.price) / count(DISTINCT oi.order_id),2) desc) as revenue_rank
    FROM order_items AS oi  
    JOIN products as p
        ON  p.product_id = oi.product_id
    GROUP BY p.product_category_name
),
review_ranked as (
    SELECT
        p.product_category_name,
        Round(avg(orv.review_score),2) as avg_review_score,
        rank() over (order by Round(avg(orv.review_score),2) asc) as worst_review_rank
    FROM order_items AS oi
    left join products as p
        ON oi.product_id = p.product_id
    left join order_reviews as orv 
        ON oi.order_id= orv.order_id
    GROUP BY p.product_category_name
)

SELECT
    r.product_category_name,
    r.avg_revenue_per_order,
    r.revenue_rank,
    v.avg_review_score,
    v.worst_review_rank
FROM revenue_ranked as r
LEFT JOIN review_ranked as v 
    ON v.product_category_name = r.product_category_name
order by r.revenue_rank;

-- SUB-QUESTION C: do sellers with faster shipping get better
-- review scores? (a correlation question, not just a window function)
-- ============================================================

-- NOTE: order_delivered_customer_date can be NULL (order never delivered).
-- Those rows need to drop out of this analysis — decide whether an inner
-- join naturally handles that (it does, if the column is NULL the join
-- condition can still run, but think about whether you need an explicit
-- WHERE ... IS NOT NULL to be safe/explicit about it).

-- join in review_score, then choose ONE of two approaches:
--   (a) bucket delta into 'early' / 'on_time' / 'late' with a CASE,
--       then avg(review_score) grouped by bucket — same CASE-bucketing
--       pattern as Topic 1's buyer_type.
--   (b) skip bucketing, use Postgres's built-in corr(y, x) aggregate
--       function directly on the two numeric columns for a real
--       correlation coefficient between -1 and 1.

With deltas as (
    SELECT     
        oi.order_id,
        oi.shipping_limit_date,
        o.order_delivered_customer_date,
        orv.review_score,
        (o.order_delivered_customer_date - oi.shipping_limit_date) as delivery_delta
    FROM order_items AS oi
    INNER JOIN orders AS o ON o.order_id = oi.order_id
    INNER JOIN order_reviews AS orv ON o.order_id = orv.order_id
    WHERE o.order_delivered_customer_date is not NULL
),
dedupe as (
SELECT
    DISTINCT(order_id),
    review_score,
    delivery_delta,
    CASE
        When EXTRACT(epoch from delivery_delta)/86400 > 0.5 then 'late'
        When EXTRACT(epoch from delivery_delta)/86400 < -0.5 then 'early'
        Else 'on time'
    End as shipment_status
from deltas)

-- Result: on time 4.38 (8,105 orders), early 4.38 (16,554), late 4.07 (71,701).
-- Caveat: shipping_limit_date is the seller's carrier-handoff deadline, not an
-- estimated delivery date, so most orders land in 'late' just from normal transit
-- time, not seller tardiness. Still, missing that deadline correlates with a real,
-- moderate drop in review score (4.07 vs 4.38) — fulfillment speed does relate to
-- customer satisfaction, even accounting for the measurement quirk.
select
    shipment_status,
    round(avg(review_score),2) as avg_review_score,
    count(*) as num_orders
from dedupe
group by shipment_status;
