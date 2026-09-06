select 'sellers_dataset' as table_name, count(*) as row_count from sellers_dataset
union all select 'customers_dataset', count(*) from customers_dataset
union all select 'geolocation_dataset', count(*) from geolocation_dataset
union all select 'product_category_name_translation', count(*) from product_category_name_translation
union all select 'products', count(*) from products
union all select 'orders', count(*) from orders
union all select 'order_items', count(*) from order_items
union all select 'order_payments', count(*) from order_payments
union all select 'order_reviews', count(*) from order_reviews
order by table_name;
