# 💧PureVale Water B2B Efficiency & Leak Detection Hub
**Mock Company:** PureVale Water (Simulating B2B Water Retailer Operations)

## 📄 Phase 1: Business Requirements & Governance Document

### 1. Project Objective

To provide Account Managers at PureVale Water with an automated, self-service Power BI dashboard. This tool will allow them to monitor corporate client water consumption, calculate financial costs using regional tariffs, benchmark operational efficiency, and automatically flag anomalous usage patterns that may indicate costly network leaks.

### 2. Key Stakeholders

* **Data Analytics Manager:** Requires an optimized relational data model, clear documentation, and accurate DAX calculations.
* **B2B Account Managers:** Require an intuitive, interactive dashboard to conduct quarterly reviews with their corporate clients and proactively alert them to potential leaks.

### 3. Core Business Questions to Answer

The final BI solution must enable stakeholders to instantly answer the following:

* What is the total water volume (m³) supplied across the network, and what is the total generated revenue?
* How does consumption vary across different UK regions and industry sectors (e.g., Manufacturing vs. Retail)?
* Which customers are the most and least efficient, normalized by company size (Water Intensity = m³ per Employee)?
* Are there any sudden, unexplained spikes in daily consumption that warrant a physical leak investigation?

### 4. Key Performance Indicators (KPIs) & Metrics

* **Total Volume (m³):** Sum of daily consumption.
* **Total Cost (£):** Dynamically calculated based on regional volumetric rates and daily fixed charges, plus Return to Sewer (RTS) allowances.
* **Water Intensity:** Total Volume (m³) / Employee Count (FTE).
* **Year-over-Year (YoY) Variance:** Percentage change in consumption compared to the same period last year.
* **Anomaly Flag:** Boolean indicator (True/False) triggered when daily usage exceeds 20% of the customer's 14-day rolling average.

### 5. Data Sources & Target Architecture

The raw data consists of internally generated using **mockaroo** free version and extracts simulating PureVale Water's CRM and meter reading systems. 

* **Source Files:**
  
  * `PureVale_Water_Customers.csv` (1000 records: Demographics, Meter Types, FTE, RTS%)
  * `Fact_WaterUsage.csv` (1000 records: Daily volumes, Reading dates, Quality flags)
   
* **Target Data Model:** The raw flat files will be processed via SQL (ETL) into a Star Schema consisting of:
  
  * `Dim_Customer`
  * `Dim_Tariff` (Created in SQL to handle regional pricing)
  * `Fact_WaterUsage`
  * `Dim_Date` (Generated in Power BI)

### 6. Data Governance & Quality Assurance

To ensure high data integrity and stakeholder trust, the following governance steps will be implemented:

* **Read Quality Tracking:** The dashboard will monitor the ratio of 'Actual' vs. 'Estimated' meter reads. High volumes of estimated reads will be flagged as a data quality risk.
* **Reconciliation Testing:** Raw CSV data totals will be aggregated using Advanced Excel (Power Query, Pivot Tables) and cross-referenced against the final SQL database outputs to ensure zero data loss during the ETL process.

### 7. Deliverables

1. **SQL Scripts:** Code used to normalize raw data into a Star Schema and generate the regional pricing table.
2. **Excel QA Tracker:** A supplementary file demonstrating raw-to-SQL data reconciliation.
3. **Power BI Dashboard:** A two-page interactive report (.pbix) featuring an Executive Summary and an Account Manager deep-dive with DAX-driven anomaly detection.


## 🔢 Phase 2: Data Engineering & Relational Modeling (SQL)

Raw data is rarely ready for reporting straight out of the box. To prepare the PureVale Water datasets for Power BI, I used **SQL Server 2022** to build a structured, optimized Data Warehouse. 

Instead of relying on one massive, slow flat file, I modeled the database using a **Star Schema**. This approach separates the descriptive business data (Dimensions) from the measurable, daily events (Facts), ensuring the database is fast, clean, and scalable.

### 1. The ETL Process (Extract, Transform, Load)

I handled the data ingestion using SQL Server Management Studio (SSMS). 

* **Extract:** I brought the raw `PureVale_Water_Customers.csv` and `Fact_WaterUsage.csv` files into SSMS using the Import Flat File wizard, placing them into temporary staging tables. I utilized schema separation. Raw CSV extracts were loaded into a dedicated stg (staging) schema, isolating raw data from the final dbo production schema used by Power BI.

* **Transform & Load:** I then wrote SQL scripts to move this data into permanent tables (`Dim_Customer` and `Fact_WaterUsage`), applying strict data types (like `DECIMAL` for percentages and `DATE` for calendar dates) to prevent formatting errors downstream. I also established a Primary/Foreign Key relationship linking the `CompanyId` in the Fact table to the `CustomerId` in the Dimension table.

## 2. Dynamic Tariff Modeling (Commercial Logic)

One of the main goals of this project was to simulate real-world B2B utility billing. Real water companies don't charge a single flat rate for every customer across the country (as I found out). 

To handle this, I manually created a `Dim_Tariff` table directly in SQL. This table stores specific volumetric rates and daily fixed charges based on different UK regions (Anglian, Northumbrian, Thames). By mapping our customer cities to these regions, I built a foundation that allows Power BI to calculate highly accurate, localized financial costs.

## 3. SQL Scripts Used

Below is the SQL architecture used to build the tables, load the pricing data, and create the final Master View that connects to Power BI.

```SQL
-- *************************************************************************
-- PureVale Water - Database Setup & Architecture
-- *************************************************************************

-- 1. Customer Dimension Table
CREATE TABLE Dim_Customer (
   	CustomerId INT PRIMARY KEY,
   	CustomerName VARCHAR(100),
   	Industry VARCHAR(50),
   	City VARCHAR(50),
   	MeterType VARCHAR(50),
   	EmployeeCount INT,
   	ReturnToSewer_Pct DECIMAL(3,2)
);

-- 2. Water Usage Fact Table
CREATE TABLE Fact_WaterUsage (
    UsageId INT IDENTITY(1,1) PRIMARY KEY, 
    CompanyId INT,
    ReadingDate DATE,                      
    DailyVolume_m3 INT,
    ReadingType VARCHAR(20),
);

-- Create new schema call "staging"
CREATE SCHEMA stg;
GO

-- Note: CSV data was loaded into the above tables via SSMS Import Wizard.

-- 3. Create the Regional Tariff Dimension
CREATE TABLE Dim_Tariff (
    Region VARCHAR(50) PRIMARY KEY,
    VolumetricRate_GBP DECIMAL(4,2),
    DailyFixedCharge_GBP DECIMAL(4,2)
);






# 👉 Still progressing — will be released by 5 PM on 23rd.


























