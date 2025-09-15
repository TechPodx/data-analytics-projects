-- Create a database

CREATE DATABASE Port_BI
GO

--*****************************************************************************************************

-- Chnage the Database

USE Port_BI;
GO

--*****************************************************************************************************

-- Create Schemas

CREATE SCHEMA stg;
GO
CREATE SCHEMA dim;
GO
CREATE SCHEMA fact;
GO

--*****************************************************************************************************

-- Imported Flat File

--*****************************************************************************************************

-- View the dataset

SELECT TOP 10 *
FROM stg.PortActivity_raw
WHERE country = 'United Kingdom'

--*****************************************************************************************************

-- Create a data type tabel 

CREATE TABLE stg.PortActivity_clean (

	-- Basic Details
	ActivityDate Date NOT NULL,
	YearNum int NULL,
	MonthNum int NULL,
	DayNum int NULL,
	PortId nvarchar(50) NULL,
	PortName nvarchar(50) NOT NULL,
	Country nvarchar(100) NULL,
	IS03 char(3) NULL,

	-- Port Calls
	portcalls_container     int NULL,
	portcalls_dry_bulk      int NULL,
	portcalls_general_cargo int NULL,
	portcalls_roro          int NULL,
	portcalls_tanker        int NULL,
	portcalls_cargo         int NULL,
	portcalls               int NULL,

	-- Import
	import_container        float NULL,
	import_dry_bulk         float NULL,
	import_general_cargo    float NULL,
	import_roro             float NULL,
	import_tanker           float NULL,
	import_cargo            float NULL,
	[import]                float NULL,

	-- Export
	export_container        float NULL,
	export_dry_bulk         float NULL,
	export_general_cargo    float NULL,
	export_roro             float NULL,
	export_tanker           float NULL,
	export_cargo            float NULL,
	[export]                float NULL,

	ObjectId                nvarchar(100) NULL,
	LoadDttm                datetime2      NOT NULL DEFAULT SYSUTCDATETIME()

);
INSERT INTO stg.PortActivity_clean (
	ActivityDate, YearNum, MonthNum, DayNum, PortId, PortName, Country, IS03, 
	portcalls_container, portcalls_dry_bulk, portcalls_general_cargo, portcalls_roro, portcalls_tanker, portcalls_cargo, portcalls, 
	import_container, import_dry_bulk, import_general_cargo, import_roro, import_tanker, import_cargo, [import], 
	export_container, export_dry_bulk, export_general_cargo, export_roro, export_tanker, export_cargo, [export], ObjectId
)
SELECT 
	TRY_CONVERT(date, [date]),	
	TRY_CONVERT(int, [year]),
	TRY_CONVERT(int, [month]),
	TRY_CONVERT(int, [day]),	
	NULLIF(LTRIM(RTRIM([portid])), ''),
	NULLIF(LTRIM(RTRIM([portname])), ''),
	NULLIF(LTRIM(RTRIM([country])), ''),
	TRY_CONVERT(char(3), [ISO3]),

	TRY_CONVERT(int, [portcalls_container]),
	TRY_CONVERT(int, [portcalls_dry_bulk]),
	TRY_CONVERT(int, [portcalls_general_cargo]),
	TRY_CONVERT(int, [portcalls_roro]),
	TRY_CONVERT(int, [portcalls_tanker]),
	TRY_CONVERT(int, [portcalls_cargo]),
	TRY_CONVERT(int, [portcalls]),

	TRY_CONVERT(float, [import_container]),
	TRY_CONVERT(float, [import_dry_bulk]),
	TRY_CONVERT(float, [import_general_cargo]),
	TRY_CONVERT(float, [import_roro]),
	TRY_CONVERT(float, [import_tanker]),
	TRY_CONVERT(float, [import_cargo]),
	TRY_CONVERT(float, [import]),

	TRY_CONVERT(float, [export_container]),
	TRY_CONVERT(float, [export_dry_bulk]),
	TRY_CONVERT(float, [export_general_cargo]),
	TRY_CONVERT(float, [export_roro]),
	TRY_CONVERT(float, [export_tanker]),
	TRY_CONVERT(float, [export_cargo]),
	TRY_CONVERT(float, [export]),
	[ObjectId]
FROM stg.PortActivity_raw;

-- Sanity Check 

SELECT
	MIN(ActivityDate) AS FirstDate,
	MAX(ActivityDate) AS LastDate,
	COUNT(*) AS RowsALL
FROM stg.PortActivity_clean
	
-- -- Sanity Check : NULL value check in critical columns

SELECT
	SUM(CASE WHEN ActivityDate IS NULL THEN 1 ELSE 0 END) AS NullDate,
	SUM(CASE WHEN PortName IS NULL THEN 1 ELSE 0 END) AS NullPort
FROM stg.PortActivity_clean;

-- *********************************************************************************************************

/*Creating a Star Schema*/

-- Date dimentsion

IF OBJECT_ID('dim.DimDate') IS NOT NULL
	DROP TABLE dim.DimDate

GO

ALTER TABLE dim.DimDate 
ADD DayOfWeek NVARCHAR(10) NULL;

CREATE TABLE dim.DimDate (
	DateKey int NOT NULL PRIMARY KEY, 
	[Date] date NOT NULL,
	[Year] int NOT NULL,
	[Month] int NOT NULL,
	[MonthName] nvarchar(20) NOT NULL,
	[Day] int NOT NULL,
	[Quater] int NOT NULL,
	ISOWeek int NOT NULL
);

GO

WITH d AS (
	SELECT MIN(ActivityDate) StartDate, MAX(ActivityDate) EndDate
	FROM stg.PortActivity_clean
), 
cal AS (
	SELECT StartDate
	FROM d
	UNION ALL

	SELECT DATEADD(day, 1, cal.StartDate) 
	FROM cal, d 
	WHERE cal.StartDate < d.EndDate
)
INSERT INTO dim.DimDate
SELECT 
	CONVERT (int, FORMAT(StartDate, 'yyyyMMdd')) AS DateKey,
	StartDate AS [Date],
	YEAR(StartDate) AS [Year] ,
	MONTH(StartDate) AS [Month],
	DATENAME(month, StartDate) AS [MonthName],
	DAY(StartDate) AS [Day],
	DATEPART(Quarter, StartDate) AS [Quarter],
	DATEPART(ISO_WEEK, StartDate) AS ISOWeek
FROM cal 
OPTION (MAXRECURSION 32767);

UPDATE dim.DimDate
SET DayOfWeek = DATENAME(WEEKDAY, [Date]);

SELECT * FROM dim.DimDate 

----------------------------------------------------------------------------

-- Port Dimention

DROP TABLE IF EXISTS dim.DimPort ;
GO

TRUNCATE TABLE dim.DimPort
GO

CREATE TABLE dim.DimPort (
	PortKey int IDENTITY(1, 1) PRIMARY KEY, 
	PortId nvarchar(50) NULL,
	PortName nvarchar(200) NOT NULL,
	Country nvarchar(50) NULL,
	IS03 char(3) NULL
);
GO
INSERT INTO dim.DimPort (PortId, PortName, Country, IS03)
SELECT c.PortId, c.PortName, c.Country, c.IS03
FROM (
  SELECT DISTINCT
    NULLIF(LTRIM(RTRIM(PortId)),'') AS PortId,
    NULLIF(LTRIM(RTRIM(PortName)),'') AS PortName,
    NULLIF(LTRIM(RTRIM(Country)),'') AS Country,
    IS03
  FROM stg.vw_PortActivity_clean_Felixstowe
) c
LEFT JOIN dim.DimPort p
  ON ISNULL(p.PortId,'') = ISNULL(c.PortId,'')
 AND p.PortName = c.PortName
WHERE p.PortKey IS NULL;
GO

-- Check the data

SELECT * 
FROM dim.DimPort

------------------------------------------------------------------------------

-- Create VesselType dimension Table

CREATE TABLE dim.DimVesselType (
	VesselTypeKey int IDENTITY(1, 1) PRIMARY KEY,
	VesselType nvarchar(50) NOT NULL
);

GO
INSERT INTO dim.DimVesselType(
	VesselType
)

VALUES ('Container'), ('Dry Bulk'), ('General Cargo'), ('RoRo'), ('Tanker'), ('Cargo Total'), ('All');
GO

-- Check the data

SELECT * 
FROM dim.DimVesselType

-- ***************************************************************************************************

-- Focus on only UK port activities

DROP TABLE IF EXISTS stg.vw_PortActivity_clean_UK
GO

CREATE VIEW stg.vw_PortActivity_clean_UK AS
SELECT * 
FROM stg.PortActivity_clean
WHERE IS03 = 'GBR'
	OR Country IN ('United Kingdom','UK','Great Britain','Britain');

	GO

-- View the data

SELECT TOP 10 * 
FROM stg.vw_PortActivity_clean_UK
GO
-- ***************************************************************************************************

CREATE VIEW stg.vw_PortActivity_clean_Felixstowe AS
SELECT *
FROM stg.PortActivity_clean
WHERE IS03 = 'GBR'
  AND (
        UPPER(PortName) LIKE '%FELIXSTOWE%'       
        OR UPPER(PortId) IN ('GBFXT')             
      );
GO

--****************************************************************************************************

-- Unpivot to tidy: Turn the wide row into one row per vesselType per date/port

DROP TABLE IF EXISTS  stg.PortActivity_long
GO

CREATE TABLE stg.vw_Validate_Totals_Felixstowe (
	ActivityDate date NOT NULL,
	PortName nvarchar(200) NOT NULL,
	Country nvarchar(50) NULL,
	IS03 Char(3) NULL,
	VesselType nvarchar(50) NOT NULL,
	PortCalls int NULL,
	ImportEst float NULL,
	ExportEst float NULL
);
GO

INSERT INTO stg.PortActivity_long_Felixstowe (
	ActivityDate, PortName, Country, IS03, VesselType, PortCalls, ImportEst, ExportEst
)
SELECT 
	c.ActivityDate, c.PortName, c.Country, c.IS03, v.VesselType, v.PortCalls, v.ImportEst, v.ExportEst
FROM stg.vw_PortActivity_clean_Felixstowe c
CROSS APPLY (VALUES
	('Container',      c.portcalls_container,     c.import_container,        c.export_container),
	('Dry Bulk',       c.portcalls_dry_bulk,      c.import_dry_bulk,         c.export_dry_bulk),
	('General Cargo',  c.portcalls_general_cargo, c.import_general_cargo,    c.export_general_cargo),
	('RoRo',           c.portcalls_roro,          c.import_roro,             c.export_roro),
	('Tanker',         c.portcalls_tanker,        c.import_tanker,           c.export_tanker),
	('Cargo Total',    c.portcalls_cargo,         c.import_cargo,            c.export_cargo),
	('All',            c.portcalls,               c.[import],                c.[export])
) v (VesselType, PortCalls, ImportEst, ExportEst);
GO

-- Check data

SELECT TOP 10 * FROM stg.vw_Validate_Totals_Felixstowe
GO

-- Validation view: Do your totals match the sum of types?

DROP VIEW IF EXISTS stg.vw_Validate_Totals
GO

CREATE VIEW stg.vw_Validate_Totals_Felixstowe AS
SELECT ActivityDate, PortName,
       SUM(CASE WHEN VesselType IN ('Container','Dry Bulk','General Cargo','RoRo','Tanker') THEN PortCalls END) AS SumType_PortCalls,
       MAX(CASE WHEN VesselType='Cargo Total' THEN PortCalls END) AS CargoTotal_PortCalls,
       MAX(CASE WHEN VesselType='All' THEN PortCalls END) AS All_PortCalls,

       SUM(CASE WHEN VesselType IN ('Container','Dry Bulk','General Cargo','RoRo','Tanker') THEN ImportEst END) AS SumType_Import,
       MAX(CASE WHEN VesselType='Cargo Total' THEN ImportEst END) AS CargoTotal_Import,
       MAX(CASE WHEN VesselType='All' THEN ImportEst END) AS All_Import,

       SUM(CASE WHEN VesselType IN ('Container','Dry Bulk','General Cargo','RoRo','Tanker') THEN ExportEst END) AS SumType_Export,
       MAX(CASE WHEN VesselType='Cargo Total' THEN ExportEst END) AS CargoTotal_Export,
       MAX(CASE WHEN VesselType='All' THEN ExportEst END) AS All_Export
FROM stg.PortActivity_long_Felixstowe
GROUP BY ActivityDate, PortName;

GO

-- Check the view

SELECT * 
FROM stg.vw_Validate_Totals_Felixstowe

-- Build facts

DROP TABLE IF EXISTS fact.FactPortDaily

GO

CREATE TABLE fact.FactPortDaily_Felixstowe (
  DateKey       int NOT NULL FOREIGN KEY REFERENCES dim.DimDate(DateKey),
  PortKey       int NOT NULL FOREIGN KEY REFERENCES dim.DimPort(PortKey),
  VesselTypeKey int NOT NULL FOREIGN KEY REFERENCES dim.DimVesselType(VesselTypeKey),
  PortCalls     int   NULL,
  ImportEst     float NULL,
  ExportEst     float NULL
);
GO
CREATE INDEX IX_FXF_Date   ON fact.FactPortDaily_Felixstowe(DateKey);
CREATE INDEX IX_FXF_Port   ON fact.FactPortDaily_Felixstowe(PortKey);
CREATE INDEX IX_FXF_VType  ON fact.FactPortDaily_Felixstowe(VesselTypeKey);
GO
INSERT INTO fact.FactPortDaily_Felixstowe (DateKey, PortKey, VesselTypeKey, PortCalls, ImportEst, ExportEst)
SELECT
  CONVERT(int,FORMAT(l.ActivityDate,'yyyyMMdd')) AS DateKey,
  p.PortKey,
  vt.VesselTypeKey,
  l.PortCalls, 
  l.ImportEst, 
  l.ExportEst
FROM stg.PortActivity_long_Felixstowe l
JOIN dim.DimPort p        ON p.PortName = l.PortName AND ISNULL(p.IS03,'') = ISNULL(l.IS03,'')
JOIN dim.DimVesselType vt ON vt.VesselType = l.VesselType;

GO

-- View the table

SELECT TOP 10 * 
FROM fact.FactPortDaily_Felixstowe

GO

-- Create a friendly reporting view 

DROP VIEW IF EXISTS dbo.vw_UK_FactPortDaily
GO

CREATE VIEW dbo.vw_Felixstowe_FactPortDaily AS
SELECT
  d.DateKey,
  d.[Date],
  dp.PortKey,
  dp.PortName,
  dp.Country,
  dp.IS03,
  vt.VesselTypeKey,
  vt.VesselType,
  f.PortCalls,
  f.ImportEst,
  f.ExportEst
FROM fact.FactPortDaily_Felixstowe f
JOIN dim.DimDate d        ON d.DateKey = f.DateKey
JOIN dim.DimPort dp       ON dp.PortKey = f.PortKey
JOIN dim.DimVesselType vt ON vt.VesselTypeKey = f.VesselTypeKey;
GO

-- View data

SELECT TOP 10 * FROM dbo.vw_Felixstowe_FactPortDaily
GO
-- ***************************************************************************************

CREATE VIEW dbo.vw_Felixstowe_Freshness AS
SELECT 
  MAX(d.[Date]) AS LastDate,
  COUNT(*)      AS RowsCount
FROM fact.FactPortDaily_Felixstowe f
JOIN dim.DimDate d ON d.DateKey = f.DateKey;
GO

SELECT * 
FROM dbo.vw_Felixstowe_Freshness
GO