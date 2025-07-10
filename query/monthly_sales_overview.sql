  -- Monthly Sales Overview
SELECT
	DATETRUNC(month, I.InvoiceDate) as InvoiceMonth, 
	SUM(Il.ExtendedPrice) AS Sum_price,
	COUNT(I.InvoiceID) AS Total_invoices, 
	SUM(Il.Quantity) AS Total_quantity
FROM 
	Sales.InvoiceLines Il 
	LEFT JOIN Sales.Invoices I ON Il.InvoiceID = I.InvoiceID
GROUP BY 
	DATETRUNC(month, I.InvoiceDate)
ORDER BY 
	DATETRUNC(month, I.InvoiceDate)