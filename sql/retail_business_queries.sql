-- 1. Total Revenue
SELECT 
    ROUND(SUM(Quantity * UnitPrice), 2) AS total_revenue
FROM cleaned_retail
WHERE Quantity > 0 AND UnitPrice > 0;




-- 2. Monthly Revenue Trend
SELECT 
    strftime('%Y-%m', InvoiceDate) AS month,
    ROUND(SUM(Quantity * UnitPrice), 2) AS monthly_revenue
FROM cleaned_retail
WHERE Quantity > 0 AND UnitPrice > 0
GROUP BY month
ORDER BY month;





-- 3. Top 10 Products by Revenue
SELECT 
    Description,
    ROUND(SUM(Quantity * UnitPrice), 2) AS revenue
FROM cleaned_retail
WHERE Quantity > 0 AND UnitPrice > 0
GROUP BY Description
ORDER BY revenue DESC
LIMIT 10;





-- 4. Top 10 Countries by Revenue
SELECT 
    Country,
    ROUND(SUM(Quantity * UnitPrice), 2) AS revenue
FROM cleaned_retail
WHERE Quantity > 0 AND UnitPrice > 0
GROUP BY Country
ORDER BY revenue DESC
LIMIT 10;





-- 5. Top 10 Customers by Spend
SELECT 
    CustomerID,
    ROUND(SUM(Quantity * UnitPrice), 2) AS total_spent
FROM cleaned_retail
WHERE Quantity > 0 
  AND UnitPrice > 0
  AND CustomerID IS NOT NULL
GROUP BY CustomerID
ORDER BY total_spent DESC
LIMIT 10;




-- 6. Products With Highest Returns
SELECT 
    Description,
    SUM(Quantity) AS returned_quantity,
    ROUND(SUM(Quantity * UnitPrice), 2) AS return_value
FROM cleaned_retail
WHERE Quantity < 0
GROUP BY Description
ORDER BY returned_quantity ASC
LIMIT 10;





-- 7. Average Order Value
SELECT 
    ROUND(
        SUM(Quantity * UnitPrice) / COUNT(DISTINCT InvoiceNo),
        2
    ) AS average_order_value
FROM cleaned_retail
WHERE Quantity > 0 AND UnitPrice > 0;





-- 8. Repeat vs One-Time Customers
WITH customer_orders AS (
    SELECT 
        CustomerID,
        COUNT(DISTINCT InvoiceNo) AS order_count
    FROM cleaned_retail
    WHERE Quantity > 0 
      AND UnitPrice > 0
      AND CustomerID IS NOT NULL
    GROUP BY CustomerID
)
SELECT
    CASE 
        WHEN order_count = 1 THEN 'One-Time Customer'
        ELSE 'Repeat Customer'
    END AS customer_type,
    COUNT(*) AS customer_count
FROM customer_orders
GROUP BY customer_type;