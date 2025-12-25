
# Revenue Trends & Customer Behavior in E-Commerce

This case study analyzes an end-to-end Retail sales dataset to uncover customer behavior patterns, revenue drivers, and operational inefficiencies, and to build data-driven models that support strategic business decisions.

Using transactional, demographic, behavioral, and operational attributes, the analysis focuses on customer segmentation, sales forecasting, recommendation systems, customer lifetime value (CLV), churn prediction, marketing optimization, price sensitivity, and delivery performance.

The objective is to demonstrate how structured data analysis can translate raw sales data into actionable business insights that improve customer retention, revenue growth, and operational efficiency.

## Problem Statements

The business experiencing uneven revenue growth and inconsistent customer retention across cities and product categories. While large volumes of transactional and behavioral data are available, the business lacks clear visibility into customer segments, purchasing behavior, pricing effectiveness, and delivery performance.
This case study aims to analyze sales, customer, and operational data to identify key revenue drivers, customer segments, churn risks, and optimization opportunities, enabling data-driven decisions to improve customer retention, sales growth, and operational efficiency.

## Dateset Overview

The dataset contains 18 columns, and 22049 records capturing a comprehensive view of:

* Customer demographics (Age, Gender, City)

* Transaction details (Order ID, Date, Product Category, Quantity, Price)

* Behavioral metrics (Device Type, Session Duration, Pages Viewed)

* Operational metrics (Delivery Time, Customer Rating)

* Financial metrics (Discount Amount, Total Amount)

* Retention indicators (Returning Customer flag)

### Data Quantity

 * No missing values

 * Consistent formatting across all fields

 * Realistic data distributions

 * Proper data types for all columns

* Logical relationships between features

## Analysis & SQL insights

#### Top 10 customers with higest revenue

```sql
SELECT customer_id, 
       sum(unit_price * quantity) as revenue 
from ecommerce_sales
group by customer_id
order by revenue desc
limit 10;
```

#### Total number of orders in each month

```sql
select to_char(date, 'YYYY-mm') as Order_date, 
       count(distinct order_id) from ecommerce_sales
GROUP by to_char(date, 'YYYY-mm')
order by order_date 
```

#### Revenue by city

```sql
select city, 
       sum(unit_price * quantity) as revenue 
from ecommerce_sales
group by city
order by revenue
```

<img width="977" height="548" alt="Image" src="https://github.com/user-attachments/assets/fb75c519-fc6b-4f69-b929-6304c0f09290" />

* Cities like Istanbul, Ankara, Izmir countributes 52% of total revenue

#### Revenue by product categories

```sql
select product_category, 
       sum(unit_price * quantity) as revenue 
from ecommerce_sales
group by product_category
order by revenue desc
```
* Electronics contributes the higest i.e 47% of the total revenue followed by 18% of Home & Garden produts and 14% of Sports products

#### Product with higest revenue in each City

```sql
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
```
* Since the Electronics contributes 47% of revenue, each city has Electronics products as the higest revenue generator

#### Top Purchasers per city

```sql
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
```

#### New vs Returning customers

```sql
select 
       case when is_returning_customer = 'true' then 'returning customer' else 'new customer' 
	   end as newvsrepeat,
	   count(order_id) as total_orders,
	   sum(unit_price * quantity) as revenue,
       Round(avg(session_duration_minutes),2) as avg_time_spent 
from ecommerce_sales
group by case when is_returning_customer = 'true' then 'returning customer' else 'new customer' end;

```

| Customer Type        | Total Orders | Revenue (₹)     | Avg Time Spent (mins) |
|----------------------|--------------|------------------|-----------------------|
| Returning Customer   | 18,029       | 23,263,417.65   | 14.53                 |
| New Customer         | 4,020        | 4,745,261.45    | 14.62                 |

* The Returning customers generator the higest revenue for the business, nearly 81%, Though the avg_time_spent is little higer for new customers

#### Customers whose total spent is above the average customers spent

```sql
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
```

* Over 35% customers are spending above the overall average of all customers, These customers are valuable to the business

####  Customers with most frequently purchased products

```sql
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
```

* Beauty, Electronics and books as frequently purchased 

#### Revenue generated by age group

```sql
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
```
<img width="990" height="663" alt="Image" src="https://github.com/user-attachments/assets/92964372-3345-4880-a7a2-5990ddab0eda" />

| Age Group        | Revenue Contribution (₹) |
|------------------|--------------------------|
| Young Age        | 18,426,416.77            |
| Middle Age       | 9,134,864.22             |
| Senior Citizen   | 447,398.11               |

* The Young customers i.e 18-39 age group countributes the higest to the business

#### Customers who made a purchase in the last 7 days but NOT between 8–30 days ago

```sql
select customer_id, order_id from ecommerce_sales
where date >= (select max(date) - interval '7 days'  from ecommerce_sales)
and customer_id not in (
select customer_id from ecommerce_sales
where date between (select max(date) from ecommerce_sales) - interval '30 days' 
           and (select max(date) from ecommerce_sales) - interval '8 days' )

```
* Over 267 customers made a purchase in last 7 days, but they did not made any order in 8 to 30 days

#### Customers who placed orders every month for the last 3 months 

```sql
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
```
* Only 1.7% customers have made order every month for the last 3 months, This number is very low for the business and should be considerd for improving the sales.

#### Customers with increasing spend month-over-month (3 months trend)

```sql
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

```

#### longest monthly purchase streak per customer

```sql
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
```

####  customers whose last order happened more than 60 days ago

```sql
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

```

*  Nearly 54% of the customers took more than 60 days to make their next order

#### Revenue By Gender

<img width="987" height="661" alt="Image" src="https://github.com/user-attachments/assets/e9706c2c-fd2a-49d1-ad46-d2c00d508706" />

## Dashboard

<img width="999" height="567" alt="Image" src="https://github.com/user-attachments/assets/8a68e4d8-2261-4e8c-ba00-fbda41d6d48b" />


# Recommendations & Business Actions

## Double-down on High-Value Returning Customers

* Launch a loyalty & rewards program (early access, cashback, free delivery)

* Introduce personalized recommendations for returning users based on past categories

* Trigger email / push offers after every successful order to encourage repeat purchases

#### Expected Impact:
* Higher retention → increased Customer Lifetime Value (CLV) → stable revenue growth

## Fix Low Repeat Purchase Rate (Critical Risk Area)

* Implement 30-day re-engagement campaigns (discounts, reminders, recommendations)

   Add time-based nudges:

   * Day 20 → Reminder

   * Day 45 → Offer

   * Day 60 → Win-back campaign

Segment customers by purchase gap and treat long-gap users as churn-risk

Expected Impact:
* Reduced churn and higher monthly active customers (MAU)

## City-Focused Growth Strategy

* Strengthen logistics and inventory planning in top revenue cities

* Pilot hyper local promotions in high-performing cities

* Use city wise top purchasers as look alike audiences for acquisition

Expected Impact:
* Scalable growth with lower operational risk

## Convert High-Engagement New Customers

* Improve first-purchase experience (simpler checkout, onboarding offers)

* Add first-order incentives with limited validity

* Show best-selling products instead of generic listings to new users

Expected Impact:
* Higher first-to-second order conversion

