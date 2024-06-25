CREATE SCHEMA dannys_diner;

SET search_path = dannys_diner;

CREATE TABLE sales
(
    "customer_id" VARCHAR(1),
    "order_date"  DATE,
    "product_id"  INTEGER
);

INSERT INTO sales
    ("customer_id", "order_date", "product_id")
VALUES ('A', '2021-01-01', '1'),
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


CREATE TABLE menu
(
    "product_id"   INTEGER,
    "product_name" VARCHAR(5),
    "price"        INTEGER
);

INSERT INTO menu
    ("product_id", "product_name", "price")
VALUES ('1', 'sushi', '10'),
       ('2', 'curry', '15'),
       ('3', 'ramen', '12');


CREATE TABLE members
(
    "customer_id" VARCHAR(1),
    "join_date"   DATE
);

INSERT INTO members
    ("customer_id", "join_date")
VALUES ('A', '2021-01-07'),
       ('B', '2021-01-09');


/* --------------------
   Case Study Questions
   --------------------*/

SELECt *
FROM sales;
SELECt *
FROM menu;
SELECT *
FROM members

-- 1. What is the total amount each customer spent at the restaurant?
/*
 Brain storm :
 1. Total amount => SUM(price)
 2. each customer => GROUP BY customer_id
 3. spent at the restaurant => JOIN menu ON product_id = product_id
*/

SELECT s.customer_id,
       SUM(m.price) AS total_amount
FROM sales AS s
         JOIN menu AS m ON s.product_id = m.product_id
GROUP BY s.customer_id

-- 2. How many days has each customer visited the restaurant?
/* -- Brain storm :
    1. days => COUNT(DISTINCT order_date)
    2. each customer => GROUP BY customer_id
    3. visited the restaurant => no need to join
*/

SELECT customer_id,
       COUNT(DISTINCT order_date) AS visit_days
FROM sales
GROUP BY customer_id

-- 3. What was the first item from the menu purchased by each customer?
/* - Brain storm
1. first item => MIN(order_date)
2. each customer => GROUP BY customer_id
3. purchased => JOIN menu ON product_id = product_id
4. Find 1st purchase => ORDER BY order_date ASC
*/

-- @ 5 rows retrieved starting from 1 in 42 ms (execution: 4 ms, fetching: 38 ms)
WITH purchase_counts AS (SELECT s.customer_id,
                                m.product_name,
                                COUNT(s.product_id)                                                              AS purchase_count,
                                ROW_NUMBER() OVER (PARTITION BY s.customer_id ORDER BY COUNT(s.product_id) DESC) AS rn
                         FROM sales s
                                  JOIN
                              menu m ON s.product_id = m.product_id
                         GROUP BY s.customer_id, m.product_name)
SELECT customer_id,
       product_name,
       purchase_count
FROM purchase_counts
WHERE rn = 1;



-- 4. What is the most purchased item on the menu and how many times was it purchased by all customers?
/* Brain storm :
1. most purchased => COUNT(product_id)
2. all customers => no need to group
3. purchased => JOIN menu ON product_id = product_id
4. Find most purchased => ORDER BY COUNT(product_id) DESC
5. the most => LIMIT 1
*/
-- @ 1 row retrieved starting from 1 in 16 ms (execution: 5 ms, fetching: 11 ms)
SELECT m.product_name,
       COUNT(s.product_id) AS total_purchased
FROM sales AS s
         JOIN menu AS m ON m.product_id = s.product_id
GROUP BY m.product_name
ORDER BY COUNT(s.product_id) DESC
LIMIT 1;
-- --- 5. Which item was the most popular for each customer?
/* Brain storm :
    1. most popular => COUNT(product_id)
    2. each customer => GROUP BY customer_id
    3. purchased => JOIN menu ON product_id = product_id
    4. Find most popular => ORDER BY COUNT(product_id) DESC
    5. the most => LIMIT 1 but we need to use ROW_NUMBER() OVER for each customer to find the most popular item
    6. the most popular => WHERE rn = 1 with rn = 1 is the most popular item for each customer has tagged by ROW_NUMBER() OVER
*/
-- @ 3 rows retrieved starting from 1 in 20 ms (execution: 3 ms, fetching: 17 ms)
WITH purchase_counts AS (SELECT s.customer_id,
                                m.product_name,
                                COUNT(s.product_id)                     AS purchase_count,
                                ROW_NUMBER() OVER (
                                    PARTITION BY
                                        s.customer_id
                                    ORDER BY COUNT(s.product_id) DESC ) AS rn
                         FROM sales s
                                  JOIN
                              menu m ON s.product_id = m.product_id
                         GROUP BY s.customer_id, m.product_name)
SELECT customer_id,
       product_name,
       purchase_count
FROM purchase_counts
WHERE rn = 1;

-- 6. Which item was purchased first by the customer after they became a member?
/* Brain storm :
   1. Member is a customer in table members -> A , B except C
   2. first purchase after become a member -> order_date > join_date
   3. first purchase -> ROW_NUMBER() - PARTITION BY cus_id with order_date ASC
   4. purchased -> JOIN menu ON product_id = product_id
   5. each customer -> GROUP BY customer_id
   -- Create a Subquery / table for each customer to find the first purchase after they become a member
   -- Then join this subquery with menu to get the product_name
*/
-- @ 2 rows retrieved starting from 1 in 33 ms (execution: 3 ms, fetching: 30 ms)
WITH purchase_after_membership AS (SELECT s.customer_id,
                                          s.order_date,
                                          s.product_id,
                                          m2.join_date,
                                          ROW_NUMBER() OVER (PARTITION BY s.customer_id ORDER BY s.order_date) as row_num
                                   FROM sales AS s
                                            JOIN members m2 on s.customer_id = m2.customer_id
                                   WHERE s.order_date >= m2.join_date)
SELECT pam.customer_id, pam.order_date, m.product_name
FROM purchase_after_membership AS pam
         JOIN menu AS m ON m.product_id = pam.product_id
WHERE pam.row_num = 1;


-- 7. Which item was purchased just before the customer became a member?
/* BRAIN STORM:
1. just before the customer became a member -> order_date < join_date
2. just before -> ROW_NUMBER() - PARTITION BY cus_id with order_date DESC
3. purchased -> JOIN menu ON product_id = product_id
4. each customer -> GROUP BY customer_id
5. Create a Subquery / table for each customer to find the first purchase after they become a member WITH - AS
6. Then join this subquery with menu to get the product_name
*/
-- @ 2 rows retrieved starting from 1 in 57 ms (execution: 2 ms, fetching: 55 ms)
WITH purchases_before_membership AS (SELECT s.customer_id,
                                            s.order_date,
                                            s.product_id,
                                            m.join_date,
                                            ROW_NUMBER()
                                            OVER (PARTITION BY s.customer_id ORDER BY s.order_date DESC) as row_num
                                     FROM sales AS s
                                              JOIN members AS m ON s.customer_id = m.customer_id
                                     WHERE s.order_date < m.join_date)
SELECT pbm.customer_id, pbm.order_date, m2.product_name
FROM purchases_before_membership AS pbm
         JOIN menu AS m2 ON m2.product_id = pbm.product_id
WHERE pbm.row_num = 1;
-- 8. What is the total items and amount spent for each member before they became a member?
/* Brain Storm:
   1. Total items => COUNT(product_id)
   2. Total amount => SUM(price)
   3. each member => GROUP BY customer_id
*/
-- @ 2 rows retrieved starting from 1 in 25 ms (execution: 2 ms, fetching: 23 ms)
SELECT s.customer_id,
       COUNT(s.product_id) AS total_items,
       SUM(m.price)        AS total_amount_price
FROM sales AS s
         JOIN menu AS m on s.product_id = m.product_id
         JOIN members AS mb on s.customer_id = mb.customer_id
WHERE s.order_date < mb.join_date
GROUP BY s.customer_id
-- 9.  If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?
/* Brain Storm
1. 1$ = 10 points
2. IF sushi => 2x points => price * 2 => CASE WHEN
3. each customer => GROUP BY customer_id
4. Each customers have -> SUM() points = price
*/
-- @ 3 rows retrieved starting from 1 in 51 ms (execution: 4 ms, fetching: 47 ms)
SELECT s.customer_id,
       SUM(CASE
            WHEN m.product_name = 'sushi' THEN m.price * 2
            ELSE m.price
           END
       ) AS total_points
FROM sales AS s
         JOIN menu AS m ON m.product_id = s.product_id
GROUP BY s.customer_id

-- 10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?
/* Brain Storm
   1. first week after a customer joins the program => order_date - join_date <= 7
   2. 2x points => price * 2 => CASE WHEN
   3. each customer => GROUP BY customer_id
   4. Each customers have -> SUM() points = price
   5. Subquery calculate point()
   */
-- @ 2 rows retrieved starting from 1 in 51 ms (execution: 3 ms, fetching: 48 ms)
WITH points AS (SELECT s.customer_id,
                       s.order_date,
                       m.price,
                       m.product_name,
                       CASE
                           WHEN s.order_date BETWEEN mbr.join_date AND mbr.join_date + INTERVAL '6 days' THEN 2
                           WHEN m.product_name = 'sushi' THEN 2
                           ELSE 1
                           END AS multiplier
                FROM sales AS s
                         JOIN menu AS m ON s.product_id = m.product_id
                         JOIN members AS mbr ON s.customer_id = mbr.customer_id)
SELECT p.customer_id,
       SUM(p.price * 10 * p.multiplier) AS total_points
FROM points AS p
WHERE p.order_date <= '2021-01-31'
GROUP BY p.customer_id;

