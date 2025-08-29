# 📊 SQL-Driven Business Analytics Framework
This repository contains my SQL-based Business Analytics Framework, designed to transform raw data into actionable insights.

</br>

It categorizes SQL queries into:</br>
<sub> - **👥 Customer Analysis**</sub> </br>
<sub> - **💰 Sales & Revenue Analysis**</sub> </br>
<sub> - **📈 Profitability Analysis**</sub> </br> </br>

Each category is organized to include: </br>
<sub> - **Purpose and Insight**, followed by **Business Question**, **Query Purpose**, **SQL Query**, **Interpretation**, and **Business Insight**. </sub>

&nbsp;

---
## 🗄️ Database Schema
The dataset comes from **Kaggle** (Coffee Sales). It consists of three tables:</br>
<sub> - customers (`customer_id`, `customer_name`, `email`, `phone_number`, `address_line_1`, `city`, `country`, `postcode`, `loyalty_card`)</sub> </br>
<sub> - orders (`order_id`, `order_date`, `customer_id`, `product_id`, `quantity`)</sub> </br>
<sub> - products (`product_id`, `coffee_type`, `roast_type`, `size`, `unit_price`, `price_per_100g`, `profit`)</sub> </br>

&nbsp;

📌 ERD (Entity Relationship Diagram):

<img width="372" height="317" alt="image" src="https://github.com/user-attachments/assets/865dc2f2-2238-4e21-ae37-a643ba9a1156" />


&nbsp;

---
## 👥 Customer Analysis
### 1. Customer Distribution (Where are our customers?) 
> - **Purpose:** Understand customer base and loyalty trends.
> - **Insight:** Identify key demographics and retention drivers.

<details> <summary> <b>a. Customer Geographic Distribution</b> </br>
<sub> - Business Question: Where are our customers located? </sub> </summary> </br> 
  
```sql
-- Query Purpose: List the total of customers from each country to understand geographic concentration.

SELECT 
	country, 
	COUNT(DISTINCT customer_id) AS total_customers
FROM customers
GROUP BY country
ORDER BY total_customers DESC;
```
> ✅ <sub>**Interpretation:** The customers are located in the United States, Ireland, and the United Kingdom.</sub>
</details>


<details> <summary> <b>b. Customer Concentration by Country with Spending Power</b> </br>
<sub> - Business Question: Does the number of customers in each country correlate with their total spending power?</sub> </summary> </br> 
  
```sql
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
```
> ✅ <sub>**Interpretation**: The number of customers in each country is correlated with their total spending power.</sub>
>
> 📈 <sub>**Business Insight**: Focus marketing and retention efforts on high-customer, high-spend regions, while exploring under-penetrated areas for growth. Prioritize loyalty programs, product availability, and budget allocation in key markets. For regions with low customers and low spend, treat them as test markets with small, low-cost campaigns to evaluate growth potential before committing significant resources.</sub>
</details>


<details> <summary> <b>c. Customer Concentration by City</b> </br>
<sub> - Business Question: Which U.S. cities have both the largest customer bases and the highest spending power?</sub> </summary> </br> 
  
```sql
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
```
> ✅ <sub>**Interpretation:** Washington has the largest customer base and the strongest purchasing power, while Kingsport has the lowest penetration and revenue.</sub>
>
> 📈 <sub>**Business Insight:** In high-market cities, focus marketing and supply chain efforts as they are key revenue drivers with broad penetration. In low-market cities, the business can either deprioritize them as not cost-effective or run small growth campaigns if aligned with the overall expansion strategy.</sub>
</details>

&nbsp;

### 2. Customer Engagement & Loyalty (How engaged are our customers?)
> - **Purpose:** Assess adoption and effectiveness of the loyalty program.
> - **Insight:** Identify high-value loyalty members and measure the ROI of the program.

<details> <summary> <b>a. Loyalty Program Penetration</b> </br>
<sub> - Business Question: How many customers are engaged in our loyalty program?</sub> </summary> </br> 
  
```sql
-- Query Purpose: Count total customers holding a loyalty card to assess adoption.

SELECT COUNT(*) total_customers 
FROM customers
WHERE loyalty_card=1;
```
> ✅ <sub>**Interpretation:** There are 487 customers holding a loyalty card.</sub>
</details>


<details> <summary> <b>b. Loyalty Card Holder Performance</b> </br>
<sub> - Business Question: Do loyalty members bring more value?</sub> </summary> </br> 

```sql
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
```
> ✅ <sub>**Interpretation:** Most loyalty card holders made only a single purchase, with only one customer reaching 5 purchases. Interestingly, despite purchasing only once, 42 loyalty members generated the highest average profit per order compared to those who purchased multiple times.</sub>
>
> 📈 <sub>**Business Insight:** This suggests that loyalty membership does not yet drive repeat purchases, but it does attract high-value one-time buyers. The business could focus on converting these high-profit, one-time loyalty members into repeat customers through personalized offers, rewards for second purchases, or tiered loyalty benefits.</sub>
</details>

&nbsp;

### 3. Customer Retention & Repeat Purchases (Who keeps coming back?)
> - **Purpose:** Identify repeat buyers and those at risk of churn.
> - **Insight:** Target retention campaigns, re-engagement strategies, and upsell opportunities.

<details> <summary> <b>a. Repeat Customer Identification</b> </br>  
<sub> - Business Question: Who are our repeat buyers?</sub> </summary> </br> 
  
```sql
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
```
> ✅ <sub>**Interpretation:** There are 3 customers with at least 2 purchases in the last 6 months.</sub> </br>
> 📈 <sub>**Business Insight:** Repeat buyers represent a core loyal group who drive consistent revenue. These customers are more predictable and cheaper to retain than acquiring new ones.</sub>
</details>


<details> <summary> <b>b. Churn Analysis</b> </br>
<sub> - Business Question: Which customers are at risk of churn?</sub> </summary> </br> </summary>
  
```sql
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
```
> ✅ <sub>**Interpretation:** There are 880 customers who haven’t placed an order in the past 6 months, putting them at risk of churn.</sub> </br>
> 📈 <sub>**Business Insight:** This signals potential revenue leakage if no re-engagement action is taken. As next steps, the business should analyze churn drivers (e.g., geographic patterns, product preferences, service issues) and apply predictive churn modeling to proactively flag and retain customers before they lapse.</sub>
</details>

&nbsp;

### 4. Customer Loyalty & Product Preference (What do they love?)
> - **Purpose:** Identify customers with strong product loyalty (always buying the same coffee type).
> - **Insight:** Segment true loyal customers for premium offerings, personalized campaigns, or upselling.

<details> <summary> <b>a. Customer Purchase Consistency</b> </br>
<sub> - Business Question: Are there customers with strong brand/product loyalty?</sub> </summary> </br> 
  
```sql
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
```
> ✅ <sub>**Interpretation:** No customers consistently purchased the same coffee type in the last 6 months. Every repeat buyer tried at least 2 different coffee types.</sub>  </br>
> 📈 <sub>**Business Insight:** Customers in the last 6 months tend to try multiple coffee types rather than sticking to one, indicating they are variety-seeking. Loyalty strategies should focus on brand experience and mix-and-match promotions rather than single-product loyalty.</sub>
</details>



## 💰 Sales & Revenue Analysis
### 1. Sales Activity
> - **Purpose:** Track sales activity across short, mid, and long-term to identify momentum.
> - **Insight:** Helps detect slowdown or acceleration in sales trends.

<details> <summary> <b>a. Recent Sales Activity</b> </br>
<sub> - Business Question: What is our short-term sales trend?</sub> </summary> </br> 
  
```sql
-- Query Purpose: Retrieve all orders placed in the last 30 days.
SELECT 
	order_date, 
	order_id 
FROM orders
WHERE order_date >= DATEADD(day, -30, (SELECT MAX(order_date) FROM orders))
ORDER BY order_date;
```
> ✅ <sub>**Interpretation:** There are only 13 orders in the last 30 days.</sub>  </br>
> 📈 <sub>**Business Insight:** Sales are very low in the short term, suggesting an urgent need for marketing campaigns or customer re-engagement efforts.</sub>
</details>



<details> <summary> <b>b. Mid-Term Sales Activity</b> </br>
<sub> - Business Question: How are medium-term sales performing?</sub> </summary> </br> 
  
```sql
-- Query Purpose: Retrieve all orders placed in the last 6 months.

SELECT 
	order_date, 
	order_id 
FROM orders
WHERE order_date >= DATEADD(month, -6, (SELECT MAX(order_date) FROM orders))
ORDER BY order_date;
```
> ✅ <sub>**Interpretation:** There are only 130 orders in the last 6 months.</sub> </br>
> 📈 <sub>**Business Insight:** Sales are weak over the medium term, highlighting potential demand stagnation. Consistent promotions or seasonal campaigns may be required to drive momentum.</sub>
</details>


<details> <summary> <b>c. Monthly Revenue Trend</b> </br>
<sub> - Business Question: How has revenue trended over time?</sub> </summary> </br> 
  
```sql
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
```
> ✅ <sub>**Interpretation:** The highest monthly revenue was in September 2021, at 1,643.55. Revenue remained strong from September 2021 to January 2022 but then dropped sharply to 393.76 in February 2022.</sub> </br>
> 📈 <sub>**Business Insight:** Revenue patterns suggest seasonality or the impact of promotions. The business should analyze the drivers of strong performance in peak months, replicate those strategies, and address factors causing declines in weaker months.</sub>
</details>

&nbsp;

### 2. Revenue Drivers
> - **Purpose:** Identify the people, products, and regions contributing most to revenue.
> - **Insight:** Helps the business focus resources where they yield the highest return.

<details> <summary> <b>a. High-Value Customers (Lifetime Value)</b> </br>
<sub> - Business Question: Who are our top-spending customers overall?</sub> </summary> </br> 
  
```sql
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
```
> ✅ <sub>**Interpretation:** These top 5 customers are VIP customers.</sub> </br>
> 📈 <sub>**Business Insight:** The business can retain and grow these VIPs with loyalty programs, exclusive deals, and personalized engagement since they contribute disproportionately to revenue.</sub>
</details>


<details> <summary> <b>b. High-Value Customers (Recent Value)</b> </br>
<sub> - Business Question: Who are our top spenders recently?</sub> </summary> </br> 
  
```sql
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
```
> ✅ <sub>**Interpretation:** These top 5 customers are the current revenue drivers.</sub> </br>
> 📈 <sub>**Business Insight:** The business can maintain their engagement through rewards, limited-time offers, or priority services to sustain short-term revenue.</sub>
</details>


<details> <summary> <b>c. Top Coffee Revenue Drivers</b> </br>
<sub> - Business Question: Which coffee type generates the most sales?</sub> </summary> </br> 
  
```sql
-- Query Purpose: Find the coffee type with the highest sales revenue in the last 6 months.

SELECT TOP 1
    p.coffee_type,
    SUM(o.quantity * p.unit_price) AS total_revenue
FROM orders o
JOIN products p ON p.product_id = o.product_id
WHERE o.order_date >= DATEADD(month, -6, (SELECT MAX(order_date) FROM orders))
GROUP BY p.coffee_type
ORDER BY total_revenue DESC;
```
> ✅ <sub>**Interpretation:** Robusta is the best-selling coffee type.</sub> </br>
> 📈 <sub>**Business Insight:** The business can prioritize Robusta in inventory, promotions, and upsell strategies while exploring opportunities to cross-sell other types.</sub>
</details>


<details> <summary> <b>d. Regional Product Preferences</b> </br>
<sub> - Business Question: What products do U.S. customers prefer?</sub> </summary> </br> 
  
```sql
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
```
> ✅ <sub>**Interpretation:** Robusta light roasted, size 0.2kg, is the most popular among U.S. customers in the last 6 months.</sub> </br>
> 📈 <sub>**Business Insight:** The business can stock and promote this product heavily in the U.S. while testing similar products (e.g., other roast levels or sizes) to broaden adoption.</sub>
</details>



<details> <summary> <b>e. Product Size Sales Analysis</b> </br>
<sub> - Business Question: Which packaging size is most in demand?</sub> </summary> </br> 
  
```sql
-- Query Purpose: Identify the product size with the highest sales volume in the last 6 months.

SELECT TOP 1
	p.size,
	SUM(o.quantity) AS total_sales_volume
FROM orders o
JOIN products p ON p.product_id = o.product_id
WHERE o.order_date >= DATEADD(month, -6, (SELECT MAX(order_date) FROM orders))
GROUP BY size
ORDER BY total_sales_volume DESC;
```
> ✅ <sub>**Interpretation:** The 2.5kg size has the highest sales volume in the last 6 months.</sub> </br>
> 📈 <sub>**Business Insight:** The business can ensure sufficient stock of 2.5kg sizes and consider bundling or discounts on smaller sizes to encourage upgrades.</sub>
</details>

&nbsp;

### 3. Order Value Analysis
> - **Purpose:** Understand transaction size extremes to optimize pricing and promotions.
> - **Insight:** Helps identify patterns in high-value transactions for replication.
  
<details> <summary> <b>a. Largest Order Analysis</b> </br>
<sub> - Business Question: What was our biggest single transaction?</sub> </summary> </br> 
  
```sql
-- Query Purpose: Find the most expensive order by total value.

SELECT TOP 1
	o.order_id,
	SUM(o.quantity * p.unit_price) AS total_spend
FROM orders o
JOIN products p ON p.product_id = o.product_id
GROUP BY order_id
ORDER BY total_spend DESC;
```
> ✅ <sub>**Interpretation:** This pinpoints the peak order.</sub> </br>
> 📈 <sub>**Business Insight:** The business can analyze this order (customer type, product mix, order timing) to replicate conditions that generate high-value transactions.</sub>
</details>



<details> <summary> <b>b. Second Largest Order Analysis</b> </br>
<sub> - Business Question: What was the next biggest single transaction?</sub> </summary> </br> 
  
```sql
-- Query Purpose: Find the second most expensive order by total value.

SELECT
	o.order_id,
	SUM(o.quantity * p.unit_price) AS total_spend
FROM orders o
JOIN products p ON p.product_id = o.product_id
GROUP BY order_id
ORDER BY total_spend DESC
OFFSET 1 ROWS FETCH NEXT 1 ROWS ONLY;
```
> ✅ <sub>**Interpretation:** This transaction is only 33.31 less than the largest order.</sub> </br>
> 📈 <sub>**Business Insight:** Similar large orders indicate potential repeatable buying behavior. The business can target these customers with upsell opportunities and personalized offers.</sub>
</details>




## 📈 Profitability Analysis
### 1. Profitability by Product Attributes
> - **Purpose:** Understand which product characteristics (roast, coffee type, combinations) generate the most profit.
> - **Insight:** Certain roasts and coffee types consistently outperform others. Optimizing product mix and marketing toward these categories can maximize profitability.

<details> <summary> <b>a. Profitability by Roast Type</b> </br>
<sub> - Business Question: Which roast type is most profitable?</sub> </summary> </br> 
  
```sql
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
```
> ✅ <sub>**Interpretation:** Light roast has the highest average profit per order.</sub> </br>
> 📈 <sub>**Business Insight:** Light roast can be prioritized in marketing and inventory planning since it contributes more profit efficiency per order.</sub>
</details>



<details> <summary> <b>b. Top Profit Drivers by Coffee & Roast</b> </br>
<sub> - Business Question: Which product combinations deliver the best profit?</sub> </summary> </br> 
  
```sql
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
```
> ✅ <sub>**Interpretation:** Liberica with light roast has the highest average profit per order.</sub> </br>
> 📈 <sub>**Business Insight:** The business can bundle Liberica light roast or position it as a premium product to strengthen profit contribution.</sub>
</details>


<details> <summary> <b>c. Most Profitable Coffee Type</b> </br>
<sub> - Business Question: Which coffee type should we prioritize?</sub> </summary> </br> 
  
```sql
-- Query Purpose: Identify the coffee type with the highest total profit in the last 6 months.

SELECT TOP 1
	p.coffee_type,
	SUM(o.quantity * p.profit) AS total_profit
FROM orders o
JOIN products p ON p.product_id = o.product_id
WHERE o.order_date >= DATEADD(month, -6, (SELECT MAX(order_date) FROM orders))
GROUP BY coffee_type
ORDER BY total_profit DESC;
```
> ✅ <sub>**Interpretation:** Liberica generated the highest total profit in the last 6 months. </sub> </br>
> 📈 <sub>**Business Insight:** The business can prioritize Liberica in production, promotions, and long-term growth strategies.</sub>
</details>

&nbsp;

### 2.  Market-Level Profitability
> - **Purpose:** Identify which regions or countries drive the most profitability.
> - **Insight:** Profit contribution varies by geography, suggesting a need to allocate resources to high-performing markets while testing growth strategies in weaker ones.

<details> <summary> <b>a. Country-Level Profit Contribution</b> </br>
<sub> - Business Question: Which market drives our profitability?</sub> </summary> </br> 
  
```sql
-- Query Purpose: Find the country contributing the most to overall profit.

SELECT TOP 1
	c.country,
	SUM(o.quantity * p.profit) AS total_profit
FROM orders o
JOIN products p ON p.product_id = o.product_id
JOIN customers c ON c.customer_id = o.customer_id
GROUP BY country
ORDER BY total_profit DESC;
```
> ✅ <sub>**Interpretation:** United States contributed the most to overall profit.</sub> </br>
> 📈 <sub>**Business Insight:** The business can focus marketing and supply chain resources on the U.S. while using low-performing markets for small, experimental campaigns.</sub>
</details>

&nbsp;

### 3.  Order & Customer Profitability
> - **Purpose:** Evaluate profitability at the order and customer level to identify efficiency and loyalty drivers.
> - **Insight:** Both order efficiency (margin) and customer repeatability are key for sustainable profits. High-margin orders and repeat buyers represent long-term profitability levers.

<details> <summary> <b>a. Order-Level Profit Margin Ranking</b> </br>
<sub> - Business Question: Which orders had the best margins?</sub> </summary> </br> 
  
```sql
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
```
> ✅ <sub>**Interpretation:** The top 10 orders had a profit margin of 0.1314 (13.14%).</sub> </br>
> 📈 <sub>**Business Insight:** The business can encourage similar purchasing patterns by replicating promotions or bundles that drove these high-margin orders.</sub>
</details>


<details> <summary> <b>b. Product Repeatability (Coffee + Roast Combo)</b> </br>
<sub> - Business Question: Which product combinations drive loyalty?</sub> </summary> </br> 
  
``` sql
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
```
> ✅ <sub>**Interpretation:** Only three coffee–roast combinations show repeat purchases, which are Dark Roasted Arabica, Light Roasted Arabica, Dark Roasted Excelsa. Each records the highest repeat purchase count of 2. </sub> </br>
> 📈 <sub>**Business Insight:** Loyalty programs and repeat-purchase campaigns can focus on these coffee–roast combinations to reinforce retention.</sub>
</details>

&nbsp;

### 4.  Profitability Efficiency
> - **Purpose:** Assess how efficiently different products convert into profit (per time or per unit of weight).
> - **Insight:** Profitability efficiency highlights production priorities—businesses should scale products with the best profit per unit.

<details> <summary> <b>a. Profit Trend Comparison (Liberica vs Excelsa)</b> </br>
<sub> - Business Question: How do different coffee types perform over time?</sub> </summary> </br> 
  
```sql
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
```
> ✅ <sub>**Interpretation:** Liberica (1567.08) outperformed Excelsa (156.22) in the last 6 months. </sub> </br>
> 📈 <sub>**Business Insight:** Liberica shows stronger profit sustainability and should be scaled up compared to Excelsa.</sub>
</details>


<details> <summary> <b>b. Profitability per 100g Analysis</b> </br>
<sub> -Business Question: Which products are most efficient in generating profit?</sub> </summary> </br> 
  
```sql
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
```
> ✅ <sub>**Interpretation:** Liberica, light roasted, 0.2kg has the highest profit per 100g. </sub> </br>
> 📈 <sub>**Business Insight:** The business should prioritize production of the small-size Liberica light roast, as it maximizes profitability per unit of weight.</sub>
</details>

&nbsp;

---
## 📊 Power BI Dashboard (Extension)
This SQL framework can be extended into a Power BI dashboard:

<img width="586" height="329" alt="image" src="https://github.com/user-attachments/assets/39f15828-9102-450a-8475-1c0a58f09393" />

- Total Revenue, Total Profit, Profit Margin, Repeat Purchase Rate → Cards
- Profit Contribution by Country → Map
- Profitability by Coffee Type → Bar Chart
- Profit Trends → Line Chart
- Order-level Profit Margin → Scatter Plot
- Customer Loyalty & Repeatability → Bar Chart
- Profitability Efficiency per 100g → Top 5 Bar Chart

> 💡 <sub>All calculated metrics are implemented using DAX measures in Power BI. Examples include Revenue per Order, Profit per Order, Margin per Order, and Repeat Purchase Rate.</sub>

&nbsp;

---
## ✅ Key Skills Demonstrated
- SQL Server (joins, aggregations, CTEs, ranking, grouping)
- Business analytics & data storytelling
- Query optimization for insights
- Data visualization with Power BI
