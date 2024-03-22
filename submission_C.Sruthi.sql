/*

-----------------------------------------------------------------------------------------------------------------------------------
													    Guidelines
-----------------------------------------------------------------------------------------------------------------------------------

The provided document is a guide for the project. Follow the instructions and take the necessary steps to finish
the project in the SQL file			

-----------------------------------------------------------------------------------------------------------------------------------
                                                         Queries
                                               
-----------------------------------------------------------------------------------------------------------------------------------*/
  use new_wheels;
  
/*-- QUESTIONS RELATED TO CUSTOMERS
     [Q1] What is the distribution of customers across states?
     Hint: For each state, count the number of customers.*/
select state, count(customer_id) as customer_count
from customer_t
group by state
order by (customer_count)desc;

-- ---------------------------------------------------------------------------------------------------------------------------------

/* [Q2] What is the average rating in each quarter?
-- Very Bad is 1, Bad is 2, Okay is 3, Good is 4, Very Good is 5.

Hint: Use a common table expression and in that CTE, assign numbers to the different customer ratings. 
      Now average the feedback for each quarter. */
with customer_feedback_t as
(select quarter_number, 
case 
when customer_feedback = 'Very Bad' then 1
when customer_feedback = 'Bad' then 2
when customer_feedback = 'Okay' then 3
when customer_feedback = 'Good' then 4
when customer_feedback = 'Very Good' then 5
end as ratings
from order_t)
select quarter_number, avg(ratings) as average_rating
from customer_feedback_t
group by quarter_number;

-- ---------------------------------------------------------------------------------------------------------------------------------

/* [Q3] Are customers getting more dissatisfied over time?

Hint: Need the percentage of different types of customer feedback in each quarter. Use a common table expression and
	  determine the number of customer feedback in each category as well as the total number of customer feedback in each quarter.
	  Now use that common table expression to find out the percentage of different types of customer feedback in each quarter.
      Eg: (total number of very good feedback/total customer feedback)* 100 gives you the percentage of very good feedback. */
with customer_feedback_count as 
(select count(customer_feedback) as cust_feed_count, quarter_number
from order_t
group by quarter_number),
customer_feedback_category_count as
(select customer_feedback, count(customer_feedback)as categ_feed, quarter_number
from order_t
group by quarter_number, customer_feedback)

select category.quarter_number, category.customer_feedback, round((category.categ_feed/feedback.cust_feed_count)*100,2) as percentage_customer_feedback
from customer_feedback_count as feedback, customer_feedback_category_count as category
where category.quarter_number = feedback.quarter_number
order by category.quarter_number,category.customer_feedback;


-- ---------------------------------------------------------------------------------------------------------------------------------

/*[Q4] Which are the top 5 vehicle makers preferred by the customer.

Hint: For each vehicle make what is the count of the customers.*/
select vehicle_maker, count(distinct(customer_id)) cust_count
from product_t
left join order_t
on product_t.product_id=order_t.product_id
group by vehicle_maker
order by (cust_count) desc
limit 5;


-- ---------------------------------------------------------------------------------------------------------------------------------

/*[Q5] What is the most preferred vehicle make in each state?

Hint: Use the window function RANK() to rank based on the count of customers for each state and vehicle maker. 
After ranking, take the vehicle maker whose rank is 1.*/
with rank_t as
(select state, vehicle_maker,count(distinct(order_t.customer_id)) as count,
rank()over(partition by state order by count(distinct(customer_t.customer_id)) desc) as ranking
from order_t
right join product_t on order_t.product_id = product_t.product_id
right join customer_t on order_t.customer_id = customer_t.customer_id
group by vehicle_maker, state
order by count desc, state)

select state, count, vehicle_maker
from rank_t
where ranking=1;


-- ---------------------------------------------------------------------------------------------------------------------------------

/*QUESTIONS RELATED TO REVENUE and ORDERS 

-- [Q6] What is the trend of number of orders by quarters?

Hint: Count the number of orders for each quarter.*/
select quarter_number, count(order_id) as order_count
from order_t
group by quarter_number
order by quarter_number;

-- ---------------------------------------------------------------------------------------------------------------------------------

/* [Q7] What is the quarter over quarter % change in revenue? 

Hint: Quarter over Quarter percentage change in revenue means what is the change in revenue from the subsequent quarter to the previous quarter in percentage.
      To calculate you need to use the common table expression to find out the sum of revenue for each quarter.
      Then use that CTE along with the LAG function to calculate the QoQ percentage change in revenue.
*/
 with quarterly_revenue_t as
 (select quarter_number, round(sum(quantity*(vehicle_price * (1-discount))),2) as revenue 
 from order_t
 group by quarter_number
 order by quarter_number)
 
 select revenue, quarter_number, lag(revenue)over(order by quarter_number) as previous_quarter_revenue,
 round(((revenue-lag(revenue)over (order by quarter_number))/lag(revenue)over(order by quarter_number))*100,2) as percent_change_in_revenue
 from quarterly_revenue_t;
      

-- ---------------------------------------------------------------------------------------------------------------------------------

/* [Q8] What is the trend of revenue and orders by quarters?

Hint: Find out the sum of revenue and count the number of orders for each quarter.*/
select quarter_number, count(order_id) as order_count, round(sum(vehicle_price-((discount/100)*vehicle_price)),2) as revenue
from order_t
group by quarter_number
order by quarter_number;

-- ---------------------------------------------------------------------------------------------------------------------------------

/* QUESTIONS RELATED TO SHIPPING 
    [Q9] What is the average discount offered for different types of credit cards?

Hint: Find out the average of discount for each credit card type.*/
select credit_card_type, round(avg((discount/100)*order_t.vehicle_price),2) as average_discount
from customer_t
right join order_t on customer_t.customer_id=order_t.customer_id
right join product_t on order_t.product_id=product_t.product_id
group by credit_card_type
order by credit_card_type;

-- ---------------------------------------------------------------------------------------------------------------------------------

/* [Q10] What is the average time taken to ship the placed orders for each quarters?
	Hint: Use the dateiff function to find the difference between the ship date and the order date.
*/
select quarter_number, round(avg(datediff(ship_date, order_date)),2) as avg_time_taken
from order_t
group by quarter_number
order by quarter_number;

-- --------------------------------------------------------Done----------------------------------------------------------------------
-- ----------------------------------------------------------------------------------------------------------------------------------
-- Business revenue
# Total Revenue
select sum(quantity * ((vehicle_price)-(discount*vehicle_price))) as Revenue
from order_t;

# Total Orders
select count(order_id) as Total_orders
from order_t;

# Total Customers
select count(distinct(customer_id)) as Total_customers
from customer_t;

#Average rating
select  avg(
case
	when customer_feedback = 'very bad' then 1
    when customer_feedback = 'bad' then 2
    when customer_feedback = 'okay' then 3
    when customer_feedback = 'good' then 4
    when customer_feedback = 'very good' then 5
end) as average_customer_rating
from order_t;

#Last quarter revenue
select quarter_number, sum((vehicle_price-(discount*vehicle_price))*quantity) as Revenue
from order_t
where quarter_number = 4;

#Last quarter order
select quarter_number, count(order_id) as Quarter_orders from order_t
where quarter_number = 4;

#Average days to ship
select avg(datediff(ship_date,order_date)) as Average_Shipping_Date
from order_t;

# % good feedback
select
    count(case when customer_feedback = 'good' or 'very good' then 1 end) as good_feedback_count,
    count(*) as total_feedback_count,
    (count(case when customer_feedback = 'good' or customer_feedback= 'very good' then 1 end) * 100.0 / count(*)) as percentage_good_feedback
from order_t;
    
