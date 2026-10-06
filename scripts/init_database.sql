/*
==============================================================
Create database and schemas
==============================================================
Script purpose:
	The script creates a new database named 'Datarehouse'.
	Additionally, the script sets up three schemas within the database:
	'bronze', 'silver', and 'gold'
*/


-- Create the 'datawarehouse' DATABASE
CREATE DATABASE datawarehouse;

-- create Schemas
CREATE SCHEMA bronze;
CREATE SCHEMA silver;
CREATE SCHEMA gold;

