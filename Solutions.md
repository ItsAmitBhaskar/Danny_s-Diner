# Case Study 1: Danny's Diner

## Solution

[View the complete code]().

***

### 1. What is the total amount each customer spent at the restaurant?

````sql
select s.customer_id, sum(m.price) as amount_spent
from sales s 
left join menu m on s.product_id = m.product_id
group by s.customer_id
order by s.customer_id;
````

#### Answer:
| Customer_id | Total_sales |
| ----------- | ----------- |
| A           | 76          |
| B           | 74          |
| C           | 36          |

- Customer A, B and C spent $76, $74 and $36 respectivly.

***

### 2. How many days has each customer visited the restaurant?

````sql
select customer_id, count(distinct order_date) as num_of_days_visited
from sales
group by customer_id;
````

#### Answer:
| Customer_id | Times_visited |
| ----------- | ----------- |
| A           | 4          |
| B           | 6          |
| C           | 2          |

- Customer A, B and C visited 4, 6 and 2 times respectivly.

***

### 3. What was the first item from the menu purchased by each customer?

````sql
SELECT distinct customer_id, product_name as first_order
from
( select s.customer_id, m.product_name,
dense_rank() over (partition by s.customer_id order by s.order_date) as rn
FROM sales s left join menu m 
on s.product_id = m.product_id) as derivedtable
where rn=1;
````

#### Answer:
| Customer_id | product_name | 
| ----------- | ----------- |
| A           | curry        | 
| A           | sushi        | 
| B           | curry        | 
| C           | ramen        |

- Customer A's first order is curry and sushi.
- Customer B's first order is curry.
- Customer C's first order is ramen.

***

### 4. What is the most purchased item on the menu and how many times was it purchased by all customers?

````sql
with orderedtotal as (
select product_id, count(customer_id) as total_orders, dense_rank() over (order by count(customer_id) desc) as rn
from sales 
group by product_id)

select od.product_id, m.product_name, total_orders 
from orderedtotal od join menu m
on od.product_id = m.product_id
where rn=1;
````



#### Answer:
| Product_name  | Times_Purchased | 
| ----------- | ----------- |
| ramen       | 8|


- Most purchased item on the menu is ramen which is 8 times.

***

### 5. Which item was the most popular for each customer?

````sql
with popularitycte as (
select customer_id, product_id, ordertotal
from (
SELECT customer_id, product_id, count(*) as ordertotal, dense_rank() over (partition by customer_id order by count(*) desc) as rn
from sales
group by customer_id, product_id) as derivedtable
where rn=1)

select customer_id, group_concat(m.product_name),max( ordertotal) as no_of_times_each_item_ordered
from popularitycte pc join menu m
on pc.product_id = m.product_id
group by pc.customer_id
order by customer_id;
````

#### Answer:
| Customer_id | Product_name | Count |
| ----------- | ---------- |------------  |
| A           | ramen        |  3   |
| B           | sushi        |  2   |
| B           | curry        |  2   |
| B           | ramen        |  2   |
| C           | ramen        |  3   |

- Customer A and C's favourite item is ramen while customer B savours all items on the menu. 

***

### 6. Which item was purchased first by the customer after they became a member?

````sql
with firstpurchasecte as (
select customer_id, product_id
from (
SELECT 
mem.customer_id, s.order_date, s.product_id, 
dense_rank() over (partition by mem.customer_id order by s.order_date) as rn
FROM members mem join sales s
on mem.customer_id = s.customer_id 
and s.order_date >= mem.join_date) as derivedtable
where rn=1)

select fp.customer_id, m.product_name as first_ordered_item
from firstpurchasecte fp
join menu m
on fp.product_id = m.product_id
order by fp.fp.customer_id;
````


#### Answer:
| customer_id |  product_name |order_date
| ----------- | ----------  |----------  |
| A           |  curry        |2021-01-07 |
| B           |  sushi        |2021-01-11 |

After becoming a member 
- Customer A's first order was curry.
- Customer B's first order was sushi.

***

### 7. Which item was purchased just before the customer became a member?

````sql
with lastpurchasecte as (
select customer_id, product_id
from (
SELECT 
mem.customer_id, s.order_date, s.product_id, 
dense_rank() over (partition by mem.customer_id order by s.order_date desc) as rn
FROM members mem join sales s
on mem.customer_id = s.customer_id 
and s.order_date < mem.join_date) as derivedtable
where rn=1)

select lp.customer_id, group_concat(m.product_name) as last_ordered_items_before_membership
from lastpurchasecte lp
join menu m
on lp.product_id = m.product_id
group by lp.customer_id
order by lp.customer_id;
````

#### Answer:
| customer_id |product_name |order_date  |
| ----------- | ----------  |---------- |
| A           |  sushi      |2021-01-01 | 
| A           |  curry      |2021-01-01 | 
| B           |   sushi     |2021-01-04 |

Before becoming a member 
- Customer A’s last order was sushi and curry.
- Customer B’s last order wassushi.

***

### 8. What is the total items and amount spent for each member before they became a member?

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

Before becoming a member
- Customer A spent $25 on 2 items.
- Customer B spent $40 on 3 items.

***

### 9. If each $1 spent equates to 10 points and sushi has a 2x points multiplier — how many points would each customer have?

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

- Total points for customer A, B and C are 860, 940 and 360 respectivly.

***

### 10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi — how many points do customer A and B have at the end of January?

````sql
WITH saleswithpricecte as (
SELECT s.*,mem.join_date, m.price
from sales s
join menu m on s.product_id = m.product_id
join members mem on s.customer_id = mem.customer_id
),

finalcte as (

select *, 
case 
when datediff(order_date, join_date) between 0 and 6 
then price*20 
else 
(case when product_id=1 then price*20 else price*10 end) end as points
from saleswithpricecte)

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

- Total points for Customer A and B are 1,370 and 820 respectivly.

***
