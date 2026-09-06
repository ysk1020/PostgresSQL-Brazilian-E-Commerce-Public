--stops the whole script immediately if any error occurs, if any statements below this line fail, the script will stop executing
\set ON_ERROR_STOP on  

-- prints how long each statement takes to executes
\timing on 

BEGIN;
-- opens a transaction block, all statements between BEGIN and COMMIT will be executed as a single unit of work

truncate table      
    order_reviews, order_payments, order_items, orders,
    products, product_category_name_translation, geolocation_dataset, customers_dataset, sellers_dataset
    RESTART IDENTITY CASCADE;
    -- empties all tables first, so this script can be run multiple times safely
    -- after fixing a problem, without 'duplicate key value violates unique constraint'f errors


-- no dependencies
\copy sellers_dataset from 'data/olist_sellers_dataset.csv' with (format CSV, HEADER true)
\copy geolocation_dataset from 'data/olist_geolocation_dataset.csv' with (format CSV, HEADER true)
\copy customers_dataset from 'data/olist_customers_dataset.csv' with (format CSV, HEADER true)
\copy products from 'data/olist_products_dataset.csv' with (format CSV, HEADER true)
\copy product_category_name_translation from 'data/product_category_name_translation.csv' with (format CSV, HEADER true)

-- depends on customers
\copy orders from 'data/olist_orders_dataset.csv' with (format CSV, HEADER true)

-- depends on orders
\copy order_items from 'data/olist_order_items_dataset.csv' with (format CSV, HEADER true)
\copy order_payments from 'data/olist_order_payments_dataset.csv' with (format CSV, HEADER true)
\copy order_reviews from 'data/olist_order_reviews_dataset.csv' with (format CSV, HEADER true)

COMMIT;
