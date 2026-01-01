create database olist_e_commerce;
use olist_e_commerce;
-- min date for date dim
SELECT min(date(`order_purchase_timestamp`)) FROM `olist_e_commerce`.`orders`;
-- max date for date dim
SELECT greatest(max(date(`order_approved_at`)),max(date(`order_delivered_carrier_date`)),
max(date(`order_delivered_customer_date`)),max(date(`order_estimated_delivery_date`))) FROM `olist_e_commerce`.`orders`;

create table date_dim(
  date_id date  primary key ,
  day int ,
  month int ,
  year int ,
  quarter int ,
  weekday_name varchar(20),
  is_weekend bool
);
insert into date_dim
(
  date_id,
  day,
  month,
  year,
  quarter,
  weekday_name,
  is_weekend
)
-- fill date dim from min date to max date with loop(CTE)
with recursive date_series as(
select date('2016-09-04') as dt
union all
select dt + interval 1 day 
from date_series
where dt < '2018-11-12'
)
select dt,DAY(dt),MONTH(dt),YEAR(dt),QUARTER(dt),DAYNAME(dt),
case 
when DAYOFWEEK(dt) in (1,7) then 1 
else 0 end 
from date_series;
-- to check 
-- select * from date_dim order by date_id  limit 7;
-- adding date columns in orders table without modifying the original (datetime)to join with date_dim
alter table orders
add column order_purchase_date DATE,
add column order_approved_date DATE,
add column order_carrier_date DATE,
add column order_delivered_date DATE,
add column order_estimated_date DATE;
SET SQL_SAFE_UPDATES = 0;
update orders 
set  order_purchase_date=date(`order_purchase_timestamp`),
order_approved_date=date(`order_approved_at`),
order_carrier_date=date(`order_delivered_carrier_date`),
order_delivered_date=date(`order_delivered_customer_date`),
order_estimated_date=date(`order_estimated_delivery_date`);
-- also in order_reviews
alter table order_reviews
add column creation_date DATE,
add column answer_date DATE;
update  order_reviews
set  creation_date=date(`review_creation_date`),
answer_date=date(`review_answer_timestamp`);
-- also in order_items
alter table orders_items
add column shipping_date DATE;
update  orders_items
set  shipping_date=date(`shipping_limit_date`);



