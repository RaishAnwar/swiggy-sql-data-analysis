select * from swiggy_data

--Data Validation & Cleaning 
--Null Check

select 
   sum(case when state is null then 1 else 0 end) as null_state,
   sum(case when city is null then 1 else 0 end) as null_city,
   sum(case when Order_Date is null then 1 else 0 end) as null_Order_Date,
   sum(case when Restaurant_Name is null then 1 else 0 end) as null_city,
   sum(case when Location is null then 1 else 0 end) as null_Location,
   sum(case when Category is null then 1 else 0 end) as null_Category,
   sum(case when Dish_Name is null then 1 else 0 end) as null_Dish_Name,
   sum(case when Price_INR is null then 1 else 0 end) as null_Price_INR,
   sum(case when Rating is null then 1 else 0 end) as null_Rating,
   sum(case when Rating_Count is null then 1 else 0 end) as null_Rating_Count
from swiggy_data;


--Blank or empty strings

select * 
from swiggy_Data
where 
 State = '' or city='' or Restaurant_Name = '' or Location= '' or Category = '' or Dish_Name= '' 

 --Duplicate Detection

 select state, city , order_date,Restaurant_name,location,category,
 dish_name,price_INR,rating_count, count(*) as CNT 
 from swiggy_Data
 group by state, city , order_date,Restaurant_name,location,category,
 dish_name,price_INR,rating_count
 Having count(*) >1


 --Delete Duplication

 with CTE as ( 
 select * , RoW_NUMBER() Over(
      partition by city , order_date,Restaurant_name,location,category,
 dish_name,price_INR,rating_count
 order by (select NULL)
 ) as rn
  from swiggy_data
  )

 DELETE FROM CTE WHERE rn>1

 --creating schema 
 --DIMENSION TABLE
 --DATE TABLE
 create table dim_date (
    date_id INT IDENTITY(1,1) PRIMARY KEY,
	Full_Date DATE,
	Year INT,
	Month INT,
	Month_Name varchar(20),
	Quarter INT,
	Day INT,
	Week INT
	)
	drop table dim_date
--DIM_LOCATION
CREATE TABLE dim_location (
   location_id INT IDENTITY(1,1) PRIMARY KEY,
   State VARCHAR(100),
   City VARCHAR(100),
   Location VARCHAr(200)
);

--dim_restaurant 
CREATE TABLE dim_restaurant (
    restaurant_id INT IDENTITY(1,1) PRIMARY KEY,
	Restaurant_Name VARCHAR(200)
);

--dim_category

CREATE TABLE dim_category(
    category_id INT IDENTITY(1,1) PRIMARY KEY,
	Category VARCHAR(200)
);
--DIM_DISH

CREATE TABLE dim_dish(
     dish_id INT IDENTITY(1,1) PRIMARY KEY,
	 Dish_Name VARCHAR(200)
);


SELECT * FROM swiggy_Data

-- FACT TABLE : Swiggy Orders

CREATE TABLE fact_swiggy_orders (
    order_id INT IDENTITY(1,1) PRIMARY KEY,

    date_id INT,
    Price_INR DECIMAL(10,2),
    Rating DECIMAL(4,2),
    Rating_Count INT,

    location_id INT,
    restaurant_id INT,
    category_id INT,
    dish_id INT,

    -- Foreign Keys
    
        FOREIGN KEY (date_id) 
        REFERENCES dim_date(date_id),

   
        FOREIGN KEY (location_id) 
        REFERENCES dim_location(location_id),

    
        FOREIGN KEY (restaurant_id) 
        REFERENCES dim_restaurant(restaurant_id),

    
        FOREIGN KEY (category_id) 
        REFERENCES dim_category(category_id),

    
        FOREIGN KEY (dish_id) 
        REFERENCES dim_dish(dish_id)
);


select COLUMN_NAME FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME='dim_category';

select * from fact_swiggy_orders
select * from swiggy_data

--INSERT DATA INTO TABLES
--DIM DATE

INSERT into dim_date (Full_Date , Year, Month,Month_Name,Quarter,Day,Week)
  select distinct 
     Order_Date,
	 YEAR(Order_Date),
	 Month(Order_Date),
	 DATENAME(MONTH,Order_date),
	 DATEPART(QUARTER,Order_Date),
	 Day(Order_Date),
	 DATEPART(Week,Order_Date)
from swiggy_Data
where Order_Date is not null;
select * from dim_date

SELECT * 
FROM sys.tables 
WHERE name = 'swiggy_data';


SELECT COLUMN_NAME
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'dim_date';


EXEC sp_rename 
    'dim_date.weak', 
    'week', 
    'COLUMN';

SELECT *
FROM dim_date
WHERE CAST(full_date AS DATE) = '2025-04-07';


--dim_location

INSERT INTO dim_location(State,City,Location)
SELECT DISTINCT 
  State,
  City,
  Location
from swiggy_Data

select * from dim_location

--dim Restaurant
INSERT INTO dim_restaurant (Restaurant_Name)
select distinct 
    Restaurant_Name
from swiggy_data;
select * from dim_restaurant
--dim category

INSERT INTO dim_category (Category)
select distinct
     Category
from swiggy_data;
select * from dim_category


--dim_dish
insert into dim_dish (Dish_Name)
select Distinct 
   Dish_Name
from swiggy_Data
select * from dim_dish
truncate table dim_dish

select * from dim_dish


--fact table
truncate table fact_swiggy_orders

INSERT INTO fact_swiggy_orders
(
    date_id,
    Price_INR,
    Rating,
    Rating_Count,
    location_id,
    restaurant_id,
    category_id,
    dish_id
)
SELECT 
    dd.date_id,
    s.Price_INR,
    s.Rating,
    s.Rating_Count,
    dl.location_id,
    dr.restaurant_id,
    dc.category_id,
    dsh.dish_id
FROM swiggy_data s

JOIN dim_date dd
    ON dd.Full_Date = s.Order_Date

JOIN dim_location dl
    ON dl.State = s.State
   AND dl.City = s.City
   AND dl.Location = s.Location

JOIN dim_restaurant dr
    ON dr.Restaurant_Name = s.Restaurant_Name

JOIN dim_category dc
    ON dc.Category = s.Category

JOIN dim_dish dsh
    ON dsh.Dish_Name = s.Dish_Name;






select * from fact_swiggy_orders 
where date_id = '193' and Price_INR = '215.00'
drop table 
EXEC sp_helpconstraint fact_swiggy_orders;

SELECT COUNT(*) FROM fact_swiggy_orders;

WITH cte AS (
    SELECT 
        order_id,
        ROW_NUMBER() OVER (
            PARTITION BY
                date_id,
                restaurant_id,
                dish_id,
                location_id,
                Price_INR,
                Rating
            ORDER BY order_id
        ) AS rn
    FROM fact_swiggy_orders
)
DELETE FROM cte
WHERE rn > 1;


SELECT * FROM fact_swiggy_orders f
join dim_date d on f.date_id = d.date_id
join dim_location l on f.location_id = l.location_id
join dim_restaurant r on f.restaurant_id = r.restaurant_id
join dim_category c on f.category_id = c.category_id
join dim_dish di on f.dish_id = di.dish_id;

select * from fact_swiggy_orders where Rating = '4.50' and date_id ='244'





SELECT TABLE_SCHEMA, TABLE_NAME
FROM INFORMATION_SCHEMA.TABLES
WHERE TABLE_NAME LIKE '%swiggy%';





--KPIS

--Total Orders

select count(*) as total_orders from fact_swiggy_orders

--Total Revenue
select 
FORMAT(sum(CONVERT(FLOAT,Price_INR))/1000000,'N2') + 'INR Million'
as Total_Revenue 
from fact_swiggy_orders

--Average Dish Price

SELECT 
    CAST(AVG(Price_INR) AS DECIMAL(10,2)) AS avg_dish_price_inr
FROM fact_swiggy_orders;



--Average Dish Price Per Dish

SELECT 
    d.Dish_Name,
    CAST(AVG(f.Price_INR) AS DECIMAL(10,2)) AS avg_dish_price_inr
FROM fact_swiggy_orders f
JOIN dim_dish d 
    ON f.dish_id = d.dish_id
GROUP BY d.Dish_Name
ORDER BY avg_dish_price_inr DESC;


--Average Rating
select ROUND(avg(Rating),2) AS Average_Rating from fact_swiggy_orders

--DEEP-DIVE Business Analysis
--MONTHLU ORDER TRENDS

SELECT
    year,
    month,
    month_name,
    total_orders,
    LAG(total_orders) OVER (ORDER BY year, month) AS prev_month_orders,
    total_orders 
      - LAG(total_orders) OVER (ORDER BY year, month) AS order_growth
FROM (
    SELECT 
        d.year,
        d.month,
        d.month_name,
        COUNT(*) AS total_orders
    FROM fact_swiggy_orders f
    JOIN dim_date d 
        ON f.date_id = d.date_id
    GROUP BY 
        d.year,
        d.month,
        d.month_name
) t
ORDER BY year, month;


--MONTHLY ORDERS TREND BY REVENUE

SELECT
    year,
    month,
    month_name,
    Total_Revenue,
    LAG(Total_Revenue) OVER (ORDER BY year, month) AS prev_month_Revenue,
    Total_Revenue
      - LAG(Total_Revenue) OVER (ORDER BY year, month) AS Revenue_Increase
FROM (
    SELECT 
        d.year,
        d.month,
        d.month_name,
        SUM(Price_INR) AS Total_Revenue
    FROM fact_swiggy_orders f
    JOIN dim_date d 
        ON f.date_id = d.date_id
    GROUP BY 
        d.year,
        d.month,
        d.month_name
) t
ORDER BY year, month;



--Quaterly Trend

select 
d.year,
d.quarter,
count(*) as Total_Orders
from fact_swiggy_orders f 
join dim_date d on f.date_id = d.date_id
group by d.year,
d.quarter
order by count(*) desc

--yearly trends

select 
d.year,
count(*) as Total_Orders
from fact_swiggy_orders f 
join dim_date d on f.date_id = d.date_id
group by d.year
order by count(*) desc

--Orders by day of week(Mon-sun)
select
    DATENAME(WEEKDAY,d.full_date) as day_name,
	count(*) as total_orders
from fact_swiggy_orders f 
join dim_date d on f.date_id = d.date_id
group by DATENAME(WEEKDAY,d.full_date)
order by DATENAME(WEEKDAY,d.full_date) desc


--Top 10 cities by order volume

select top 10
l.city,
count(*) as total_orders from fact_swiggy_orders f
join dim_location l on l.location_id = f.location_id
group by l.city 
order by count(*) desc


--top 10 cities by most revenue AND Revenue % SHARE

SELECT
    l.City,
    SUM(f.Price_INR) AS city_revenue,
    CAST(
        SUM(f.Price_INR) * 100.0 / SUM(SUM(f.Price_INR)) OVER ()
        AS DECIMAL(5,2)
    ) AS revenue_percentage
FROM fact_swiggy_orders f
JOIN dim_location l ON f.location_id = l.location_id
GROUP BY l.City
ORDER BY revenue_percentage DESC;


--revenue contribution by states
select 
l.state,
sum(f.price_INR) as total_revenue from fact_swiggy_orders f
join dim_location l on l.location_id = f.location_id
group by l.state 
order by sum(f.price_INR) desc

--top 10 restaurants by orders and revenue
select top 10
r.restaurant_name,
count(*) as Total_Orders,
sum(f.price_INR) as Total_Revenue
from fact_swiggy_orders f 
join dim_restaurant r on f.restaurant_id = r.restaurant_id
group by r.restaurant_name
order by count(*)  desc

--Top Categories by order volume
select
c.category,
count(*) as total_orders 
from fact_swiggy_orders f
join dim_category c on c.category_id = f.category_id
group by c.category
order by count(*) desc



--MOST ORDERED DISHES

select top 10
d.dish_name,
count(*) as total_orders 
from fact_swiggy_orders f
join dim_dish d on d.dish_id = f.dish_id
group by d.dish_name
order by count(*) desc

--CUISINE PERFORMANCE (orders + avg rating)

select * from dim_category
select * from fact_swiggy_orders

SELECT
    c.Category AS cuisine,
    COUNT(*) AS total_orders,
    CAST(AVG(f.Rating) AS DECIMAL(10,2)) AS avg_rating
FROM fact_swiggy_orders f
JOIN dim_category c
    ON f.category_id = c.category_id
GROUP BY c.Category
ORDER BY total_orders DESC;









--Total Orders by Price Range

SELECT
    CASE
        WHEN Price_INR < 100 THEN 'Under 100'
        WHEN Price_INR BETWEEN 100 AND 199 THEN '100 - 199'
        WHEN Price_INR BETWEEN 200 AND 299 THEN '200 - 299'
        WHEN Price_INR BETWEEN 300 AND 499 THEN '300 - 499'
        ELSE '500+'
    END AS price_range,
    COUNT(*) AS total_orders
FROM fact_swiggy_orders
GROUP BY
    CASE
        WHEN Price_INR < 100 THEN 'Under 100'
        WHEN Price_INR BETWEEN 100 AND 199 THEN '100 - 199'
        WHEN Price_INR BETWEEN 200 AND 299 THEN '200 - 299'
        WHEN Price_INR BETWEEN 300 AND 499 THEN '300 - 499'
        ELSE '500+'
    END
ORDER BY total_orders DESC;


--Rating Count Distribution 

select 
 rating
from fact_swiggy_orders 
group by rating
order by rating;

--HIght-Rating Orders %

SELECT
    CAST(
        COUNT(CASE WHEN Rating >= 4 THEN 1 END) * 100.0
        / COUNT(*)
    AS DECIMAL(5,2)) AS high_rating_percentage
FROM fact_swiggy_orders;


--Average Order Value

SELECT
    CAST(SUM(Price_INR) / COUNT(*) AS DECIMAL(10,2)) AS avg_order_value
FROM fact_swiggy_orders;


--Month-on-Month % Growth(Orders)

SELECT
    year,
    month,
    month_name,
    total_orders,
    CAST(
        (total_orders 
        - LAG(total_orders) OVER (ORDER BY year, month)) * 100.0
        / LAG(total_orders) OVER (ORDER BY year, month)
    AS DECIMAL(10,2)) AS mom_growth_percent
FROM (
    SELECT 
        d.year,
        d.month,
        d.month_name,
        COUNT(*) AS total_orders
    FROM fact_swiggy_orders f
    JOIN dim_date d ON f.date_id = d.date_id
    GROUP BY d.year, d.month, d.month_name
) t;




--Revenue Contribution % by CITY

SELECT
    l.City,
    SUM(f.Price_INR) AS city_revenue,
    CAST(
        SUM(f.Price_INR) * 100.0 / SUM(SUM(f.Price_INR)) OVER ()
        AS DECIMAL(5,2)
    ) AS revenue_percentage
FROM fact_swiggy_orders f
JOIN dim_location l ON f.location_id = l.location_id
GROUP BY l.City
ORDER BY revenue_percentage DESC;


--WEEKDAY VS WEEKDAY ORDERS 

SELECT
    CASE 
        WHEN DATENAME(WEEKDAY, d.Full_Date) IN ('Saturday','Sunday')
        THEN 'Weekend'
        ELSE 'Weekday'
    END AS day_type,
    COUNT(*) AS total_orders
FROM fact_swiggy_orders f
JOIN dim_date d ON f.date_id = d.date_id
GROUP BY
    CASE 
        WHEN DATENAME(WEEKDAY, d.Full_Date) IN ('Saturday','Sunday')
        THEN 'Weekend'
        ELSE 'Weekday'
    END;


	--Top Revenue Concentration (Pareto KPI – 80/20 idea)

SELECT
    r.Restaurant_Name,
    SUM(f.Price_INR) AS total_revenue,
    SUM(SUM(f.Price_INR)) OVER (
        ORDER BY SUM(f.Price_INR) DESC
    ) * 100.0
    / SUM(SUM(f.Price_INR)) OVER () AS cumulative_revenue_pct
FROM fact_swiggy_orders f
JOIN dim_restaurant r ON f.restaurant_id = r.restaurant_id
GROUP BY r.Restaurant_Name
ORDER BY total_revenue DESC;

















