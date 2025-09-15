SELECT * FROM pizza_sales_data; -- Checking the data table

-- ** Calculating KPIs **

-- 1. Total Revenue

SELECT 
	ROUND(SUM(total_price),2) AS Total_Revenue 
FROM pizza_sales_data;

-- 2. Average Order Value

SELECT 
	ROUND(SUM(total_price) / COUNT(DISTINCT order_id), 2) AS Average_Order_Value 
FROM pizza_sales_data;

-- 3. Total Pizza Sold

SELECT 
	SUM(quantity) AS Total_Pizza_Sold
FROM pizza_sales_data;

-- 4. Total Orders (The total Number of orders placed)

SELECT 
	COUNT(DISTINCT order_id) AS Total_Orders
FROM pizza_sales_data;

-- 5. Averatage Pizzas Per order

SELECT 
	SUM(quantity) / COUNT(DISTINCT order_id) AS Average_Pizza_Per_Order
FROM pizza_sales_data;


-- ** Chart Requirements**

-- 1. Daily Trend for Total Orders

SELECT
	DATENAME(DW, order_date) AS Order_Dates,
	COUNT(DISTINCT order_id) AS Total_Orders
FROM pizza_sales_data
GROUP BY DATENAME(DW, order_date);


-- 2. Monthly Trend for Total Orders

SELECT 
	DATENAME(MONTH, order_date) AS Order_Months,
	COUNT(DISTINCT order_id) AS Total_Orders
FROM pizza_sales_data
GROUP BY DATENAME(MONTH, order_date)
ORDER BY Total_Orders DESC;

-- 3. Percentage of Sales by Pizza Category

SELECT 
	pizza_category,
	ROUND(SUM(total_price) / (SELECT SUM(total_price) FROM pizza_sales_data WHERE MONTH(order_date) = 1) * 100, 2) AS Percenrage_of_Sales_by_Pizza_Category
FROM pizza_sales_data
WHERE MONTH(order_date) = 1
GROUP BY pizza_category;


-- 4. Percentage of Sales by Pizza Size

SELECT
	pizza_size,
	ROUND(SUM(total_price) / (SELECT SUM(total_price) FROM pizza_sales_data WHERE DATEPART(QUARTER, order_date) = 1) * 100, 2) AS Percenrage_of_Sales_by_Pizza_Size
FROM pizza_sales_data
WHERE DATEPART(QUARTER, order_date) = 1
GROUP BY pizza_size;


SELECT * FROM pizza_sales_data;

-- 5. Total Pizza Sold by Pizza Category

SELECT
	pizza_category,
	SUM(quantity) AS Pizza_Sold_by_Category
FROM pizza_sales_data
GROUP BY pizza_category;

-- 6. Top 5 Best Sellers by Revenue, Total Quantity and Total Orders

SELECT TOP 5 -- Top 5 Pizzas by Total Revenue
	pizza_name,
	SUM(total_price) AS Total_Revenue
FROM pizza_sales_data
GROUP BY pizza_name
ORDER BY Total_Revenue DESC

SELECT TOP 5 -- Top 5 Pizzas by Total Quantity
	pizza_name,
	SUM(quantity) AS Total_Quantity
FROM pizza_sales_data
GROUP BY pizza_name
ORDER BY Total_Quantity DESC

SELECT TOP 5 -- Top 5 Pizzas by Total Orders
	pizza_name,
	COUNT(DISTINCT order_id) AS Total_Orders
FROM pizza_sales_data
GROUP BY pizza_name
ORDER BY Total_Orders DESC

-- 7. Bottom 5 Best Sellers by Revenue, Total Quantity and Total Orders

SELECT TOP 5 -- Bottom 5 Pizzas by Total Revenue
	pizza_name,
	SUM(total_price) AS Total_Revenue
FROM pizza_sales_data
GROUP BY pizza_name
ORDER BY Total_Revenue 

SELECT TOP 5 -- Bottom 5 Pizzas by Total Quantity
	pizza_name,
	SUM(quantity) AS Total_Quantity
FROM pizza_sales_data
GROUP BY pizza_name
ORDER BY Total_Quantity 

SELECT TOP 5 -- Bottom 5 Pizzas by Total Orders
	pizza_name,
	COUNT(DISTINCT order_id) AS Total_Orders
FROM pizza_sales_data
GROUP BY pizza_name
ORDER BY Total_Orders 


