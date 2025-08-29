-- Query Purpose: List the total of customers from each country to understand geographic concentration. 
SELECT 
	country, 
	COUNT(DISTINCT customer_id) AS total_customers
FROM customers
GROUP BY country
ORDER BY total_customers DESC;

-- Query Purpose: Calculate both the number of customers and their total spend per country to compare geographic concentration against spending power. 
SELECT 
	c.country, 
	COUNT(DISTINCT c.customer_id) AS total_customers,
	SUM(o.quantity * p.unit_price) AS total_spend
FROM orders o
JOIN customers c ON c.customer_id = o.customer_id
JOIN products p ON p.product_id = o.product_id
GROUP BY c.country
ORDER BY total_spend DESC;

-- Query Purpose: List the U.S. cities by customer count and spending power, to understand geographic concentration at the city level.
SELECT 
	c.city, 
	COUNT(DISTINCT c.customer_id) AS total_customers,
	SUM(o.quantity * p.unit_price) AS total_spend
FROM orders o
JOIN customers c ON c.customer_id = o.customer_id
JOIN products p ON p.product_id = o.product_id
WHERE c.country = 'United States'
GROUP BY c.city
ORDER BY total_spend DESC, total_customers DESC;

-- Query Purpose: Count total customers holding a loyalty card to assess adoption.
SELECT COUNT(*) total_customers 
FROM customers
WHERE loyalty_card=1;

-- Query Purpose: Calculate total orders, total spend, and average profit per order for loyalty card holders.
WITH order_profit AS (
	SELECT 
		o.order_id,
		o.customer_id,
		SUM(o.quantity * p.unit_price) AS spend_per_order,
		SUM(o.quantity * p.profit) AS profit_per_order
	FROM orders o
	JOIN products p ON p.product_id = o.product_id
	JOIN customers c ON c.customer_id = o.customer_id
	WHERE c.loyalty_card = 1
	GROUP BY o.order_id, o.customer_id
)
SELECT 
	op.customer_id,
	c.customer_name,
	COUNT(op.order_id) AS total_orders,
	SUM(op.spend_per_order) AS total_spend,
	CAST(AVG(op.profit_per_order) AS DECIMAL(10,2)) AS avg_profit
FROM order_profit op
JOIN customers c ON c.customer_id = op.customer_id
GROUP BY op.customer_id, c.customer_name
ORDER BY avg_profit DESC;

-- Query Purpose: Find customers with at least 2 purchases in the last 6 months.
SELECT
	c.customer_id,
	c.customer_name,
	COUNT(DISTINCT o.order_id) AS total_orders
FROM orders o
JOIN customers c ON c.customer_id = o.customer_id
WHERE o.order_date >= DATEADD(month, -6, (SELECT MAX(order_date) FROM orders))
GROUP BY c.customer_id, c.customer_name
HAVING COUNT(DISTINCT o.order_id) >= 2
ORDER BY total_orders DESC;

-- Query Purpose: Identify customers who haven’t ordered in the past 6 months.
SELECT 
	c.customer_id,
	c.customer_name
FROM customers c
WHERE NOT EXISTS (
	SELECT 1 
	FROM orders o
	WHERE o.customer_id = c.customer_id 
	AND order_date >= DATEADD(month, -6, (SELECT MAX(order_date) FROM orders))
);

-- Query Purpose: Identify customers who always purchase the same coffee type in the last 6 months.
SELECT 
	c.customer_id,
	c.customer_name,
	MAX(p.coffee_type) AS consistent_coffee_type,
	COUNT(DISTINCT o.order_id) AS total_orders
FROM orders o
JOIN customers c ON c.customer_id = o.customer_id
JOIN products p ON p.product_id = o.product_id
WHERE o.order_date >= DATEADD(month, -6, (SELECT MAX(order_date) FROM orders))
GROUP BY c.customer_id, c.customer_name
HAVING COUNT(DISTINCT p.coffee_type) = 1 AND COUNT(DISTINCT o.order_id) > 1
ORDER BY total_orders DESC;

-- Query Purpose: Retrieve all orders placed in the last 30 days.
SELECT 
	order_date, 
	order_id 
FROM orders
WHERE order_date >= DATEADD(day, -30, (SELECT MAX(order_date) FROM orders))
ORDER BY order_date;

-- Query Purpose: Retrieve all orders placed in the last 6 months.
SELECT 
	order_date, 
	order_id 
FROM orders
WHERE order_date >= DATEADD(month, -6, (SELECT MAX(order_date) FROM orders))
ORDER BY order_date;

-- Query Purpose: Show monthly sales revenue for the past 12 months.
SELECT 
	YEAR(o.order_date) AS years,
	MONTH(o.order_date) AS months, 
	SUM(o.quantity * p.unit_price) AS monthly_revenue
FROM orders o 
JOIN products p ON p.product_id = o.product_id
WHERE o.order_date >= DATEADD(month, -12, (SELECT MAX(order_date) FROM orders))
GROUP BY YEAR(o.order_date), MONTH(o.order_date)
ORDER BY years, months;

-- Query Purpose: List top 5 customers by lifetime spending.
SELECT TOP 5 
	c.customer_id, 
	c.customer_name, 
	SUM(o.quantity * p.unit_price) AS total_spent 
FROM customers c 
JOIN orders o ON o.customer_id = c.customer_id 
JOIN products p ON p.product_id = o.product_id
GROUP BY c.customer_id, c.customer_name
ORDER BY total_spent DESC;

-- Query Purpose: List top 5 customers by spending in the last 30 days.
SELECT TOP 5 
	c.customer_id, 
	c.customer_name, 
	SUM(o.quantity * p.unit_price) AS total_spent 
FROM customers c 
JOIN orders o ON o.customer_id = c.customer_id 
JOIN products p ON p.product_id = o.product_id
WHERE o.order_date >= DATEADD(day, -30, (SELECT MAX(order_date) FROM orders))
GROUP BY c.customer_id, c.customer_name
ORDER BY total_spent DESC;

-- Query Purpose: Find the coffee type with the highest sales revenue in the last 6 months.
SELECT TOP 1
    p.coffee_type,
    SUM(o.quantity * p.unit_price) AS total_revenue
FROM orders o
JOIN products p ON p.product_id = o.product_id
WHERE o.order_date >= DATEADD(month, -6, (SELECT MAX(order_date) FROM orders))
GROUP BY p.coffee_type
ORDER BY total_revenue DESC;

-- Query Purpose: Identify the most popular product type among U.S. customers in the last 6 months.
SELECT TOP 1
	p.product_id,
	p.coffee_type,
	p.roast_type,
	p.size,
	SUM(o.quantity) AS total_quantity_sold
FROM orders o
JOIN products p ON p.product_id = o.product_id
JOIN customers c ON c.customer_id = o.customer_id
WHERE o.order_date >= DATEADD(month, -6, (SELECT MAX(order_date) FROM orders))
AND c.country = 'United States'
GROUP BY p.product_id, p.coffee_type, p.roast_type, p.size
ORDER BY total_quantity_sold DESC;

-- Query Purpose: Identify the product size with the highest sales volume in the last 6 months.
SELECT TOP 1
	p.size,
	SUM(o.quantity) AS total_sales_volume
FROM orders o
JOIN products p ON p.product_id = o.product_id
WHERE o.order_date >= DATEADD(month, -6, (SELECT MAX(order_date) FROM orders))
GROUP BY size
ORDER BY total_sales_volume DESC;

-- Query Purpose: Find the most expensive order by total value.
SELECT TOP 1
	o.order_id,
	SUM(o.quantity * p.unit_price) AS total_spend
FROM orders o
JOIN products p ON p.product_id = o.product_id
GROUP BY order_id
ORDER BY total_spend DESC;

-- Query Purpose: Find the second most expensive order by total value.
SELECT
	o.order_id,
	SUM(o.quantity * p.unit_price) AS total_spend
FROM orders o
JOIN products p ON p.product_id = o.product_id
GROUP BY order_id
ORDER BY total_spend DESC
OFFSET 1 ROWS FETCH NEXT 1 ROWS ONLY;

-- Query Purpose: Calculate average profit per order for each roast type.
WITH order_profit AS (
	SELECT 
		o.order_id, 
		p.roast_type, 
		SUM(o.quantity * p.profit) AS total_profit_per_order
	FROM orders o 
	JOIN products p ON p.product_id = o.product_id
	GROUP BY o.order_id, p.roast_type
)
SELECT
	roast_type, 
	CAST(AVG(total_profit_per_order) AS DECIMAL(10,2)) AS avg_profit
FROM order_profit
GROUP BY roast_type
ORDER BY avg_profit DESC;

-- Query Purpose: Show the top 5 coffee–roast combinations by average profit per order.
WITH order_profit AS (
	SELECT 
		o.order_id, 
		p.coffee_type, 
		p.roast_type, 
		SUM(o.quantity * p.profit) AS total_profit_per_order
	FROM orders o 
	JOIN products p ON p.product_id = o.product_id
	GROUP BY o.order_id, p.coffee_type, p.roast_type
)
SELECT TOP 5 
	coffee_type,
	roast_type, 
	CAST(AVG(total_profit_per_order) AS DECIMAL(10,2)) AS avg_profit
FROM order_profit
GROUP BY coffee_type, roast_type
ORDER BY avg_profit DESC;

-- Query Purpose: Identify the coffee type with the highest total profit in the last 6 months.
SELECT TOP 1
	p.coffee_type,
	SUM(o.quantity * p.profit) AS total_profit
FROM orders o
JOIN products p ON p.product_id = o.product_id
WHERE o.order_date >= DATEADD(month, -6, (SELECT MAX(order_date) FROM orders))
GROUP BY coffee_type
ORDER BY total_profit DESC;

-- Query Purpose: Find the country contributing the most to overall profit.
SELECT TOP 1
	c.country,
	SUM(o.quantity * p.profit) AS total_profit
FROM orders o
JOIN products p ON p.product_id = o.product_id
JOIN customers c ON c.customer_id = o.customer_id
GROUP BY country
ORDER BY total_profit DESC;

-- Query Purpose: Rank the top 10 orders by profit margin (total_profit ÷ total_revenue).
WITH profit_revenue AS (
	SELECT 
		order_id,
		SUM(o.quantity * p.profit) AS total_profit_per_order,
		SUM(o.quantity * p.unit_price) AS total_revenue_per_order
	FROM orders o
	JOIN products p ON p.product_id = o.product_id
	GROUP BY order_id
)
SELECT TOP 10 
	order_id, 
	CAST((total_profit_per_order / total_revenue_per_order) AS DECIMAL(10,4)) AS margin_profit_per_order
FROM profit_revenue
WHERE total_revenue_per_order > 0
ORDER BY margin_profit_per_order DESC;

-- Query Purpose: Identify the coffee–roast combinations with the top 5 most repeat purchases.
SELECT TOP 5 
	coffee_type,
	roast_type,
	SUM(order_count) AS total_repeat_orders
FROM (
	SELECT 
		o.customer_id,
		p.coffee_type,
		p.roast_type,
		COUNT(DISTINCT o.order_id) AS order_count
	FROM orders o
	JOIN products p ON p.product_id = o.product_id 
	GROUP BY o.customer_id, p.coffee_type, p.roast_type
	HAVING COUNT(DISTINCT o.order_id) > 1
) repeat_orders
GROUP BY coffee_type, roast_type
ORDER BY total_repeat_orders DESC;

-- Query Purpose: Compare profit trends of Liberica vs Excelsa in the last 6 months.
SELECT 
	DISTINCT p.coffee_type,
	SUM(o.quantity * p.profit) AS total_profit
FROM orders o
JOIN products p ON p.product_id = o.product_id
WHERE p.coffee_type = 'Lib' 
OR p.coffee_type = 'Exc'
AND o.order_date >= DATEADD(month, -6, (SELECT MAX(order_date) FROM orders))
GROUP BY p.coffee_type
ORDER BY total_profit DESC;

-- Query Purpose: Rank products by profit per 100g and recommend production priorities. 
SELECT 
	p.product_id,
	p.coffee_type,
	p.roast_type,
	p.size,
	SUM(o.quantity * p.profit) AS total_profit,
	SUM(o.quantity * p.size * 1000) AS total_grams,
	CAST((SUM(o.quantity * p.profit) / SUM(o.quantity * p.size * 1000) * 100) AS DECIMAL(10,2)) AS profit_per_100g
FROM orders o
JOIN products p ON p.product_id = o.product_id
GROUP BY p.product_id, p.coffee_type, p.roast_type, p.size
ORDER BY profit_per_100g DESC;
