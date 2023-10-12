# What is the total amount each customer spent at the restaurant?

select s.customer_id,sum(m.price) as spent from sales s,menu m
where s.product_id=m.product_id
group by s.customer_id;

# How many days has each customer visited the restaurant?

with temp as (select s.customer_id, count(day(s.order_date)) as days from sales s, menu m
where s.product_id=m.product_id
group by s.customer_id,s.order_date)
select customer_id,count(days) from temp
group by customer_id;

# What was the first item from the menu purchased by each customer?

with temp2 as (select s.customer_id,m.product_name,m.product_id,dense_rank() over(partition by customer_id order by order_date asc) as rank_ from sales s,menu m
where s.product_id=m.product_id)
select customer_id,product_name from temp2
where rank_ = 1
group by customer_id,product_id;

# What is the most purchased item on the menu and how many times was it purchased by all customers?

select count(product_name)as time_pruchased,product_name  from sales s,menu m
where s.product_id=m.product_id
group by product_name
order by time_pruchased desc limit 1;

# how many times a product purchased by each customer ?

select customer_id,product_name,count(*) as times_purchased from sales s,menu m
where s.product_id=m.product_id
group by customer_id,product_name; 

# What is the most purchased item on the menu and how many times was it purchased by each customer?

with temp4 as(select s.customer_id,m.product_name,m.product_id from sales s
join menu m on s.product_id=m.product_id),
temp5 as (select customer_id,product_name,dense_rank()over(order by product_id desc)as rank3 from temp4)
select customer_id,product_name,count(rank3) from temp5
where rank3=1 group by customer_id;

# Which item was the most popular for each customer?

with temp5 as(select s.customer_id,m.product_name,count(m.product_name) as number_ from sales s
join menu m on s.product_id=m.product_id
group by s.customer_id,m.product_name)
select customer_id,product_name from
(select customer_id,product_name,dense_rank() over(partition by customer_id order by number_ desc) 
as rank4 from temp5) as temp6
where rank4= 1
group by customer_id,product_name;

# Which item was purchased first by the customer after they became a member?

select customer_id,join_date,product_name,order_date from (select s.customer_id,m.join_date,me.product_name,s.order_date,dense_rank()over(partition by customer_id order by order_date)
as rank_date from sales s
join members m on m.customer_id=s.customer_id
join menu me on s.product_id=me.product_id
where s.order_date >= m.join_date
group by s.customer_id, me.product_name,s.order_date
order by s.order_date desc) as rank_table
where rank_date=1;

# Which item was purchased just before the customer became a member?

with temp as (select s.customer_id,m.product_name,s.order_date,me.join_date,
dense_rank() over(partition by s.customer_id order by s.order_date desc) as item_rank
from sales s
join menu m on s.product_id=m.product_id
join members me on s.customer_id=me.customer_id
where s.order_date <= me.join_date)
select customer_id,product_name,order_date,join_date from temp
where item_rank=1;

# What is the total items and amount spent for each member before they became a member including the date they joined?

select s.customer_id,sum(m.price),count(*)from sales s
join menu m on s.product_id=m.product_id
join members me on s.customer_id=me.customer_id
where s.order_date<=me.join_date
group by s.customer_id;

# What is the total items and amount spent for each member before they became a member?

select s.customer_id,sum(m.price),count(*)from sales s
join menu m on s.product_id=m.product_id
join members me on s.customer_id=me.customer_id
where s.order_date<me.join_date
group by s.customer_id;

# If each $1 spent equates to 10 points and sushi has a 2x points multiplier
# - how many points would each customer have?

with temp as (select s.customer_id,m.product_name, (case when m.product_name in ('curry','ramen') then m.price *10 else m.price*20 end )
as points
from sales s join menu m on s.product_id=m.product_id)
select customer_id,sum(points) from temp
group by customer_id;

# In the first week after a customer joins the program (including their join date) they earn 
#2x points on all items, not just sushi - how many points do customer A and B have at the end of January?

with temp1 as(
select me.product_name,me.price,s.customer_id,s.order_date,s.product_id,m.join_date , date_add(join_date,INTERVAL 6 DAY) as 1st_week 
from sales as s
join members as m
on m.customer_id = s.customer_id
join menu as me
on me.product_id = s.product_id) ,
# where order_date between join_date and 1st_week
temp2 as(
select * , case when order_date between join_date and 1st_week then price*10*2
		when order_date not between join_date and 1st_week and product_name like 'sushi' then price*10*2
        when order_date not between join_date and 1st_week and product_name like 'curry' then price*10
        when order_date not between join_date and 1st_week and product_name like 'ramen' then price*10
end as points
from temp1)
select customer_id,sum(points) as total_points
from temp2
where MONTH(order_date) = 1
group by customer_id ;