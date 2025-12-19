# swiggy-sql-data-analysis
SQL-based data analysis project on Swiggy food delivery data using star schema modeling and business KPIs.

# Swiggy SQL Data Analysis Project

## Project Description
This project demonstrates an end-to-end **SQL-based data analysis workflow** on Swiggy food delivery data.  
The objective is to transform raw transactional data into an analytical data model and derive **business KPIs and insights** that answer real product and business questions.

This project is designed to reflect **actual Data Analyst work**, not just SQL practice.

---

## Business Problem
Food delivery platforms like Swiggy need answers to questions such as:
- How many orders and how much revenue is generated?
- How does demand change over time?
- Which cities, restaurants, cuisines, and dishes perform best?
- What price ranges do customers prefer?
- Where are quality or growth improvement opportunities?

This project answers these questions using SQL.

---

## Dataset & Grain
- **Dataset:** Swiggy food delivery orders
- **Grain:**  
  **1 row = 1 dish ordered**
- Because the data is dish-level, all KPIs are interpreted accordingly  
  (e.g., average dish price instead of order-level AOV).

---

## Data Modeling Approach
A **Star Schema** was created to make analysis scalable and easy.

### Fact Table
- `fact_swiggy_orders`
  - Stores measurable data such as:
    - `Price_INR`
    - `Rating`
    - `Rating_Count`

### Dimension Tables
- `dim_date` – date, month, quarter, weekday
- `dim_location` – state, city, location
- `dim_restaurant` – restaurant details
- `dim_category` – cuisine
- `dim_dish` – dish names

This separation allows flexible slicing of data across time, location, cuisine, and product.

---

## Data Cleaning & Preparation
- Checked and handled **null values**
- Identified and removed **duplicate records**
- Ensured consistent joins before loading data into fact and dimension tables
- Loaded data using structured SQL scripts (ETL-style flow)

---

## Key KPIs & What They Tell

### Core Performance KPIs
- **Total Orders** – overall demand on the platform
- **Total Revenue** – total sales value
- **Average Dish Price** – typical customer spend per dish
- **Average Rating & High-Rating %** – customer satisfaction indicator

### Time-Based Analysis
- **Monthly, Quarterly, Yearly Trends** – seasonality and growth patterns
- **Month-on-Month Growth (Orders & Revenue)** – demand acceleration or slowdown over time

### Location Performance
- **Top Cities by Orders & Revenue**
- **Revenue Contribution % by City**
  - Shows revenue concentration in key cities

### Product & Cuisine Analysis
- **Top Restaurants & Dishes** – demand drivers
- **Cuisine Performance (Orders + Rating)**
  - High orders + low ratings → quality improvement areas
  - Low orders + high ratings → growth opportunities

### Pricing Analysis
- **Orders by Price Range**
  - Identifies customer price sensitivity
  - Helps understand optimal pricing bands

### Advanced Analysis
- **Pareto (80/20) Analysis**
  - Identifies small set of restaurants contributing most revenue

---

## Example KPI Queries

### Total Orders
```sql
SELECT COUNT(*) AS total_orders
FROM fact_swiggy_orders;
```
### Month-on-Month Order Growth
```sql
SELECT
  year,
  month,
  total_orders,
  total_orders - LAG(total_orders) OVER (ORDER BY year, month) AS order_growth
FROM (
  SELECT d.year, d.month, COUNT(*) AS total_orders
  FROM fact_swiggy_orders f
  JOIN dim_date d ON f.date_id = d.date_id
  GROUP BY d.year, d.month
) t;
```

### Monthly Revenue Trend & MoM Growth
```sql
SELECT
  year,
  month,
  month_name,
  total_revenue,
  LAG(total_revenue) OVER (ORDER BY year, month) AS prev_month_revenue,
  total_revenue - LAG(total_revenue) OVER (ORDER BY year, month) AS revenue_growth
FROM (
  SELECT
    d.year,
    d.month,
    d.month_name,
    SUM(Price_INR) AS total_revenue
  FROM fact_swiggy_orders f
  JOIN dim_date d ON f.date_id = d.date_id
  GROUP BY d.year, d.month, d.month_name
) t
ORDER BY year, month;
```
### Total Orders
```sql
SELECT COUNT(*) AS total_orders
FROM fact_swiggy_orders;
```
### Total Revenue
```sql
SELECT SUM(Price_INR) AS total_revenue
FROM fact_swiggy_orders;
```

### Average Dish Price
```sql
SELECT CAST(AVG(Price_INR) AS DECIMAL(10,2)) AS avg_dish_price
FROM fact_swiggy_orders;
```
### Average Rating
```sql
SELECT ROUND(AVG(Rating),2) AS avg_rating
FROM fact_swiggy_orders;
```
### High-Rating Orders Percentage
```sql
SELECT
  CAST(
    COUNT(CASE WHEN Rating >= 4 THEN 1 END) * 100.0 / COUNT(*)
  AS DECIMAL(5,2)) AS high_rating_percentage
FROM fact_swiggy_orders;
```

