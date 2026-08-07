/*
==========================================================================================
                         CLASSICMODELS SALES ANALYSIS PROJECT
==========================================================================================

Author   : Bhawna Chahar
Database : ClassicModels

Project Overview
----------------
This project analyzes the ClassicModels database to solve real-world business
problems using SQL. The analysis focuses on sales performance, customer behavior,
product performance, and revenue trends to generate actionable business insights.

Key SQL Concepts Covered
-------------------------
• Joins (INNER JOIN, LEFT JOIN)
• Aggregate Functions
• GROUP BY & HAVING
• CASE Statements
• Subqueries
• Common Table Expressions (CTEs)
• Window Functions
• Ranking Functions
• Date Functions
• Business Analytics

==========================================================================================
                           PROJECT CONTENTS
==========================================================================================

📈 SALES & REVENUE ANALYSIS
---------------------------
1. Top Revenue Generating Products
2. Top Revenue Generating Customers
3. Revenue by Country
4. Monthly Revenue Trend
5. Month-over-Month Revenue Growth

👥 CUSTOMER ANALYSIS
--------------------
1. Customer Segmentation (Gold | Silver | Bronze)
2. High-Value Customers (Above Average Spending)
3. Top Customer by Revenue in Each Country
4. Customers Who Never Placed an Order
5. Average Order Value (AOV)

📦 PRODUCT ANALYSIS
-------------------
1. Best Selling Products
2. Products Never Ordered
3. Top Revenue Product by Product Line
4. Product Line Revenue Contribution (%)

📋 ORDER ANALYSIS
-----------------
1. Latest Order of Every Customer
2. Previous Order Date Analysis
3. Days Between Consecutive Orders

📊 CUSTOMER BEHAVIOUR ANALYSIS
------------------------------
1. Customer Spending Trend Analysis
2. Customers with Increased Spending
3. Current vs Previous Order Revenue Comparison

==========================================================================================


/*
==========================================================================================
📈 SALES & REVENUE ANALYSIS
==========================================================================================
*/

-- Top Revenue-Generating Products

SELECT
    p.productCode,
    p.productName,
    SUM(od.quantityOrdered) AS total_quantity_sold,
    SUM(od.quantityOrdered * od.priceEach) AS revenue
FROM products p
JOIN orderdetails od
    ON p.productCode = od.productCode
GROUP BY
    p.productCode,
    p.productName
ORDER BY revenue DESC;



-- Top Revenue-Generating Customers

SELECT
    c.customerNumber,
    c.customerName,
    COUNT(DISTINCT o.orderNumber) AS total_orders,
    SUM(od.quantityOrdered * od.priceEach) AS revenue
FROM customers c
JOIN orders o
    ON c.customerNumber = o.customerNumber
JOIN orderdetails od
    ON o.orderNumber = od.orderNumber
GROUP BY
    c.customerNumber,
    c.customerName
ORDER BY revenue DESC
LIMIT 10;



-- Revenue by Country

SELECT
    c.country,
    COUNT(DISTINCT o.orderNumber) AS total_orders,
    SUM(od.quantityOrdered * od.priceEach) AS revenue
FROM customers c
JOIN orders o
    ON c.customerNumber = o.customerNumber
JOIN orderdetails od
    ON o.orderNumber = od.orderNumber
GROUP BY
    c.country
ORDER BY revenue DESC
LIMIT 10;



-- Monthly Revenue Trend

SELECT
    YEAR(o.orderDate) AS year,
    MONTH(o.orderDate) AS month,
    COUNT(DISTINCT o.orderNumber) AS total_orders,
    SUM(od.quantityOrdered * od.priceEach) AS revenue
FROM orders o
JOIN orderdetails od
    ON o.orderNumber = od.orderNumber
GROUP BY
    YEAR(o.orderDate),
    MONTH(o.orderDate)
ORDER BY
    YEAR(o.orderDate),
    MONTH(o.orderDate);



-- Month-over-Month Revenue Growth

WITH order_revenue AS
(
    SELECT
        YEAR(o.orderDate) AS year,
        MONTH(o.orderDate) AS month,
        SUM(od.quantityOrdered * od.priceEach) AS revenue
    FROM orders o
    JOIN orderdetails od
        ON o.orderNumber = od.orderNumber
    GROUP BY
        YEAR(o.orderDate),
        MONTH(o.orderDate)
),

previous_month AS
(
    SELECT
        year,
        month,
        revenue,
        LAG(revenue) OVER
        (
            ORDER BY year, month
        ) AS previous_revenue
    FROM order_revenue
)

SELECT
    year,
    month,
    revenue,
    previous_revenue,
    (revenue - previous_revenue) AS revenue_growth,
    ROUND(
        ((revenue - previous_revenue) / previous_revenue) * 100,
        2
    ) AS growth_percentage
FROM previous_month;
*/


/*
==========================================================================================
👥 CUSTOMER ANALYSIS
==========================================================================================
*/


-- Customer Segmentation (Gold | Silver | Bronze)

WITH customer_revenue AS
(
    SELECT
        c.customerNumber,
        c.customerName,
        SUM(od.quantityOrdered * od.priceEach) AS revenue
    FROM customers c
    JOIN orders o
        ON c.customerNumber = o.customerNumber
    JOIN orderdetails od
        ON o.orderNumber = od.orderNumber
    GROUP BY
        c.customerNumber,
        c.customerName
)

SELECT
    customerNumber,
    customerName,
    revenue,
    CASE
        WHEN revenue >= 100000 THEN 'Gold'
        WHEN revenue >= 50000 THEN 'Silver'
        ELSE 'Bronze'
    END AS customer_segment
FROM customer_revenue
ORDER BY revenue DESC;



-- High-Value Customers (Above Average Spending)

WITH customer_revenue AS
(
    SELECT
        c.customerNumber,
        c.customerName,
        SUM(od.quantityOrdered * od.priceEach) AS revenue
    FROM customers c
    JOIN orders o
        ON c.customerNumber = o.customerNumber
    JOIN orderdetails od
        ON o.orderNumber = od.orderNumber
    GROUP BY
        c.customerNumber,
        c.customerName
)

SELECT
    customerNumber,
    customerName,
    revenue
FROM customer_revenue
WHERE revenue >
(
    SELECT AVG(revenue)
    FROM customer_revenue
)
ORDER BY revenue DESC;



-- Top Customer by Revenue in Each Country

WITH customer_revenue AS
(
    SELECT
        c.country,
        c.customerNumber,
        c.customerName,
        SUM(od.quantityOrdered * od.priceEach) AS revenue
    FROM customers c
    JOIN orders o
        ON c.customerNumber = o.customerNumber
    JOIN orderdetails od
        ON o.orderNumber = od.orderNumber
    GROUP BY
        c.country,
        c.customerNumber,
        c.customerName
),

ranked_customers AS
(
    SELECT
        *,
        ROW_NUMBER() OVER
        (
            PARTITION BY country
            ORDER BY revenue DESC
        ) AS revenue_rank
    FROM customer_revenue
)

SELECT
    country,
    customerNumber,
    customerName,
    revenue
FROM ranked_customers
WHERE revenue_rank = 1;



-- Customers Who Never Placed an Order

SELECT
    c.customerNumber,
    c.customerName,
    c.country
FROM customers c
LEFT JOIN orders o
    ON c.customerNumber = o.customerNumber
WHERE o.orderNumber IS NULL;



-- Average Order Value (AOV)

WITH customer_revenue AS
(
    SELECT
        c.customerNumber,
        c.customerName,
        COUNT(DISTINCT o.orderNumber) AS total_orders,
        SUM(od.quantityOrdered * od.priceEach) AS revenue
    FROM customers c
    JOIN orders o
        ON c.customerNumber = o.customerNumber
    JOIN orderdetails od
        ON o.orderNumber = od.orderNumber
    GROUP BY
        c.customerNumber,
        c.customerName
)

SELECT
    customerNumber,
    customerName,
    total_orders,
    revenue,
    ROUND(revenue / total_orders, 2) AS average_order_value
FROM customer_revenue
ORDER BY average_order_value DESC;

/*
==========================================================================================
📦 PRODUCT ANALYSIS
==========================================================================================
*/


-- Best-Selling Products

SELECT
    p.productCode,
    p.productName,
    SUM(od.quantityOrdered) AS total_quantity_sold,
    SUM(od.quantityOrdered * od.priceEach) AS total_revenue
FROM products p
JOIN orderdetails od
    ON p.productCode = od.productCode
GROUP BY
    p.productCode,
    p.productName
ORDER BY
    total_quantity_sold DESC;



-- Products Never Ordered

SELECT
    p.productCode,
    p.productName,
    p.productLine
FROM products p
LEFT JOIN orderdetails od
    ON p.productCode = od.productCode
WHERE od.productCode IS NULL;



-- Top Revenue Product by Product Line

WITH product_revenue AS
(
    SELECT
        p.productLine,
        p.productCode,
        p.productName,
        SUM(od.quantityOrdered * od.priceEach) AS revenue
    FROM products p
    JOIN orderdetails od
        ON p.productCode = od.productCode
    GROUP BY
        p.productLine,
        p.productCode,
        p.productName
),

ranked_products AS
(
    SELECT
        *,
        ROW_NUMBER() OVER
        (
            PARTITION BY productLine
            ORDER BY revenue DESC
        ) AS product_rank
    FROM product_revenue
)

SELECT
    productLine,
    productCode,
    productName,
    revenue
FROM ranked_products
WHERE product_rank = 1;



-- Product Line Revenue Contribution (%)

WITH productline_revenue AS
(
    SELECT
        p.productLine,
        SUM(od.quantityOrdered * od.priceEach) AS revenue
    FROM products p
    JOIN orderdetails od
        ON p.productCode = od.productCode
    GROUP BY
        p.productLine
)

SELECT
    productLine,
    revenue,
    ROUND(
        (revenue * 100.0 /
        (SELECT SUM(revenue) FROM productline_revenue)),
        2
    ) AS revenue_contribution_percentage
FROM productline_revenue
ORDER BY
    revenue DESC;
    
    
    /*
==========================================================================================
📋 ORDER ANALYSIS
==========================================================================================
*/


-- Latest Order of Every Customer

WITH latest_order AS
(
    SELECT
        c.customerNumber,
        c.customerName,
        o.orderNumber,
        o.orderDate,
        ROW_NUMBER() OVER
        (
            PARTITION BY c.customerNumber
            ORDER BY o.orderDate DESC
        ) AS order_rank
    FROM customers c
    JOIN orders o
        ON c.customerNumber = o.customerNumber
)

SELECT
    customerNumber,
    customerName,
    orderNumber,
    orderDate
FROM latest_order
WHERE order_rank = 1;



-- Previous Order Date Analysis

SELECT
    c.customerNumber,
    c.customerName,
    o.orderNumber,
    o.orderDate,

    LAG(o.orderDate) OVER
    (
        PARTITION BY c.customerNumber
        ORDER BY o.orderDate
    ) AS previous_order_date

FROM customers c
JOIN orders o
    ON c.customerNumber = o.customerNumber
ORDER BY
    c.customerNumber,
    o.orderDate;



-- Days Between Consecutive Orders

WITH customer_orders AS
(
    SELECT
        c.customerNumber,
        c.customerName,
        o.orderNumber,
        o.orderDate,

        LAG(o.orderDate) OVER
        (
            PARTITION BY c.customerNumber
            ORDER BY o.orderDate
        ) AS previous_order_date

    FROM customers c
    JOIN orders o
        ON c.customerNumber = o.customerNumber
)

SELECT
    customerNumber,
    customerName,
    orderNumber,
    previous_order_date,
    orderDate,

    DATEDIFF(orderDate, previous_order_date) AS days_between_orders

FROM customer_orders
ORDER BY
    customerNumber,
    orderDate;
    
    /*
==========================================================================================
📊 CUSTOMER BEHAVIOUR ANALYSIS
==========================================================================================
*/


-- Customer Spending Trend Analysis

WITH order_revenue AS
(
    SELECT
        c.customerNumber,
        c.customerName,
        o.orderNumber,
        o.orderDate,
        SUM(od.quantityOrdered * od.priceEach) AS order_revenue
    FROM customers c
    JOIN orders o
        ON c.customerNumber = o.customerNumber
    JOIN orderdetails od
        ON o.orderNumber = od.orderNumber
    GROUP BY
        c.customerNumber,
        c.customerName,
        o.orderNumber,
        o.orderDate
),

previous_order AS
(
    SELECT
        customerNumber,
        customerName,
        orderNumber,
        orderDate,
        order_revenue,

        LAG(order_revenue) OVER
        (
            PARTITION BY customerNumber
            ORDER BY orderDate
        ) AS previous_revenue

    FROM order_revenue
)

SELECT
    customerNumber,
    customerName,
    orderNumber,
    orderDate,
    order_revenue,
    previous_revenue,

    (order_revenue - previous_revenue) AS revenue_difference,

    CASE
        WHEN order_revenue > previous_revenue THEN 'Increased'
        WHEN order_revenue < previous_revenue THEN 'Decreased'
        ELSE 'No Change'
    END AS spending_trend

FROM previous_order
ORDER BY
    customerNumber,
    orderDate;



-- Customers with Increased Spending

WITH order_revenue AS
(
    SELECT
        c.customerNumber,
        c.customerName,
        o.orderNumber,
        o.orderDate,
        SUM(od.quantityOrdered * od.priceEach) AS order_revenue
    FROM customers c
    JOIN orders o
        ON c.customerNumber = o.customerNumber
    JOIN orderdetails od
        ON o.orderNumber = od.orderNumber
    GROUP BY
        c.customerNumber,
        c.customerName,
        o.orderNumber,
        o.orderDate
),

previous_order AS
(
    SELECT
        customerNumber,
        customerName,
        orderNumber,
        orderDate,
        order_revenue,

        LAG(order_revenue) OVER
        (
            PARTITION BY customerNumber
            ORDER BY orderDate
        ) AS previous_revenue

    FROM order_revenue
)

SELECT
    customerNumber,
    customerName,
    orderNumber,
    orderDate,
    previous_revenue,
    order_revenue,

    (order_revenue - previous_revenue) AS revenue_growth

FROM previous_order
WHERE order_revenue > previous_revenue
ORDER BY
    revenue_growth DESC;



-- Current vs Previous Order Revenue Comparison

WITH order_revenue AS
(
    SELECT
        c.customerNumber,
        c.customerName,
        o.orderNumber,
        o.orderDate,
        SUM(od.quantityOrdered * od.priceEach) AS order_revenue
    FROM customers c
    JOIN orders o
        ON c.customerNumber = o.customerNumber
    JOIN orderdetails od
        ON o.orderNumber = od.orderNumber
    GROUP BY
        c.customerNumber,
        c.customerName,
        o.orderNumber,
        o.orderDate
),

previous_order AS
(
    SELECT
        customerNumber,
        customerName,
        orderNumber,
        orderDate,
        order_revenue,

        LAG(order_revenue) OVER
        (
            PARTITION BY customerNumber
            ORDER BY orderDate
        ) AS previous_revenue

    FROM order_revenue
)

SELECT
    customerNumber,
    customerName,
    orderNumber,
    orderDate,
    previous_revenue,
    order_revenue,

    (order_revenue - previous_revenue) AS revenue_difference,

    ROUND(
        ((order_revenue - previous_revenue)
        / NULLIF(previous_revenue,0)) * 100,
        2
    ) AS growth_percentage

FROM previous_order
ORDER BY
    customerNumber,
    orderDate;    
    