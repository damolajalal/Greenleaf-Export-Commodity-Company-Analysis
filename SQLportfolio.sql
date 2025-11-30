--Data Cleaning
--Duplicates handling
WITH d_export AS (SELECT *, ROW_NUMBER() OVER(PARTITION BY order_id, product,
quantity_mt, unit_price_usd, buyer_country, quality_grade, 
order_status, order_date,shipment_date, Total_value_usd ORDER BY order_id) AS row_num
FROM exportproject)
DELETE
FROM d_export
WHERE row_num > 1;

--Finding missing column
SELECt *
FROM [exportproject]
WHERE Quantity_MT is null;

SELECt *
FROM [exportproject]
WHERE Unit_Price_USD= ' ';

SELECt *
FROM [exportproject]
WHERE Buyer_Country is null OR Buyer_Country= ' ';

SELECt *
FROM [exportproject]
WHERE Quality_Grade is null OR Quality_Grade= ' ';

SELECt *
FROM [exportproject]
WHERE Order_Date is null OR Order_Status= ' ';

SELECt *
FROM [exportproject]
WHERE Order_Status = 'completed' and Shipment_Date is null;

--date validation

WITH dateval AS (SELECT
	min(order_date) AS earliest_ord_date, 
	MAX(order_date) AS oldest_ord_date,
	MIN(shipment_date) AS  earliest_ship_date,
	MAX(shipment_date)  AS oldest_ship_date
FROM [exportproject])
SELECT *
FROM dateval
WHERE earliest_ord_date < '2021-01-01' 
	OR oldest_ord_date > '2025-05-19'
	OR earliest_ship_date < '2021-01-06'
	OR oldest_ship_date > '2025-07-01';

--check valid values
SELECT Quantity_MT, Unit_Price_USD, Total_Value_USD
FROM [exportproject]
WHERE Quantity_MT<=0 OR Unit_Price_USD <=0;

SELECT *
FROM [exportproject]
WHERE Total_Value_USD <> ROUND(quantity_mt * unit_price_usd, 2);

UPDATE [export project]
SET Total_Value_USD= ROUND(quantity_mt * unit_price_usd, 2)
WHERE Total_Value_USD <> ROUND(quantity_mt * unit_price_usd, 2);

--name standardisation
SELECT DISTINCT Product
FROM [exportproject]

UPDATE [exportproject]
SET product= TRIM(product)

UPDATE [exportproject]
SET Buyer_Country= TRIM(Buyer_Country);

SELECT DISTINCT order_status
FROM [exportproject];


ALTER TABLE [exportproject]
ADD shipping_duration_days INT;

UPDATE [exportproject]
SET shipping_duration_days= DATEDIFF(DAY, order_date, shipment_date)
WHERE shipment_date IS NOT NULL;

--flag delayed shipments
ALTER TABLE exportproject
ADD is_delayed CHAR(1);

UPDATE exportproject
SET shipping_duration_days = NULL 
WHERE order_status IN ('Pending', 'Cancelled')

UPDATE exportproject
SET shipment_date = NULL 
WHERE order_status IN ('Pending', 'Cancelled')

SELECT*
FROM exportproject
WHERE shipping_duration_days< 0 OR shipping_duration_days>60;

SELECT*
FROM exportproject
WHERE order_status='completed' and shipping_duration_days is null

--REVENUE ANALYSIS

SELECT ROUND(SUM(total_value_USD),2) AS Total_revenue
FROM exportproject ;

--revenue by year
SELECT  YEAR(order_date) AS Order_Year, 
	ROUND(SUM(total_value_USD),2) AS Total_revenue	
FROM exportproject 
GROUP BY YEAR(order_date) 
ORDER BY Order_Year;

SELECT YEAR(order_date) AS order_year, 
	Product, buyer_country, 
	ROUND(SUM(total_value_USD),2) AS Total_revenue	
FROM exportproject 
GROUP BY YEAR(order_date), product,buyer_country
ORDER BY product;
--YOY
WITH YoY AS (
SELECT YEAR(order_date) AS Year, 
SUM(total_value_USD) AS Total_Revenue,
LAG(SUM(total_value_USD))
OVER(ORDER BY year(order_date)) AS pre_rev
FROM exportproject GROUP BY YEAR(order_date))
SELECT YEAR, Total_REvenue, pre_rev, 
ROUND(((Total_Revenue-Pre_rev)/(pre_rev)*100),2) AS YOY
FROM YoY
ORDER BY Year;

WITH MoM AS (
SELECT Month(order_date) AS Month, 
SUM(total_value_USD) AS Total_Revenue,
LAG(SUM(total_value_USD))
OVER(ORDER BY MONTH(order_date)) AS pre_rev
FROM exportproject GROUP BY MONTH(order_date))
SELECT MONTH, Total_REvenue, pre_rev, 
ROUND(((Total_Revenue-Pre_rev)/(pre_rev)*100),2) AS YOY
FROM MoM
ORDER BY MONTH;
--Quarterly Revenue
SELECT Year(order_date) AS Year, 
	DATEPART(QUARTER,Order_date) AS QUARTER, 
	SUM(total_value_USD) AS QUARTERLY_Revenue
FROM exportproject
GROUP BY Year(order_date), 
	DATEPART(QUARTER,Order_date)
ORDER BY Year,QUARTER

--PRODUCT ANALYSIS(product revenue by year)
SELECT YEAR(order_date) AS Year, Product,ROUND(SUM(total_value_USD),0)
	AS revenue
FROM exportproject
GROUP BY Product, YEAR(order_date)
ORDER BY revenue;

WITH YoY AS (
SELECT Year(order_date) AS Year, Product,
SUM(total_value_USD) AS Total_Revenue,
LAG(SUM(total_value_USD))
OVER(ORDER BY YEAR(order_date)) AS pre_rev
FROM exportproject GROUP BY YEAR(order_date), Product)
SELECT Year, product,Total_REvenue, pre_rev, 
ROUND(((Total_Revenue-Pre_rev)/(pre_rev)*100),2) AS YOY
FROM YOY
GROUP BY product
ORDER BY year;

---product  volume anAalysis
SELECT product, SUM(quantity_mt) AS total_quantity,
	ROUND(SUM(total_value_usd),2) AS total_revenue, 
	ROUND(SUM(total_value_usd)/SUM(quantity_mt),2) AS avg_price_mt
FROM exportproject
GROUP BY Product
ORDER BY total_quantity DESC;
--bUYER COUNTRY ANALYSIS
SELECT Buyer_Country,
	SUM(total_value_usd) AS total_revenue
FROM exportproject
GROUP  BY Buyer_Country
ORDER BY total_revenue DESC;

SELECT YEAR(ORDER_DATE) AS YEAR, Buyer_Country,
	SUM(total_value_usd) AS total_revenue
FROM exportproject
GROUP  BY YEAR(ORDER_DATE), Buyer_Country
ORDER BY total_revenue DESC;

WITH YoY AS (
SELECT Year(order_date) AS Year, Buyer_Country,
SUM(total_value_USD) AS Total_Revenue,
LAG(SUM(total_value_USD))
OVER(ORDER BY YEAR(order_date)) AS pre_rev
FROM exportproject GROUP BY YEAR(order_date), Buyer_Country)
SELECT Year, Buyer_Country,Total_REvenue, pre_rev, 
ROUND(((Total_Revenue-Pre_rev)/(pre_rev)*100),2) AS YOY
FROM YOY
ORDER BY Year;
--customer insight

SELECT Buyer_Country, COUNT(order_Id) AS Total_orders,
	ROUND(SUM(total_value_usd),2) AS Total_Revenue,
	ROUND(AVG(total_value_usd),2) AS avg_order_value
FROM exportproject
WHERE order_Status = 'completed'
GROUP BY Buyer_country
ORDER BY total_orders DESC

SELECT * 
FROM exportproj


