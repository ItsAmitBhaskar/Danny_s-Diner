# Case Study 1: Danny's Diner

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
#### Answer:
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
#### Answer:
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

#### Answer:
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
  select product_id, count(customer_id) as total_orders, dense_rank() over (order by count(customer_id) desc) as rn
  from sales 
  group by product_id
)

select od.product_id, m.product_name, total_orders 
from orderedtotal od
join menu m on od.product_id = m.product_id
where rn=1;
````

#### Answer:
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

SELECT customer_id, group_concat(m.product_name) as products,max( ordertotal) as no_of_times_each_item_ordered
FROM popularitycte pc
JOIN menu m ON pc.product_id = m.product_id
GROUP BY pc.customer_id
ORDER BY customer_id;
````

#### Answer:
| customer_id | products          | no_of_times_each_item_ordered |
| ----------- | ------------------|-------------------------------|
| A           | ramen             |  3                            |
| B           | sushi,curry,ramen |  2                            |
| C           | ramen             |  3                            |

***

### 6. Which item was purchased first by the customer after they became a member?
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


#### Answer:
| customer_id |  product_name |order_date
| ----------- | ----------  |----------  |
| A           |  curry        |2021-01-07 |
| B           |  sushi        |2021-01-11 |

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

#### Answer:
| customer_id |product_name |order_date  |
| ----------- | ----------  |---------- |
| A           |  sushi      |2021-01-01 | 
| A           |  curry      |2021-01-01 | 
| B           |   sushi     |2021-01-04 |

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


#### Answer:
| customer_id |Items | total_sales |
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


#### Answer:
| customer_id | Points | 
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

#### Answer:
| Customer_id | Points | 
| ----------- | ---------- |
| A           | 1370 |
| B           | 820 |

***
