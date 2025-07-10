-- Sales by State and Territory
WITH states_sales AS (
SELECT
	Sp.StateProvinceName AS State_name, 
	SUM(ExtendedPrice) AS Sales_amount
FROM 
	Sales.InvoiceLines Il 
	JOIN Sales. Invoices I ON Il.InvoiceID = I.InvoiceID
	JOIN Sales.Customers C ON I.CustomerID = C.CustomerID
	JOIN Application.Cities Ct ON C.DeliveryCityID = Ct.CityID
	JOIN Application.StateProvinces Sp ON Ct.StateProvinceID = Sp.StateProvinceID
GROUP BY 
	Sp.StateProvinceName, 
	Sp.LatestRecordedPopulation
)

SELECT 
	State_name, 
	Sp.SalesTerritory, 
	Sales_amount,
	-- Revenue per capita
	Sales_amount/Sp.LatestRecordedPopulation AS sales_per_capital

FROM 
	states_sales Ss 
	JOIN Application.StateProvinces Sp ON Ss.State_name = Sp.StateProvinceName
ORDER BY 
	Sales_amount DESC