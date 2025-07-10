-- Monthly Cumulative Sales by Year
SELECT
	InvoiceMonth, 
	Sum_price,
	-- Reset accumulation each year
	SUM(Sum_price) OVER (PARTITION BY DATETRUNC(year, InvoiceMonth) ORDER BY InvoiceMonth) AS cummulative_sales
FROM
(SELECT
	DATETRUNC(month, I.InvoiceDate) as InvoiceMonth, 
	SUM(Il.ExtendedPrice) AS Sum_price
FROM 
	Sales.InvoiceLines Il 
	LEFT JOIN Sales.Invoices I ON Il.InvoiceID = I.InvoiceID
GROUP BY 
	DATETRUNC(month, I.InvoiceDate)
) AS t