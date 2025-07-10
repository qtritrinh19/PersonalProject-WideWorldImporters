-- Year-over-Year (YoY) Growth by Month
WITH monthly_sales AS (
    SELECT
      DATETRUNC(month, I.InvoiceDate) AS InvoiceMonth,
      SUM(Il.ExtendedPrice) AS MonthlySales
    FROM 
		  Sales.InvoiceLines Il
		  JOIN Sales.Invoices I ON Il.InvoiceID = I.InvoiceID
    GROUP BY 
		  DATETRUNC(month, I.InvoiceDate)
)

SELECT 
    InvoiceMonth,
    MonthlySales,
	-- Revenue same month last year
    LAG(MonthlySales, 12) OVER (ORDER BY InvoiceMonth) AS SalesLastYear,
	-- Year-over-year growth %
    CASE 
        WHEN LAG(MonthlySales, 12) OVER (ORDER BY InvoiceMonth) IS NULL THEN NULL
        ELSE ROUND(100.0 * (MonthlySales - LAG(MonthlySales, 12) OVER (ORDER BY InvoiceMonth)) / NULLIF(LAG(MonthlySales, 12) OVER (ORDER BY InvoiceMonth), 0), 2)
    END AS YoY_Growth_Percent
FROM 
	monthly_sales
ORDER BY 
	InvoiceMonth
