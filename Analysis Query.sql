Create database Supply_Chain;

select * from SupplyChain;

--Calculate the total revenue generated for each product type

SELECT
  [Product_type],
  ROUND(SUM([Revenue_generated]),2) AS Revenue_Generated
FROM SupplyChain
GROUP BY [Product_type]
ORDER BY 2 DESC;


--Determine the average price of products in each product category

SELECT
  [Product_type],
  ROUND(AVG(price),2) AS avg_price
FROM SupplyChain
GROUP BY [Product_type]
ORDER BY 2 DESC;


--Identify the top 5 product with the highest number of units sold

SELECT Top 5
  [Product_type],
  [SKU],
  SUM([Number_of_products_sold]) AS Sales_Volume
FROM SupplyChain
GROUP BY [Product_type], [SKU]
ORDER BY 3 DESC;

--Calculate the average amount of days it takes for a supplier to deliver products.

SELECT
  supplier_name,
  CAST(AVG(Lead_time) AS INT) AS avg_lead_time
FROM SupplyChain
GROUP BY Supplier_name
ORDER BY avg_lead_time DESC;

--Determine the top 3 products by sales volume for each product type.

WITH ProductSales AS (
  SELECT
    Product_type,
    sku,
    SUM(number_of_products_sold) AS Sales_Volume
  FROM SupplyChain
  GROUP BY Product_type,SKU
)

SELECT *
FROM
(
  SELECT *,
  ROW_NUMBER()OVER(
    PARTITION BY product_type
    ORDER BY sales_volume DESC) AS product_rnk
FROM ProductSales) AS sb1
WHERE product_rnk <= 3;


--Calculate average lead times for different suppliers.

SELECT 
  [Supplier_name],
  ROUND(AVG([Lead_time]),2) AS avg_supplier_lead_time
FROM SupplyChain
GROUP BY Supplier_name;


--Identify the top 3 suppliers with the highest defect rates.

SELECT top 3
  supplier_name,
  ROUND(AVG(defect_rates),2) AS avg_defect_rates
FROM SupplyChain
GROUP BY Supplier_name
ORDER BY 2 DESC


--Find the most used supplier for each product type.

WITH SupplierCounts AS (
SELECT
  product_type, 
  supplier_name, 
  COUNT(*) AS supplier_count,
  DENSE_RANK()OVER(
    PARTITION BY product_type
    ORDER BY COUNT(*) DESC
  ) AS supplier_rnk
FROM SupplyChain
GROUP BY Product_type,Supplier_name)

SELECT *
FROM SupplierCounts
WHERE supplier_rnk = 1;



--Calculate the total production volume for each supplier.

SELECT
  supplier_name,
  SUM(production_volumes) AS production_volumes
FROM SupplyChain
GROUP BY Supplier_name
ORDER BY production_volumes DESC;


--Determine the average manufacturing lead time in days across all products.

SELECT
  AVG(manufacturing_lead_time) AS avg_manufacturing_lead_time
FROM SupplyChain;

--Identify the supplier, product and product type with the lowest defect rates.

SELECT
  supplier_name,
  sku,
  product_type,
  defect_rates
FROM SupplyChain
WHERE defect_rates = (SELECT MIN(defect_rates) FROM SupplyChain);


--Calculate the average manufacturing cost per unit for each product type.

SELECT
  product_type,
  ROUND(SUM(manufacturing_costs) / SUM(production_volumes),2) AS avg_unit_cost
FROM SupplyChain
GROUP BY Product_type;

--Analyze the relationship between production volume and defect rates for each supplier.

SELECT
  supplier_name,
  SUM(production_volumes) AS production_volumes,
  ROUND(AVG(defect_rates), 2) AS avg_defect_rates
FROM SupplyChain
GROUP BY Supplier_name
ORDER BY production_volumes DESC;


--Calculate the total shipping cost for each shipping carrier.

SELECT
  shipping_carriers,
  ROUND(SUM(shipping_costs),2) AS shipping_costs
FROM SupplyChain
GROUP BY Shipping_carriers
ORDER BY shipping_costs DESC;


--Determine the average shipping time for products delivered by air.

SELECT
  ROUND(AVG(shipping_times),2) AS avg_shipping_time
FROM SupplyChain
WHERE transportation_modes = 'Air';

--Determine the most frequently used transportation mode for products sourced from Mumbai.

SELECT top 1
  transportation_modes,
  COUNT(*) AS mode_count
FROM SupplyChain
WHERE location = 'Mumbai'
GROUP BY Transportation_modes
ORDER BY mode_count DESC;


--Identify the top 3 suppliers with the highest average shipping costs.

SELECT Top 3
  supplier_name,
  ROUND(AVG(shipping_costs),2) AS avg_shipping_costs
FROM SupplyChain
GROUP BY Supplier_name
ORDER BY avg_shipping_costs DESC;



--Find the shipping routes with average shippingcosts exceeding the average shipping cost for all the routes.

SELECT
  routes,
  ROUND(AVG(shipping_costs),2) AS avg_shipping_cost
FROM SupplyChain
GROUP BY Routes
HAVING ROUND(AVG(shipping_costs),2) > (SELECT ROUND(AVG(shipping_costs),2) FROM SupplyChain);

--Find the top carriers per location based on shipment volume.

WITH LocationCarriers AS(
SELECT
  location,
  shipping_carriers,
  COUNT(shipping_carriers) AS shipment_volume,
  RANK()OVER(
    PARTITION BY location
    ORDER BY COUNT(shipping_carriers) DESC
  )AS rnk
FROM SupplyChain
GROUP BY Location, Shipping_carriers
)

SELECT
  location,
  shipping_carriers,
  shipment_volume
FROM LocationCarriers
WHERE rnk = 1;

--Classify shipping carriers into performance categories (e.g., good, average, poor) by comparing their average shipping time
--to the overall average shipping time and calculate the total shipping cost for each carrier

WITH AvgShippingTime AS (
  -- Calculate the overall average shipping time across all carriers
  SELECT 
    ROUND(AVG([Shipping_times]), 2) AS avg_shipping_time
  FROM 
    SupplyChain
), 
CarrierPerformance AS (
  -- For each carrier, calculate their average shipping time and total shipping cost
  SELECT 
    [Shipping_carriers], 
    ROUND(AVG([Shipping_times]), 2) AS carrier_avg_shipping_time, 
    SUM([Shipping_costs]) AS total_shipping_cost,
    -- Compare carrier's average shipping time to the overall average and classify them
    CASE 
      WHEN ROUND(AVG([Shipping_times]), 2) < (SELECT avg_shipping_time FROM AvgShippingTime) THEN 'Good'
      WHEN ROUND(AVG([Shipping_times]), 2) = (SELECT avg_shipping_time FROM AvgShippingTime) THEN 'Average'
      ELSE 'Poor'
    END AS performance_category
  FROM 
    SupplyChain
  GROUP BY 
    [Shipping_carriers]
)
-- Final result to display the classification and total shipping cost for each carrier
SELECT 
  [Shipping_carriers], 
  carrier_avg_shipping_time, 
  performance_category, 
  total_shipping_cost
FROM 
  CarrierPerformance
ORDER BY 
  performance_category ASC, carrier_avg_shipping_time;