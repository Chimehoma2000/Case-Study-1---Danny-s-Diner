
--IMPORTING TABLES INTO DATABASE


CREATE TABLE sales (
  "customer_id" VARCHAR(1),
  "order_date" DATE,
  "product_id" INTEGER
);

INSERT INTO sales
  ("customer_id", "order_date", "product_id")
VALUES
  ('A', '2021-01-01', '1'),
  ('A', '2021-01-01', '2'),
  ('A', '2021-01-07', '2'),
  ('A', '2021-01-10', '3'),
  ('A', '2021-01-11', '3'),
  ('A', '2021-01-11', '3'),
  ('B', '2021-01-01', '2'),
  ('B', '2021-01-02', '2'),
  ('B', '2021-01-04', '1'),
  ('B', '2021-01-11', '1'),
  ('B', '2021-01-16', '3'),
  ('B', '2021-02-01', '3'),
  ('C', '2021-01-01', '3'),
  ('C', '2021-01-01', '3'),
  ('C', '2021-01-07', '3');
 

CREATE TABLE menu (
  "product_id" INTEGER,
  "product_name" VARCHAR(5),
  "price" INTEGER
);

INSERT INTO menu
  ("product_id", "product_name", "price")
VALUES
  ('1', 'sushi', '10'),
  ('2', 'curry', '15'),
  ('3', 'ramen', '12');
  

CREATE TABLE members (
  "customer_id" VARCHAR(1),
  "join_date" DATE
);

INSERT INTO members
  ("customer_id", "join_date")
VALUES
  ('A', '2021-01-07'),
  ('B', '2021-01-09');


  --SELECT FROM DIFFERENT TABLES

  Select *
  From dbo.members

  Select *
  From dbo.menu

  Select *
  From dbo.sales

   --ANSWERS TO PROBLEM STATEMENTS
 -- 1 What is the total amount each customer spent at the restaurant?

  Select Distinct customer_id,SUM (price) as Total_Price
  From dbo.sales
  Join dbo.menu
  ON  dbo.sales.product_id = dbo.menu.product_id
  Group By customer_id




 --2 How many days has each customer visited the restaurant?
	
  Select customer_id, count(Distinct(order_date)) as date_visited
  From sales
  Group by customer_id


  
  --3. What was the first item from the menu purchased by each customer?

 
  WITH query AS -- Naming the CTE as query.
  (
  SELECT s.customer_id, m.product_name,
  ROW_NUMBER() OVER(PARTITION BY s.customer_id ORDER BY s.order_date ASC) as rank   --WINDOW FUNCTIION
  FROM dbo.sales s
  JOIN dbo.menu m
  ON s.product_id= m.product_id
  )
  SELECT customer_id, product_name
  FROM query
  WHERE rank = 1


--4. What is the most purchased item on the menu and how many times was it purchased by all customers?

--Finding all products and purchase amount
Select m.product_name, COUNT (s.product_id) as purchase_amt
  From dbo.sales s
  JOIN menu m
 ON s.product_id = m.product_id
 Group BY m.product_name
 Order by purchase_amt DESC

 -- Removing the lower puchased items, leaving only the highest purchased.
 Select TOP 1 m.product_name, COUNT (s.product_id) as purchase_amt
  From dbo.sales s
  JOIN menu m
 ON s.product_id = m.product_id
 Group BY m.product_name
 Order by purchase_amt DESC



  
--5. Which item was the most popular for each customer?

WITH query AS --CTE
(
SELECT
s.customer_id,
m.product_name,
count (*) as order_count, -- alias cannot be used in the order by below
DENSE_RANK() OVER (PARTITION BY s.customer_id ORDER BY count (*) desc) as ranking --DENSE_RANK(Does not skip rankafter a tally)
FROM sales s
JOIN menu m
ON s.product_id = m.product_id
GROUP BY s.customer_id, m.product_name
)
SELECT  customer_id, product_name
FROM query
WHERE ranking = 1


--6. Which item was purchased first by the customer after they became a member?

WITH query AS --CTE
(
Select s.Customer_id, me.product_name, s.order_date, mb.join_date,
DENSE_RANK()  OVER (PARTITION BY s.Customer_id ORDER BY order_date) as rnk --RANK
FROM sales s
JOIN menu me
ON s.product_id = me.product_id
JOIN members mb
ON s.customer_id = mb.customer_id
WHERE s.order_date > mb.join_date
)
SELECT customer_id, product_name
FROM query
WHERE rnk = 1 --CRITERIA



--7. Which item was purchased just before the customer became a member?


WITH query AS --CTE
(
Select s.Customer_id, me.product_name, s.order_date, mb.join_date,
DENSE_RANK()  OVER (PARTITION BY s.Customer_id ORDER BY order_date DESC) as rnk --RANK
FROM sales s
JOIN menu me
ON s.product_id = me.product_id
JOIN members mb
ON s.customer_id = mb.customer_id
WHERE s.order_date < mb.join_date -- 
)
SELECT customer_id, product_name
FROM query
WHERE rnk = 1 --CRITERIA


--8. What is the total items and amount spent for each member before they became a member?

WITH query AS
(
SELECT s.customer_id,s.product_id, m.product_name, m.price, s.order_date, me.join_date
FROM sales s
JOIN menu m
ON s.product_id = m.product_id 
JOIN members me
ON s.customer_id = me.customer_id
WHERE  me.join_date > s.order_date 
)
SELECT 
customer_id, 
SUM (price) as TotalPriceAmt,
COUNT (product_id) as TotalproductAmt
FROM query
GROUP BY customer_id



--9. If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?

WITH query AS  ---CTE
(
SELECT m.product_name, s.customer_id, m.price,
CASE 
	WHEN product_name = 'sushi' THEN price * 10 * 2
	ELSE price * 10
END as points
FROM menu m
JOIN sales s
ON s.product_id = m.product_id
)
SELECT
customer_id,
SUM (points) as TotalPoints
FROM query
GROUP BY customer_id
ORDER BY customer_id ASC



--10.In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?



WITH query AS
(
SELECT s.customer_id, m.price,me.join_date, s.order_date,
DATEADD (Day, 6, join_date)as promo_end_date,
CASE
	WHEN s.order_date BETWEEN me.join_date AND DATEADD (Day, 6, join_date) THEN m.price * 10 * 2
	ELSE m.price * 10
END as points
FROM sales s
JOIN menu m
ON s.product_id = m.product_id 
JOIN members me
ON s.customer_id = me.customer_id
WHERE   s.order_date >= me.join_date
)
SELECT 
customer_id, 
SUM (points) as TotalPoints
FROM query
GROUP BY customer_id



--											Bonus Questions
--										   Join All The Things
--The following questions are related creating basic data tables that Danny and his team 
--can use to quickly derive insights without needing to join the underlying tables using SQL.

--Recreate the following table output using the available data:

--customer_id	order_date	product_name	price	member
--   A	        2021-01-01	   curry	     15	      N
--	 A			2021-01-01		sushi		 10		  N
--	 A			2021-01-07		curry		 15		  Y
--	 A			2021-01-10		ramen		 12		  Y
--	 A			2021-01-11	  ramen			 12		  Y
--	 A		    2021-01-11	  ramen		     12		  Y
--	 B			2021-01-01	  curry			 15		  N
--	 B			2021-01-02	  curry			 15		  N
--	 B			2021-01-04		sushi		 10		 N
--	 B			2021-01-11		sushi		 10		 Y
--	 B			2021-01-16		ramen		 12		 Y
--	 B			2021-02-01		ramen		 12		 Y
--	 C			2021-01-01		ramen		 12		 N
--	 C			2021-01-01		ramen		 12		 N
--	 C			2021-01-07		ramen		 12		 N


SELECT s.customer_id,s.order_date,m.product_name, m.price,
CASE
	WHEN me.join_date IS NULL THEN 'N'
	WHEN me.join_date < s.order_date THEN 'N'
	WHEN me.join_date > s.order_date THEN 'Y'
	ELSE 0
END AS member
FROM sales s
JOIN menu m
ON s.product_id=m.product_id
RIGHT JOIN members me
ON s.customer_id = me.customer_id
--GROUP BY s.customer_id,m.product_name
ORDER BY s.customer_id DESC
