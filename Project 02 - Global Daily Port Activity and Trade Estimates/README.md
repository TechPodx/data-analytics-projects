# Port Activity & Trade Intelligence — **Felixstowe**

*A compact, portfolio-ready BI project built with **SQL Server Express + SSMS** and **Power BI Desktop**. Scope: **Port of Felixstowe (UK)**.*

---

## 🧭 Overview

This project turns the public “Daily Port Activity & Trade Estimates” dataset into an explainable analytics product for **Port of Felixstowe**.  
It demonstrates: a clean **star schema** in SQL Server, **tidy/unpivot** transformation, **data-quality checks**, and clear **Power BI** storytelling.

### Page 1 — **Felixstowe Ops Overview**

![Dashboard Demo](https://github.com/TechPodx/Style-Repo/blob/main/Gif/Port_BIPage_1_gif.gif)

### Page 2 — **Vessel Mix & Efficiency (UK)** 

![Dashboard Demo](https://github.com/TechPodx/Style-Repo/blob/main/Gif/Port_BIPage_2-gif.gif)
---

## 🧰 Tools Used

- **SQL Server Express + SSMS**
  - Data import, typing/cleansing
  - Staging → Tidy (unpivot) → Dimensions → Fact → Reporting Views
  - Simple DQ/validation views

- **Power BI Desktop**
  - Import mode from SQL views
  - Relationships on surrogate keys
  - DAX measures for KPIs, time intelligence, and vessel mix
  - Two concise report pages (Overview, Mix & Seasonality)

---

## 🧪 What I Built in SQL (using **your exact script**)

> All object names below match your SQL. The full SQL lives in `sql/00_build_port_bi.sql` in this repo.

### 1) Database & Schemas
- `CREATE DATABASE Port_BI;`
```SQL
CREATE DATABASE Port_BI
```
- Schemas: `stg`, `dim`, `fact`
```SQL
CREATE SCHEMA stg;
CREATE SCHEMA dim;
CREATE SCHEMA fact;
```

### 2) Import → Staging
- **Raw**: `stg.PortActivity_raw` *(via SSMS → Import Flat File)*
        Dataset: [Daily Port Activity Data and Trade Estimates](https://www.kaggle.com/datasets/arunvithyasegar/daily-port-activity-data-and-trade-estimates/data)
- **Typed & Cleaned**: `stg.PortActivity_clean`  
  - `TRY_CONVERT` for dates/ints/floats  
  - Trimmed text, null handling  
  - Columns include: `ActivityDate, YearNum, MonthNum, DayNum, PortId, PortName, Country, IS03, portcalls_* , import_*, export_* , ObjectId`
```SQL
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
```

### 3) Sanity Checks
- Min/Max date, total rows
```SQL
SELECT
	MIN(ActivityDate) AS FirstDate,
	MAX(ActivityDate) AS LastDate,
	COUNT(*) AS RowsALL
FROM stg.PortActivity_clean
```
- Null checks for critical fields (`ActivityDate`, `PortName`)
```SQL
SELECT
	SUM(CASE WHEN ActivityDate IS NULL THEN 1 ELSE 0 END) AS NullDate,
	SUM(CASE WHEN PortName IS NULL THEN 1 ELSE 0 END) AS NullPort
FROM stg.PortActivity_clean;
```

### 4) Dimensions
- **Date**: `dim.DimDate` (Year/Month/MonthName/Day/Quarter/ISOWeek/DayOfWeek)
```SQL
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
```

- **Port**: `dim.DimPort` (note: `IS03` is the 3-letter ISO code column in your script)
```SQL
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
```

- **Vessel Type**: `dim.DimVesselType` (fixed list: Container, Dry Bulk, General Cargo, RoRo, Tanker, Cargo Total, All)
```SQL
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
```

### 5) Scope Views (UK & Felixstowe)
- **UK view**: `stg.vw_PortActivity_clean_UK`  
  (filters `IS03='GBR'` or country variants)
```SQL
DROP TABLE IF EXISTS stg.vw_PortActivity_clean_UK
GO

CREATE VIEW stg.vw_PortActivity_clean_UK AS
SELECT * 
FROM stg.PortActivity_clean
WHERE IS03 = 'GBR'
	OR Country IN ('United Kingdom','UK','Great Britain','Britain');

	GO
```
- **Felixstowe view**: `stg.vw_PortActivity_clean_Felixstowe`  
  (filters `IS03='GBR'` and `PortName LIKE '%FELIXSTOWE%'` or `PortId='GBFXT'`)
```SQL

CREATE VIEW stg.vw_PortActivity_clean_Felixstowe AS
SELECT *
FROM stg.PortActivity_clean
WHERE IS03 = 'GBR'
  AND (
        UPPER(PortName) LIKE '%FELIXSTOWE%'       
        OR UPPER(PortId) IN ('GBFXT')             
      );
GO
```

### 6) **Unpivot to Tidy** (long form)
- **Table**: `stg.PortActivity_long_Felixstowe`  
  One row per **Date × Port × VesselType**, built with `CROSS APPLY (VALUES …)` from:
  - `portcalls_*` → `PortCalls`
  - `import_*` → `ImportEst`
  - `export_*` → `ExportEst`
```SQL
CREATE TABLE stg.PortActivity_long_Felixstowe (
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
```

### 7) **Build Fact**
- **Fact**: `fact.FactPortDaily_Felixstowe`  
  Columns: `DateKey`, `PortKey`, `VesselTypeKey`, `PortCalls`, `ImportEst`, `ExportEst`  
  Indexes: `(DateKey)`, `(PortKey)`, `(VesselTypeKey)`
```SQL
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
```

### 8) Data Quality / Governance
- **Validation view**: `stg.vw_Validate_Totals_Felixstowe`  
  Confirms **sum of cargo types ≈ Cargo Total ≈ All** for Calls/Import/Export.
```SQL
DROP VIEW IF EXISTS stg.vw_Validate_Totals_Felixstowe
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

```

### 9) Reporting View
- **Power BI view**: `dbo.vw_Felixstowe_FactPortDaily`  
  Joins **Fact + DimDate + DimPort + DimVesselType** and exposes the keys for clean relationships.
```SQL

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
```
---

## 📊 Power BI Model

- **Imported tables/views**
  - `dbo.vw_Felixstowe_FactPortDaily`
  - `dim.DimDate` *(mark as **Date table** using `[Date]`)*
  - `dim.DimPort`
  - `dim.DimVesselType`
  - *(Optional)* `dbo.vw_Felixstowe_Freshness` for a “Data through” card

- **Relationships (single direction, Dim → View)**
  - `vw_Felixstowe_FactPortDaily[DateKey]` → `DimDate[DateKey]`
  - `vw_Felixstowe_FactPortDaily[PortKey]` → `DimPort[PortKey]`
  - `vw_Felixstowe_FactPortDaily[VesselTypeKey]` → `DimVesselType[VesselTypeKey]`

---

## 🧮 DAX — Exact Measures (grouped, as used)

> Table names in measures below match your Power BI model:  
> `'vw_Felixstowe_FactPortDaily'`, `'dim DimDate'`, `'dim DimPort'`, `'dim DimVesselType'`.

### **Base Totals**
```DAX
Port Calls :=
SUM ( 'vw_Felixstowe_FactPortDaily'[PortCalls] )

Import Volume :=
SUM ( 'vw_Felixstowe_FactPortDaily'[ImportEst] )

Export Volume :=
SUM ( 'vw_Felixstowe_FactPortDaily'[ExportEst] )

Trade Volume Total :=
[Import Volume] + [Export Volume]

Trade Balance (EX - IM) :=
[Export Volume] - [Import Volume]

Trade Tons per Call :=
DIVIDE ( [Trade Volume Total], [Port Calls] )
```

### **Time Windows**
```DAX

Port Call 7-Days :=
CALCULATE (
    [Port Calls],
    DATESINPERIOD ( 'dim DimDate'[Date], MAX ( 'dim DimDate'[Date] ), -7, DAY )
)

Port Calls MTD :=
CALCULATE ( [Port Calls], DATESMTD ( 'dim DimDate'[Date] ) )

Port Calls YTD :=
CALCULATE ( [Port Calls], DATESYTD ( 'dim DimDate'[Date] ) )

Trade MTD :=
CALCULATE ( [Trade Volume Total], DATESMTD ( 'dim DimDate'[Date] ) )

Trade YTD :=
CALCULATE ( [Trade Volume Total], DATESYTD ( 'dim DimDate'[Date] ) )

```

### **Shares & Growth**
```DAX

Import Share % :=
DIVIDE ( [Import Volume], [Trade Volume Total] )

Export Share % :=
DIVIDE ( [Export Volume], [Trade Volume Total] )

Trade Volume YoY % :=
VAR Curr = [Trade Volume Total]
VAR Prev = CALCULATE ( [Trade Volume Total], SAMEPERIODLASTYEAR ( 'dim DimDate'[Date] ) )
RETURN IF ( NOT ISBLANK ( Prev ), DIVIDE ( Curr - Prev, Prev ) )

Trade YTD YoY % :=
VAR Curr = [Trade YTD]
VAR Prev = CALCULATE ( [Trade YTD], SAMEPERIODLASTYEAR ( 'dim DimDate'[Date] ) )
RETURN IF ( NOT ISBLANK ( Prev ), DIVIDE ( Curr - Prev, Prev ) )

```

### **Vessel Mix (Page 2)**
```DAX

Container Share % :=
VAR CargoCalls =
    CALCULATE ( [Port Calls], NOT 'dim DimVesselType'[VesselType] IN {"All","Cargo Total"} )
RETURN
DIVIDE (
    CALCULATE ( [Port Calls], 'dim DimVesselType'[VesselType] = "Container" ),
    CargoCalls
)
```

### **Titles & Meta**
```DAX

Data Through :=
MAX ( 'vw_Felixstowe_FactPortDaily'[Date] )

Title Felixstowe :=
"Port Activity & Trade Intelligence — Felixstowe  (" &
FORMAT ( MIN ( 'dim DimDate'[Date] ), "dd MMM yyyy" ) & " → " &
FORMAT ( MAX ( 'dim DimDate'[Date] ), "dd MMM yyyy" ) & ")"
```

## 📈 Power BI Pages

### Page 1 — **Overview (Felixstowe)**

![Dashboard Demo](https://github.com/TechPodx/Style-Repo/blob/main/Gif/Port_BIPage_1_gif.gif)

**Slicers**
- `Year`, `Quarter`, `VesselType` (default: **All**)

**KPI Cards**
- **Port Calls**
- **Trade Volume Total**
- **Trade Tons per Call**
- **Trade Balance (EX - IM)**
- **Trade YTD YoY %**
- *(Optional)* **Data Through**

**Trend (Dual-Axis Line)**
- **X:** `DimDate[Date]`
- **Y1:** `Port Calls` *(with `Port Call 7-Days` helper line)*
- **Y2:** `Trade Volume Total`

**Matrix (VesselType Detail)**
- **Rows:** `VesselType`
- **Values:** `Port Calls`, `Export Volume`, `Import Volume`, `Trade Volume Total`, `Trade Tons per Call`
- *Includes “All” and “Cargo Total” rows for reconciliation.*

---

### Page 2 — **Vessel Mix & Efficiency (UK)**

![Dashboard Demo](https://github.com/TechPodx/Style-Repo/blob/main/Gif/Port_BIPage_2-gif.gif)

**Bar: Port Calls by VesselType**
- Exclude **All** and **Cargo Total** for real mix analysis.

**Heatmap (Matrix): Seasonality**
- **Rows:** `MonthName`
- **Columns:** `DayOfWeek`
- **Values:** `Port Calls`
- Apply **conditional formatting (color scale)** to surface busy/quiet periods.

**Waterfall: Monthly Trade Balance**
- **Category:** `YearMonth` *(created from `DimDate[Date]` and sorted by a numeric key)*
- **Y:** `Trade Balance (EX - IM)`
- **Tooltips:** `Import Volume`, `Export Volume`, `Trade Volume Total`

---











































