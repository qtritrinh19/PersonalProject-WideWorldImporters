# SQL Analytics Project: **WideWorldImporters**

This project uses SQL to analyze sales data from the WideWorldImporters database across three main areas: time, product, and region. It includes monthly and yearly sales tracking, cumulative and year-over-year growth, product segmentation by price, performance by category, and identification of top-selling items. Regional analysis covers sales by state, territory, and city, along with per capita metrics and trend changes. All queries apply T-SQL techniques like CTEs, window functions, and conditional logic to simulate real-world business reporting.


## 1. Data Source:

**WideWorldImporters** is a sample OLTP database developed by Microsoft to simulate a mid-sized wholesale and retail business. It contains realistic transactional data across various domains, including sales, purchasing, inventory, customers, and suppliers.

Link: [Wide World Importers sample database v1.0](https://github.com/Microsoft/sql-server-samples/releases/tag/wide-world-importers-v1.0)

This project is based on a subset of tables from the database, primarily focused on sales, product, and location data:

- **Sales-related tables**:  `Sales.Invoices`, `Sales.InvoiceLines`, `Sales.Customers`
- **Product-related tables**:  `Warehouse.StockItems`, `Warehouse.StockGroups`, `Warehouse.StockItemStockGroups`
- **Location-related tables**:  `Application.Cities`, `Application.StateProvinces`

## 2. SQL-Based Exploratory Analysis

### 2.1. **Time-based analysis**

#### 2.1.1. Monthly Sales Overview

```sql
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
```

| InvoiceMonth | Sum_price   | Total_invoices | Total_quantity |
|--------------|-------------|----------------|----------------|
| 2013-01-01   | 4335972.97  | 5246           | 193271         |
| 2013-02-01   | 3193304.60  | 3707           | 142120         |
| 2013-03-01   | 4451081.62  | 5330           | 207486         |
| ...          | ...         | ...            | ...            |
| 2016-03-01   | 5330250.56  | 6074           | 252408         |
| 2016-04-01   | 5236062.81  | 5923           | 251945         |
| 2016-05-01   | 5704232.71  | 6351           | 270036         |

This query provides a monthly summary of total revenue, invoice count, and quantity sold. It enables several key business insights:

- Sales Seasonality: Identify high-performing and low-performing months to uncover seasonal trends and demand cycles.

- Invoice Volume Trends: Track changes in the number of invoices issued per month to monitor business activity over time.

- Average Order Value: By comparing revenue to invoice count, the average sales value per order can be inferred—helpful for evaluating customer purchasing behavior.

- Sales Efficiency: Analyzing revenue alongside total quantity sold helps assess whether high sales come from volume or high-value items.

- Anomalies or Spikes: Detect unusual patterns or sharp changes in any metric that may indicate promotions, supply issues, or unexpected events.

#### 2.1.2. Monthly Cumulative Sales by Year

```sql
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
```

| InvoiceMonth | Sum_price   | cummulative_sales |
|--------------|-------------|-------------------|
| 2013-01-01   | 4335972.97  | 4335972.97        |
| 2013-02-01   | 3193304.60  | 7529277.57        |
| 2013-03-01   | 4451081.62  | 11980359.19       |
| ...          | ...         | ...               |
| 2016-03-01   | 5330250.56  | 15030733.59       |
| 2016-04-01   | 5236062.81  | 20266796.40       |
| 2016-05-01   | 5704232.71  | 25971029.11       |

Instead of viewing monthly sales in isolation, this query shifts the focus to how revenue builds up progressively throughout each year. By calculating the cumulative total, it provides a more holistic view of performance trends and reveals several unique insights:

- Sales Growth Momentum: Helps assess how quickly revenue builds during the year—revealing strong or slow growth phases.

- Target Tracking: Provides a clear picture of how current performance aligns with annual sales goals or projections.

- Early Warning Signals: A flat or slow accumulation curve early in the year can help identify underperformance before it becomes critical.
  
- Performance Consistency: Smooth and steady cumulative growth may indicate operational stability or strong customer retention.


#### 2.1.3. Year-over-Year (YoY) Growth by Month

```sql
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

```

| InvoiceMonth | MonthlySales       | SalesLastYear        | YoY_Growth_Percent |
|--------------|--------------------|----------------------|--------------------|
| 2013-01      | 4,335,972.97       | –                    | –                  |
| 2013-02      | 3,193,304.60       | –                    | –                  |
| 2013-03      | 4,451,081.62       | –                    | –                  |
| ...          | ...                | ...                  | ...                |
| 2016-03      | 5,330,250.56       | 5,207,351.93         | 2.36%              |
| 2016-04      | 5,236,062.81       | 5,834,255.09         | -10.25%            |
| 2016-05      | 5,704,232.71       | 5,152,840.72         | 10.70%             |

This query measures the percentage change in monthly sales compared to the same month in the previous year, providing direct visibility into growth or decline on an annual basis. Unlike cumulative or raw totals, YoY analysis reveals true performance shifts by controlling for seasonality and calendar alignment. Key insights include:

- Normalized Performance Benchmarking: Compares each month to its counterpart in the previous year, making it easier to assess real growth independent of seasonal effects.

- Growth Volatility Detection: Fluctuations in YoY percentages help highlight unstable demand patterns or irregular operational performance.

- Impact of Strategic Changes: Sudden increases or drops may correlate with pricing, marketing campaigns, supply chain adjustments, or external events.

- Identifying Recovery or Decline: Persistent positive YoY trends suggest sustained improvement, while consecutive negative values may indicate downturns or stagnation.

### 2.2. **Product performance**

#### 2.2.1. Monthly Product Group Performance

```sql
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
```
| InvoiceYear | InvoiceMonth | StockGroupName   | Total_amount | avg_change | pm_change |
|-------------|--------------|------------------|--------------|------------|-----------|
| 2013        | 01           | Clothing         | 1,144,552.45 | Below AVG  | No change |
| 2013        | 02           | Clothing         |   841,948.35 | Below AVG  | Decrease  |
| 2013        | 03           | Clothing         | 1,298,550.10 | Over AVG   | Increase  |
| ...         | ...          | ...              | ...          | ...        | ...       |
| 2016        | 04           | T-Shirts         |   830,898.00 | Over AVG   | Decrease  |
| 2016        | 05           | T-Shirts         |   872,380.80 | Over AVG   | Increase  |
| 2016        | 05           | USB Novelties    |   103,624.18 | Over AVG   | Increase  |

This query evaluates how different product groups perform month by month, enabling comparative analysis within and across years. It introduces two key perspectives: relative performance (against group average) and temporal change (month-over-month). From this, several insights emerge:

- Category Health Monitoring: Identify which product groups are consistently underperforming or overachieving relative to their yearly average.

- Momentum Tracking Within Product Groups: The month-over-month trend highlights whether a group’s performance is gaining or losing traction over time.

- Diversified Revenue Contribution: By comparing different stock groups, businesses can assess the breadth of their revenue sources — e.g., whether sales are concentrated or well-distributed.

- Detecting Seasonal or Irregular Patterns: A product group with alternating peaks and drops may indicate seasonality or operational volatility.

#### 2.2.2. Top 3 Selling Products per Product Group

```sql
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
```

| StockGroupName   | StockItemID | UnitPrice | StockItemName                                                       | total_revenue  | total_quan  |
|------------------|-------------|-----------|---------------------------------------------------------------------|----------------|-------------|
| Clothing         | 88          | 18.00     | "The Gu" red shirt XML tag t-shirt (White) 7XL                      | 1559455.20     | 75336       |
| Clothing         | 79          | 18.00     | "The Gu" red shirt XML tag t-shirt (White) S                        | 1537596.00     | 74280       |
| Clothing         | 148         | 18.00     | Halloween skull mask (Gray) L                                       | 1529647.20     | 73896       |
| ...              | ...         | ...       | ...                                                                 | ...            | ...         |
| USB Novelties    | 15          | 240.00    | USB food flash drive - dessert 10 drive variety pack                | 1562118.60     | 5884        |
| USB Novelties    | 8           | 240.00    | USB food flash drive - dim sum 10 drive variety pack                | 1475220.00     | 5537        |
| USB Novelties    | 13          | 32.00     | USB food flash drive - shrimp cocktail                              | 220281.12      | 6204        |


This query ranks individual products within each product group based on total revenue and identifies the top three performers. Rather than viewing performance at the category level, this analysis drills down to specific stock items, offering the following key insights:

- Best-Selling Products Identification: Spot the most profitable products in each category, which can be prioritized for promotion, inventory planning, or product bundling.

- Product Concentration Risk: If revenue in a group is dominated by a single top-seller, it may indicate over-reliance on a narrow product line.

- Unit Price vs. Quantity Dynamics: Comparing `UnitPrice` and `total_quan` reveals whether high revenue is driven by high price, high volume, or both.

- Performance Distribution Within Groups: Understanding how competitive the top items are within a group (e.g., small gap vs. huge drop between rank 1 and 3) can inform diversification strategies.

#### 2.2.3. Product Price Range Analysis

```sql
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
```

| price_range  | sum_of_sale     |
|--------------|-----------------|
| Below 100$   | 118569492.45    |
| 100-300$     | 60554398.85     |
| Over 500$    | 12773338.65     |
| 300-500$     | 6146209.50      |

This query groups products by their final unit price (including tax) into defined price tiers and sums up the total revenue generated by each range. It offers practical insights into customer purchasing behavior and the company's pricing structure:

- Revenue Distribution by Price Tier: Highlights which pricing segments (e.g., below $100 or over $500) contribute most to total sales.

- Price Sensitivity Insight: Reveals whether customers are more responsive to affordable products or premium offerings, which informs both pricing and product design strategies.

### 2.3. **Regional performance**

#### 2.3.1. Sales by State and Territory

```sql
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
```
| State_name             | SalesTerritory    | Sales_amount  | sales_per_capital  |
|------------------------|-------------------|---------------|--------------------|
| Texas                  | Southwest         | 13747265.11   | 0.499789           |
| Pennsylvania           | Mideast           | 11247214.88   | 0.846625           |
| California             | Far West          | 10153238.90   | 0.244889           |
| ...                    | ...               | ...           | ...                |
| New Hampshire          | New England       | 1052763.50    | 0.764869           |
| Hawaii                 | Far West          | 364314.77     | 0.259473           |

This query aggregates sales revenue by state and links each state to its broader sales territory. Additionally, it calculates sales per capita to normalize performance based on population size. It uncovers two key insights:

- Top-Performing States and Territories: Identifies which regions generate the most revenue, helping prioritize geographic focus.

- Market Penetration Efficiency: Sales per capita reveals how deeply the company has penetrated each market, independent of population size — highlighting under-tapped or saturated regions.

#### 2.3.2. Monthly Sales Trend by Sales Territory

```sql
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

```

| InvoiceYear | InvoiceMonth | SalesTerritory | TotalSales | avg_change | pm_change |
|-------------|--------------|----------------|------------|------------|-----------|
| 2013        | 1            | External       | 89102.00   | Over AVG   | No change |
| 2013        | 2            | External       | 45176.89   | Below AVG  | Decrease  |
| 2013        | 3            | External       | 86368.80   | Over AVG   | Increase  |
| ...         | ...          | ...            | ...        | ...        | ...       |
| 2016        | 3            | Southwest      | 630162.17  | Below AVG  | Increase  |
| 2016        | 4            | Southwest      | 641164.00  | Below AVG  | Increase  |
| 2016        | 5            | Southwest      | 754316.18  | Over AVG   | Increase  |

This query tracks monthly revenue trends across sales territories, identifying whether each region is performing above or below its yearly average, and whether monthly sales are increasing or decreasing over time. From this, we can derive key insights:

- Territory Momentum Tracking: Detects whether each region is gaining or losing sales momentum month by month, helping detect growth or slowdown early.

- Consistency vs. Volatility: Highlights which territories maintain stable performance and which experience frequent spikes or drops — useful for risk assessment and forecasting.

- Benchmarking Against Yearly Average: Flags underperforming months that may require sales interventions, and celebrates months that exceed expectations.

#### 2.3.3. Top Cities by Sales

```sql
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

```

| CityName         | StateProvinceName | SalesTerritory   | SalesAmount |
|------------------|-------------------|------------------|-------------|
| Sinclair         | Wyoming           | Rocky Mountain   | 648919.36   |
| Teutopolis       | Illinois          | Great Lakes      | 639424.77   |
| East Fultonham   | Ohio              | Great Lakes      | 628838.61   |
| ...              | ...               | ...              | ...         |
| Long Beach       | Washington        | Far West         | 26069.42    |
| Ellisville       | Illinois          | Great Lakes      | 15189.32    |
| Midland          | Washington        | Far West         | 8326.23     |


This query ranks cities based on total sales revenue and maps each city to its corresponding state and sales territory. It enables a deep dive into location-based performance with the following key insights:

- City-Level Revenue Leaders: Identifies the most profitable cities, which can serve as benchmarks or models for expansion strategies.

- Urban Sales Concentration: Reveals whether a small number of cities dominate overall sales — useful for assessing sales distribution and dependency.

- Territory Optimization Clues: Allows detection of standout cities within underperforming territories, guiding fine-tuned regional planning.


## 3. Business Insights – Strategic Recommendations:

### Business insights:

- Sales are growing steadily, but with weaker performance in the early months

Monthly and year-over-year trends show that total sales are increasing steadily, especially in the third and fourth quarters of the year. However, the first quarter had some months with lower sales compared to the same months in the previous year.

Insight: Early-year performance could be improved with more effective sales campaigns or targeted seasonal product strategies.

- Product groups show different patterns and seasonality

Some product groups, such as Office Supplies and Computing, perform well in the second half of the year, while others like Packaging Materials show consistently low revenue across all months.

Insight: Strong product groups should be prioritized before peak seasons. Weak product groups should be reviewed to consider changes in pricing, bundling, or possible removal.

- Mid-priced products bring in the highest total revenue

Products priced between $100 and $300 generate most of the total sales value. Expensive products (above $500) are sold less often, but each sale brings in a large amount of money.

Insight: Products in the mid-price range are best for wide promotion. High-priced products can be targeted to loyal customers or used in special offers.

- Only a few products in each group bring in most of the money

In every product category, the top 3 items contribute more than 70% of the group’s total sales value. That means most revenue comes from just a few key items.

Insight: Focus on the best-selling products when planning stock, promotions, and customer targeting.

- Some regions are underperforming

Sales in some areas (like the Southwest or Central territories) are often lower than average and are decreasing in some months. However, a few small-population regions show very high revenue per person.

Insight: The company should review its sales strategy in weaker regions and also explore unique opportunities in smaller regions where customer value is high.

- Sales are concentrated in a few large cities
 
Most of the total revenue comes from a small number of major cities.

Insight: Key cities should receive priority in marketing, product delivery, and customer retention programs.

### Strategic recommendations:

- Strengthen campaigns during the first and second quarters of the year to mitigate off-season slumps reflected in YoY growth drops.

- Reassess underperforming product groups for potential retirement or bundling strategies.

- Focus marketing and upsell efforts on mid-priced products, which have the highest volume and stable contribution.

- Prioritize inventory and marketing around the top 3 best-selling products per group to optimize profitability from high-impact items.

- Launch regional initiatives targeting underperforming sales territories (e.g., Southwest), supported by sales enablement resources.

- Explore high-per-capita sales states for niche targeting, particularly in states with lower populations but strong engagement.







