/*
Secondly, we can analyze the revenue growing and if growth accelerating or decelerating over time.
    Additionally we can analyze how much of revenue comes from feight(shiping) vs product prices, and is that ratio stable
    Cumulative revenue from top 10% of customers (the Pareto question)
    What it's asking: Sort all customers by how much they've spent in total. Take the top 10% of spenders. 
    What percentage of total revenue do just those customers account for? 
    This is the classic "80/20 rule" check — do a small number of customers disproportionately drive the business?
*/
-- Business question: is monthly revenue growing, and is growth accelerating or decelerating?
-- Caveats: Nov 2016 has zero orders (no revenue row appears that month);
-- Sept 2016-Dec 2016 is pilot/test volume; Sept 2018 is a partial/truncated month, not a real crash.

with monthly_revenue as(
    select
        sum(oi.price) as total_revenue,
        sum(oi.freight_value) as total_freight,
        date_trunc('month', o.order_purchase_timestamp) as order_month
    from order_items as oi
    inner join orders as o 
        on oi.order_id = o.order_id
    group by order_month    
)

select 
    order_month,
    total_revenue,
    -- total_freight,
    -- total_revenue - total_freight as product_revenue,
    -- round(total_freight / total_revenue, 2)
    sum(total_revenue) over(order by order_month) as cumulative_revenue,
    avg(total_revenue) over(order by order_month rows between 2 preceding and CURRENT row) as avg_monthly_revenue
from monthly_revenue
order by order_month;
