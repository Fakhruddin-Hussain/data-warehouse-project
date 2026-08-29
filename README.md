# Modern Data Warehouse with PostgreSQL (Medallion Architecture)

## Overview
An end-to-end SQL data warehouse project implementing Bronze, Silver, and Gold layers with PostgreSQL, managed via Docker and pgAdmin.

## Architecture
- **Bronze Layer:** Raw data ingestion from source CSV files.
- **Silver Layer:** Data cleaning, standardization, and quality checks.
- **Gold Layer:** Star schema dimensional modeling (Fact and Dimension tables) optimized for analytics.

## Getting Started

### Prerequisites
- Docker Desktop with WSL 2 backend enabled

### Setup & Run
1. Clone the repository:
bash
git clone 
cd data-warehouse-project
2. Copy the environment variables:
cp .env.example .env
3. Start the services:
docker compose up -d
4. Access **pgAdmin** at `http://localhost:8080`.
