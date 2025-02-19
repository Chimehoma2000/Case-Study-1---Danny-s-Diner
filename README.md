#  <h1 align="center"> Case-Study-1---Danny's-Diner</h1>
![image](https://github.com/user-attachments/assets/0b783ee0-dfb2-48d1-8133-e9f0719b8e4a)
## <h1 align="center"> Case-Study-1-Data Source </h1>
#### Data is a random challenge hosted on a website [See Here](https://8weeksqlchallenge.com/)
## Entity Relationship Diagram
![Image](https://github.com/user-attachments/assets/a680babd-0895-4d54-a34f-1d44b4fd3201)

 ## <h1 align="center"> CASE STUDY QUESTIONS </h1>
Each of the following case study questions can be answered using a single SQL statement:

1 What is the total amount each customer spent at the restaurant?  
2 How many days has each customer visited the restaurant?  
3 What was the first item from the menu purchased by each customer?  
4 What is the most purchased item on the menu and how many times was it purchased by all customers?  
5 Which item was the most popular for each customer?  
6 Which item was purchased first by the customer after they became a member?  
7 Which item was purchased just before the customer became a member?  
8 What is the total items and amount spent for each member before they became a member?  
9 If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?  
10 In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?    

<h1 align="center">SOLUTION </h1>


###  1. What is the total amount each customer spent at the restaurant?

```sql
  Select Distinct customer_id,SUM (price) as Total_Price
  From dbo.sales
  Join dbo.menu
  ON  dbo.sales.product_id = dbo.menu.product_id
  Group By customer_id

```

#### Query Result:
| customer_id | Total_Price|
| ----------- | -----------|
| A           | 76         |
| B           | 74         |
| C           | 36         |


###  2. How many days has each customer visited the restaurant?  

```sql
   Select customer_id, count(Distinct(order_date)) as date_visited
  From sales
  Group by customer_id


```

#### Query Result:
| customer_id | date_visited|
| ----------- | -----------|
| A           | 4      |
| B           | 6      |
| C           | 2      |  

###  3. What was the first item from the menu purchased by each customer? 

```sql
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


```

#### Query Result:
| customer_id | product_name|
| ----------- | -----------|
| A           |   sushi    |
| B           |   curry    |
| C           |  ramen     |


###  4. What is the most purchased item on the menu and how many times was it purchased by all customers?  

```sql
--Finding all products and purchase amount
Select m.product_name, COUNT (s.product_id) as purchase_amt
  From dbo.sales s
  JOIN menu m
 ON s.product_id = m.product_id
 Group BY m.product_name
 Order by purchase_amt DESC

```

#### Query Result:
| product_name| purchase_amt|
|-----------  | ----------- |
| ramen       |       8    |
| curry       |       4    |
| sushi       |       3    |



```sql
 -- Removing the lower puchased items, leaving only the highest purchased.
 Select TOP 1 m.product_name, COUNT (s.product_id) as purchase_amt
  From dbo.sales s
  JOIN menu m
 ON s.product_id = m.product_id
 Group BY m.product_name
 Order by purchase_amt DESC

```

#### Query Result:
| product_name| purchase_amt|
|-----------  | ----------- |
| ramen       |       8    |


###  5. Which item was the most popular for each customer?  

```sql
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

```


#### Query Result:
|customer_id	|product_name |
| -----------| ----------- |
|    A	      |  ramen      |
|    B       |  sushi      |
|    B       |  curry      |
|    B       |  ramen      |
|    C       |  ramen      |


###  6. Which item was purchased first by the customer after they became a member?
```sql

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


```


#### Query Result:
|customer_id	|product_name |
| -----------| ----------- |
|    A	      |  ramen      |
|    B       |  sushi      |




### 7. Which item was purchased just before the customer became a member?
```sql

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


```


#### Query Result:
|customer_id	|product_name |
| -----------| ----------- |
|    A	      |  sushi      |
|    A       |  curry      |
|    B       |  sushi      |



### 8. What is the total items and amount spent for each member before they became a member?
```sql

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

```


#### Query Result:
|customer_id	|TotalPriceAmt |TotalproductAmt |
| -----------| ----------- |---------- |
|    A	      |  25         |2     |
|    B       | 40         |3|


### 9. If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?
```sql

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


```


#### Query Result:
|customer_id	|TotalPoints |
| -----------| ----------- |
|    A	      |  860       |
|    B       | 940         |
|    C       | 360        |


### 10.In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?

```sql

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



```


#### Query Result:
|customer_id	|TotalPoints |
| -----------| ----------- |
|    A	      |  1020     |
|    B       | 440         |

