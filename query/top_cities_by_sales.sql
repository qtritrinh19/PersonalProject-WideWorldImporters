-- Top Cities by Sales
SELECT 
    Ct.CityName,
    Sp.StateProvinceName,
    Sp.SalesTerritory,
    SUM(Il.ExtendedPrice) AS SalesAmount
FROM 
	Sales.InvoiceLines Il
	JOIN Sales.Invoices I ON Il.InvoiceID = I.InvoiceID
	JOIN Sales.Customers C ON I.CustomerID = C.CustomerID
	JOIN Application.Cities Ct ON C.DeliveryCityID = Ct.CityID
	JOIN Application.StateProvinces Sp ON Ct.StateProvinceID = Sp.StateProvinceID
GROUP BY 
	Ct.CityName, 
	Sp.StateProvinceName, 
	Sp.SalesTerritory
ORDER BY 
	SalesAmount DESC
