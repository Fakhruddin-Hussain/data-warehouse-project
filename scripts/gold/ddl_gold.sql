/*
===============================================================================
DDL Script: Create Gold Views
===============================================================================
Script Purpose:
    This script creates views in the 'gold' layer in the warehouse.
    Dropping existing views if they already exist.
    The Gold Layer represents the final dimention and fact tables(STAR Schema)

    Each view performs transformations and combines data from the silver layer
    to produce clean, enriched and business ready dataset.

USAGE:
    - These views can be queried directly by analytics and reporting
===============================================================================
*/

-- ===========================================================================
-- Create Dimension: gold.dim_customers
-- ===========================================================================
-- Dimension table for customers with comprehensive attributes.

-- Drop view if exists
CREATE OR REPLACE VIEW gold.dim_customers AS
SELECT
	ROW_NUMBER() OVER (ORDER BY ci.cst_id) AS customer_key,
	ci.cst_id AS customer_id,
	ci.cst_key AS customer_number,
	ci.cst_firstname AS first_name,
	ci.cst_lastname AS last_name,
	cl.cntry AS country,
	ci.cst_marital_status AS marital_status,
	CASE WHEN ci.cst_gndr != 'n/a' THEN ci.cst_gndr
		 ELSE COALESCE(cg.gen,'n/a')
	END AS gender,
	cg.bdate AS birthdate,
	ci.cst_create_date AS create_date
FROM silver.crm_cust_info ci JOIN
	silver.erp_cust_az12 cg ON
	ci.cst_key=cg.cid LEFT JOIN
	silver.erp_loc_a101 cl ON
	ci.cst_key=cl.cid;


-- ===========================================================================
-- Create Dimension: gold.dim_products
-- ===========================================================================
-- Dimension table for products with comprehensive attributes.

-- Drop view if exists
CREATE OR REPLACE VIEW gold.dim_products AS
SELECT
	ROW_NUMBER() OVER (ORDER BY pi.prd_start_dt, pi.prd_key) AS product_key,
	pi.prd_id AS product_id,
	pi.prd_key AS product_number,
	pi.prd_nm AS product_name,
	pi.cat_id AS category_id,
	pc.cat AS category,
	pc.subcat AS subcategory,
	pc.maintenance AS maintenance,
	pi.prd_cost AS cost,
	pi.prd_line AS product_line,
	pi.prd_start_dt AS start_date
FROM silver.crm_prd_info pi LEFT JOIN
	silver.erp_px_cat_g1v2 pc ON
	pi.cat_id = pc.id
WHERE pi.prd_end_dt IS NULL; -- Filter out all historical data

-- ===========================================================================
-- Create Fact: gold.fact_sales
-- ===========================================================================
-- Fact table for sales with comprehensive attributes.

CREATE OR REPLACE VIEW gold.fact_sales AS
SELECT
	-- Surrogate Keys (Dimension Lookups)
	dp.product_key,
	dc.customer_key,
	-- Natural Keys (Source System Identifiers)
	sd.sls_ord_num AS order_number,
	-- Date Dimensions
	sd.sls_order_dt AS order_date,
	sd.sls_ship_dt AS shipping_date,
	sd.sls_due_dt AS due_date,
	-- Measures (Facts)
	sd.sls_sales AS sales_amount,
	sd.sls_quantity AS quantity,
	sd.sls_price AS price
FROM silver.crm_sales_details sd
-- Use LEFT JOIN to keep sales records even if dimensions are missing
LEFT JOIN gold.dim_products dp	
	ON sd.sls_prd_key = dp.product_number
LEFT JOIN gold.dim_customers dc
	ON sd.sls_cust_id = dc.customer_id;
