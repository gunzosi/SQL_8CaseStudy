CREATE DATABASE pizza_runner;

CREATE SCHEMA pizza_runner;
-- DROP SCHEMA pizza_runner;
SET search_path = pizza_runner;

-- DROP TABLE IF EXISTS runners;
CREATE TABLE runners
(
    "runner_id"         INTEGER,
    "registration_date" DATE
);
INSERT INTO runners
    ("runner_id", "registration_date")
VALUES (1, '2021-01-01'),
       (2, '2021-01-03'),
       (3, '2021-01-08'),
       (4, '2021-01-15');


-- DROP TABLE IF EXISTS customer_orders;
CREATE TABLE customer_orders
(
    "order_id"    INTEGER,
    "customer_id" INTEGER,
    "pizza_id"    INTEGER,
    "exclusions"  VARCHAR(4),
    "extras"      VARCHAR(4),
    "order_time"  TIMESTAMP
);

INSERT INTO customer_orders
("order_id", "customer_id", "pizza_id", "exclusions", "extras", "order_time")
VALUES ('1', '101', '1', '', '', '2020-01-01 18:05:02'),
       ('2', '101', '1', '', '', '2020-01-01 19:00:52'),
       ('3', '102', '1', '', '', '2020-01-02 23:51:23'),
       ('3', '102', '2', '', NULL, '2020-01-02 23:51:23'),
       ('4', '103', '1', '4', '', '2020-01-04 13:23:46'),
       ('4', '103', '1', '4', '', '2020-01-04 13:23:46'),
       ('4', '103', '2', '4', '', '2020-01-04 13:23:46'),
       ('5', '104', '1', 'null', '1', '2020-01-08 21:00:29'),
       ('6', '101', '2', 'null', 'null', '2020-01-08 21:03:13'),
       ('7', '105', '2', 'null', '1', '2020-01-08 21:20:29'),
       ('8', '102', '1', 'null', 'null', '2020-01-09 23:54:33'),
       ('9', '103', '1', '4', '1, 5', '2020-01-10 11:22:59'),
       ('10', '104', '1', 'null', 'null', '2020-01-11 18:34:49'),
       ('10', '104', '1', '2, 6', '1, 4', '2020-01-11 18:34:49');


-- DROP TABLE IF EXISTS runner_orders;
CREATE TABLE runner_orders
(
    "order_id"     INTEGER,
    "runner_id"    INTEGER,
    "pickup_time"  VARCHAR(19),
    "distance"     VARCHAR(7),
    "duration"     VARCHAR(10),
    "cancellation" VARCHAR(23)
);

INSERT INTO runner_orders
("order_id", "runner_id", "pickup_time", "distance", "duration", "cancellation")
VALUES ('1', '1', '2020-01-01 18:15:34', '20km', '32 minutes', ''),
       ('2', '1', '2020-01-01 19:10:54', '20km', '27 minutes', ''),
       ('3', '1', '2020-01-03 00:12:37', '13.4km', '20 mins', NULL),
       ('4', '2', '2020-01-04 13:53:03', '23.4', '40', NULL),
       ('5', '3', '2020-01-08 21:10:57', '10', '15', NULL),
       ('6', '3', 'null', 'null', 'null', 'Restaurant Cancellation'),
       ('7', '2', '2020-01-08 21:30:45', '25km', '25mins', 'null'),
       ('8', '2', '2020-01-10 00:15:02', '23.4 km', '15 minute', 'null'),
       ('9', '2', 'null', 'null', 'null', 'Customer Cancellation'),
       ('10', '1', '2020-01-11 18:50:20', '10km', '10minutes', 'null');


-- DROP TABLE IF EXISTS pizza_names;
CREATE TABLE pizza_names
(
    "pizza_id"   INTEGER,
    "pizza_name" TEXT
);
INSERT INTO pizza_names
    ("pizza_id", "pizza_name")
VALUES (1, 'Meatlovers'),
       (2, 'Vegetarian');


-- DROP TABLE IF EXISTS pizza_recipes;
CREATE TABLE IF NOT EXISTS pizza_recipes
(
    "pizza_id" INTEGER,
    "toppings" TEXT
);
INSERT INTO pizza_recipes
    ("pizza_id", "toppings")
VALUES (1, '1, 2, 3, 4, 5, 6, 8, 10'),
       (2, '4, 6, 7, 9, 11, 12');


-- DROP TABLE IF EXISTS pizza_toppings;
CREATE TABLE IF NOT EXISTS pizza_toppings
(
    "topping_id"   INTEGER,
    "topping_name" TEXT
);
INSERT INTO pizza_toppings
    ("topping_id", "topping_name")
VALUES (1, 'Bacon'),
       (2, 'BBQ Sauce'),
       (3, 'Beef'),
       (4, 'Cheese'),
       (5, 'Chicken'),
       (6, 'Mushrooms'),
       (7, 'Onions'),
       (8, 'Pepperoni'),
       (9, 'Peppers'),
       (10, 'Salami'),
       (11, 'Tomatoes'),
       (12, 'Tomato Sauce');

-- ETL Query
SELECT *
FROM customer_orders;
SELECT *
FROM pizza_names;
SELECT *
FROM pizza_recipes;
SELECT *
FROM pizza_toppings;
SELECT *
FROM runner_orders;
SELECT *
FROM runners;

---- PART A : ------------------------------- A. Pizza Metrics ---------------------------------------------
-- ⁉️ @ 1. How many pizzas were ordered?
/* --- Brain Storm
1. Count the total number of rows in the `customer_orders` table, each row represents a pizza order.
2. COUNT()
*/
-- ⚡ Runtime : 1 row retrieved starting from 1 in 42 ms (execution: 3 ms, fetching: 39 ms)
--- QUERY :
SELECT COUNT(*) AS total_pizzas_ordered
FROM customer_orders;

-- ⁉️ @ 2. How many unique customer orders were made?
/* --- Brain Storm
1. Count the total number of unique `order_id` in the `customer_orders` table.
*/
-- ⚡ Runtime :
--- QUERY :
SELECT COUNT(DISTINCT "order_id") AS unique_orders
FROM customer_orders;

-- ⁉️ @ 3. How many successful orders were delivered by each runner?
/* --- Brain Storm
1. success order => `cancellation` is NULL
2. Count the total number of successful orders delivered by each runner. => COUNT()
3. GROUP BY `runner_id`
*/
-- ⚡ Runtime :
--- QUERY :
SELECT runner_id, COUNT(order_id) AS successful_orders
FROM runner_orders
WHERE cancellation IS NULL
   OR cancellation = ''
GROUP BY runner_id;

-- ⁉️ @ 4. How many of each type of pizza was delivered?
/* --- Brain Storm
1.
2.
*/
-- ⚡ Runtime :
--- QUERY :
SELECT pn.pizza_name, COUNT(co.pizza_id) AS total_delivered
FROM customer_orders AS co
         JOIN pizza_names AS pn ON pn.pizza_id = co.pizza_id
GROUP BY pn.pizza_name;

-- ⁉️ @ 5. How many Vegetarian and Meatlovers were ordered by each customer?
/* --- Brain Storm
1.How many - COUNT()
2. Vegetarian and Meatlovers - WHERE
3. by each customer - GROUP BY
*/
-- ⚡ Runtime :
--- QUERY : 8 rows retrieved starting from 1 in 43 ms (execution: 3 ms, fetching: 40 ms)
--- QUERY without WHERE : 8 rows retrieved starting from 1 in 22 ms (execution: 3 ms, fetching: 19 ms)
SELECT co.customer_id,
       pn.pizza_name,
       COUNT(co.pizza_id) AS total_ordered
FROM customer_orders co
         JOIN pizza_names pn ON co.pizza_id = pn.pizza_id
-- WHERE pizza_name IN ('Vegetarian', 'Meatlovers')
GROUP BY co.customer_id, pn.pizza_name;

-- ⁉️ @ 6. What was the maximum number of pizzas delivered in a single order?
/* --- Brain Storm
1. Max number of pizzas - MAX()
2. delivered in a single order - GROUP BY
3. Find MAXIMUM Order - ORDER BY DESC LIMIT 1
*/
-- ⚡ Runtime :
--- QUERY :
SELECT MAX(pizza_count) AS max_pizzas_delivered
FROM (SELECT order_id, COUNT(pizza_id) AS pizza_count
      FROM customer_orders
      GROUP BY order_id) subquery;


-- ⁉️ @ 7. For each customer, how many delivered pizzas had at least 1 change and how many had no changes?
/* --- Brain Storm
1.
*/
-- ⚡ Runtime :
--- QUERY :
SELECT customer_id,
       SUM(CASE WHEN exclusions IS NOT NULL OR extras IS NOT NULL THEN 1 ELSE 0 END) AS pizzas_with_changes,
       SUM(CASE WHEN exclusions IS NULL AND extras IS NULL THEN 1 ELSE 0 END)        AS pizzas_without_changes
FROM customer_orders
GROUP BY customer_id;

-- ⁉️ @ 8. How many pizzas were delivered that had both exclusions and extras?
/* --- Brain Storm
1. Exclusions and Extras - WHERE IS NOT NULL
2. Count the total number of pizzas - COUNT()
3. delivered - WHERE IS NOT NULL
*/
-- ⚡ Runtime :
--- QUERY :
SELECT COUNT(*) AS pizzas_with_both_changes
FROM customer_orders
WHERE exclusions IS NOT NULL
  AND extras IS NOT NULL;

-- ⁉️ @ 9. What was the total volume of pizzas ordered for each hour of the day?
/* --- Brain Storm
1. each hour of the day - EXTRACT(HOUR FROM order_time)
2. total volume of pizzas - COUNT()
3. GROUP BY EXTRACT(HOUR FROM order_time)
*/
-- ⚡ Runtime : 6 rows retrieved starting from 1 in 23 ms (execution: 4 ms, fetching: 19 ms)
--- QUERY :
SELECT EXTRACT(HOUR FROM order_time) AS hour_of_day,
       COUNT(pizza_id)               AS total_pizzas_ordered
FROM customer_orders
GROUP BY hour_of_day
ORDER BY hour_of_day;
-- ⚡ Runtime : 6 rows retrieved starting from 1 in 20 ms (execution: 3 ms, fetching: 17 ms)
SELECT EXTRACT(HOUR FROM order_time) AS order_hour, COUNT(*) AS total_pizzas
FROM customer_orders
GROUP BY EXTRACT(HOUR FROM order_time)
ORDER BY order_hour;


-- @ 10. What was the volume of orders for each day of the week?
/* --- Brain Storm
1. each day of the week - EXTRACT(DOW FROM order_time)
2. total volume of orders - COUNT()
3. GROUP BY EXTRACT(DOW FROM order_time)
*/
-- ⚡ Runtime :
--- QUERY :
SELECT EXTRACT(DOW FROM order_time) AS day_of_week,
       COUNT(*)                     AS total_orders
FROM customer_orders
GROUP BY day_of_week
ORDER BY day_of_week;

-- # ---------------------------------------------------------------------------------------------
---- PART B 🐍 : ---------------------- B. Runner and Customer Experience ---------------------------
-- ⁉️ @ B.1 : How many runners signed up for each 1 week period? (i.e. week starts 2021-01-01)
/* --- Brain Storm
1. 1 week period - DATE_TRUNC('week', registration_date)
2. Count the total number of runners - COUNT()
3. GROUP BY DATE_TRUNC('week', registration_date)
*/
-- ⚡ Runtime :
--- QUERY : 3 rows retrieved starting from 1 in 57 ms (execution: 5 ms, fetching: 52 ms)
SELECT DATE_TRUNC('week', registration_date) AS week_start,
       COUNT(*)                              AS runners_signed_up
FROM runners
GROUP BY week_start
ORDER BY week_start;

-- ⁉️ @ B.2 : What was the average time in minutes it took for each runner to arrive at the Pizza Runner HQ to pickup the order?
/* --- Brain Storm
1. Average time in minutes - AVG (pickup_time - order_time) => EXTRACT(EPOCH FROM pickup_time - order_time) / 60
2. took for each runner to arrive at the Pizza Runner HQ to pickup the order - pickup_time - order_time
3. GROUP BY runner_id
*/
-- ⚡ Runtime :
--- QUERY :
SELECT ro.runner_id,
       AVG(EXTRACT(EPOCH FROM (ro.pickup_time::timestamp - co.order_time)) / 60) AS avg_pickup_time_minutes
FROM runner_orders ro
         JOIN
     customer_orders co ON ro.order_id = co.order_id
WHERE ro.pickup_time IS NOT NULL
  AND ro.pickup_time != 'null'
GROUP BY ro.runner_id;


-- ⁉️ @ B.3 : Is there any relationship between the number of pizzas and how long the order takes to prepare?
/* --- Brain Storm

*/
-- ⚡ Runtime :
--- QUERY :
SELECT COUNT(co.pizza_id)                                                        AS pizza_count,
       AVG(EXTRACT(EPOCH FROM (ro.pickup_time::timestamp - co.order_time)) / 60) AS avg_prepare_time_minutes
FROM customer_orders co
         JOIN
     runner_orders ro ON co.order_id = ro.order_id
WHERE ro.pickup_time IS NOT NULL
  AND ro.pickup_time != 'null'
GROUP BY co.order_id
ORDER BY pizza_count;
-- ⁉️ @ B.4 : What was the average distance travelled for each customer?
/* --- Brain Storm

*/
-- ⚡ Runtime :
--- QUERY :
SELECT co.customer_id,
       AVG(CAST(ro.distance AS DOUBLE PRECISION)) AS avg_distance_km
FROM customer_orders co
         JOIN
     runner_orders ro ON co.order_id = ro.order_id
WHERE ro.distance IS NOT NULL
GROUP BY co.customer_id;
--- GPT
-- 5 rows retrieved starting from 1 in 36 ms (execution: 3 ms, fetching: 33 ms)
SELECT co.customer_id,
       AVG(
               CASE
                   WHEN ro.distance ~ '^\d+(\.\d+)?(km)?$'
                       THEN CAST(REGEXP_REPLACE(ro.distance, '[^\d.]+', '', 'g') AS DOUBLE PRECISION)
                   ELSE NULL
                   END
       ) AS avg_distance_km
FROM customer_orders co
         JOIN
     runner_orders ro ON co.order_id = ro.order_id
WHERE ro.distance IS NOT NULL
GROUP BY co.customer_id;

-- ⁉️ @ B.5 : What was the difference between the longest and shortest delivery times for all orders?
/* --- Brain Storm

*/
-- ⚡ Runtime :
--- QUERY :
SELECT MAX(CAST(REGEXP_REPLACE(SPLIT_PART(duration, ' ', 1), '\D+', '', 'g') AS INTEGER)) -
       MIN(CAST(REGEXP_REPLACE(SPLIT_PART(duration, ' ', 1), '\D+', '', 'g') AS INTEGER)) AS delivery_time_difference_minutes
FROM runner_orders
WHERE duration IS NOT NULL
  AND duration != 'null'
  AND REGEXP_REPLACE(SPLIT_PART(duration, ' ', 1), '\D+', '', 'g') != '';

-- ⁉️ @ B.6 : What was the average speed for each runner for each delivery and do you notice any trend for these values?
/* --- Brain Storm

*/
-- ⚡ Runtime :
--- QUERY :
SELECT ro.runner_id,
       AVG(
               CAST(REGEXP_REPLACE(ro.distance, '[^\d.]+', '', 'g') AS DOUBLE PRECISION) /
               (CAST(REGEXP_REPLACE(SPLIT_PART(ro.duration, ' ', 1), '[^\d.]+', '', 'g') AS DOUBLE PRECISION) / 60)
       ) AS avg_speed_kmh
FROM runner_orders ro
WHERE ro.distance IS NOT NULL
  AND ro.distance != 'null'
  AND ro.duration IS NOT NULL
  AND ro.duration != 'null'
  AND REGEXP_REPLACE(ro.distance, '[^\d.]+', '', 'g') != ''
  AND REGEXP_REPLACE(SPLIT_PART(ro.duration, ' ', 1), '[^\d.]+', '', 'g') != ''
GROUP BY ro.runner_id
ORDER BY avg_speed_kmh DESC;
-- ⁉️ @ B.7 : What is the successful delivery percentage for each runner?
/* --- Brain Storm

*/
-- ⚡ Runtime :
--- QUERY :
SELECT ro.runner_id,
       100.0 * SUM(CASE WHEN ro.cancellation IS NULL OR ro.cancellation = '' THEN 1 ELSE 0 END) /
       COUNT(ro.order_id) AS success_rate
FROM runner_orders ro
GROUP BY ro.runner_id;
-- # ---------------------------------------------------------------------------------------------
---- PART C 🦖 : ------------------------- C. Ingredient Optimisation -------------------------------
-- ⁉️ @ C.1 : What are the standard ingredients for each pizza?
/* --- Brain Storm

*/
-- ⚡ Runtime : 16 rows retrieved starting from 1 in 371 ms (execution: 20 ms, fetching: 351 ms)
--- QUERY :
SELECT pn.pizza_name,
       pt.topping_name
FROM pizza_recipes pr
         JOIN
     pizza_names pn ON pr.pizza_id = pn.pizza_id
         JOIN
     pizza_toppings pt ON POSITION(pt.topping_id::TEXT IN pr.toppings) > 0
ORDER BY pn.pizza_name, pt.topping_name;
-- ⁉️ @ C.2 : What was the most commonly added extra?
/* --- Brain Storm

*/
-- ⚡ Runtime :
--- QUERY :
SELECT pt.topping_name,
       COUNT(*) AS extra_count
FROM customer_orders co
         JOIN
     pizza_toppings pt ON POSITION(pt.topping_id::TEXT IN co.extras) > 0
GROUP BY pt.topping_name
ORDER BY extra_count DESC
LIMIT 1;

-- ⁉️ @ C.3 : What was the most common exclusion?
/* --- Brain Storm

*/
-- ⚡ Runtime :
--- QUERY :
SELECT pt.topping_name,
       COUNT(*) AS exclusion_count
FROM customer_orders co
         JOIN
     pizza_toppings pt ON POSITION(pt.topping_id::TEXT IN co.exclusions) > 0
GROUP BY pt.topping_name
ORDER BY exclusion_count DESC
LIMIT 1;

-- ⁉️ @ C.4 : Generate an order item for each record in the customers_orders table in the format of one of the following:
-- Meat Lovers
-- Meat Lovers - Exclude Beef
-- Meat Lovers - Extra Bacon
-- Meat Lovers - Exclude Cheese, Bacon - Extra Mushroom, Peppers
/* --- Brain Storm

*/
-- ⚡ Runtime :
--- QUERY :
SELECT co.order_id,
       pn.pizza_name ||
       CASE
           WHEN co.exclusions IS NOT NULL AND co.exclusions <> '' THEN ' - Exclude ' ||
                                                                       STRING_AGG(pt_ex.topping_name, ', ' ORDER BY pt_ex.topping_name)
           ELSE ''
           END ||
       CASE
           WHEN co.extras IS NOT NULL AND co.extras <> '' THEN ' - Extra ' ||
                                                               STRING_AGG(pt_ex_topping.topping_name, ', '
                                                                          ORDER BY pt_ex_topping.topping_name)
           ELSE ''
           END AS order_item
FROM customer_orders co
         JOIN
     pizza_names pn ON co.pizza_id = pn.pizza_id
         LEFT JOIN
     pizza_toppings pt_ex ON POSITION(pt_ex.topping_id::TEXT IN co.exclusions) > 0
         LEFT JOIN
     pizza_toppings pt_ex_topping ON POSITION(pt_ex_topping.topping_id::TEXT IN co.extras) > 0
GROUP BY co.order_id, pn.pizza_name, co.exclusions, co.extras
ORDER BY co.order_id;
-- ⁉️ @ C.5 : Generate an alphabetically ordered comma separated ingredient list for each pizza order from the
-- customer_orders table and add a 2x in front of any relevant ingredients
-- For example: "Meat Lovers: 2xBacon, Beef, ... , Salami"
/* --- Brain Storm

*/
-- ⚡ Runtime :
--- QUERY :
SELECT co.order_id,
       pn.pizza_name || ': ' ||
       STRING_AGG(
               CASE
                   WHEN pt.topping_name IN (SELECT pt_ex_topping.topping_name
                                            FROM pizza_toppings pt_ex_topping
                                            WHERE POSITION(pt_ex_topping.topping_id::TEXT IN co.extras) > 0)
                       THEN '2x' || pt.topping_name
                   ELSE pt.topping_name
                   END,
               ', ' ORDER BY pt.topping_name
       ) AS ingredient_list
FROM customer_orders co
         JOIN
     pizza_names pn ON co.pizza_id = pn.pizza_id
         JOIN
     pizza_recipes pr ON co.pizza_id = pr.pizza_id
         JOIN
     pizza_toppings pt ON POSITION(pt.topping_id::TEXT IN pr.toppings) > 0
GROUP BY co.order_id, pn.pizza_name
ORDER BY co.order_id;

-- ⁉️ @ C.6 : What is the total quantity of each ingredient used in all delivered pizzas sorted by most frequent first?
/* --- Brain Storm

*/
-- ⚡ Runtime :
--- QUERY :
SELECT pt.topping_name,
       COUNT(*) AS total_quantity
FROM customer_orders co
         JOIN
     pizza_recipes pr ON co.pizza_id = pr.pizza_id
         JOIN
     pizza_toppings pt ON POSITION(pt.topping_id::TEXT IN pr.toppings) > 0
GROUP BY pt.topping_name
ORDER BY total_quantity DESC;

-- # ---------------------------------------------------------------------------------------------

---- PART D 🐳 : ------------------------------ D. Pricing and Ratings ------------------------------
-- ⁉️ @ D.1 : If a Meat Lovers pizza costs $12 and Vegetarian costs $10 and there were no charges for changes - how much money has Pizza Runner made so far if there are no delivery fees?
/* --- Brain Storm

*/
-- ⚡ Runtime :
--- QUERY :
SELECT SUM(CASE
               WHEN pn.pizza_name = 'Meatlovers' THEN 12
               WHEN pn.pizza_name = 'Vegetarian' THEN 10
    END) AS total_revenue
FROM customer_orders co
         JOIN
     pizza_names pn ON co.pizza_id = pn.pizza_id;

-- ⁉️ @ D.2 : What if there was an additional $1 charge for any pizza extras?
-- Add cheese is $1 ext
/* --- Brain Storm

*/
-- ⚡ Runtime :
--- QUERY :
SELECT SUM(CASE
               WHEN pn.pizza_name = 'Meatlovers' THEN 12
               WHEN pn.pizza_name = 'Vegetarian' THEN 10
               END +
           CASE
               WHEN co.extras IS NOT NULL AND co.extras <> '' THEN 1
               ELSE 0
               END) AS total_revenue_with_extras
FROM customer_orders co
         JOIN
     pizza_names pn ON co.pizza_id = pn.pizza_id;
-- ⁉️ @ D.3 : The Pizza Runner team now wants to add an additional ratings system that allows customers to rate their runner, how would you design an additional table for this new dataset - generate a schema for this new table and insert your own data for ratings for each successful customer order between 1 to 5.
/* --- Brain Storm

*/
-- ⚡ Runtime :
--- QUERY :
CREATE TABLE runner_ratings
(
    order_id    INTEGER,
    customer_id INTEGER,
    runner_id   INTEGER,
    rating      INTEGER,
    PRIMARY KEY (order_id)
);

-- Insert sample data
INSERT INTO runner_ratings (order_id, customer_id, runner_id, rating)
VALUES (1, 101, 1, 5),
       (2, 101, 1, 4),
       (3, 102, 1, 5),
       (4, 103, 2, 3),
       (5, 104, 3, 4),
       (7, 105, 2, 5),
       (8, 102, 2, 4),
       (10, 104, 1, 5);
-- ⁉️ @ D.4 : Using your newly generated table - can you join all of the information together to form a table which has the following information for successful deliveries?
-- customer_id
-- order_id
-- runner_id
-- rating
-- order_time
-- pickup_time
-- Time between order and pickup
-- Delivery duration
-- Average speed
-- Total number of pizzas
/* --- Brain Storm

*/
-- ⚡ Runtime :
--- QUERY :
SELECT co.customer_id,
       ro.order_id,
       ro.runner_id,
       rr.rating,
       co.order_time,
       ro.pickup_time,
       EXTRACT(EPOCH FROM (ro.pickup_time::timestamp - co.order_time)) / 60 AS time_between_order_and_pickup,
       CAST(REGEXP_REPLACE(ro.duration, '[^\d.]+', '', 'g') AS INTEGER)     AS delivery_duration,
       CASE
           WHEN CAST(REGEXP_REPLACE(ro.duration, '[^\d.]+', '', 'g') AS INTEGER) > 0 THEN
               CAST(REGEXP_REPLACE(ro.distance, '[^\d.]+', '', 'g') AS DOUBLE PRECISION) /
               NULLIF(CAST(REGEXP_REPLACE(ro.duration, '[^\d.]+', '', 'g') AS INTEGER), 0) * 60
           ELSE
               NULL
           END                                                              AS avg_speed_kmh,
       COUNT(co.pizza_id)                                                   AS total_pizzas
FROM runner_orders ro
         JOIN
     customer_orders co ON ro.order_id = co.order_id
         JOIN
     runner_ratings rr ON ro.order_id = rr.order_id
WHERE (ro.cancellation IS NULL OR ro.cancellation = '')
  AND ro.duration IS NOT NULL
  AND REGEXP_REPLACE(ro.duration, '[^\d.]+', '', 'g') != ''
  AND CAST(REGEXP_REPLACE(ro.duration, '[^\d.]+', '', 'g') AS INTEGER) > 0
GROUP BY co.customer_id, ro.order_id, ro.runner_id, rr.rating, co.order_time, ro.pickup_time, ro.duration, ro.distance
ORDER BY co.customer_id;
-- ⁉️ @ D.5 : If a Meat Lovers pizza was $12 and Vegetarian $10 fixed prices with no cost for extras and each runner is paid $0.30 per kilometre traveled - how much money does Pizza Runner have left over after these deliveries?
/* --- Brain Storm

*/
-- ⚡ Runtime :
--- QUERY :
WITH revenue AS (SELECT SUM(CASE
                                WHEN pn.pizza_name = 'Meatlovers' THEN 12
                                WHEN pn.pizza_name = 'Vegetarian' THEN 10
    END) AS total_revenue
                 FROM customer_orders co
                          JOIN
                      pizza_names pn ON co.pizza_id = pn.pizza_id),
     runner_payments AS (SELECT SUM(CAST(REGEXP_REPLACE(ro.distance, '[^\d.]+', '', 'g') AS DOUBLE PRECISION) *
                                    0.30) AS total_runner_payment
                         FROM runner_orders ro
                         WHERE ro.distance IS NOT NULL
                           AND ro.distance != 'null')
SELECT revenue.total_revenue - runner_payments.total_runner_payment AS net_revenue
FROM revenue,
     runner_payments;
-- # ---------------------------------------------------------------------------------------------

---- PART E 🐉 : E. Bonus Questions
-- ⁉️ @ E : If Danny wants to expand his range of pizzas - how would this impact the existing data design?
-- Write an INSERT statement to demonstrate what would happen if a new Supreme pizza with all the toppings was added to the Pizza Runner menu?


