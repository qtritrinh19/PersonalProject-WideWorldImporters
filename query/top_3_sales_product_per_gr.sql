-- Top 3 Selling Products per Product Group
WITH ItemSales AS (
    SELECT
        Sg.StockGroupName,
        St.StockItemID,
		St.UnitPrice, 
        St.StockItemName,
        SUM(Il.ExtendedPrice) AS total_revenue,
        SUM(Il.Quantity) AS total_quan
    FROM 
		Sales.InvoiceLines Il
		JOIN Sales.Invoices I ON Il.InvoiceID  = I.InvoiceID
		JOIN Warehouse.StockItems St ON Il.StockItemID = St.StockItemID
		JOIN Warehouse.StockItemStockGroups Stsg ON St.StockItemID = Stsg.StockItemID
		JOIN Warehouse.StockGroups Sg ON Stsg.StockGroupID = Sg.StockGroupID
    GROUP BY 
		Sg.StockGroupName, 
		St.StockItemID, 
		St.UnitPrice,
		St.StockItemName
),
-- Rank products by revenue within each group
Ranked AS (
    SELECT
        *,
        RANK() OVER (PARTITION BY StockGroupName ORDER BY total_revenue DESC) AS rk
    FROM 
		ItemSales
)
SELECT
    StockGroupName,
    StockItemID,
	UnitPrice, 
    StockItemName,
    total_revenue,
    total_quan
FROM 
	Ranked
WHERE 
	rk <= 3 -- Select top 3 products for each product group
ORDER BY 
	StockGroupName, 
	rk