/* 
Thirdly, we can analyze the seller performance:
    Which sellers are consistently top-ranked across multiple  months vs one hit wonders?
    
    Which product categories have the best revenue-per-order but the worst review scores — i.e., where's the quality/margin tension? 
    (join order_items → products → translation → order_reviews, RANK by revenue and separately by avg review_score, compare)

    Do sellers with faster shipping (order_delivered_customer_date - shipping_limit_date) get measurably better review scores? 
    (this is a real correlation question, not just a window function — good for showing you go beyond mechanical technique practice)
*/
