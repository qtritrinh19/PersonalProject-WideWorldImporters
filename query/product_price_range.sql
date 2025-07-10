-- Product Price Range Analysis
WITH segmentation_price AS (
SELECT
	St.StockItemName, 
	St.UnitPrice, 
	St.UnitPrice*(1+St.TaxRate/100) AS UnitPriceWithTax,
	 -- Categorize into price range
	CASE WHEN St.UnitPrice*(1+St.TaxRate/100) > 500 THEN 'Over 500$'
		 WHEN St.UnitPrice*(1+St.TaxRate/100) BETWEEN 300 AND 500 THEN '300-500$'
		 WHEN St.UnitPrice*(1+St.TaxRate/100) BETWEEN 100 AND 300 THEN '100-300$'
		 ELSE 'Below 100$'
	END AS price_range, 
	Il.Quantity, 
	Il.ExtendedPrice, 
	Il.InvoiceID
FROM 
	Sales.InvoiceLines Il 
	JOIN Warehouse.StockItems St ON Il.StockItemID = St.StockItemID
)

SELECT
	price_range,
	SUM(ExtendedPrice) AS sum_of_sale
FROM 
	segmentation_price
GROUP BY 
	price_range
ORDER BY 
	SUM(ExtendedPrice) DESC