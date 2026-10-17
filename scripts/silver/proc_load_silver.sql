/*
===============================================================================
Stored Procedure: Load Silver Layer (Bronze -> Silver)
===============================================================================
Script Purpose:
      This stored procedure performs ETL (Extract, Transform Load) process to populate
      the 'silver' schema tables from 'bronze' schema.
    It performs the following actions:
      - Truncates the silver tables before loading data.
      - Insert transformed and cleansed data from bronze into silver tables

Parameters:
    None. 
	  This stored procedure does not accept any parameters or return any values.

Usage Example:
    CALL silver.load_silver();
===============================================================================
*/


CREATE OR REPLACE PROCEDURE silver.load_silver()
LANGUAGE plpgsql AS $$
-- Declaration section
DECLARE
	rows_inserted INT;
	v_message VARCHAR(50);
	v_sqlstate VARCHAR(50);
	start_time TIMESTAMP;
	end_time TIMESTAMP;
	batch_start_time TIMESTAMP;
	batch_end_time TIMESTAMP;
-- Execution section
BEGIN
	RAISE NOTICE '=============================================';
	RAISE NOTICE 'Loading the Silver Layer';
	RAISE NOTICE '=============================================';

	RAISE NOTICE '---------------------------------------------';
	RAISE NOTICE 'Loading the CRM Tables ';
	RAISE NOTICE '---------------------------------------------';
	/* Do data Transformation
	=> Remove trailing and leading spaces. Removes unwanted spaces to ensure
		Data cosistency, and uniformity across all records.
	=> Handle missing values. Fills in the blanks with a default value
	=> Normalize and standardize gender & marital status values. Maps coded values to meaningful, user friendly descriptions
	=> Remove Duplicates using Data filtering. Ensure only one record per entity by identifying and retaining the most relevant row.
	*/
	start_time := NOW();
	batch_start_time := NOW();
	RAISE NOTICE '>> Truncating Table: silver.crm_cust_info';
	-- Truncate the table before loading the data
	TRUNCATE TABLE silver.crm_cust_info;
	RAISE NOTICE '>> Inserting Data Into: silver.crm_cust_info';
	WITH ranked_table AS
	(SELECT *,
	 ROW_NUMBER() OVER (PARTITION BY cst_id ORDER BY cst_create_date DESC ) AS flag_last
	FROM bronze.crm_cust_info
	)
	INSERT INTO silver.crm_cust_info(
		cst_id,
		cst_key,
		cst_firstname,
		cst_lastname,
		cst_gndr,
		cst_marital_status,
		cst_create_date
	)
	SELECT cst_id,
		cst_key,
		TRIM(cst_firstname) AS cst_firstname,
		TRIM(cst_lastname) AS cst_lastname,
		CASE WHEN UPPER(TRIM(cst_gndr))='F' THEN 'Female'
			 WHEN UPPER(TRIM(cst_gndr))='M' THEN 'Male'
			 ELSE 'n/a'
		END AS cst_gnder, -- Normalise Gender values to readable format
		CASE WHEN UPPER(TRIM(cst_marital_status))='M' THEN 'Married'
			 WHEN UPPER(TRIM(cst_marital_status))='S' THEN 'Single'
			 ELSE 'n/a'
		END AS cst_marital_status, -- Normalise Marital status  to readable format
		cst_create_date
	FROM ranked_table
	WHERE flag_last = 1;
	end_time := NOW();
	RAISE NOTICE '>> Load Duration: % seconds', CAST(EXTRACT(EPOCH FROM (end_time - start_time)) AS VARCHAR(50));
	RAISE NOTICE '---------------';

	/* Do Data Transformation
	=> Derived Columns:
		Create new columns based on calculation or transformation of existing ones
		cat_id and prd_key derived from prd_key
	=> Handle Missing Values (using coalesce in this case)
	=> Data Normalization and missing value(prd_line)
	=> Data Type Casting (timestamp to date in start date and end date)
	=> Data Enrichment:
		Add new, relevant data to enhance the dataset for analysis(product end date)
	*/
	start_time := NOW();
	RAISE NOTICE '>> Truncating Table: silver.crm_prd_info';
	-- Truncate the table before loading the data
	TRUNCATE TABLE silver.crm_prd_info;
	RAISE NOTICE '>> Inserting Data Into: silver.crm_prd_info';
	INSERT INTO silver.crm_prd_info(
	prd_id,
	cat_id,
	prd_key,
	prd_nm,
	prd_cost,
	prd_line,
	prd_start_dt,
	prd_end_dt
	)
	SELECT  prd_id,
			REPLACE(SUBSTRING(prd_key FROM 1 FOR 5),'-','_') AS cat_id, -- Extract Category ID
			SUBSTRING(prd_key FROM 7) AS prd_key,						-- Extract Product Key
			prd_nm,
			COALESCE(prd_cost,0) AS prd_cost,
			CASE UPPER(TRIM(prd_line))
				 WHEN 'M' THEN 'Mountain'
				 WHEN 'R' THEN 'Road'
				 WHEN 'S' THEN 'Other Sales'
				 WHEN 'T' THEN 'Touring'
				 ELSE 'n/a'
			END AS prd_line, -- Map product line code to descriptive values
			prd_start_dt :: DATE,
			(LEAD(prd_start_dt) OVER(PARTITION BY prd_key ORDER BY prd_start_dt) - INTERVAL '1 day')::DATE AS prd_end_dt
			-- Calculate the end date as 1 day prior to next start date
	FROM bronze.crm_prd_info;
	end_time := NOW();
	RAISE NOTICE '>> Load Duration: % seconds', CAST(EXTRACT(EPOCH FROM (end_time - start_time)) AS VARCHAR(50));
	RAISE NOTICE '---------------';

	/* Do Data Transformation
	=> Handling Invalid Data
	=> Data Type Casting
	=> Handling Missing Data: Deriving data from already existing columns

	=> AS per Rule Discussed with the souce department
		-> If Sales is negative, zero or null derive it using qty and price
		-> If Price is zero or null, calculate it using sales and qty
		-> If Price is negative, convert it into a positive value
	*/
	start_time := NOW();
	RAISE NOTICE '>> Truncating Table: silver.crm_sales_details';
	-- Truncate the table before loading the data
	TRUNCATE TABLE silver.crm_sales_details;
	RAISE NOTICE '>> Inserting Data Into: silver.crm_sales_details';
	INSERT INTO silver.crm_sales_details(
	sls_ord_num,
	sls_prd_key,
	sls_cust_id,
	sls_order_dt,
	sls_ship_dt,
	sls_due_dt,
	sls_sales,
	sls_quantity,
	sls_price
	)
	SELECT
	sls_ord_num,
	sls_prd_key,
	sls_cust_id,
	CASE WHEN sls_order_dt=0 OR LENGTH(sls_order_dt :: TEXT)!=8 THEN NULL -- hangling invalid date which cannnot be converted
		 ELSE TO_DATE(sls_order_dt::TEXT,'YYYYMMDD') -- casting to date type
	END AS sls_order_dt,
	CASE WHEN sls_ship_dt=0 OR LENGTH(sls_ship_dt :: TEXT)!=8 THEN NULL
		 ELSE TO_DATE(sls_ship_dt::TEXT,'YYYYMMDD')
	END AS sls_ship_dt,
	CASE WHEN sls_due_dt=0 OR LENGTH(sls_due_dt :: TEXT)!=8 THEN NULL
		 ELSE TO_DATE(sls_due_dt::TEXT,'YYYYMMDD')
	END AS sls_due_dt,
	CASE WHEN sls_sales<=0 OR sls_sales IS NULL OR sls_sales != sls_quantity* ABS(sls_price) THEN sls_quantity*ABS(sls_price) 
		 ELSE sls_sales -- recalculate sales if original data is missing or incorrect
	END AS sls_sales,
	sls_quantity,
	CASE WHEN sls_price=0 OR sls_price IS NULL THEN sls_sales/NULLIF(sls_quantity,0)
		 WHEN sls_price<0 THEN sls_price*-1
		 ELSE sls_price
	END AS sls_price -- Derive price if original value is invalid or missing
	FROM bronze.crm_sales_details;
	end_time := NOW();
	RAISE NOTICE '>> Load Duration: % seconds', CAST(EXTRACT(EPOCH FROM (end_time - start_time)) AS VARCHAR(50));
	RAISE NOTICE '---------------';

	RAISE NOTICE '---------------------------------------------';
	RAISE NOTICE 'Loading the ERP Tables ';
	RAISE NOTICE '---------------------------------------------';
	/*
		=> Handled Invalid Values
		=> Handled Missing Values
		=> Data Normalization
	*/
	start_time := NOW();
	RAISE NOTICE '>> Truncating Table: silver.erp_cust_az12';
	-- Truncate the table before loading the data
	TRUNCATE TABLE silver.erp_cust_az12;
	RAISE NOTICE '>> Inserting Data Into: silver.erp_cust_az12';
	INSERT INTO silver.erp_cust_az12(
	cid,
	bdate,
	gen
	)
	SELECT
	CASE WHEN cid LIKE 'NAS%' THEN SUBSTRING(cid FROM 4)
		 ELSE cid
	END AS cid, -- Remove NAS prefix if present
	CASE WHEN bdate>NOW() THEN NULL
		 ELSE bdate
	END AS bdate, -- Set future birthdays to null
	-- bdate,
	CASE UPPER(TRIM(gen))
		 WHEN 'F' THEN 'Female'
		 WHEN 'M' THEN 'Male'
		 WHEN NULL THEN 'n/a'
		 WHEN 'FEMALE' THEN 'Female'
		 WHEN 'MALE' THEN 'Male'
		 ELSE 'n/a'
	END AS gen -- Normalize gender values and handle unknown cases
	FROM bronze.erp_cust_az12;
	end_time := NOW();
	RAISE NOTICE '>> Load Duration: % seconds', CAST(EXTRACT(EPOCH FROM (end_time - start_time)) AS VARCHAR(50));
	RAISE NOTICE '---------------';

	-- Handled Invalid Values
	-- Data Normalization
	start_time := NOW();
	RAISE NOTICE '>> Truncating Table: silver.erp_loc_a101';
	-- Truncate the table before loading the data
	TRUNCATE TABLE silver.erp_loc_a101;
	RAISE NOTICE '>> Inserting Data Into: silver.erp_loc_a101';
	INSERT INTO silver.erp_loc_a101(
	cid,cntry
	)
	SELECT REPLACE(cid,'-','') AS cid,
	CASE WHEN UPPER(TRIM(cntry)) IN ('GERMANY','DE') THEN 'Germany'
		 WHEN UPPER(TRIM(cntry)) IN ('US','USA') THEN 'United States'
		 WHEN UPPER(TRIM(cntry))='' OR UPPER(TRIM(cntry)) IS NULL THEN 'n/a'
		 ELSE cntry
	END AS cntry -- Normalize and handle missing or blank country codes
	FROM bronze.erp_loc_a101;
	end_time := NOW();
	RAISE NOTICE '>> Load Duration: % seconds', CAST(EXTRACT(EPOCH FROM (end_time - start_time)) AS VARCHAR(50));
	RAISE NOTICE '---------------';

	/*
	 Good data quality. Data Inserted As Is
	*/
	start_time := NOW();
	RAISE NOTICE '>> Truncating Table: silver.erp_px_cat_g1v2';
	-- Truncate the table before loading the data
	TRUNCATE TABLE silver.erp_px_cat_g1v2;
	RAISE NOTICE '>> Inserting Data Into: silver.erp_px_cat_g1v2';
	INSERT INTO silver.erp_px_cat_g1v2(
	id,
	cat,
	subcat,
	maintenance
	)
	SELECT
	id,
	cat,
	subcat,
	maintenance
	FROM bronze.erp_px_cat_g1v2;
	end_time := NOW();
	RAISE NOTICE '>> Load Duration: % seconds', CAST(EXTRACT(EPOCH FROM (end_time - start_time)) AS VARCHAR(50));
	RAISE NOTICE '---------------';

	batch_end_time := NOW();
	RAISE NOTICE '==================================================';
	RAISE NOTICE 'Loading Silver Layer is completed';
	RAISE NOTICE 'Total Load Duration: % seconds', CAST(EXTRACT(EPOCH FROM (batch_end_time - batch_start_time)) AS VARCHAR(50));
	RAISE NOTICE '==================================================';

EXCEPTION
	WHEN others
	THEN
		GET STACKED DIAGNOSTICS
			v_sqlstate = RETURNED_SQLSTATE;
			v_message = MESSAGE_TEXT;
		RAISE NOTICE 'Failed to load. SQLSTATE: %, Error Message: %',v_sqlstate, v_message;
END;
$$;
