CREATE DATABASE data_mart;

CREATE SCHEMA data_mart;
SET search_path = data_mart;

-- DROP TABLE IF EXISTS data_mart.weekly_sales;
CREATE TABLE data_mart.weekly_sales
(
    "week_date"     VARCHAR(7),
    "region"        VARCHAR(13),
    "platform"      VARCHAR(7),
    "segment"       VARCHAR(4),
    "customer_type" VARCHAR(8),
    "transactions"  INTEGER,
    "sales"         INTEGER
);

INSERT INTO data_mart.weekly_sales
("week_date", "region", "platform", "segment", "customer_type", "transactions", "sales")



----------------------------------------- @ Data Cleansing Steps @ ------------------------------------------
-- In a single query, perform the following operations and generate a new table in the data_mart schema named clean_weekly_sales:
-- 1. Convert the week_date to a DATE format
DROP TABLE IF EXISTS clean_weekly_sales;
CREATE TABLE IF NOT EXISTS data_mart.clean_weekly_sales AS
SELECT CAST(weekly_sales.week_date AS DATE) AS week_date,
       region,
       weekly_sales.segment                 AS original_segment,
       weekly_sales.sales,
       weekly_sales.transactions
FROM data_mart.weekly_sales;

-- 2. Add a week_number as the second column for each week_date value, for example any value from the 1st of January to 7th of January will be 1, 8th to 14th will be 2 etc
ALTER TABLE data_mart.clean_weekly_sales
    ADD COLUMN IF NOT EXISTS week_number INTEGER;

UPDATE data_mart.clean_weekly_sales
SET week_number = CEIL(EXTRACT(DAY FROM week_date) / 7)
WHERE week_date IS NOT NULL;

-- 3. Add a month_number with the calendar month for each week_date value as the 3rd column
ALTER TABLE data_mart.clean_weekly_sales
    ADD COLUMN IF NOT EXISTS month_number INTEGER;

UPDATE data_mart.clean_weekly_sales
SET month_number = EXTRACT(MONTH FROM week_date)
WHERE week_date IS NOT NULL;

-- 4. Add a calendar_year column as the 4th column containing either 2018, 2019 or 2020 values
ALTER TABLE data_mart.clean_weekly_sales
    ADD COLUMN IF NOT EXISTS calendar_year INTEGER;

UPDATE data_mart.clean_weekly_sales
SET calendar_year = EXTRACT(YEAR FROM week_date)
WHERE week_date IS NOT NULL;
-- 5. Add a new column called age_band after the original segment column using the following mapping on the number inside the segment value
ALTER TABLE data_mart.clean_weekly_sales
    ADD COLUMN IF NOT EXISTS age_band VARCHAR(20);

UPDATE data_mart.clean_weekly_sales
SET age_band =
        CASE
            WHEN RIGHT(original_segment, 1) = '1' THEN 'Young Adults'
            WHEN RIGHT(original_segment, 1) = '2' THEN 'Middle Aged'
            WHEN RIGHT(original_segment, 1) IN ('3', '4') THEN 'Retirees'
            ELSE 'Unknown'
            END
WHERE original_segment IS NOT NULL;
-- 6. Add a new demographic column using the following mapping for the first letter in the segment values:
ALTER TABLE data_mart.clean_weekly_sales
    ADD COLUMN IF NOT EXISTS demographic VARCHAR(20);

UPDATE data_mart.clean_weekly_sales
SET demographic =
        CASE LEFT(original_segment, 1)
            WHEN 'C' THEN 'Couples'
            WHEN 'F' THEN 'Families'
            ELSE 'Unknown'
            END
WHERE original_segment IS NOT NULL;
-- 7. Ensure all null string values with an "unknown" string value in the original segment column as well as the new age_band and demographic columns
UPDATE data_mart.clean_weekly_sales
SET original_segment = COALESCE(original_segment, 'Unknown'),
    age_band         = COALESCE(age_band, 'Unknown'),
    demographic      = COALESCE(demographic, 'Unknown')
WHERE original_segment IS NULL
   OR age_band IS NULL
   OR demographic IS NULL;
-- 8. Generate a new avg_transaction column as the sales value divided by transactions rounded to 2 decimal places for each record
ALTER TABLE data_mart.clean_weekly_sales
    ADD COLUMN IF NOT EXISTS avg_transaction NUMERIC(10, 2);

UPDATE data_mart.clean_weekly_sales
SET avg_transaction = ROUND(sales::NUMERIC / transactions, 2)
WHERE transactions != 0;

---
SELECT *
FROM weekly_sales;

SELECT *
FROM clean_weekly_sales;
-- -------------------------------------------  FINAL / SUMMARY
CREATE TEMP TABLE clean_weekly_sales AS (SELECT TO_DATE(week_date, 'DD/MM/YY')                     AS week_date,
                                                DATE_PART('week', TO_DATE(week_date, 'DD/MM/YY'))  AS week_number,
                                                DATE_PART('month', TO_DATE(week_date, 'DD/MM/YY')) AS month_number,
                                                DATE_PART('year', TO_DATE(week_date, 'DD/MM/YY'))  AS calendar_year,
                                                region,
                                                platform,
                                                segment,
                                                CASE
                                                    WHEN RIGHT(segment, 1) = '1' THEN 'Young Adults'
                                                    WHEN RIGHT(segment, 1) = '2' THEN 'Middle Aged'
                                                    WHEN RIGHT(segment, 1) in ('3', '4') THEN 'Retirees'
                                                    ELSE 'unknown' END                             AS age_band,
                                                CASE
                                                    WHEN LEFT(segment, 1) = 'C' THEN 'Couples'
                                                    WHEN LEFT(segment, 1) = 'F' THEN 'Families'
                                                    ELSE 'unknown' END                             AS demographic,
                                                transactions,
                                                ROUND((sales::NUMERIC / transactions), 2)          AS avg_transaction,
                                                sales
                                         FROM data_mart.weekly_sales);
---------------------------------------- @ 2. Data Exploration -----------------------------------------------------
-- 1. What day of the week is used for each week_date value?
SELECT DISTINCT(TO_CHAR(week_date, 'Day')) AS week_day
FROM clean_weekly_sales;
SELECT DISTINCT(EXTRACT(ISODOW FROM week_date)) AS day_of_week_numeric
FROM clean_weekly_sales;

-- https://www.postgresql.org/docs/current/functions-datetime.html

-- 2. What range of week numbers are missing from the dataset?
WITH week_number_cte AS (
  SELECT GENERATE_SERIES(1,52) AS week_number
)

SELECT DISTINCT week_no.week_number
FROM week_number_cte AS week_no
LEFT JOIN clean_weekly_sales AS sales
  ON week_no.week_number = sales.week_number
WHERE sales.week_number IS NULL;


-- C2
-- Xác định các số tuần hiện có trong tập dữ liệu
WITH current_weeks AS (SELECT DISTINCT week_number
                       FROM clean_weekly_sales),

-- Tạo ra chuỗi các số tuần từ 1 đến 52
     all_weeks AS (SELECT generate_series(1, 52) AS week_number)

-- Xác định các số tuần bị thiếu
SELECT week_number
FROM all_weeks
WHERE week_number NOT IN (SELECT week_number
                          FROM current_weeks)
ORDER BY week_number;


-- 3. How many total transactions were there for each year in the dataset?
SELECT calendar_year, SUM(transactions) AS total_transactions
FROM pg_temp.clean_weekly_sales
GROUP BY calendar_year;

-- 4. What is the total sales for each region for each month?
SELECT region,
       SUM(sales) AS total_sales,
       month_number,
       calendar_year
FROM pg_temp.clean_weekly_sales
GROUP BY region, month_number,calendar_year
ORDER BY region,calendar_year, month_number;

-- 5. What is the total count of transactions for each platform
SELECT platform, SUM(transactions) AS total_transaction
FROM pg_temp.clean_weekly_sales
GROUP BY platform;

-- 6. What is the percentage of sales for Retail vs Shopify for each month?
WITH monthly_sales AS (SELECT calendar_year,
                              month_number,
                              platform,
                              SUM(sales) AS total_sales
                       FROM pg_temp.clean_weekly_sales
                       GROUP BY calendar_year, month_number, platform)
SELECT calendar_year, month_number, platform,
       ROUND(total_sales
                 / SUM(total_sales)
                   OVER (PARTITION BY calendar_year, month_number) * 100 , 2) AS sales_percentage
FROM monthly_sales
WHERE platform IN ('Retail', 'Shopify')
ORDER BY calendar_year, month_number, platform;

-- 7. What is the percentage of sales by demographic for each year in the dataset?
WITH yearly_sales AS (SELECT calendar_year,
                             demographic,
                             SUM(sales) AS total_sales
                      FROM pg_temp.clean_weekly_sales
                      GROUP BY calendar_year, demographic)
SELECT calendar_year,
       demographic,
       ROUND(total_sales / SUM(total_sales) OVER (PARTITION BY calendar_year) * 100, 2) AS sales_percentages
FROM yearly_sales
ORDER BY calendar_year, demographic;

-- 8. Which age_band and demographic values contribute the most to Retail sales?
SELECT age_band, demographic, SUM(sales) AS total_sales
FROM pg_temp.clean_weekly_sales
WHERE platform = 'Retail'
GROUP BY age_band, demographic
ORDER BY age_band
LIMIT 1;

-- 9. Can we use the avg_transaction column to find the average transaction size for each year for Retail vs Shopify? If not - how would you calculate it instead?
SELECT calendar_year,
    platform,
    AVG(avg_transaction) AS average_transaction_size
FROM pg_temp.clean_weekly_sales
WHERE platform IN ('Retail', 'Shopify')
GROUP BY calendar_year, platform
ORDER BY average_transaction_size

---------------------------------------------- @ 3. Before & After Analysis -----------------------------------------------------------------
--> This technique is usually used when we inspect an important event and want to inspect the impact before and after a certain point in time.
-- -> a. Taking the week_date value of 2020-06-15 as the baseline week where the Data Mart sustainable packaging changes came into effect.
-- -> b. We would include all week_date values for 2020-06-15 as the start of the period after the change and the previous week_date values would be before
-- -> c. Using this analysis approach - answer the following questions:
-- 1. What is the total sales for the 4 weeks before and after 2020-06-15? What is the growth or reduction rate in actual values and percentage of sales?
-- Total sales for 4 weeks before and after 2020-06-15
WITH sales_before_after AS (SELECT SUM(CASE
                                           WHEN week_date >= '2020-06-08' AND week_date < '2020-06-15' THEN sales
                                           ELSE 0 END) AS sales_before,
                                   SUM(CASE
                                           WHEN week_date >= '2020-06-15' AND week_date < '2020-06-22' THEN sales
                                           ELSE 0 END) AS sales_after
                            FROM clean_weekly_sales)
SELECT sales_before,
       sales_after,
       sales_after - sales_before                                               AS sales_difference,
       ROUND(((sales_after - sales_before) / NULLIF(sales_before, 0)) * 100, 2) AS sales_growth_percentage
FROM sales_before_after;


-- 2. What about the entire 12 weeks before and after?
-- Total sales for 12 weeks before and after 2020-06-15
WITH sales_before_after AS (SELECT SUM(CASE
                                           WHEN week_date >= '2020-03-16' AND week_date < '2020-06-15' THEN sales
                                           ELSE 0 END) AS sales_before,
                                   SUM(CASE
                                           WHEN week_date >= '2020-06-15' AND week_date < '2020-09-07' THEN sales
                                           ELSE 0 END) AS sales_after
                            FROM clean_weekly_sales)
SELECT sales_before,
       sales_after,
       sales_after - sales_before                                               AS sales_difference,
       ROUND(((sales_after - sales_before) / NULLIF(sales_before, 0)) * 100, 2) AS sales_growth_percentage
FROM sales_before_after;


-- 3. How do the sale metrics for these 2 periods before and after compare with the previous years in 2018 and 2019?
WITH sales_comparison AS (SELECT EXTRACT(YEAR FROM week_date) AS year,
                                 SUM(CASE
                                         WHEN week_date >= '2018-06-18' AND week_date < '2018-09-10' THEN sales
                                         ELSE 0 END)          AS sales_2018,
                                 SUM(CASE
                                         WHEN week_date >= '2019-06-17' AND week_date < '2019-09-09' THEN sales
                                         ELSE 0 END)          AS sales_2019,
                                 SUM(CASE
                                         WHEN week_date >= '2020-03-16' AND week_date < '2020-06-15' THEN sales
                                         ELSE 0 END)          AS sales_before_2020,
                                 SUM(CASE
                                         WHEN week_date >= '2020-06-15' AND week_date < '2020-09-07' THEN sales
                                         ELSE 0 END)          AS sales_after_2020
                          FROM clean_weekly_sales
                          WHERE EXTRACT(YEAR FROM week_date) IN (2018, 2019, 2020)
                          GROUP BY EXTRACT(YEAR FROM week_date))
SELECT year,
       sales_2018,
       sales_2019,
       sales_before_2020,
       sales_after_2020,
       sales_before_2020 - COALESCE(sales_2018, 0)                                                          AS sales_diff_before_2020_vs_2018,
       ROUND(((sales_before_2020 - COALESCE(sales_2018, 0)) / NULLIF(COALESCE(sales_2018, 0), 0)) * 100,
             2)                                                                                             AS sales_growth_percentage_before_2020_vs_2018,
       sales_after_2020 - COALESCE(sales_2019, 0)                                                           AS sales_diff_after_2020_vs_2019,
       ROUND(((sales_after_2020 - COALESCE(sales_2019, 0)) / NULLIF(COALESCE(sales_2019, 0), 0)) * 100,
             2)                                                                                             AS sales_growth_percentage_after_2020_vs_2019
FROM sales_comparison;

