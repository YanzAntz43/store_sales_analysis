

CREATE TABLE sales_store (
	transaction_id varchar(15),
	customer_id varchar(15),
	customer_name varchar(50),
	customer_age int,
	gender varchar(15),
	product_id varchar(15),
	product_name varchar(50),
	product_category varchar(15),
	quantiy int,
	prce float,
	payment_mode varchar(15),
	purchase_date date,
	time_of_purchase time,
	status varchar(15)
)

select * from sales_store

set dateformat dmy
bulk insert sales_store
from 'I:\sql projects\Data cleaning\ANKIT RAZ MISHRA\sales_store_updated_allign_with_video.csv'
with (
	firstrow = 2,
	fieldterminator = ',',
	rowterminator = '\n'
 );

 -- Before cleaning data we make temporary table so original data will be safe

 select * into sales1 from sales_store

 select * from sales1

 -- Step 1: check and Remove duplicates
select transaction_id, count(*)
from sales1
group by transaction_id
having count(transaction_id) > 1

with CTE as (
	select *,
		   ROW_NUMBER() over (partition by transaction_id order by transaction_id) as Row_Num
	from sales1
)
select * from CTE
where transaction_id in ('TXN240646', 'TXN342128', 'TXN855235', 'TXN981773')

-- or

WITH ranked_sales AS (
    SELECT
        *,
        ROW_NUMBER() OVER (
            PARTITION BY transaction_id
            ORDER BY transaction_id
        ) AS rn
    FROM sales1
)
SELECT *
FROM ranked_sales
WHERE rn > 1;

-- to delete duplicates

with cte as 
(select *, ROW_NUMBER() over(partition by transaction_id
order by transaction_id) as Row_Num
from sales1)
delete from cte
where Row_Num = 2

-- or

WITH ranked_sales AS (
    SELECT
        transaction_id,
        ROW_NUMBER() OVER (
            PARTITION BY transaction_id
            ORDER BY transaction_id
        ) AS rn
    FROM sales1
)
DELETE FROM ranked_sales
WHERE rn = 2


-- Step 2: Correction oh headers
EXEC sp_rename'sales1.quantiy', 'quantity', 'COLUMN'

EXEC sp_rename'sales1.prce', 'price', 'COLUMN'

-- step 3: to check data types of each column
select COLUMN_NAME, DATA_TYPE
from INFORMATION_SCHEMA.COLUMNS
where TABLE_NAME = 'sales1'


-- step 4: to check for null values in each column

-- check the null count first part
DECLARE @SQL NVARCHAR(MAX) = '';

SELECT @SQL = STRING_AGG(
'SELECT ''' + COLUMN_NAME + ''' AS ColumnName, 
COUNT(*) AS NullCount
FROM ' + QUOTENAME(TABLE_SCHEMA) + '.sales1
WHERE ' + QUOTENAME(COLUMN_NAME) + ' IS NULL',
' UNION ALL '
)
WITHIN GROUP (ORDER BY COLUMN_NAME)
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'sales1';

-- Execute the dynamic SQL
EXEC sp_executesql @SQL;


-- treating the null values

select *
from sales1
where transaction_id is null
or
customer_id is null
or
customer_name is null
or
customer_age is null
or
gender is null
or
product_id is null
or
product_name is null
or
product_category is null
or
quantity is null
or
payment_mode is null
or
purchase_date is null
or
status is null
or
price is null

--  Delete the outliers that exist
delete from sales1
where transaction_id is null

-- treating null  values
select * from sales1
where customer_name = 'Ehsaan Ram'

update sales1
set customer_id = 'CUST9494'
where transaction_id = 'TXN977900' --(same row with transaction id that customer_id is null)

select * from sales1
where customer_name = 'Damini Raju'

update sales1
set customer_id = 'CUST1401'
where transaction_id = 'TXN985663'

select * from sales1
where customer_id = 'CUST1003'

update sales1
set customer_name = 'Mahika Saini', customer_age = 35, gender = 'Male'
where transaction_id = 'TXN432798'

select * from sales1

-- Step 5: Data Cleaning for ex: in gender column F and Female, suppose only i syllable is required

select distinct  gender
from sales1

update sales1
set gender = 'Male'
where gender = 'M'

update sales1
set gender = 'Female'
where gender = 'F'

select distinct payment_mode
from sales1

update sales1
set payment_mode = 'Credit Card'
where payment_mode = 'CC'


-- Step 6: Solving Business Insight Questions (Data Analysis)

-- 1. What are the top 5mos selling products by quantity?

select * from sales1
select distinct status
from sales1

select top 5 product_name, product_category, sum(quantity) [total_Quantity_sold]
from sales1
where status = 'delivered'
group by product_name, product_category
order by [total_Quantity_sold] desc

-- Business problem: we don't know which products are most in demand
-- Business impact: helps prioritize stock and boost through targeted promotions

-- 2. Which products are most frequently cancelled?
select top 5 product_name, count(*) as total_cancelled
from sales1
where status = 'cancelled'
group by product_name
order by total_cancelled desc

-- Business problem: Frequent cancellation affect revenue and customer trust.
-- Business impact: Identify poor-performing products to improve quality or remove from catalog


-- 3. What time of the day has the highest number of purchases?

select * from sales1

	select
		case
		   when	datepart(hour, time_of_purchase) between 0 and 5 then 'Night'
		   when	datepart(hour, time_of_purchase) between 6 and 11 then 'Morning'
		   when	datepart(hour, time_of_purchase) between 12 and 17 then 'Afternoon'		
		   when	datepart(hour, time_of_purchase) between 18 and 23 then 'evening'
		end as time_of_day,
		count(*) as total_orders
	from sales1
	group by 
		case
		   when	datepart(hour, time_of_purchase) between 0 and 5 then 'Night'
		   when	datepart(hour, time_of_purchase) between 6 and 11 then 'Morning'
		   when	datepart(hour, time_of_purchase) between 12 and 17 then 'Afternoon'		
		   when	datepart(hour, time_of_purchase) between 18 and 23 then 'evening'
		end
		order by total_orders desc 

-- Business prroblem solved: Find peak sales times
-- Business impact: Optimizing staffing, prootions, and server loads


-- 4. Who are the top 5 highest spending custmers?

select * from sales1

select top 5 customer_name,
	format(sum(price*quantity),'C0','en-IN') as total_spend  -- N stands for number format 
from sales1                                          -- 0 for no decimal places				     
group by customer_name                               -- en-IN is for Indian currency format
order by sum(price*quantity) desc                    -- C stands for currency format

-- Business problem solved : Identity high-value customers
-- Business impact: Personalized offers, loyalty rewards, and retention

-- 5. Which product categories generate the most revenue?

select * from sales1

select product_category, 
format(sum(price*quantity),'C0','en-IN') as Revenue
from sales1
group by product_category
order by sum(price*quantity) desc

-- Business problem solved: Identify top revenue-generating categories
-- Business impact: Refine product strategy, supply chain, and promotions
-- Allowing the business to invest more in high-margin or high-emand categories


-- 6. What is the return/cancellation rate by product category?

select * from sales1

-- cancellation

select product_category,
	format(count(case when status = 'cancelled' then 1 end)*100.0/count(*),'N3') + ' %'  
	as cancelled_percentage
from sales1
group by product_category
order by cancelled_percentage desc

-- returned

select product_category,
	format(count(case when status = 'returned' then 1 end)*100.0/count(*),'N3') + ' %'  
	as returned_percentage
from sales1
group by product_category
order by returned_percentage desc

-- Business problem solved: Monitor dissatisfaction trends per category
-- Business impact: Reduces return, improve product description / expectations,
-- Helps identify and fix product or logistic issues


-- 7. What is the most preferred payment method?

select * from sales1

select payment_mode, count(payment_mode) as total_count
from sales1
group by payment_mode
order by total_count desc

-- Business problem solved: Know which payment options customers prefer
-- Business impact: streamline payment processing, prioritize popular methods.


-- 8. How does age group affect purchasing behavior?

select * from sales1
--select min(customer_age), max(customer_age) from sales1

select 
	case 
		when customer_age between 18 and 25 then '18-25'
		when customer_age between 26 and 35 then '26-35'
		when customer_age between 36 and 50 then '36-50'
		else '51+'
	end as customer_age,
	format(sum(price*quantity),'C0', 'en-IN') as total_purchase
from sales1
group by case 
		when customer_age between 18 and 25 then '18-25'
		when customer_age between 26 and 35 then '26-35'
		when customer_age between 36 and 50 then '36-50'
		else '51+'
	end
order by sum(price*quantity) desc

-- Business problem solved: Understand customers demographics
-- Business impact: Targeted marketing, product recommendations by age group.

-- 9. What's the monthly sales trend?

select * from sales1

--Method 1

select
	format(purchase_date,'yyyy-MM') as Month_Year,
	format(sum(price*quantity),'C0','en-IN') as total_sales,
	sum(quantity) as total_quantity
from sales1
group by format(purchase_date,'yyyy-MM')

-- Method 2

select * from sales1
	
	select
		--YEAR(purchase_date) as Years,
		MONTH(purchase_date) as Months,
		format(sum(price*quantity),'C0','en-IN') as total_sales,
		sum(quantity) as total_quantity
from sales1
group by MONTH(purchase_date)
order by  Months

-- Business problem solved: Sales fluctuations go unnoticed
-- Business impact: plan inventory, marketing according to seasonal trends


-- 10. Are certain genders buying more specific product categories?

select * from sales1

--Method 1
select gender, product_category, count(product_category) as total_purchases
from sales1
group by gender, product_category
order by gender 

--Method 2
select *
from (
	select gender, product_category
	from sales1
	) as sourse_table
pivot (
		count(gender)
		for gender in ([Male], [Female])
	) as pivot_table
order by product_category

--or we can use

SELECT
    product_category,
    COUNT(CASE WHEN gender = 'Male' THEN 1 END) AS Male,
    COUNT(CASE WHEN gender = 'Female' THEN 1 END) AS Female
FROM sales1
GROUP BY product_category
ORDER BY product_category;

-- Business problem solved: Gender-based productd preferences
-- Business impact: personalizd ads, gender-focused campaigns



