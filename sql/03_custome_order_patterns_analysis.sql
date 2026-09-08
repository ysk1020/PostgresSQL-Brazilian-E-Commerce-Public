/*  
So let's start with the analyzing the data we have. In this SQL script, 
we will perform various analytical queries to gain insights from our dataset. 
We will explore trends, patterns, and relationships within the data to inform our decision-making process.

Here are some questions we can answer with our analysis:
First of all, related with customer order patterns. 
    Which customers are repeat buyers vs. one-time? What's the distribution of orders-per-customer? (you already built the days-between-orders query
    this is its natural companion: COUNT(*) OVER (PARTITION BY customer_unique_id) bucketed into 1, 2, 3+ orders)
    Repeat buyers vs one-time buyers, average order value, and frequency of purchases. 
*/
-- CTE: collapse from one-row-per-order down to one-row-per-real-person,
-- counting how many orders each person placed
WITH customer_order_counts AS (
    select
        c.customer_unique_id,       -- the true person-level id (customer_id is per-order, not per-person)
        count(o.order_id) as num_orders  -- how many orders this person placed
    from orders as o
    join customers_dataset as c on o.customer_id = c.customer_id  -- link each order to the real person who placed it
    group by c.customer_unique_id   -- one row per person, not per order
),
order_totals as (
    select 
        order_id,
        sum(price) as order_value
    from order_items
    group by order_id
)

-- Bucket each person's order count into a business-readable label,
-- then count how many people fall into each bucket
Select
    case
        when num_orders = 1 then 'one-time buyer'   -- ordered exactly once
        when num_orders = 2 then 'two-time buyer'    -- ordered exactly twice
        else 'repeat buyer' end as buyer_type,       -- ordered 3+ times
    COUNT(DISTINCT(c.customer_unique_id)) AS num_customers,        -- how many people fall into this bucket
    ROUND(AVG(order_value), 2) as avg_order_value
from customer_order_counts as c
join customers_dataset as cd 
    on c.customer_unique_id = cd.customer_unique_id
join orders AS o 
    on cd.customer_id = o.customer_id
left join order_totals AS ot 
    on o.order_id = ot.order_id
group by buyer_type              -- collapse from one-row-per-person to one-row-per-bucket
order by num_customers desc;     -- largest bucket first
