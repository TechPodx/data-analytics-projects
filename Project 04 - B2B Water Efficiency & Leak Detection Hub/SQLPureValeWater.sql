-- Drop the database if exists (DO NOT RUN UNLESS NECESSARY)
IF EXISTS (SELECT 1 FROM sys.databases WHERE name = 'PureValeWater')
BEGIN
	ALTER DATABASE PureValeWater SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
	DROP DATABASE PureValeWater;
END;
GO

-- Create a database
CREATE DATABASE "PureValeWater";
GO

-- Change the database to the one just created
USE "PureValeWater";
GO

-- Create empty table to hold the data later

-- Customer table
DROP TABLE IF EXISTS Dim_Customer; -- (DO NOT RUN UNLESS NECESSARY)
CREATE TABLE Dim_Customer (
	CustomerId INT PRIMARY KEY,
	CustomerName VARCHAR(100),
	Industry VARCHAR(50),
	City VARCHAR(50),
	MeterType VARCHAR(50),
	EmployeeCount INT,
	ReturnToSewer_Pct DECIMAL(3,2)
);
GO

-- Water usage table
DROP TABLE IF EXISTS Fact_waterUsag; -- (DO NOT RUN UNLESS NECESSARY)
CREATE TABLE Fact_waterUsage (
	UsageId INT IDENTITY(1,1) PRIMARY KEY,
	CompanyId INT,
	ReadingDate DATE,
	DailyVolume_m3 DECIMAL(8,2),
	ReadingType VARCHAR(20)
);
GO

-- Price Table
DROP TABLE IF EXISTS Dim_tariff; -- (DO NOT RUN UNLESS NECESSARY)
CREATE TABLE Dim_tariff(
	Region VARCHAR(50) PRIMARY KEY,
	VolumetricRate_GBP DECIMAL(4,2),
	DailyFixedCharge_GBP DECIMAL(4,2)
);
GO

-- Create new schema call "staging"
DROP SCHEMA IF EXISTS stg; -- (DO NOT RUN UNLESS NECESSARY)
GO
CREATE SCHEMA stg;
GO

-- Transfer data to the tables

-- Customer Data

INSERT INTO dbo.Dim_Customer (CustomerId, CustomerName, Industry, City, MeterType, EmployeeCount, ReturnToSewer_Pct)
SELECT CustomerId, CustomerName, Industry, City, MeterType, EmployeeCount, ReturnToSewer_Pct
FROM stg.PureVale_Water_Customers_Temp;
GO

-- Usage data

INSERT INTO dbo.Fact_waterUsage (CompanyId, ReadingDate, DailyVolume_m3, ReadingType)
SELECT CompanyId, CAST (ReadingDate AS DATE), DailyVolume_m3, ReadingType
FROM stg.Fact_WaterUsage_Temp;
GO

/*
We can drop Temporaty Tables if needed 

DROP TABLE stg.PureVale_Water_Customers_Temp;
DROP TABLE stg.Fact_WaterUsage_Temp;
GO
*/


-- Insert our mock UK pricing directly into the Tariff table
INSERT INTO Dim_Tariff (Region, VolumetricRate_GBP, DailyFixedCharge_GBP)
VALUES 
    ('Anglian', 1.75, 0.50),       
    ('Northumbrian', 1.45, 0.40),  
    ('Thames', 1.60, 0.65);
GO

-- Create the Master Reporting View

CREATE VIEW vw_Reporting_Master AS
SELECT 
	f.ReadingDate,
    c.CustomerName,
    c.Industry,
    c.City,
    c.MeterType,
    c.EmployeeCount,
    c.ReturnToSewer_Pct,
    f.DailyVolume_m3,
    f.ReadingType,
	CASE -- Construct region name column
		WHEN c.City IN ('Ipswich', 'Peterborough', 'Norwich', 'Colchester') THEN 'Anglian'
		WHEN c.City IN ('Sunderland', 'Darlington') THEN 'Northumbrian'
        WHEN c.City = 'Windsor' THEN 'Thames'
		ELSE 'Other'
	END AS RegionName
FROM Fact_waterUsage f
JOIN Dim_Customer c ON f.CompanyId = c.CustomerId;
GO



-- Checks

SELECT *
FROM vw_Reporting_Master

SELECT *
FROM dbo.Fact_waterUsage

SELECT *
FROM dbo.Dim_Customer

SELECT *
FROM dbo.Dim_tariff

SELECT *
FROM stg.Fact_WaterUsage_Temp

SELECT *
FROM stg.Fact_WaterUsage_Temp