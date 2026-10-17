/*
===============================================================================
Quality Checks
===============================================================================
Script Purpose:
    This script performs various quality checks for data consistency, accuracy, and
    standardization across the 'silver' schemas.
    It includes checks for:
    	- Null Or Duplicate Primary Keys.
    	- Unwanted spaces in string fields.
    	- Data standardization & consistency.
    	- Invalid date ranges and orders.
    	- Data consistency between related fields

Usage Notes:
    - Run this scipts after loading silver layer.
    - Investigate and resolve any discripencies found during the checks.
===============================================================================
*/


-- ============================================================
-- Checking 'crm_cust_info'
-- ============================================================

-- Check for Nulls Or Duplicates in Primary Key
-- Expectation: No Result
SELECT cst_id,
	COUNT(*)
FROM silver.crm_cust_info
GROUP BY cst_id
HAVING COUNT(*)>1 OR cst_id IS NULL;

WITH ranked_table AS
(SELECT *,
 ROW_NUMBER() OVER (PARTITION BY cst_id ORDER BY cst_create_date DESC ) AS flag_last
FROM silver.crm_cust_info
)
SELECT *
FROM ranked_table
WHERE flag_last != 1;

-- Check for unwanted Spaces
-- Expectation: No Results
SELECT cst_firstname
FROM silver.crm_cust_info
WHERE cst_firstname != TRIM(cst_firstname);

SELECT cst_lastname
FROM silver.crm_cust_info
WHERE cst_lastname != TRIM(cst_lastname);

-- Data Standardizationa & Consistency
SELECT DISTINCT cst_gndr
FROM silver.crm_cust_info;
	
SELECT DISTINCT cst_marital_status
FROM silver.crm_cust_info;

SELECT * FROM silver.crm_cust_info

-- ============================================================
-- Checking 'crm_prd_info'
-- ============================================================

SELECT *
FROM silver.crm_prd_info

-- Check duplicated in product id
-- Expectation: no result
SELECT prd_id,
	COUNT(*)
FROM silver.crm_prd_info
GROUP BY prd_id
HAVING COUNT(*)>1 OR prd_id IS NULL;

-- Check unwanted spaces in product name
-- Expectation: no result
SELECT prd_nm
FROM silver.crm_prd_info
WHERE TRIM(prd_nm) != prd_nm

-- Check Nulls or Negative Numbers
-- Expectation: no result
SELECT prd_cost
FROM silver.crm_prd_info
WHERE prd_cost IS NULL OR prd_cost<0;

-- Check for consitency in low cardinality columns
SELECT DISTINCT prd_line
FROM silver.crm_prd_info

-- Check for Invalid Date Orders
SELECT *
FROM silver.crm_prd_info
WHERE prd_end_dt < prd_start_dt

-- ============================================================
-- Checking 'crm_sales_details'
-- ============================================================

-- Quality Check for Silver Table
SELECT *
FROM silver.crm_sales_details;

SELECT DISTINCT sls_cust_id
FROM silver.crm_sales_details
WHERE sls_cust_id NOT IN
	(SELECT cst_id FROM silver.crm_cust_info);

SELECT DISTINCT sls_prd_key
FROM silver.crm_sales_details
WHERE sls_prd_key NOT IN
	(SELECT prd_key FROM silver.crm_prd_info);

--Check for Invalid date order.(Order date should be earlier than shippind and due date)
SELECT *
FROM silver.crm_sales_details
WHERE sls_order_dt>sls_ship_dt OR sls_order_dt>sls_due_dt;

-- Check Data Consistency: Between Sales, Quantity and Price
-- Sales should be equal to quantity * Price
-- Sales, Quantity and Price should not be Null, Negative or Zero
SELECT *
FROM silver.crm_sales_details
WHERE sls_sales != sls_quantity* sls_price
OR sls_sales IS NULL OR sls_quantity IS NULL OR sls_price IS NULL
OR sls_sales <=0 OR sls_quantity <=0 OR sls_price <=0
ORDER BY sls_sales, sls_quantity, sls_price;

-- ============================================================
-- Checking 'erp_cust_az12'
-- ============================================================

SELECT * FROM silver.erp_cust_az12

-- Check the duplicates in Primary key
SELECT cid,
COUNT(*)
FROM silver.erp_cust_az12
GROUP BY cid
HAVING COUNT(*)>1 OR cid NOT IN
(SELECT DISTINCT cst_key FROM silver.crm_cust_info)

-- Check for out of range birthdays
SELECT bdate
FROM silver.erp_cust_az12
WHERE bdate> NOW()

-- Data Standardization & Consistency
SELECT DISTINCT gen
FROM silver.erp_cust_az12

-- ============================================================
-- Checking 'erp_loc_a101'
-- ============================================================

SELECT * FROM silver.erp_loc_a101;

-- Check duplicates in primart key
SELECT cid,
COUNT(*)
FROM silver.erp_loc_a101
GROUP BY cid
HAVING COUNT(*)>1;

-- Data Standardization & Consistency
SELECT DISTINCT cntry
FROM silver.erp_loc_a101;

-- ============================================================
-- Checking 'erp_px_cat_g1v2'
-- ============================================================

SELECT * FROM silver.erp_px_cat_g1v2;

-- Check duplicates in primary key
-- Expected: No result
SELECT id,
COUNT(*)
FROM silver.erp_px_cat_g1v2
GROUP BY id
HAVING COUNT(*)>1;

-- Check unwanted spaces
-- Expectation: No result
SELECT id
FROM silver.erp_px_cat_g1v2
WHERE TRIM(id)!=id;

SELECT *
FROM silver.erp_px_cat_g1v2
WHERE TRIM(cat)!=cat OR TRIM(subcat)!=subcat OR TRIM(maintenance)!=maintenance; 

-- Data Normalization & Standardization
SELECT DISTINCT cat
FROM silver.erp_px_cat_g1v2;

SELECT DISTINCT subcat
FROM silver.erp_px_cat_g1v2;

SELECT DISTINCT maintenance
FROM silver.erp_px_cat_g1v2;
