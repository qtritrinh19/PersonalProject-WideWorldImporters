-- Monthly Product Group Performance
WITH performance_ana AS (
SELECT
	YEAR(I.InvoiceDate) AS InvoiceYear,
	MONTH(I.InvoiceDate) AS InvoiceMonth,
	Sg.StockGroupName, 
	SUM(Il.ExtendedPrice) AS Total_amount
FROM 
	Sales.Invoices I 
	JOIN Sales.InvoiceLines Il ON I.InvoiceID = Il.InvoiceID
	JOIN Warehouse.StockItems St ON Il.StockItemID = St.StockItemID
	JOIN Warehouse.StockItemStockGroups Stsg ON St.StockItemID = Stsg.StockItemID
	JOIN Warehouse.StockGroups Sg ON Stsg.StockGroupID = Sg.StockGroupID
GROUP BY 
	YEAR(I.InvoiceDate), 
	MONTH(I.InvoiceDate), 
	Sg.StockGroupName
)

SELECT
	InvoiceYear, 
	InvoiceMonth, 
	StockGroupName, 
	Total_amount,
	-- Compare monthly total against the average of that year
	CASE WHEN Total_amount < AVG(Total_amount) OVER (PARTITION BY StockGroupName, InvoiceYear)  THEN 'Below AVG'
		 WHEN Total_amount > AVG(Total_amount) OVER (PARTITION BY StockGroupName, InvoiceYear)  THEN 'Over AVG'
		 ELSE 'AVG'
	END avg_change,
	-- Track performance trend compared to the previous month
	CASE WHEN Total_amount - LAG(Total_amount) OVER (PARTITION BY StockGroupName ORDER BY InvoiceYear, InvoiceMonth) < 0 THEN 'Decrease'
		 WHEN Total_amount - LAG(Total_amount) OVER (PARTITION BY StockGroupName ORDER BY InvoiceYear, InvoiceMonth) > 0 THEN 'Increase'
		 ELSE 'No change'
	END AS pm_change
FROM 
	performance_ana
ORDER BY 
	InvoiceYear, 
	StockGroupName, 
	InvoiceMonth