-- Creating datasets

CREATE TABLE sales (
  customer_id VARCHAR(1),
  order_date DATE,
  product_id INTEGER
);

INSERT INTO sales
  (customer_id, order_date, product_id)
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
  product_id INTEGER,
  product_name VARCHAR(5),
  price INTEGER
);

INSERT INTO menu
  (product_id, product_name, price)
VALUES
  ('1', 'sushi', '10'),
  ('2', 'curry', '15'),
  ('3', 'ramen', '12');

CREATE TABLE members (
  customer_id VARCHAR(1),
  join_date DATE
);

INSERT INTO members
  (customer_id, join_date)
VALUES
  ('A', '2021-01-07'),
  ('B', '2021-01-09');

-- Queries for CASE STUDY QUESTIONS

-- Ques 1. What is the total amount each customer spent at the restaurant?

select s.customer_id, sum(m.price) as amount_spent
from sales s 
left join menu m on s.product_id = m.product_id
group by s.customer_id
order by s.customer_id;
--------------------------------------------------------------------------------------------------------------------------------------------------------------
  
-- Ques 2. How many days has each customer visited the restaurant?

select customer_id, count(distinct order_date) as num_of_days_visited
from sales
group by customer_id;
--------------------------------------------------------------------------------------------------------------------------------------------------------------

-- Ques 3. What was the first item from the menu purchased by each customer?

SELECT distinct customer_id, product_name as first_order
from
( select s.customer_id, m.product_name,
dense_rank() over (partition by s.customer_id order by s.order_date) as rn
FROM sales s left join menu m 
on s.product_id = m.product_id) as derivedtable
where rn=1;
--------------------------------------------------------------------------------------------------------------------------------------------------------------

-- Ques 4. What is the most purchased item on the menu and how many times was it purchased by all customers?

with orderedtotal as (
select product_id, count(customer_id) as total_orders, dense_rank() over (order by count(customer_id) desc) as rn
from sales 
group by product_id)

select od.product_id, m.product_name, total_orders 
from orderedtotal od join menu m
on od.product_id = m.product_id
where rn=1;
--------------------------------------------------------------------------------------------------------------------------------------------------------------
  
-- Ques 5. Which item was the most popular for each customer?

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
--------------------------------------------------------------------------------------------------------------------------------------------------------------

-- Ques 6. Which item was purchased first by the customer after they became a member?

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
--------------------------------------------------------------------------------------------------------------------------------------------------------------

-- Ques 7. Which item was purchased just before the customer became a member?

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
--------------------------------------------------------------------------------------------------------------------------------------------------------------

-- Ques 8. What is the total items and amount spent for each member before they became a member?

SELECT 
mem.customer_id, count(s.product_id) as total_items, sum(m.price) as total_amount
FROM members mem 
join sales s on mem.customer_id = s.customer_id and s.order_date < mem.join_date
join menu m on s.product_id = m.product_id
group by mem.customer_id
order by mem.customer_id;
--------------------------------------------------------------------------------------------------------------------------------------------------------------

-- Ques 9. If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?
SELECT 
s.customer_id, 
sum(case when s.product_id=1 then m.price*20 else m.price*10 end) as total_points
FROM sales s
join menu m on s.product_id = m.product_id
group by s.customer_id
order by s.customer_id;
--------------------------------------------------------------------------------------------------------------------------------------------------------------

/* Ques 10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi. 
how many points do customer A and B have at the end of January?*/

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
      (case when product_id=1 then price*20 else price*10 end) 
  end as points
from saleswithpricecte)

select customer_id, sum(points) as total_points
from finalcte
where month(order_date) = 01 and year(order_date)='2021'
group by customer_id
order by customer_id;
