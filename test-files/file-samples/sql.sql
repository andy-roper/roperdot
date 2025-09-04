-- Poorly formatted SQL file for testing formatters
create table users(id INT primary key auto_increment,name varchar(100) not null,email VARCHAR(255) UNIQUE not null,age int,created_at timestamp default current_timestamp);

CREATE TABLE orders (
id int PRIMARY KEY AUTO_INCREMENT,user_id INT,total DECIMAL(10,2),
status enum('pending','processing','shipped','delivered') DEFAULT 'pending',
order_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
FOREIGN KEY(user_id) REFERENCES users(id) ON DELETE cascade
);

insert into users(name,email,age) values('John Doe','john@example.com',25),('Jane Smith','jane@example.com',30),('Bob Johnson','bob@example.com',35);

INSERT INTO orders (user_id,total,status) VALUES (1,99.99,'pending'),(2,149.50,'processing'),(1,75.25,'shipped'),(3,200.00,'delivered');

select u.name,u.email,count(o.id) as order_count,sum(o.total) as total_spent from users u left join orders o on u.id = o.user_id where u.age >= 25 group by u.id,u.name,u.email having count(o.id) > 0 order by total_spent desc;

SELECT o.id as order_id,u.name as customer_name,o.total,o.status,o.order_date FROM orders o INNER JOIN users u ON o.user_id = u.id WHERE o.status IN('pending','processing') AND o.total > 50.00 ORDER BY o.order_date DESC LIMIT 10;

update users set age = 26 where name = 'John Doe';

UPDATE orders SET status = 'shipped',updated_at = NOW() WHERE status = 'processing' and total > 100.00;

select * from(select user_id,avg(total) as avg_order_value from orders group by user_id) as subquery where avg_order_value > (select avg(total) from orders);

DELETE FROM orders WHERE status = 'delivered' AND order_date < DATE_SUB(NOW(),INTERVAL 1 YEAR);

create index idx_user_email on users(email);
CREATE INDEX idx_order_status ON orders(status,order_date);

alter table users add column last_login timestamp null;
ALTER TABLE orders ADD CONSTRAINT chk_total CHECK(total >= 0);

select u.name,o.total,
case 
when o.total < 50 then 'Small Order'
when o.total between 50 and 100 then 'Medium Order'
else 'Large Order'
end as order_size
from users u
join orders o on u.id = o.user_id
where o.status != 'cancelled'
order by o.total;

CREATE VIEW user_order_summary AS
select u.id,u.name,u.email,COUNT(o.id) as total_orders,COALESCE(SUM(o.total),0) as total_spent,MAX(o.order_date) as last_order_date from users u left join orders o on u.id = o.user_id group by u.id,u.name,u.email;

drop table if exists temp_users;

CREATE TEMPORARY TABLE temp_users AS SELECT * FROM users WHERE age > 30;

select name,email from users union all select 'Guest User' as name,'guest@example.com' as email;