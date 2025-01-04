# Case Study 1: DANNY'S DINER

## Input tables
#### sales
| customer_id | order_date | product_id |
|-------------|------------|------------|
|A|	2021-01-01|	1|
|A|	2021-01-01|	2|
|A|	2021-01-07|	2|
|A|	2021-01-10	|3|
|A|	2021-01-11	|3|
|A| 2021-01-11	|3|
|B| 2021-01-01	|2|
|B| 2021-01-02	|2|
|B| 2021-01-04	|1|
|B|	2021-01-11	|1|
|B|	2021-01-16	|3|
|B|	2021-02-01	|3|
|C|	2021-01-01	|3|
|C|	2021-01-01	|3|
|C|	2021-01-07	|3|

#### menu
|product_id  |product_name  |price      |
| ------------|------------|------------|
|1            | sushi      |	10        |
|2            |	curry      |	15        |
|3            |	ramen      |	12        |

#### members
|customer_id  |join_date  |
| ------------|------------|
|A            |2021-01-07|
|B            |	2021-01-09|

***
## Solution
[View the complete code](https://github.com/ItsAmitBhaskar/Danny_s-Diner/commit/d1d77ac4a5a94432866ec0fe095ab1df876f7b7f).
***

### 1. What is the total amount each customer spent at the restaurant?
#### MySQL Query
```sql
SELECT
  s.customer_id, sum(m.price) as amount_spent
FROM sales s 
LEFT JOIN menu m ON s.product_id = m.product_id
GROUP BY s.customer_id
ORDER BY s.customer_id;
```
#### Output:
| customer_id | amount_spent |
| ----------- | ----------- |
| A           | 76          |
| B           | 74          |
| C           | 36          |
***

### 2. How many days has each customer visited the restaurant?
#### MySQL Query
```sql
select customer_id, count(distinct order_date) as num_of_days_visited
from sales
group by customer_id;
```
#### Output:
| customer_id | num_of_days_visited |
| ----------- | ----------- |
| A           | 4          |
| B           | 6          |
| C           | 2          |
***

### 3. What was the first item from the menu purchased by each customer?
#### MySQL Query
```sql
SELECT
distinct customer_id, product_name as first_order
FROM
    (  SELECT
        s.customer_id, m.product_name,
        dense_rank() over (partition by s.customer_id order by s.order_date) as rn
        FROM sales s
        LEFT JOIN menu m on s.product_id = m.product_id
    ) as derivedtable
WHERE rn=1;
````
#### Output:
| customer_id | first_order | 
| ----------- | ----------- |
| A           | sushi       | 
| A           | curry       | 
| B           | curry       | 
| C           | ramen       |
***

### 4. What is the most purchased item on the menu and how many times was it purchased by all customers?
#### MySQL Query
````sql
with orderedtotal as (
  select
    product_id, count(customer_id) as total_orders,
    dense_rank() over (order by count(customer_id) desc) as rn
  from sales 
  group by product_id
)

select od.product_id, m.product_name, total_orders 
from orderedtotal od
join menu m on od.product_id = m.product_id
where rn=1;
````
#### Output:
| product_id  | product_name | total_orders|
| ----------- | ----------- |--------------|
|    3        | ramen       |8             |
***

### 5. Which item was the most popular for each customer?
#### MySQL Query
````sql
WITH popularitycte as
(
  SELECT customer_id, product_id, ordertotal
  FROM (
        SELECT customer_id, product_id,
                count(*) as ordertotal,
                dense_rank() over (partition by customer_id order by count(*) desc) as rn
        FROM sales
        GROUP BY customer_id, product_id
        ) as derivedtable
  WHERE rn=1
)

SELECT
  customer_id,
  group_concat(m.product_name) as products,
  max( ordertotal) as no_of_times_each_item_ordered
FROM
  popularitycte pc
JOIN
   menu m ON pc.product_id = m.product_id
GROUP BY pc.customer_id
ORDER BY customer_id;
````
#### Output:
| customer_id | products          | no_of_times_each_item_ordered |
| ----------- | ------------------|-------------------------------|
| A           | ramen             |  3                            |
| B           | sushi,curry,ramen |  2                            |
| C           | ramen             |  3                            |
***

### 6. Which item was purchased first by the customer after they became a member?
Since there is no explicit information given in the question, I am assuming any order made by a customer on the date of becoming a member has been made after taking the membership.
#### MySQL Query
````sql
WITH firstpurchasecte AS
(
  SELECT
  customer_id, product_id
  FROM (
        SELECT 
          mem.customer_id, s.order_date, s.product_id, 
          dense_rank() over (partition by mem.customer_id order by s.order_date) as rn
        FROM members mem
        join sales s on mem.customer_id = s.customer_id and s.order_date >= mem.join_date
        ) as derivedtable
  WHERE rn=1
)

select fp.customer_id, m.product_name as first_ordered_item
from firstpurchasecte fp
join menu m on fp.product_id = m.product_id
order by fp.customer_id;
````
#### Output:
| customer_id |  first_ordered_item |
| ----------- | ----------  |
| A           |  curry        |
| B           |  sushi        |
***

### 7. Which item was purchased just before the customer became a member?
#### MySQL Query
````sql
WITH lastpurchasecte AS
(
  SELECT customer_id, product_id
  FROM (
        SELECT
          mem.customer_id, s.order_date, s.product_id, 
          dense_rank() over (partition by mem.customer_id order by s.order_date desc) as rn
        FROM members mem
        join sales s on mem.customer_id = s.customer_id and s.order_date < mem.join_date
        ) as derivedtable
  WHERE rn=1
)

select
  lp.customer_id, group_concat(m.product_name) as last_ordered_items_before_membership
from lastpurchasecte lp
join menu m on lp.product_id = m.product_id
group by lp.customer_id
order by lp.customer_id;
````
#### Output:
| customer_id |last_ordered_items_before_membership |
| ----------- | ----------  |
| A           |  sushi,curry     |
| B           |   sushi     |
***

### 8. What is the total items and amount spent for each member before they became a member?
#### MySQL Query
````sql
SELECT 
mem.customer_id, count(s.product_id) as total_items, sum(m.price) as total_amount
FROM members mem 
join sales s on mem.customer_id = s.customer_id and s.order_date < mem.join_date
join menu m on s.product_id = m.product_id
group by mem.customer_id
order by mem.customer_id;
````
#### Output:
| customer_id |total_items | total_amount |
| ----------- | ---------- |----------  |
| A           | 2 |  25       |
| B           | 3 |  40       |
***

### 9. If each $1 spent equates to 10 points and sushi has a 2x points multiplier — how many points would each customer have?
#### MySQL Query
````sql
SELECT 
s.customer_id, 
sum(case when s.product_id=1 then m.price*20 else m.price*10 end) as total_points
FROM sales s
join menu m on s.product_id = m.product_id
group by s.customer_id
order by s.customer_id;
````
#### Output:
| customer_id | total_points | 
| ----------- | -------|
| A           | 860 |
| B           | 940 |
| C           | 360 |
***

### 10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi — how many points do customer A and B have at the end of January?
#### MySQL Query
````sql
WITH saleswithpricecte as
(
  SELECT s.*,mem.join_date, m.price
  FROM sales s
  JOIN menu m on s.product_id = m.product_id
  JOIN members mem on s.customer_id = mem.customer_id
),

finalcte as (
  select *, 
  case 
    when datediff(order_date, join_date) between 0 and 6 
    then price*20 
    else 
      (case when product_id=1 then price*20 else price*10 end)
    end as points
  from saleswithpricecte
)

select customer_id, sum(points) as total_points
from finalcte
where month(order_date) = 01 and year(order_date)='2021'
group by customer_id
order by customer_id;
````
#### Output:
| customer_id | total_points | 
| ----------- | ---------- |
| A           | 1370 |
| B           | 820 |
***
