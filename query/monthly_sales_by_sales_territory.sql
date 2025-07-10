-- Monthly Sales Trend by Sales Territory
WITH territory_performance AS (
SELECT
	YEAR(I.InvoiceDate) AS InvoiceYEAR,
    MONTH(I.InvoiceDate) AS InvoiceMonth,
    Sp.SalesTerritory,
    SUM(Il.ExtendedPrice) AS TotalSales
FROM 
	Sales.InvoiceLines Il
	JOIN Sales.Invoices I ON Il.InvoiceID = I.InvoiceID
	JOIN Sales.Customers C ON I.CustomerID = C.CustomerID
	JOIN Application.Cities Ct ON C.DeliveryCityID = Ct.CityID
	JOIN Application.StateProvinces Sp ON Ct.StateProvinceID = Sp.StateProvinceID
GROUP BY 
	YEAR(I.InvoiceDate),
    MONTH(I.InvoiceDate), 
	Sp.SalesTerritory
)

SELECT
	InvoiceYear, 
	InvoiceMonth, 
	SalesTerritory, 
	TotalSales,
	-- Compare monthly sales with the territory's average in that year
	CASE WHEN TotalSales < AVG(TotalSales) OVER (PARTITION BY SalesTerritory, InvoiceYear)  THEN 'Below AVG'
		 WHEN TotalSales > AVG(TotalSales) OVER (PARTITION BY SalesTerritory, InvoiceYear)  THEN 'Over AVG'
		 ELSE 'AVG'
	END avg_change,
	-- Month-over-month change direction
	CASE WHEN TotalSales - LAG(TotalSales) OVER (PARTITION BY SalesTerritory ORDER BY InvoiceYear, InvoiceMonth) < 0 THEN 'Decrease'
		 WHEN TotalSales - LAG(TotalSales) OVER (PARTITION BY SalesTerritory ORDER BY InvoiceYear, InvoiceMonth) > 0 THEN 'Increase'
		 ELSE 'No change'
	END AS pm_change
FROM 
	territory_performance
ORDER BY 
	InvoiceYear, 
	SalesTerritory, 
	InvoiceMonth
