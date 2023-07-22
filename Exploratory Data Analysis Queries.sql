/*

-----------------------------------------------------------------------------------------------------------------------------------
													    Guidelines
-----------------------------------------------------------------------------------------------------------------------------------

The provided document is a guide for the project. Follow the instructions and take the necessary steps to finish
the project in the SQL file			

-----------------------------------------------------------------------------------------------------------------------------------
                                                         Queries
                                               
-----------------------------------------------------------------------------------------------------------------------------------*/

/*
Priliminary queries to help check data sanity
*/
-- ensure that there are no duplicate entries in order_t table
SELECT 
    COUNT(order_id) AS total_order_count
FROM
    order_t;

SELECT 
    COUNT(DISTINCT (order_id)) AS distinct_order_count
FROM
    order_t;

-- ensure that all orders do have customer feedback and also that there are only the expected values for customer feed back (Very Bad, Bad, Okay, Good, Very Good)
SELECT DISTINCT
    customer_feedback
FROM
    order_t;

-- ensure that the orders data only spans across one year (only quarters witin year 2018 are specified)
SELECT 
    MIN(order_date) AS min_order_date,
    MAX(order_date) AS max_order_date
FROM
    order_t;

-- --------------------------------------------------------------------------------------------------------------------------------
  
/*-- QUESTIONS RELATED TO CUSTOMERS
     [Q1] What is the distribution of customers across states?
     Hint: For each state, count the number of customers.*/
SELECT 
    state, COUNT(customer_id) AS customer_count
FROM
    customer_t
GROUP BY state
ORDER BY customer_count DESC;

-- ---------------------------------------------------------------------------------------------------------------------------------
/* [Q2] What is the average rating in each quarter?
-- Very Bad is 1, Bad is 2, Okay is 3, Good is 4, Very Good is 5.

Hint: Use a common table expression and in that CTE, assign numbers to the different customer ratings. 
      Now average the feedback for each quarter. 

Note: For reference, refer to question number 4. Week-2: mls_week-2_gl-beats_solution-1.sql. 
      You'll get an overview of how to use common table expressions from this question.*/
WITH customer_rating_t AS (
	SELECT 
    quarter_number,
		CASE
			WHEN customer_feedback = 'Very Bad' THEN 1
			WHEN customer_feedback = 'Bad' THEN 2
			WHEN customer_feedback = 'Okay' THEN 3
			WHEN customer_feedback = 'Good' THEN 4
			WHEN customer_feedback = 'Very Good' THEN 5
		END AS rating
	FROM
    order_t)
SELECT 
    quarter_number,
    ROUND(AVG(rating), 2) average_customer_rating
FROM
    customer_rating_t
GROUP BY quarter_number
ORDER BY quarter_number;

-- ---------------------------------------------------------------------------------------------------------------------------------

/* [Q3] Are customers getting more dissatisfied over time?

Hint: Need the percentage of different types of customer feedback in each quarter. Use a common table expression and
	  determine the number of customer feedback in each category as well as the total number of customer feedback in each quarter.
	  Now use that common table expression to find out the percentage of different types of customer feedback in each quarter.
      Eg: (total number of very good feedback/total customer feedback)* 100 gives you the percentage of very good feedback.
      
Note: For reference, refer to question number 4. Week-2: mls_week-2_gl-beats_solution-1.sql. 
      You'll get an overview of how to use common table expressions from this question.*/
WITH customer_feedback_catagory_count as (
	SELECT 
		quarter_number,
		customer_feedback,
		COUNT(customer_feedback) AS feedback_catagory_count
	FROM
		order_t
	GROUP BY quarter_number , customer_feedback
), customer_feedback_count AS (
	SELECT 
		quarter_number, COUNT(customer_feedback) AS feedback_count
	FROM
		order_t
	GROUP BY quarter_number)
SELECT 
    catag.quarter_number,
    catag.customer_feedback,
    ROUND((catag.feedback_catagory_count / feed.feedback_count) * 100, 2) percentage_customer_feedback
FROM
    customer_feedback_catagory_count AS catag,
    customer_feedback_count AS feed
WHERE
    catag.quarter_number = feed.quarter_number
ORDER BY catag.quarter_number , catag.customer_feedback;
      
-- ---------------------------------------------------------------------------------------------------------------------------------

/*[Q4] Which are the top 5 vehicle makers preferred by the customer.

Hint: For each vehicle make what is the count of the customers.*/
SELECT 
    vehicle_maker, COUNT(DISTINCT (customer_id)) customer_count
FROM
    product_t
        LEFT JOIN
    order_t ON order_t.product_id = product_t.product_id
GROUP BY vehicle_maker
ORDER BY customer_count DESC
LIMIT 5;

-- ---------------------------------------------------------------------------------------------------------------------------------

/*[Q5] What is the most preferred vehicle make in each state?

Hint: Use the window function RANK() to rank based on the count of customers for each state and vehicle maker. 
After ranking, take the vehicle maker whose rank is 1.*/

WITH ranked_t AS (
	SELECT 
		state, 
        vehicle_maker, 
        COUNT(DISTINCT(order_t.customer_id)) AS count,
			RANK() OVER(PARTITION BY state ORDER BY count(DISTINCT(customer_t.customer_id)) DESC) AS ranking 
	FROM 
		order_t 
			RIGHT JOIN 
		product_t ON order_t.product_id = product_t.product_id
			RIGHT JOIN 
		customer_t ON order_t.customer_id = customer_t.customer_id
	GROUP BY state, vehicle_maker
	ORDER BY state, count DESC)
SELECT 
	state, 
    vehicle_maker, 
    count
FROM 
	ranked_t
WHERE 
	ranking=1;

-- ---------------------------------------------------------------------------------------------------------------------------------

/*QUESTIONS RELATED TO REVENUE and ORDERS 

-- [Q6] What is the trend of number of orders by quarters?

Hint: Count the number of orders for each quarter.*/
SELECT 
    quarter_number, COUNT(order_id) AS number_of_orders
FROM
    order_t
GROUP BY quarter_number
ORDER BY quarter_number;

-- ---------------------------------------------------------------------------------------------------------------------------------

/* [Q7] What is the quarter over quarter % change in revenue? 

Hint: Quarter over Quarter percentage change in revenue means what is the change in revenue from the subsequent quarter to the previous quarter in percentage.
      To calculate you need to use the common table expression to find out the sum of revenue for each quarter.
      Then use that CTE along with the LAG function to calculate the QoQ percentage change in revenue.
*/
WITH quarterly_revenue_t AS (
	SELECT 
		quarter_number,
		ROUND(SUM(vehicle_price - ((discount / 100) * vehicle_price)), 2) AS revenue
	FROM
		order_t
	GROUP BY quarter_number
	ORDER BY quarter_number)
SELECT 
	quarter_number, 
    revenue,
    LAG(revenue) OVER (ORDER BY quarter_number) previous_quarter_revenue,
	ROUND(((revenue - LAG(revenue) OVER (ORDER BY quarter_number)) / LAG(revenue) OVER (ORDER BY quarter_number)) *100, 2) percentage_change_in_revenue
FROM
	quarterly_revenue_t;     
      
-- ---------------------------------------------------------------------------------------------------------------------------------

/* [Q8] What is the trend of revenue and orders by quarters?

Hint: Find out the sum of revenue and count the number of orders for each quarter.*/
SELECT 
    quarter_number,
    COUNT(order_id) number_of_orders,
    ROUND(SUM(vehicle_price - ((discount / 100) * vehicle_price)), 2) revenue
FROM
    order_t
GROUP BY quarter_number
ORDER BY quarter_number;

-- ---------------------------------------------------------------------------------------------------------------------------------

/* QUESTIONS RELATED TO SHIPPING 
    [Q9] What is the average discount offered for different types of credit cards?

Hint: Find out the average of discount for each credit card type.*/
SELECT 
    credit_card_type,
    ROUND(AVG((discount / 100) * order_t.vehicle_price), 2) average_discount
FROM
    order_t
        RIGHT JOIN
    product_t ON order_t.product_id = product_t.product_id
        RIGHT JOIN
    customer_t ON order_t.customer_id = customer_t.customer_id
GROUP BY credit_card_type
ORDER BY credit_card_type;

-- ---------------------------------------------------------------------------------------------------------------------------------

/* [Q10] What is the average time taken to ship the placed orders for each quarters?
	Hint: Use the dateiff function to find the difference between the ship date and the order date.
*/
SELECT 
    quarter_number,
    ROUND(AVG(DATEDIFF(ship_date, order_date)), 2) AS average_days_to_ship
FROM
    order_t
GROUP BY quarter_number
ORDER BY quarter_number;
 
-- --------------------------------------------------------Done----------------------------------------------------------------------
-- ----------------------------------------------------------------------------------------------------------------------------------
/*
Additional Queries to help build the Business Overview portion of the report
*/
-- Calculate Total Revenue
SELECT 
    ROUND(SUM(vehicle_price - ((discount / 100) * vehicle_price)), 2) AS total_revenue
FROM
    order_t;

-- Total Orders
SELECT 
    COUNT(DISTINCT (order_id)) total_orders
FROM
    order_t;

-- Total Customers
SELECT 
    COUNT(DISTINCT (customer_id)) total_customers
FROM
    order_t;

-- Average Rating
WITH customer_rating_t AS (
	SELECT 
		quarter_number,
		CASE
			WHEN customer_feedback = 'Very Bad' THEN 1
			WHEN customer_feedback = 'Bad' THEN 2
			WHEN customer_feedback = 'Okay' THEN 3
			WHEN customer_feedback = 'Good' THEN 4
			WHEN customer_feedback = 'Very Good' THEN 5
		END AS rating
	FROM
		order_t)
SELECT 
    AVG(rating) average_rating
FROM
    customer_rating_t; 

-- Last Qtr Revenue
SELECT 
    ROUND(SUM(vehicle_price - ((discount / 100) * vehicle_price)), 2) q4_revenue
FROM
    order_t
WHERE
    quarter_number = 4;

-- Last Qtr Orders
SELECT 
    COUNT(DISTINCT (order_id)) q4_orders
FROM
    order_t
WHERE
    quarter_number = 4;

-- Avg Days to Ship
SELECT 
    AVG(DATEDIFF(ship_date, order_date)) average_days_to_ship
FROM
    order_t;

-- Percentage of Good Feedback
with customer_feedback_catagory_count as (
	SELECT 
		customer_feedback,
		COUNT(customer_feedback) feedback_catagory_count
	FROM
		order_t
	GROUP BY customer_feedback
), customer_feedback_count as (
	SELECT 
		COUNT(customer_feedback) AS feedback_count
	FROM
		order_t)
SELECT 
    A.customer_feedback,
    ROUND((A.feedback_catagory_count / B.feedback_count) * 100, 2) AS percentage_customer_feedback
FROM
    customer_feedback_catagory_count AS A,
    customer_feedback_count AS B
ORDER BY A.customer_feedback;

