--  Creation of Schema
CREATE SCHEMA tech_electro;
USE tech_electro;

-- DATA EXPLORATION
SELECT * FROM tech_electro.external_factors LIMIT 5;
SELECT * FROM tech_electro.`sales data` LIMIT 5;
SELECT * FROM tech_electro.product_information LIMIT 5;

-- Understanding the structure of our dataset
SHOW COLUMNS FROM tech_electro.external_factors;
DESCRIBE tech_electro.`sales data`;
DESC tech_electro.product_information;

-- Data cleaning
-- change to the right data type for all columns
-- starting from the external factor table: 
-- this is how we want our table to be: SalesDate DATE , GDP DECIMAL(15,2) , InflationRate DECIMAL(5,2), SeasonalFactor DECIMAL(5,2)
-- first, let's change our date format
ALTER TABLE tech_electro.external_factors 
ADD COLUMN New_Sales_Date DATE;
SET SQL_SAFE_UPDATES = 0; -- Turning off safe updates
UPDATE tech_electro.external_factors
SET New_Sales_Date = STR_TO_DATE(`Sales Date`, '%d/%m/%Y');
ALTER TABLE tech_electro.external_factors
DROP COLUMN `Sales Date`;
ALTER TABLE tech_electro.external_factors
CHANGE COLUMN New_Sales_Date Sales_Date DATE;

-- next, let's change our GDP format to this- GDP DECIMAL(15,2)
ALTER TABLE tech_electro.external_factors
MODIFY COLUMN GDP DECIMAL(15,2);

-- next, let's change our InflationRate to this- InflationRate DECIMAL(5,2)
ALTER TABLE tech_electro.external_factors
MODIFY COLUMN `Inflation Rate` DECIMAL(5,2);

-- next, let's change our Seasonal Factor to this- SeasonalFactor DECIMAL(5,2)
ALTER TABLE tech_electro.external_factors
MODIFY COLUMN `Seasonal Factor` DECIMAL(5,2);

-- now, let's confirm our changes have been made
SHOW COLUMNS FROM tech_electro.external_factors;

-- let's make changes to product information table: 
-- this is how we want our table to be: ProductID INT NOT NULL, Product_Category TEXT, Promotions ENUM('yes', 'no')

ALTER TABLE tech_electro.product_information
ADD COLUMN NewPromotions ENUM('yes', 'no');
UPDATE tech_electro.product_information
SET NewPromotions = CASE
   WHEN Promotions = 'yes' THEN 'yes'
   WHEN Promotions = 'no' THEN 'no'
   ELSE NULL
END;

ALTER TABLE tech_electro.product_information
DROP COLUMN Promotions;

ALTER TABLE tech_electro.product_information
CHANGE COLUMN NewPromotions Promotions ENUM('yes', 'no');

-- let's make changes to sales data table: 
-- this is how we want our table to be: Product_ID INT NOT NULL, Sales_Date DATE, Inventory_Quantity INT, Product_Cost DECIMAL(10, 2)
-- first, let's change our date format
ALTER TABLE tech_electro.`sales data`
ADD COLUMN New_Sales_Date DATE;
SET SQL_SAFE_UPDATES = 0; -- Turning off safe updates
UPDATE tech_electro.`sales data`
SET New_Sales_Date = STR_TO_DATE(`Sales Date`, '%d/%m/%Y');
ALTER TABLE tech_electro.`sales data`
DROP COLUMN `Sales Date`;
ALTER TABLE tech_electro.`sales data`
CHANGE COLUMN New_Sales_Date Sales_Date DATE;

-- next, let's change our Product_Cost to this- ProductCost DECIMAL(10, 2)
ALTER TABLE tech_electro.`sales data`
MODIFY COLUMN `Product Cost` DECIMAL(10, 2);

-- Handling Missing Values(still under data cleaning)
-- Identify missing values using IS NULL function
-- let's work on external factors table 
SELECT
 SUM(CASE WHEN `Sales_Date` IS NULL THEN 1 ELSE 0 END) AS missing_sales_date,
 SUM(CASE WHEN `GDP` IS NULL THEN 1 ELSE 0 END) AS missing_gdp,
 SUM(CASE WHEN `Inflation Rate` IS NULL THEN 1 ELSE 0 END) AS missing_inflation_rate,
 SUM(CASE WHEN `Seasonal Factor` IS NULL THEN 1 ELSE 0 END) AS missing_seasonal_factor
 FROM tech_electro.external_factors;
 
-- let's work on product_information table
SELECT
 SUM(CASE WHEN `Product ID` IS NULL THEN 1 ELSE 0 END) AS missing_product_id,
 SUM(CASE WHEN `Product Category` IS NULL THEN 1 ELSE 0 END) AS missing_product_category,
 SUM(CASE WHEN Promotions IS NULL THEN 1 ELSE 0 END) AS missing_promotions
 FROM tech_electro.product_information;
 
 -- let's work on product_information table
SELECT
 SUM(CASE WHEN `Product ID` IS NULL THEN 1 ELSE 0 END) AS missing_product_id,
 SUM(CASE WHEN `Product Category` IS NULL THEN 1 ELSE 0 END) AS missing_product_category,
 SUM(CASE WHEN Promotions IS NULL THEN 1 ELSE 0 END) AS missing_promotions
 FROM tech_electro.product_information;

  -- let's work on sales_data table
SELECT
 SUM(CASE WHEN `Product ID` IS NULL THEN 1 ELSE 0 END) AS missing_product_id,
 SUM(CASE WHEN `Inventory Quantity` IS NULL THEN 1 ELSE 0 END) AS missing_inventory_quantity,
 SUM(CASE WHEN `Product Cost` IS NULL THEN 1 ELSE 0 END) AS missing_product_cost,
 SUM(CASE WHEN `Sales_Date` IS NULL THEN 1 ELSE 0 END) AS missing_sales_date
 FROM tech_electro.`sales data`;
 
 -- CHECKING FOR DUPLICATES USING "GROUP BY" and "HAVING" CLAUSES and REMOVING THEM IF NECCESSARY
 -- EXTERNAL FACTORS TABLE
 SELECT sales_date, COUNT(*) AS COUNT
 FROM tech_electro.external_factors
 GROUP BY sales_date
 HAVING COUNT > 1;
 
 -- To know the total number of duplicates we have in this table
 SELECT COUNT(*) FROM(SELECT sales_date, COUNT(*) AS COUNT
 FROM tech_electro.external_factors
 GROUP BY sales_date
 HAVING COUNT > 1) AS DUPLICATE;

-- PRODUCT INFORMATION TABLE
SELECT `Product ID`, `Product Category`, COUNT(*) AS COUNT
FROM tech_electro.product_information
GROUP BY `Product ID`, `Product Category`
HAVING COUNT > 1;

 -- To know the total number of duplicates we have in this table
 SELECT COUNT(*) FROM(SELECT `Product ID`, COUNT(*) AS COUNT
FROM tech_electro.product_information
GROUP BY `Product ID`
HAVING COUNT > 1) AS DUPLICATE;

-- SALES DATA TABLE
SELECT `Product ID`, `Sales_Date`, COUNT(*) AS COUNT
FROM tech_electro.`sales data`
GROUP BY `Product ID`, `Sales_Date`
HAVING COUNT > 1;

-- HANDLING DUPLICATES FOR EXTERNAL FACTORS TABLE & PRODUCT INFORMATION TABLE
-- EXTERNAL FACTOR TABLE
DELETE e1 FROM tech_electro.external_factors e1
INNER JOIN(
  SELECT Sales_Date,
  ROW_NUMBER() OVER (PARTITION BY Sales_Date ORDER BY Sales_Date) AS rn
  FROM tech_electro.external_factors
  ) e2 ON e1.Sales_Date = e2.Sales_Date
  WHERE e2.rn > 1;
  
-- PRODUCT DATA
DELETE p1 FROM tech_electro.product_information p1
INNER JOIN(
  SELECT `Product ID`,
  ROW_NUMBER() OVER (PARTITION BY `Product ID` ORDER BY `Product ID`) AS rn
FROM tech_electro.product_information
) p2 ON p1.`Product ID` = p2.`Product ID`
  WHERE p2.rn > 1;
  
  -- DATA INTEGRATON
  -- Combining sales_data and product_information
  CREATE VIEW sales_product_data AS
  SELECT
  s.`Product ID`,
  s.Sales_Date,
  s.`Inventory Quantity`,
  s.`Product Cost`,
  p.`Product Category`,
  p.Promotions
  FROM `sales data` s
  JOIN product_information p ON s.`Product ID` = p.`Product ID`;
  
  -- Combining sales_product_data and external_factors
  CREATE VIEW Inventory_data AS 
  SELECT
  sp.`Product ID`,
  sp.Sales_Date,
  sp.`Inventory Quantity`,
  sp.`Product Cost`,
  sp.`Product Category`,
  sp.Promotions,
  e.GDP,
  e.`Inflation Rate`,
  e.`Seasonal Factor`
  FROM sales_product_data sp
  LEFT JOIN external_factors e
  ON sp.Sales_Date = e.Sales_Date;
  
  -- DESCRIPTIVE ANALYSIS
  -- Calculating basic statistics
  -- Average Sales (To be calculated as the product of "Inventory Quantity" and "Product Cost")
  SELECT `Product ID`,
  ROUND(AVG(`Inventory Quantity` * `Product Cost`)) AS avg_sales
  FROM Inventory_data
  GROUP BY `Product ID`
  ORDER BY avg_sales DESC;
  
  -- Median Stock Levels(i.e. "Inventory Quantity")
  SELECT `Product ID`, AVG(`Inventory Quantity`) AS median_stock
  FROM (
   SELECT `Product ID`,
		   `Inventory Quantity`,
  ROW_NUMBER() OVER(PARTITION BY `Product ID` ORDER BY `Inventory Quantity`) AS row_num_asc,
  ROW_NUMBER() OVER(PARTITION BY `Product ID` ORDER BY `Inventory Quantity` DESC) AS row_num_desc
   FROM Inventory_data
  ) AS subquery
  WHERE row_num_asc IN (row_num_desc, row_num_desc - 1, row_num_desc + 1)
  GROUP BY `Product ID`;
  
  -- Product performance metrics (total sales per product)
SELECT `Product ID`,
ROUND(SUM(`Inventory Quantity` * `Product Cost`)) AS total_sales
FROM Inventory_data
GROUP BY `Product ID`
ORDER BY total_sales DESC;

-- To identify high demand products based on average sales
WITH HighDemandProducts As (
 SELECT `Product ID`, AVG(`Inventory Quantity`) As avg_sales
  FROM Inventory_data
   GROUP BY `Product ID`
HAVING avg_sales > (
SELECT AVG(`Inventory Quantity`) * 0.95 FROM `Sales data`
   )
)

-- Calculate stockout frequency for high demand products
SELECT s.`Product ID`,
COUNT(*) as stockout_frequency
FROM Inventory_data s
WHERE s.`Product ID` IN (SELECT `Product ID` FROM HighDemandProducts)
AND s.`Inventory Quantity` = 0
GROUP BY s.`Product ID`;

-- INFLUENCE OF EXTERNAL FACTORS
-- GDP: Represents ooverall economic health and  growth of a nation. A higher GDP indicates more customer spending leading to 
-- increased sales for businesses. A lower GDP signifies an economic downturn, potentially leading to decreased sales.
-- Inflation Rate: Rate at which general level of price and goods is rising and pirchasing power is falling. Hence, a high inflation
-- rate will lead to decreased sales.

-- GDP
SELECT `Product ID`,
AVG(CASE WHEN `GDP` > 0 THEN `Inventory Quantity` ELSE NULL END) AS avg_sales_positive_gdp,
AVG(CASE WHEN `GDP` <= 0 THEN `Inventory Quantity` ELSE NULL END) AS avg_sales_non_positive_gdp
FROM Inventory_data
GROUP BY `Product ID`
HAVING avg_sales_positive_gdp IS NOT NULL;

-- Inflation Rate
SELECT `Product ID`,
AVG(CASE WHEN `Inflation Rate` > 0 THEN `Inventory Quantity` ELSE NULL END) AS avg_sales_positive_inflation,
AVG(CASE WHEN `Inflation Rate` <= 0 THEN `Inventory Quantity` ELSE NULL END) AS avg_sales_non_positive_inflation
FROM Inventory_data
GROUP BY `Product ID`
HAVING avg_sales_positive_inflation IS NOT NULL

-- INVENTORY OPTIMIZATION
-- This aims to ensure that the right amount of stock is maintained to meet customer's demand while minimizing holding cost and potential stockout.
-- Determine the optimal reorder point for each product based on historical sales data and external factors.
-- Reorder point is the level at which new orders should be placed
-- Reorder Point = Lead Time Demand + Safety Stock
-- Lead Time Demand is the expected sales during the lead time 
-- Lead Time Demand = Rolling Average Sales x Lead Time
-- Reorder Point = Rolling Average Sales x Lead Time + Z x Lead Time^-2 x Standard Deviation of Demand 
-- Safety Stock is an extra buffer stock to account for variability in demand and supply. Incase they run out of their lead time demand, safety
-- stock is there to cover up.
-- Safety Stock = Z x Lead Time^-2 x Standard Deviation of Demand 
-- Z = 1.645
-- A constant lead time of 7days for all products
-- We aim for a 95% service level

WITH InventoryCalculations AS (
  -- First Subquery
  SELECT `Product ID`,
         AVG(rolling_avg_sales) AS avg_rolling_sales,
         AVG(rolling_variance) AS avg_rolling_variance
  FROM (
    SELECT `Product ID`,
           AVG(subquery1.daily_sales) OVER (PARTITION BY `Product ID` ORDER BY Sales_Date ROWS BETWEEN 6 PRECEDING AND CURRENT ROW) AS rolling_avg_sales,
           AVG(squared_diff) OVER (PARTITION BY `Product ID` ORDER BY Sales_Date ROWS BETWEEN 6 PRECEDING AND CURRENT ROW) AS rolling_variance
    FROM (
      SELECT `Product ID`,
              Sales_Date,
             `Inventory Quantity` * `Product Cost` AS daily_sales,
             (`Inventory Quantity` * `Product Cost` - AVG(`Inventory Quantity` * `Product Cost`) OVER(PARTITION BY `PRODUCT ID` ORDER BY Sales_Date ROWS BETWEEN 6 PRECEDING AND CURRENT ROW)),
             (`Inventory Quantity` * `Product Cost` - AVG(`Inventory Quantity` * `Product Cost`) OVER(PARTITION BY `PRODUCT ID` ORDER BY Sales_Date ROWS BETWEEN 6 PRECEDING AND CURRENT ROW)) AS squared_diff
      FROM Inventory_data
    ) AS subquery1  -- Alias for the first subquery
  ) AS subquery2  -- Alias for the second subquery
  GROUP BY `Product ID`
)
SELECT `Product ID`,
       avg_rolling_sales * 7 AS lead_time_demand,
       1.645 * (avg_rolling_variance * 7) AS safety_stock,
       (avg_rolling_sales * 7) + (1.645 * (avg_rolling_variance * 7)) AS reorder_point
FROM InventoryCalculations;


-- Create Iventory optimization table
-- Step 1: Create a new table called "inventory_optimization"
CREATE TABLE inventory_optimization (
    `Product ID` INT,
    Reorder_point DOUBLE
);

-- Step 2: Create the stored procedure to recalculate Reorder point
DELIMITER //
CREATE PROCEDURE RecalculateReorderPoint(productID INT)
BEGIN
    DECLARE avgRollingSales DOUBLE;
    DECLARE avgRollingVariance DOUBLE;
    DECLARE leadTimeDemand DOUBLE;
    DECLARE safetyStock DOUBLE;
    DECLARE reorderPoint DOUBLE;
    
    SELECT AVG(rolling_avg_sales), AVG(rolling_variance)
	INTO avgRollingSales, avgRollingVariance
  FROM (
	 SELECT `Product ID`,
		 AVG(subquery1.daily_sales) OVER (PARTITION BY `Product ID` ORDER BY Sales_Date ROWS BETWEEN 6 PRECEDING AND CURRENT ROW) AS rolling_avg_sales,
		 AVG(squared_diff) OVER (PARTITION BY `Product ID` ORDER BY Sales_Date ROWS BETWEEN 6 PRECEDING AND CURRENT ROW) AS rolling_variance
	 FROM (
         SELECT `Product ID`,
              Sales_Date,
             `Inventory Quantity` * `Product Cost` AS daily_sales,
             (`Inventory Quantity` * `Product Cost` - AVG(`Inventory Quantity` * `Product Cost`) OVER(PARTITION BY `PRODUCT ID` ORDER BY Sales_Date ROWS BETWEEN 6 PRECEDING AND CURRENT ROW)) AS squared_diff
         FROM Inventory_data
    ) AS InnerDerived
  ) AS OuterDerived;
  SET leadTimeDemand = avgRollingSales * 7; 
  SET safetyStock = 1.645 * SQRT(avgRollingVariance * 7);
  SET reorderPoint = leadTimeDemand * safetyStock;
    
INSERT INTO inventory_optimization (`Product ID`, Reorder_point)
VALUES (productID, reorderPoint)
ON DUPLICATE KEY UPDATE Reorder_Point = reorderPoint;
END //
DELIMITER ;

-- Step 3: Make Inventory_data a permananent table 
CREATE TABLE Inventory_table AS SELECT * FROM Inventory_data;

-- Step 4: Create the Triggger
DELIMITER //
CREATE TRIGGER AfterInsertUnifiedTable
AFTER INSERT ON Inventory_table
FOR EACH ROW
BEGIN 
 CALL RecalculateReorderPoint(NEW, `ProductID`);
 END //
 DELIMITER ;
 
 -- OVERSTOCKING AND UNDERSTOCKING
 -- Overstocked: Products with inventory constantly higher than their sales trend i.e the rolling avg sales can be considered overstocked
 -- Understocked: Products that frequently have their inventory quantity of zero, despite having sales
 WITH RollingSales AS (
  SELECT 
    `Product ID`,
    Sales_Date,
    AVG(`Inventory Quantity` * `Product Cost`) OVER (
      PARTITION BY `Product ID` 
      ORDER BY Sales_Date 
      ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
    ) AS rolling_avg_sales
  FROM Inventory_data
),

-- Calculate the number of days a product was out of stock
StockoutDays AS (
  SELECT 
    `Product ID`,
    COUNT(*) AS stockout_days
  FROM inventory_table
  WHERE `Inventory Quantity` = 0
  GROUP BY `Product ID`
)

-- Join the above CTEs with the main table to get the results
SELECT 
  f.`Product ID`,
  AVG(f.`Inventory Quantity` * f.`Product Cost`) AS avg_inventory_value,
  AVG(rs.rolling_avg_sales) AS avg_rolling_sales,
  COALESCE(sd.stockout_days, 0) AS stockout_days
FROM 
  inventory_table f
JOIN 
  RollingSales rs ON f.`Product ID` = rs.`Product ID` AND f.Sales_Date = rs.Sales_Date
LEFT JOIN 
  StockoutDays sd ON f.`Product ID` = sd.`Product ID`
GROUP BY 
  f.`Product ID`, sd.stockout_days;
  
  
  -- MONITOR AND ADJUST
   -- Monitor Inventory Level
CREATE PROCEDURE MonitorInventoryLevels()
BEGIN
SELECT `Product ID`, AVG(`Inventory Quantity`) AS AvgInventory
FROM Inventory_table
GROUP BY `Product ID`
ORDER BY AvgInventory DESC
END//
DELIMITER ;

-- Monitor Sales Trend
  DELIMITER //
CREATE PROCEDURE MonitorSalesTrends()
BEGIN
    SELECT 
        `Product ID`, 
        Sales_Date,
        AVG(`Inventory Quantity` * `Product Cost`) OVER (
            PARTITION BY `Product ID` 
            ORDER BY Sales_Date 
            ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
        ) AS RollingAvgSales
    FROM 
        Inventory_data
    ORDER BY 
        `Product ID`, 
        Sales_Date;
END //

DELIMITER ;

-- Monitor Stockout Frequencies
DELIMITER //
CREATE PROCEDURE MonitorStockouts()
BEGIN
SELECT `Product ID`, COUNT(*) AS StockoutDays
FROM inventory_table
WHERE `Inventory Quantity` = 0
GROUP BY `Product ID`
ORDER BY StockoutDays DESC;
END//
DELIMITER ;

-- FEEDBACK LOOP

-- Feedback Loop Establishment:
-- Feedback Portal: Develop an online platform for stakeholders to easily submit feedback on inventory performance and challenges.
-- Review Meetings: Organize periodic sessions to discuss inventory system performance and gather direct insights.
-- System Monitoring: Use established SQL procedures to track system metrics, with deviations from from expectations flagged for review.

-- Refinement Based on Feedback:
-- Feedback Analysis: Regularly complile and scrutinize feedback to identify recurring themes or pressing issues.
-- Action Implementation: Prioritize and act on the feedback to adjust reorder points, safety stock levels, or overall processes.
-- Change Communication: Inform Stakeholders about changes, underscoring the value of their feedback and ensuring transparency.


-- GENERAL RECOMMENDATION

-- Inventory Discrepancies: The initial stages of the analysis revealed significant discrepancies in inventory levels, 
-- with instances of both overstocking and understocking. These inconsistencies were contributing to capital inefficiencies and customer 
-- dissatisfaction.

-- Sales Trend and External Influences: The analysis indicated that sales trend were notably influenced by various external factors.
--  Recognizing these patterns provides an opportunity to forecast demand more accurately.

-- Suboptimal Inventory Levels: Through the inventory optimization analysis, it was evident that the existing inventory levels were not
-- optimized for current sales trend. Products were identified that had either close inventory.


-- RECOMMENDATIONS
-- 1) Implement Dynamic Inventory Management: The company should transition from a static to a dynamic inventory management system,
--    adjusting inventory levels based on real-time sales trends, seasonality, and external factors.

-- 2) Optimize Reorder Points and Safety Stocks: Utilize the reorder points and safety stock calculated during the analysis to minimize 
--     stockouts and reduce excess inventory. Regulary review these metrics to ensure they align with current market conditions.

-- 3) Enhance Pricing Strategies: Conduct a thorough review of product pricing strategies, especially for products identified as unprofitable
--     Consider factors such as competitor pricing, market demand, and product acquisition costs.

