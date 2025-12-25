set search_path to "Customer Behavior"

SELECT min(date), max(date) from ecommerce_sales

-- top 10 customers with higest revenue ---
SELECT customer_id, 
       sum(unit_price * quantity) as revenue 
from ecommerce_sales
group by customer_id
order by revenue desc
limit 10

---- total number of orders in each month ----
select to_char(date, 'YYYY-mm') as Order_date, 
       count(distinct order_id) from ecommerce_sales
GROUP by to_char(date, 'YYYY-mm')
order by order_date 

----- total revnue by city ------
select city, 
       sum(unit_price * quantity) as revenue 
from ecommerce_sales
group by city
order by revenue

--- revenue by products -- 
select product_category, 
       sum(unit_price * quantity) as revenue 
from ecommerce_sales
group by product_category
order by revenue desc

---- top product with higest revenue by city
with cte as (
select city, 
       product_category, 
	   revenue, 
	   rank() over(partition by city order by revenue desc) as category_ranking
from (
select city, 
       product_category, 
	   sum(unit_price * quantity) as revenue from ecommerce_sales
group by city, product_category
)
)

select city, product_category, revenue from cte
where  category_ranking =1 
order by revenue desc

------ top purchasers per city ------
with product_purchased as (
select  city, 
        customer_id, 
		count(product_category) as total_product_purchased 
from ecommerce_sales
group by city, customer_id
),
highest_purchaser as (
select city, 
       customer_id, 
	   total_product_purchased,
	   dense_rank() over(partition by city order by total_product_purchased desc) as dk
from product_purchased
)

select city, customer_id, total_product_purchased from highest_purchaser
where dk = 1;

--- new vs repeat customer session avgerage --------
select 
       case when is_returning_customer = 'true' then 'returning customer' else 'new customer' 
	   end as newvsrepeat,
	   count(order_id) as total_orders,
	   sum(unit_price * quantity) as revenue,
       Round(avg(session_duration_minutes),2) as avg_time_spent 
from ecommerce_sales
group by case when is_returning_customer = 'true' then 'returning customer' else 'new customer' end;



select * from (
SELECT customer_id, 
       sum(unit_price * quantity) as revenue 
from ecommerce_sales
group by customer_id
order by revenue desc
limit 10
) a
inner join (select order_id, customer_id, date, city, unit_price, quantity from ecommerce_sales) e
on a.customer_id = e.customer_id
order by e.date

-- customers whose total spend is above the average customer spend -----
select 
    customer_id,
    sum(quantity * unit_price) as total_spent
	from ecommerce_sales
group by customer_id
HAVING sum(quantity * unit_price) > (select avg(customer_total_spent)
from (
select 
    sum(quantity * unit_price) as customer_total_spent 
	from ecommerce_sales
    group by customer_id
) as custtotals
)
order by total_spent desc


---- customer with most frequently purchased product category -----
with frequent as (
select customer_id,
       product_category,
	   count(*) as frequency,
	   rank() over(partition by customer_id order by count(*) desc) as rn
from ecommerce_sales
group by customer_id,
       product_category
)

select customer_id, 
       product_category, frequency
from frequent
where rn = 1
order by frequency desc

------ customers by age buckets (Teen, Young Adult, Middle Age, Senior) and revenue contribution ---- 
-- 18 - 39 young adult
-- 40 - 59 middle age
-- 60 - 75 senior citizen
select 
    case when age between 18 and 39 then 'Young Age' 
	     when age between 40 and 59 then 'Middle Age'
		 else 'Senior Citizen' 
	end as ages,
	round(sum(unit_price * quantity),2) as revenue_contribution
from ecommerce_sales
group by case when age between 18 and 39 then 'Young Age' 
	     when age between 40 and 59 then 'Middle Age'
		 else 'Senior Citizen' end
order by revenue_contribution desc

 --- weekly sales -------
SELECT TO_CHAR(date, 'YYYY-mm') as month,
       TO_CHAR(date, 'YYYY-WW') as week_number, 
       sum(unit_price * quantity) as total_sales FROM ecommerce_sales
group by TO_CHAR(date, 'YYYY-mm'), TO_CHAR(date, 'YYYY-WW')
order by total_sales desc

------ customers who made a purchase in the last 7 days but NOT between 8–30 days ago ---
select customer_id, order_id from ecommerce_sales
where date >= (select max(date) - interval '7 days'  from ecommerce_sales)
and customer_id not in (
select customer_id from ecommerce_sales
where date between (select max(date) from ecommerce_sales) - interval '30 days' 
           and (select max(date) from ecommerce_sales) - interval '8 days' )


-- for each city, the device type that generates the highest revenue ----
select * from (
select city, 
       device_type,
	   sum(quantity * unit_price) as revenue,
	   rank() over(partition by city order by sum(quantity * unit_price) desc) as rn
from ecommerce_sales
group by 
city, 
device_type
) a
where a.rn = 1

-- customers who placed orders every month for the last 3 months -- 

with max_month as (
select date_trunc('month', max(date)) max_month from ecommerce_sales
),
cust_months as (
select customer_id,
       date_trunc('month', date) as month_start
from ecommerce_sales, max_month
where date_trunc('month', date) >= max_month.max_month - interval '2 month'
      and date_trunc('month', date) <= max_month.max_month
group by customer_id, date_trunc('month', date)
order by customer_id
)
select customer_id
from cust_months
group by customer_id
having count(distinct month_start) = 3;

-- customers who placed more than 2 orders in a single day -- 
select customer_id, 
       date, 
	   count(*) as order_count
from ecommerce_sales
group by customer_id, date
having count(*) > 2

--- customers with increasing spend month-over-month (3 months trend) ---
with monthly_spent as (
select customer_id, 
       date_trunc('month', date)::date as month_start,
	   sum(total_amount) as montly_revenue
from ecommerce_sales
group by customer_id,  date_trunc('month', date)::date
order by customer_id, date_trunc('month', date)::date
),
previous_months as  (
select customer_id,
       month_start,
	   montly_revenue,
	   lag(montly_revenue, 1) over(partition by customer_id order by month_start) as prev_month,
	   lag(montly_revenue, 2) over(partition by customer_id order by month_start) as prev2_months
from monthly_spent 
)
select distinct customer_id from previous_months
where prev2_months is not null 
      and prev2_months < prev_month
	  and prev_month < montly_revenue

-- For each city, whether average delivery time is increasing month-over-month --
with avg_increasing as (
select city, 
       date_trunc('month', date)::date as month, 
	   Round(avg(delivery_time_days),2) as avg_delivery_time
from ecommerce_sales
where extract(year from date) = '2023'
group by city, date_trunc('month', date)::date
order by date_trunc('month', date)::date, city
),
inc_months as (
select city,
       month,
	   avg_delivery_time,
       lag(avg_delivery_time, 1) over(partition by city order by month) as month_1,
	   lag(avg_delivery_time, 2) over(partition by city order by month) as month_2,
	   lag(avg_delivery_time, 3) over(partition by city order by month) as month_3,
	   lag(avg_delivery_time, 4) over(partition by city order by month) as month_4,
	   lag(avg_delivery_time, 5) over(partition by city order by month) as month_5,
	   lag(avg_delivery_time, 6) over(partition by city order by month) as month_6,
	   lag(avg_delivery_time, 7) over(partition by city order by month) as month_7,
	   lag(avg_delivery_time, 8) over(partition by city order by month) as month_8,
	   lag(avg_delivery_time, 9) over(partition by city order by month) as month_9,
	   lag(avg_delivery_time, 10) over(partition by city order by month) as month_10,
	   lag(avg_delivery_time, 11) over(partition by city order by month) as month_11

from avg_increasing
)
select distinct city from inc_months
where month_11 is not null 
     and month_11 < month_10 and month_10 < month_9 and month_9 < month_8
      and month_8 < month_7 and month_7 < month_6 and month_6 < month_5 and month_5 < month_4
	  and month_3 < month_2 and month_2 < month_1 and month_1 < 


--- Rank customers by revenue within each age group. ---
with buckets as (
select customer_id, 
    case when age between 18 and 39 then 'Young Age' 
	     when age between 40 and 59 then 'Middle Age'
		 else 'Senior Citizen' 
	end as ages,
	total_amount
from ecommerce_sales
),
higest_generater as (
select customer_id, 
       ages, 
	   sum(total_amount),
	   dense_rank() over(partition by ages order by sum(total_amount) desc) as dk
from buckets
group by customer_id,
         ages
		 )

select * from higest_generater
where dk <= 10
order by ages

-- longest monthly purchase streak per customer ---
with monthly as (
select distinct customer_id,
       date_trunc('month', date)::date as month
from ecommerce_sales
),
indexed as (
select customer_id,
       month,
	   extract(year from month)::int*12 + extract(month from  month)::int as month_num,
	   row_number() over(partition by customer_id order by month) as rn
from monthly
),
streaks as (
select customer_id,
       month,
	   month_num - rn as grp
from indexed
),
streak_length as (
select customer_id,
       grp, 
	   count(*) as streak_length,
	   min(month) as streak_start,
	   max(month) as streak_end
	   from streaks
group by customer_id, grp
)
SELECT distinct on (customer_id)
    customer_id,
    streak_length AS longest_monthly_streak,
    streak_start,
    streak_end
FROM streak_length
order BY customer_id, streak_length desc;

-- AOV between customers on Mobile vs Desktop using window functions. ---
select 
      customer_id,
	  device_type,
	  round(avg(total_amount) over(partition by customer_id, device_type),2) as avg_value
from ecommerce_sales

-- customers whose last order happened more than 60 days ago ---- 

with last_order as (
select e.customer_id,
       e.date,
	   a.max_date,
	   lag(date, 1) over(partition by e.customer_id order by e.date) as prev_order_date,
	   e.date - lag(e.date, 1) over(partition by e.customer_id order by date) as days
from ecommerce_sales e
inner join 
(
select customer_id, 
       max(date) as max_date 
from ecommerce_sales
group by customer_id
) a on e.customer_id = a.customer_id 
)

select  distinct customer_id, days from last_order
where date = max_date and days > 60
order by days DESC




