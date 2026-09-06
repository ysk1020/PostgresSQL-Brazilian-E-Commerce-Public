-- drop tables if they exist, so script can be run multiple times without error
DROP TABLE IF EXISTS order_reviews CASCADE;
DROP TABLE IF EXISTS orders CASCADE;
DROP TABLE IF EXISTS order_items CASCADE;
DROP TABLE IF EXISTS order_payments CASCADE;
DROP TABLE IF EXISTS customers_dataset CASCADE;
DROP TABLE IF EXISTS geolocation_dataset CASCADE;
DROP TABLE IF EXISTS products CASCADE;
DROP TABLE IF EXISTS product_category_name_translation CASCADE;
DROP TABLE IF EXISTS sellers_dataset CASCADE;

-- create tables no dependencies first
-- sellers
create table sellers_dataset (
    seller_id varchar(50) primary key,
    seller_zip_code_prefix int,
    seller_city varchar(50),
    seller_state char(2)
);
-- customers
create table customers_dataset (
    customer_id varchar(50) primary key,
    customer_unique_id varchar(50),
    customer_zip_code_prefix int,
    customer_city varchar(50),
    customer_state char(2)
);
-- geolocation
-- no primary key: source data is raw repeated GPS pings per zip prefix, not unique at any grain
create table geolocation_dataset (
    geolocation_zip_code_prefix int,
    geolocation_lat numeric(10, 8),
    geolocation_lng numeric(11, 8),
    geolocation_city varchar(50),
    geolocation_state char(2)
);
-- product_category_name_translation
create table product_category_name_translation (
    product_category_name varchar(100) primary key,
    product_category_name_english varchar(100)
);
-- products
create table products (
    product_id varchar(50) primary key,
    product_category_name varchar(100),
    product_name_length int,
    product_description_length int,
    product_photos_qty int,
    product_weight_g int,
    product_length_cm int,
    product_height_cm int,
    product_width_cm int
);

-- create dependent tables after
-- orders — FK → customers
create table orders (
    order_id varchar(50) primary key,
    customer_id varchar(50) references customers_dataset(customer_id),
    order_status varchar(20),
    order_purchase_timestamp timestamp,
    order_approved_at timestamp,
    order_delivered_carrier_date timestamp,
    order_delivered_customer_date timestamp,
    order_estimated_delivery_date timestamp
);
-- order_items — FK → orders, products, sellers
create table order_items (
    order_id varchar(50) references orders(order_id),
    order_item_id int,
    product_id varchar(50) references products(product_id),
    seller_id varchar(50) references sellers_dataset(seller_id),
    shipping_limit_date timestamp,
    price numeric(10, 2),
    freight_value numeric(10, 2),
    primary key (order_id, order_item_id)
);
-- order_payments — FK → orders
create table order_payments (
    order_id varchar(50) references orders(order_id),
    payment_sequential int,
    payment_type varchar(20),
    payment_installments int,
    payment_value numeric(10, 2),
    primary key (order_id, payment_sequential)
);
-- order_reviews — FK → orders
-- composite primary key, not review_id alone: review_id has duplicate values
-- in the source data, but (review_id, order_id) is unique
create table order_reviews (
    review_id varchar(50),
    order_id varchar(50) references orders(order_id),
    review_score int,
    review_comment_title varchar(100),
    review_comment_message text,
    review_creation_date timestamp,
    review_answer_timestamp timestamp,
    primary key (review_id, order_id)
);

-- indexes on columns that are frequently used in queries
CREATE INDEX idx_orders_customer_id ON orders(customer_id);
CREATE INDEX idx_order_items_order_id ON order_items(order_id);
CREATE INDEX idx_order_items_product_id ON order_items(product_id);
CREATE INDEX idx_order_payments_order_id ON order_payments(order_id);
CREATE INDEX idx_order_reviews_order_id ON order_reviews(order_id);
