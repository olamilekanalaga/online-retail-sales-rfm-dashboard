-- RFM Analysis and Cohort Analysis Queries
-- These queries are written for SQLite and use the cleaned_retail table.

-- 1. RFM metrics by customer
WITH sales AS (
    SELECT
        CustomerID,
        InvoiceNo,
        InvoiceDate,
        Quantity * UnitPrice AS Revenue
    FROM cleaned_retail
    WHERE Quantity > 0
      AND UnitPrice > 0
      AND CustomerID IS NOT NULL
),
analysis_date AS (
    SELECT DATE(MAX(InvoiceDate), '+1 day') AS max_date
    FROM sales
)
SELECT
    CustomerID,
    CAST(JULIANDAY((SELECT max_date FROM analysis_date)) - JULIANDAY(MAX(InvoiceDate)) AS INTEGER) AS Recency,
    COUNT(DISTINCT InvoiceNo) AS Frequency,
    ROUND(SUM(Revenue), 2) AS Monetary
FROM sales
GROUP BY CustomerID
ORDER BY Monetary DESC;

-- 2. Customer monthly cohort table
WITH sales AS (
    SELECT DISTINCT
        CustomerID,
        InvoiceNo,
        strftime('%Y-%m', InvoiceDate) AS InvoiceMonth
    FROM cleaned_retail
    WHERE Quantity > 0
      AND UnitPrice > 0
      AND CustomerID IS NOT NULL
),
first_purchase AS (
    SELECT
        CustomerID,
        MIN(InvoiceMonth) AS CohortMonth
    FROM sales
    GROUP BY CustomerID
),
cohort_data AS (
    SELECT
        s.CustomerID,
        f.CohortMonth,
        s.InvoiceMonth,
        ((CAST(strftime('%Y', s.InvoiceMonth || '-01') AS INTEGER) - CAST(strftime('%Y', f.CohortMonth || '-01') AS INTEGER)) * 12)
        + (CAST(strftime('%m', s.InvoiceMonth || '-01') AS INTEGER) - CAST(strftime('%m', f.CohortMonth || '-01') AS INTEGER))
        + 1 AS CohortIndex
    FROM sales s
    JOIN first_purchase f
      ON s.CustomerID = f.CustomerID
)
SELECT
    CohortMonth,
    CohortIndex,
    COUNT(DISTINCT CustomerID) AS Customers
FROM cohort_data
GROUP BY CohortMonth, CohortIndex
ORDER BY CohortMonth, CohortIndex;

-- 3. RFM segment summary from an exported rfm_segments table
-- Import outputs/rfm_segments.csv as rfm_segments before running this query.
SELECT
    Segment,
    COUNT(*) AS Customers,
    ROUND(SUM(Monetary), 2) AS Revenue,
    ROUND(AVG(Recency), 1) AS AverageRecency,
    ROUND(AVG(Frequency), 1) AS AverageFrequency,
    ROUND(AVG(Monetary), 2) AS AverageSpend
FROM rfm_segments
GROUP BY Segment
ORDER BY Revenue DESC;
