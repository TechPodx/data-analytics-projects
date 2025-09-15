# 🍕 Pizza Sales Analysis Dashboard

## 📌 Project Overview
This project analyzes pizza sales data to uncover key insights into business performance.  
The analysis was performed using **SQL** for data processing and **Power BI** for visualization.  
The final dashboard provides an interactive way to explore sales trends, customer behavior, and product performance.

### Page 1 Home: ![Dashboard Demo](https://github.com/TechPodx/Style-Repo/blob/main/Gif/Pizza_Home-gif.gif)

---

## 📝 Client Requirements

The client requested an analytical dashboard that provides:

### **KPI Requirements**
1. **Total Revenue** – The sum of the total price of all pizza orders.  
2. **Average Order Value** – The average amount spent per order (Total Revenue ÷ Total Orders).  
3. **Total Pizzas Sold** – The total quantity of pizzas sold.  
4. **Total Orders** – The total number of unique orders placed.  
5. **Average Pizzas Per Order** – The average number of pizzas per order (Total Pizzas Sold ÷ Total Orders).  

### **Charts Requirements**
1. **Daily Trend for Total Orders** – Bar chart to show daily order volume trends.  
2. **Hourly Trend for Total Orders** – Line chart to track hourly order patterns.  
3. **Percentage of Sales by Pizza Category** – Pie chart to analyze contribution of pizza categories.  
4. **Percentage of Sales by Pizza Size** – Pie chart to compare performance of pizza sizes.  
5. **Top & Bottom 5 Pizzas** – Identifying best and worst performers by revenue, orders, and quantity.

---

## 🗄️ SQL Queries Used

### **1. KPI Queries**
```SQL
-- Total Revenue
SELECT ROUND(SUM(total_price),2) AS Total_Revenue 
FROM pizza_sales_data;

-- Average Order Value
SELECT ROUND(SUM(total_price) / COUNT(DISTINCT order_id), 2) AS Average_Order_Value 
FROM pizza_sales_data;

-- Total Pizzas Sold
SELECT SUM(quantity) AS Total_Pizza_Sold
FROM pizza_sales_data;

-- Total Orders
SELECT COUNT(DISTINCT order_id) AS Total_Orders
FROM pizza_sales_data;

-- Average Pizzas per Order
SELECT SUM(quantity) / COUNT(DISTINCT order_id) AS Average_Pizza_Per_Order
FROM pizza_sales_data;
```
### **2. Charts Queries**
```SQL
-- Daily Trend for Total Orders
SELECT DATENAME(DW, order_date) AS Order_Day,
       COUNT(DISTINCT order_id) AS Total_Orders
FROM pizza_sales_data
GROUP BY DATENAME(DW, order_date);

-- Monthly Trend for Total Orders
SELECT DATENAME(MONTH, order_date) AS Order_Month,
       COUNT(DISTINCT order_id) AS Total_Orders
FROM pizza_sales_data
GROUP BY DATENAME(MONTH, order_date)
ORDER BY Total_Orders DESC;

-- Percentage of Sales by Pizza Category
SELECT pizza_category,
       ROUND(SUM(total_price) * 100.0 / (SELECT SUM(total_price) FROM pizza_sales_data), 2) AS Pct_Sales
FROM pizza_sales_data
GROUP BY pizza_category;

-- Percentage of Sales by Pizza Size
SELECT pizza_size,
       ROUND(SUM(total_price) * 100.0 / (SELECT SUM(total_price) FROM pizza_sales_data), 2) AS Pct_Sales
FROM pizza_sales_data
GROUP BY pizza_size;

-- Top 5 Pizzas by Revenue
SELECT TOP 5 pizza_name, SUM(total_price) AS Total_Revenue
FROM pizza_sales_data
GROUP BY pizza_name
ORDER BY Total_Revenue DESC;
```

## 📊 Dashboard Insights

The interactive **Power BI dashboard** provides the following:

### **KPI Cards**
- **Total Revenue:** 817.86K  
- **Average Order Value:** 38.31  
- **Total Pizzas Sold:** 49,574  
- **Total Orders:** 21,350  
- **Avg Pizzas per Order:** 2.32  

---

### **Visuals**
1. **Daily Trend (Bar Chart)** – Shows Friday & Saturday evenings as peak order times.  
2. **Monthly Trend (Line Chart)** – Maximum orders in **July** and **January**.  
3. **Sales by Pizza Category (Pie Chart)** – Classic contributes the **highest revenue**.  
4. **Sales by Pizza Size (Pie Chart)** – Large pizzas dominate sales (**45.89% share**).  
5. **Top 5 Pizzas** – Thai Chicken, Barbecue Chicken, and California Chicken are best sellers.  
6. **Bottom 5 Pizzas** – Spinach and Brie Carre pizzas underperform in sales.  

---

### **Business Insights**
- **Weekends drive the highest sales**, especially Friday & Saturday evenings.  
- **Classic category and Large size pizzas** contribute the maximum sales.  
- **Top 5 pizzas account for a significant share of total revenue.**  
- **Low-performing pizzas** (e.g., Spinach, Brie Carre) may need menu review or promotional support.  

---

## 🚀 Tech Stack
- **SQL Server** – Data extraction and KPI calculations.  
- **Power BI** – Data visualization and interactive dashboard.  
- **Excel/CSV** – Source dataset format.  

---

## 📂 Project Structure

pizza-sales-analysis/
│── data/ # Source dataset
│── sql/ # SQL scripts for KPIs and charts
│── dashboard/ # Power BI dashboard (.pbix) and screenshots
│── README.md # Project documentation



































