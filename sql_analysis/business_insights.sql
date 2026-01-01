use `olist_e_commerce`;
-- --     1)delivery & (logistics) performance     -- --
-- Q1) Are all orders delivered on time?
select 
case when `order_delivered_customer_date` <= `order_estimated_delivery_date`
then "On Time" else "Late" end  as delivery_status ,count(*) as total_orders  from orders 
where `order_delivered_customer_date` is not null
group by delivery_status;
-- Approximately 8% of orders were delivered after the expected date.
-- -----------------------------------------------
-- Q2) Average & max delay for late orders
select count(*) as delayed_orders,
round(avg(datediff(`order_delivered_customer_date`,`order_estimated_delivery_date`)),2) AS avg_delay_days,
max(datediff(`order_delivered_customer_date`,`order_estimated_delivery_date`)) as max_delay_days
from orders 
where `order_delivered_customer_date` is not null 
and `order_delivered_customer_date`>`order_estimated_delivery_date`;
-- While  8% of  orders were delayed, those orders arrived 8.9 days late on average, 
-- with max_delay_days up to 188 days, 
-- -----------------------------------------------
-- Q3) Does this delay affect reviews?
select 
case when orders.`order_delivered_customer_date`>orders.`order_estimated_delivery_date` then "Late" else "On Time" end
as delivery_status,
count(order_reviews.`review_score`) as total_reviews,
round(avg(order_reviews.`review_score`),2) as avg_score
from orders join order_reviews on orders.order_id=order_reviews.order_id
where orders.`order_delivered_customer_date` is not null 
group by delivery_status;
-- Orders delivered after the estimated date receive  moderately lower review scores
-- -----------------------------------------------
-- Q4) state-level delay, rate, avg delay & reviews 
-- is the huge delay in remote states affect review_score ?
-- what is the delay_rate in each state? 
-- Does the delay vary depending on the state?
-- what is the avg_delay_days in each state?
select customer_state as state ,
sum(case when `order_delivered_customer_date`> orders.`order_estimated_delivery_date` then 1 else 0 end )
as count_late_orders,
count(*) as total_orders,
round(sum(case when `order_delivered_customer_date`> orders.`order_estimated_delivery_date` then 1 else 0 end )
*100/count(*),2) as delay_rate,
round(avg( case when `order_delivered_customer_date`>`order_estimated_delivery_date` 
       then datediff(`order_delivered_customer_date`,`order_estimated_delivery_date`) end ),2)  as avg_delay_days,
round(avg(`review_score`),2) as avg_score
from order_reviews  join orders  on orders.order_id=order_reviews.order_id join customers 
on  customers.`ï»؟customer_id`=orders.customer_id
where `order_delivered_customer_date` is not null 
group by state
order by avg_delay_days desc ;
-- Customer satisfaction remains relatively stable across all Brazilian states,
-- meaning Overall, customer satisfaction during the state was fairly stable. 
-- with average review scores ranging from 3.58 to 4.20, even in remote regions
-- Delivery delays are not uniformly distributed across states.
--  While large commercial hubs eg(SP) handle high order volumes with relatively low delay rates, 
--  indicating stable logistics performance under scale
-- In contrast, several mid-volume states eg(RJ,BA,CE,MA,AL) exhibit disproportionately high delay rates,
-- suggesting operational inefficiencies that may have a stronger impact on customer experience and reviews.
-- Remote states eg(AP,AC) exhibit extreme delays but low overall business impact due to limited order volume.
-- ------------------------------------------------
-- Low-volume states with extreme delays
-- Q5) Do distance and extreme delivery delays negatively affect customer engagement in low-volume states
select customer_state as state ,
count(*) as total_orders, 
round(avg( case when `order_delivered_customer_date`>`order_estimated_delivery_date` 
       then datediff(`order_delivered_customer_date`,`order_estimated_delivery_date`) end ),2)  as avg_delay_days,
round(avg(`review_score`),2) as avg_score
from order_reviews  join orders  on orders.order_id=order_reviews.order_id join customers 
on  customers.`ï»؟customer_id`=orders.customer_id
where `order_delivered_customer_date` is not null 
group by state
having total_orders <300
order by  avg_delay_days desc;
-- Low-volume and remote states exhibit extreme average delivery delays,
-- however, their overall business impact remains limited due to the small number of orders.
-- Despite long delays, average review scores remain relatively stable,
-- suggesting that distance-related delays do not significantly discourage customer engagement in these regions.
-- As a result, While these states experience extreme delays, 
-- their limited order volume suggests a lower short-term business impact compared to high-volume regions.
-- ------------------------------------------------
-- Q6)Is the seller playing role in delayed  oders?
with delay_parts as (
select order_id , datediff(o.order_delivered_carrier_date,o.order_approved_at)
     as handling_days, 
     datediff(`order_delivered_customer_date`,o.order_delivered_carrier_date)
     as logistics_days,
     datediff(`order_approved_at`,`order_purchase_timestamp`)
     as approved_days , customer_state ,
     datediff(`order_delivered_customer_date`,order_purchase_timestamp) as total_days
     from orders o join customers c on o.customer_id=c.`ï»؟customer_id`
where `order_delivered_customer_date`>`order_estimated_delivery_date` 
and `order_delivered_customer_date` is not null
and o.order_approved_at is not null 
and o.order_delivered_carrier_date is not null )
select 
case when handling_days/total_days>=0.6 then 'Seller Dominated'
when logistics_days/total_days>=0.6 then 'Logistics Dominated'
else 'Mixed Responsibility' end as delay_source,
count(*) as delayed_orders,
 round(count(*) * 100.0 / sum(count(*)) over(), 2) as pct_of_delays
from delay_parts group by delay_source;
-- although, around 9% of delayed orders is seller-dominated by up to 60% but still
-- logistics distance is dominated in delivery delays (82% of delayed orders is logistics-dominated by up to 60%)
-- ----------------------------------------------------------------------------------
-- --              2)Seller Performance     -- --  
-- Q1)Who are the sellers with the most number of delayed orders?
select seller_id, round(avg(case when `order_estimated_delivery_date`> `order_approved_at` 
then datediff(`order_delivered_carrier_date`,`order_approved_at`) end),2) as avg_handeling_days,
sum(case when `order_estimated_delivery_date`<`order_delivered_customer_date` then 1 else 0 end)
as num_delayed_orders,
round(avg(case when `order_estimated_delivery_date`<`order_delivered_customer_date` 
then datediff(`order_delivered_customer_date`,`order_estimated_delivery_date`) else 0 end),2)
as delayed_orders_days,
round(avg(datediff(`order_delivered_customer_date`,`order_delivered_carrier_date`)),2)
as avg_logistics_days
from orders join orders_items on orders.order_id=orders_items.order_id
group by seller_id
order by num_delayed_orders desc
limit 10;
--  but Obviously that logistics play a major role than seller handling in delay  
-- -----------------------------------------------------------------
-- Q2) Who are the sellers whose poor performance play major role than logistics in delay?
select  seller_id, sum(case when `order_estimated_delivery_date`<`order_delivered_customer_date` 
then 1 else 0 end) as delayed_orders,
round(avg(datediff(`order_delivered_carrier_date`,`order_approved_at`)),2)
     as handling_days, 
     round(avg(datediff(`order_delivered_customer_date`,o.order_delivered_carrier_date)),2)
     as logistics_days,
     round(avg(datediff(`order_delivered_customer_date`,order_purchase_timestamp)),2) as avg_days,
	round(avg(datediff(o.order_delivered_carrier_date,o.order_approved_at))
    *100/avg(datediff(`order_delivered_customer_date`,order_purchase_timestamp)),2)as handling_pct
     from orders o join orders_items oi on o.order_id=oi.order_id
where `order_delivered_customer_date`>`order_estimated_delivery_date` 
and `order_delivered_customer_date` is not null
and o.order_delivered_carrier_date is not null 
group by seller_id
having delayed_orders >=10 and handling_pct>=60
order by handling_pct desc;
-- these sellers cause more than 60% of the total delay time as handling days
-- -------------------------------------------------------------------
-- I noticed in data in some orders that order_estimated_delivery_date<order_delivered_carrier_date
-- who are the sellers that responsible for this ?? and number of these orders ??
select seller_id,sum(case when  `order_estimated_delivery_date`<`order_delivered_carrier_date` then 1 else 0 end) as
num_very_delayed_orders , count(*) as total_orders , 
sum(case when  `order_estimated_delivery_date`<`order_delivered_carrier_date` then 1 else 0 end)
*100/count(*)as delay_after_estimated_rate
from orders_items oi join orders o on o.order_id=oi.order_id
group by  seller_id
having  delay_after_estimated_rate>30 and num_very_delayed_orders>5
order by num_very_delayed_orders desc;
-- These sellers are responsible for shipping the largest possible number of orders after
-- the expected delivery date.
-- Most delays are logistics-related, but a small subset of sellers are significant contributors
-- -----------------------------------------------------------------------------------------
-- --              3)Customer Behavior & Satisfaction         -- --
-- Q1)who are the customers whose orders were delivered after estimated and ordered again 
-- and what is  thier avg score?
-- and what is the Average number of days delayed after the expected date??
select   o.customer_id ,
sum(case when  `order_estimated_delivery_date`<`order_delivered_customer_date` then 1 else 0 end) as
num_delayed_orders,count(o.order_id) as total_orders,round(avg(`review_score`)) as score ,
round(avg(datediff(`order_delivered_customer_date`,`order_estimated_delivery_date`)),2) as delay_days
from orders o join order_reviews r  on o.order_id=r.order_id
group by o.customer_id
having  num_delayed_orders>0 and total_orders>1
order by delay_days desc, score desc;
-- The highest number of times they ordered from the site was 2 (just another time)
-- ---------------------------------------------------------------
-- but even the customers whose all orders were on time ,
-- the highest number of times they ordered from the site was 2
select   o.customer_id ,
sum(case when  `order_estimated_delivery_date`<`order_delivered_customer_date` then 1 else 0 end) as
num_delayed_orders,count(o.order_id) as total_orders,round(avg(`review_score`)) as score 
from orders o join order_reviews r  on o.order_id=r.order_id
group by o.customer_id
having  num_delayed_orders=0 
order by  total_orders desc;
-- ---------------------------------------------------------------
-- 	Q2)what the avg score for every group of them ??
select
    case
        when num_delayed_orders = total_orders then 'All Orders Delayed'
        when num_delayed_orders = 0 then 'No Delays'
        else 'Mixed'
    end as delay_experience,
    round(avg(score),2) as avg_score,
    count(*) as customers
from (
    select
        o.customer_id,
        count(o.order_id) as total_orders,
        sum(case when o.order_delivered_customer_date > o.order_estimated_delivery_date then 1 else 0 end) as num_delayed_orders,
        avg(r.review_score) as score
    from orders o
    join order_reviews r on o.order_id = r.order_id
    group by o.customer_id
) t
group by delay_experience;
-- It is clear that the customers are divided into those whose all orders were delayed
-- and those whose all orders were on time.
--  It is clear that  the delay affects the score.
-- ---------------------------------------------------------------------
-- why?? is this  from the distance or seller??
select
    seller_id,
    customer_state,
    delayed_orders,
    avg_delay_days,
    round(
        avg_delay_days -
        avg(avg_delay_days) over (partition by customer_state)
    ,2) as diff_from_state_avg
from (
    select
        oi.seller_id,
        c.customer_state,
        count(*) as delayed_orders,
        avg(datediff(o.order_delivered_customer_date,
                     o.order_estimated_delivery_date)) as avg_delay_days
    from orders o
    join orders_items oi on o.order_id = oi.order_id
    join customers c on o.`customer_id` = c.`ï»؟customer_id`
    where o.order_delivered_customer_date > o.order_estimated_delivery_date
    group by oi.seller_id, c.customer_state 
) t
where delayed_orders >= 10 
order by diff_from_state_avg desc;
-- By benchmarking sellers against the average delay behavior within the same customer state,
-- we identified a subset of sellers whose delays significantly exceed the regional norm.Since و
-- these sellers operate under the same logistical conditions,the excessive delays 
-- are likely driven by seller-side operational inefficiencies rather than distance-related logistics
-- ----------------------------------------------------------------------------------------
-- --            4)about the system of the site       -- -- 
-- Q1)what is the avg delay days for approval the orders??
select
    case
        when datediff(order_approved_at, order_purchase_timestamp) <= 1 then 'Same or Next Day'
        when datediff(order_approved_at, order_purchase_timestamp) <= 7 then 'Within a Week'
        else 'More than a Week'
    end as approval_bucket,
    count(*) as orders_count,
    round(count(*) * 100.0 / sum(count(*)) over (),2) as pct_of_orders,
    round(avg(datediff(order_approved_at, order_purchase_timestamp)),2) as avg_delay_days
from orders
where order_approved_at is not null
group by approval_bucket;
--  87% of orders approved within the same or next day.13% of orders approved within a week
-- While a small fraction of orders (0.05%) experience approval delays exceeding one week (13 days as avg),
--  these cases are extremely rare and do not reflect the system’s typical performance
-- ---------------------------------------------------------------------
-- --                 5) payments & revenue impact         -- --
-- Q1)What are the most commonly used payment methods?
-- )Does payment type affects  revenue?
-- )Does the expensive orders paid by specific payment type?
select `payment_type` , count(*) as count , 
round(sum(`payment_value`),2) as total_revenue ,
round(avg(`payment_value`),2) as avg_order_value  from payments
group by `payment_type` order by count desc;
-- credit_card is the most payment type used even with expensive orders
-- no relation between payment type and revenue
-- credit cards dominate both order volume and revenue, making them the most critical payment method for business stability.
-- ---------------------------------------------------------------
-- Q2) Does the price affect buying 
select
    case 
        when p.payment_value < 100 then 'Low Value'
        when p.payment_value between 100 and 300 then 'Medium Value'
        else 'High Value'
    end as order_value_group,
    count(*) as total_orders
from  payments p 
group by order_value_group
order by total_orders desc;
-- It is normal that The higher the price, the lower the demand for it
-- ---------------------------------------------------------------
-- Q3)Do expensive orders get paid in installments more often?
select
    case 
        when p.payment_value < 100 then 'Low Value'
        when p.payment_value between 100 and 300 then 'Medium Value'
        else 'High Value'
    end as order_value_group,
    round(avg(p.payment_installments),2) as avg_installments,
    count(*) as total_orders
from payments p
group by order_value_group
order by avg_installments desc;
-- Higher-value orders are more likely to be paid in multiple installments, 
-- indicating customer price sensitivity for expensive purchases
-- ---------------------------------------------------------------
-- Q4)Do installments affect revenue?
select
    case 
        when payment_installments = 1 then 'Single Payment'
        else 'Installments'
    end as payment_mode,
    count(*) as total_orders,
    round(avg(payment_value),2) as avg_order_value,
    round(sum(payment_value),2) as total_revenue
from payments
group by payment_mode;
-- installment options encourage customers to purchase more expensive items
-- leading to more revenue
-- --------------------------------------------------------------------------------------
-- --                             6)Cancelation        -- -- 
-- Q1) when did the most cancelations happen?? 
select
    case 
        when order_approved_at is null then 
        'Before Approval'
        when order_approved_at is not  null and  `order_delivered_carrier_date` is  null 
        then 'before carrier'
        when  `order_delivered_carrier_date` is not  null and `order_delivered_customer_date` is null
        then 'after carrier' end as cancel_stage,
    count(*) as canceled_orders
from orders
where order_status='canceled'
group by cancel_stage;
-- Most order cancellations occur after payment approval but before carrier 
-- This suggests that cancellations are likely driven by seller-side delays
-- or order processing issues rather than delivery distance or logistics performance.
-- -------------------------------------------------------------
-- Does the price affect??
select
    case 
        when p.payment_value < 100 then 'Low Value'
        when p.payment_value between 100 and 300 then 'Medium Value'
        else 'High Value'
    end as order_value_group,
    count(*) as total_orders,
    sum(case when o.order_status = 'canceled' then 1 else 0 end) as canceled_orders,
    round(sum(case when o.order_status = 'canceled' then 1 else 0 end)*100.0/count(*),2) as cancel_rate
from orders o
join payments p on o.order_id = p.order_id
group by order_value_group
order by cancel_rate desc;
-- low value orders are the most cancelation most requested , and most paid one singe payment
-- ------------------------------------------------------------
-- Does away estimated_delivery_date  affect ?  
select customer_state as state,count(*) as total_orders,
sum(case when order_status ='canceled' then 1 else 0 end )as canceled_orders,
round(sum(case when order_status = 'canceled' then 1 else 0 end) * 100.0 / count(*),2) as cancel_rate,
round(avg(datediff(`order_estimated_delivery_date`,`order_purchase_timestamp`)),2) as avg_estimmated_days
from customers join orders on  customers.`ï»؟customer_id`=orders.customer_id
group by customer_state
order by  avg_estimmated_days desc;
-- although avg_estimmated_days is large , the cancel rate is low  
-- --------------------------------------------------------------
-- Q2)who the customers with the most cancelation 
select  o.`customer_id`,count(*) as total_orders_canceled
from orders o
where `order_status` = 'canceled'
group by o.`customer_id`
order by total_orders_canceled desc;
-- Order cancellations are not driven by repeated behavior from specific customers; 
-- cancellations appear to be isolated, one-off events rather than habitual customer behavior
-- --------------------------------------------------------------
-- Q3)which months with most cancelation??
select month(`order_purchase_timestamp`) as _month, count(*) canceled_orders,
round(count(*) * 100.0 / sum(count(*)) over (), 2) as pct_of_total_orders
from orders where `order_status`='canceled' group by _month order by canceled_orders desc;
-- Cancellation rates vary significantly by month, with August, February,
-- and July showing the highest proportion of canceled orders. 
-- This indicates potential seasonal issues, such as supply chain delays, promotional campaigns,
-- or payment failures, which should be investigated to minimize losses. December shows the lowest cancellation rate,
-- suggesting more stable operations during this period
-- ----------------------------------------------------------------------------------------
-- --                      7)Products & categories        -- -- 
-- Q1) What are the most and least 10 orderd products in each category ?
with products_orderd as (
select `product_category_name_english` as category ,p.`product_id` as product, count(*) as ordered_times
from orders_items oi join products p on p.`product_id`=oi.`product_id` 
join `product_category_name_translation` pt on pt.`product_category_name`=p.`product_category_name`
group by `product_category_name_english`,p.`product_id`)
, ranked as (
select * , row_number() over (partition by category order by ordered_times desc) as ranked_desc,
row_number() over (partition by category order by ordered_times ) as ranked_asc
from products_orderd
)
select 
    category,
    product,
    ordered_times
from ranked
where ranked_desc <=10 or ranked_asc <=10
order by  category;
-- -------------------------------------------------------------
-- Q2)what is the average price per category?
select `product_category_name_english` as category , avg(price) as avg_price , count(*) as total_orders
from `product_category_name_translation` pt  join products p on p. `product_category_name`=
pt.`product_category_name` join orders_items oi on p.product_id=oi.product_id
group by category order by avg_price  desc;
-- Computers stands out as a high-value category with the highest average item price (~1098),
-- despite having a relatively low number of items sold (203). 
-- This suggests that computer-related products are positioned as premium items with lower purchase frequency but higher value per sale
-- In contrast, categories such as Home Appliances , Watches Gifts  and Cool_Stuff show significantly lower average prices but higher sales volumes, indicating more accessible pricing and broader customer demand.
-- ---------------------------------------------------------------------
-- Q3)what are the top 4 ordered products per season?
-- Seasonality is based on shipping date, which may slightly differ from purchase date
with sesson_products as (select case when  month(`shipping_date`) in (1,2,3) then "winter" 
when  month(`shipping_date`) in (4,5,6) then "spring" 
when month(`shipping_date`) in (7,8,9) then "summer" 
else "autumn" end as season,
p.product_id  as product ,`product_category_name_english` as category,
count(*) as total_orders
from  products p  join orders_items oi on p.product_id=oi.product_id 
join `product_category_name_translation` pt  on p.`product_category_name`= pt.`product_category_name`
group by season,product ),
ranked as (select * ,row_number()over(partition by season order by total_orders desc) as ranked_products_season
from sesson_products )
select season,product,category,total_orders from ranked where ranked_products_season<=4;
-- 1)Product demand shows clear seasonal patterns, with different categories dominating each season, 
-- indicating that customer purchasing behavior is influenced by seasonal needs
-- 2)Garden Tools dominate autumn and summer seasons,
--  reflecting increased demand for outdoor maintenance and gardening activities during these periods
-- 3)During winter, Furniture Decor and Computer Accessories emerge as top-selling products,
--  suggesting a shift toward indoor-related purchases
-- These seasonal trends can be leveraged for inventory planning, seasonal promotions, 
-- and targeted marketing campaigns to align product availability with customer demand.
-- -------------------------------------------------------------------------------------
-- --                            8) needed Offers           -- --
-- Q1) which months needs offers?
select month(`order_purchase_timestamp`)as purchase_month, count(*) as total_orders ,
round(count(*) * 100.0 / sum(count(*)) over (), 2) as pct_of_orders
from orders group by purchase_month order by total_orders ;
-- Order volume varies significantly by month, 
-- with September and October showing the lowest number of purchases
-- These months represent off-peak periods and are strong candidates 
-- for promotional campaigns to stimulate customer demand
-- -----------------------------------end------------------------------------------------
