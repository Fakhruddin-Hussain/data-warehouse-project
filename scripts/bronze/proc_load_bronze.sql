/*
===============================================================================
Stored Procedure: Load Bronze Layer (Source -> Bronze)
===============================================================================
Script Purpose:
    This stored procedure loads data into the 'bronze' schema from external CSV files. 
    It performs the following actions:
    - Truncates the bronze tables before loading data.
    - Uses the `COPY FROM WITH` command to load data from csv Files to bronze tables.

Parameters:
    None. 
	  This stored procedure does not accept any parameters or return any values.

Usage Example:
    CALL bronze.load_bronze();
===============================================================================
*/

CREATE OR REPLACE PROCEDURE bronze.load_bronze()
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
	RAISE NOTICE 'Loading the Bronze Layer';
	RAISE NOTICE '=============================================';

	RAISE NOTICE '---------------------------------------------';
	RAISE NOTICE 'Loading the CRM Tables ';
	RAISE NOTICE '---------------------------------------------';

	start_time := NOW();
	batch_start_time := NOW();
	RAISE NOTICE '>> Truncating Table: bronze.crm_cust_info';
	-- Truncate the table before loading the data
	TRUNCATE TABLE bronze.crm_cust_info;
	
	RAISE NOTICE '>> Inserting Data Into: bronze.crm_cust_info';
	-- Bulk insert CRM Customer Info
	COPY bronze.crm_cust_info 
	FROM '/datasets/source_crm/cust_info.csv' 
	WITH (FORMAT CSV, HEADER, DELIMITER ',');
	-- CAPTURE THE ROW COUNT HERE
    GET DIAGNOSTICS rows_inserted = ROW_COUNT;
    -- PRINT THE ROW COUNT
    RAISE NOTICE '>> (%) rows loaded in table', rows_inserted;
	end_time := NOW();
	RAISE NOTICE '>> Load Duration: % seconds', CAST(EXTRACT(EPOCH FROM (end_time - start_time)) AS VARCHAR(50));
	RAISE NOTICE '---------------';

	start_time := NOW();
	RAISE NOTICE '>> Truncating Table: bronze.crm_prd_info';
	-- Truncate the table before loading the data
	TRUNCATE TABLE bronze.crm_prd_info;

	RAISE NOTICE '>> Inserting Data Into: bronze.crm_prd_info';
	-- Bulk insert CRM Product Info
	COPY bronze.crm_prd_info 
	FROM '/datasets/source_crm/prd_info.csv' 
	WITH (FORMAT CSV, HEADER, DELIMITER ',');
	-- CAPTURE THE ROW COUNT HERE
    GET DIAGNOSTICS rows_inserted = ROW_COUNT;
    -- PRINT THE ROW COUNT
    RAISE NOTICE '>> (%) rows loaded in table', rows_inserted;
	end_time := NOW();
	RAISE NOTICE '>> Load Duration: % seconds', CAST(EXTRACT(EPOCH FROM (end_time - start_time)) AS VARCHAR(50));
	RAISE NOTICE '---------------';

	start_time := NOW();
	RAISE NOTICE '>> Truncating Table: bronze.crm_sales_details';
	-- Truncate the table before loading the data
	TRUNCATE TABLE bronze.crm_sales_details;

	RAISE NOTICE '>> Inserting Data Into: bronze.crm_sales_details';
	-- Bulk insert CRM Sales Details
	COPY bronze.crm_sales_details 
	FROM '/datasets/source_crm/sales_details.csv' 
	WITH (FORMAT CSV, HEADER, DELIMITER ',');
	-- CAPTURE THE ROW COUNT HERE
    GET DIAGNOSTICS rows_inserted = ROW_COUNT;
    -- PRINT THE ROW COUNT
    RAISE NOTICE '>> (%) rows loaded in table', rows_inserted;
	end_time := NOW();
	RAISE NOTICE '>> Load Duration: % seconds', CAST(EXTRACT(EPOCH FROM (end_time - start_time)) AS VARCHAR(50));
	RAISE NOTICE '---------------';

	RAISE NOTICE '---------------------------------------------';
	RAISE NOTICE 'Loading the ERP Tables ';
	RAISE NOTICE '---------------------------------------------';

	start_time := NOW();
	RAISE NOTICE '>> Truncating Table: bronze.erp_cust_az12';
	-- Truncate the table before loading the data
	TRUNCATE TABLE bronze.erp_cust_az12;

	RAISE NOTICE '>> Inserting Data Into: bronze.erp_cust_az12';
	-- Bulk insert ERP Customer Data
	COPY bronze.erp_cust_az12 
	FROM '/datasets/source_erp/CUST_AZ12.csv' 
	WITH (FORMAT CSV, HEADER, DELIMITER ',');
	-- CAPTURE THE ROW COUNT HERE
    GET DIAGNOSTICS rows_inserted = ROW_COUNT;
    -- PRINT THE ROW COUNT
    RAISE NOTICE '>> (%) rows loaded in table', rows_inserted;
	end_time := NOW();
	RAISE NOTICE '>> Load Duration: % seconds', CAST(EXTRACT(EPOCH FROM (end_time - start_time)) AS VARCHAR(50));
	RAISE NOTICE '---------------';

	start_time := NOW();
	RAISE NOTICE '>> Truncating Table: bronze.erp_loc_a101';
	-- Truncate the table before loading the data
	TRUNCATE TABLE bronze.erp_loc_a101;

	RAISE NOTICE '>> Inserting Data Into: bronze.erp_loc_a101';
	-- Bulk insert ERP Location Data
	COPY bronze.erp_loc_a101 
	FROM '/datasets/source_erp/LOC_A101.csv' 
	WITH (FORMAT CSV, HEADER, DELIMITER ',');
	-- CAPTURE THE ROW COUNT HERE
    GET DIAGNOSTICS rows_inserted = ROW_COUNT;
    -- PRINT THE ROW COUNT
    RAISE NOTICE '>> (%) rows loaded in table', rows_inserted;
	end_time := NOW();
	RAISE NOTICE '>> Load Duration: % seconds', CAST(EXTRACT(EPOCH FROM (end_time - start_time)) AS VARCHAR(50));
	RAISE NOTICE '---------------';

	start_time := NOW();
	RAISE NOTICE '>> Truncating Table: bronze.erp_px_cat_g1v2';
	-- Truncate the table before loading the data
	TRUNCATE TABLE bronze.erp_px_cat_g1v2;

	RAISE NOTICE '>> Inserting Data Into: bronze.erp_px_cat_g1v2';
	-- Bulk insert ERP Category Data
	COPY bronze.erp_px_cat_g1v2
	FROM '/datasets/source_erp/PX_CAT_G1V2.csv' 
	WITH (FORMAT CSV, HEADER, DELIMITER ',');
	-- CAPTURE THE ROW COUNT HERE
    GET DIAGNOSTICS rows_inserted = ROW_COUNT;
    -- PRINT THE ROW COUNT
    RAISE NOTICE '>> (%) rows loaded in table', rows_inserted;
	end_time := NOW();
	RAISE NOTICE '>> Load Duration: % seconds', CAST(EXTRACT(EPOCH FROM (end_time - start_time)) AS VARCHAR(50));
	RAISE NOTICE '---------------';

	batch_end_time := NOW();
	RAISE NOTICE '==================================================';
	RAISE NOTICE 'Loading Bronze Layer is completed';
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
