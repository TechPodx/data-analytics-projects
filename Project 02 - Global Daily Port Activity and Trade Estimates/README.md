# Port Activity & Trade Intelligence — **Felixstowe**

*A compact, portfolio-ready BI project built with **SQL Server Express + SSMS** and **Power BI Desktop**. Scope: **Port of Felixstowe (UK)**.*

---

## 🧭 Overview

This project turns the public “Daily Port Activity & Trade Estimates” dataset into an explainable analytics product for **Port of Felixstowe**.  
It demonstrates: a clean **star schema** in SQL Server, **tidy/unpivot** transformation, **data-quality checks**, and clear **Power BI** storytelling.

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
- Schemas: `stg`, `dim`, `fact`

### 2) Import → Staging
- **Raw**: `stg.PortActivity_raw` *(via SSMS → Import Flat File)*
- **Typed & Cleaned**: `stg.PortActivity_clean`  
  - `TRY_CONVERT` for dates/ints/floats  
  - Trimmed text, null handling  
  - Columns include: `ActivityDate, YearNum, MonthNum, DayNum, PortId, PortName, Country, IS03, portcalls_* , import_*, export_* , ObjectId`

### 3) Sanity Checks
- Min/Max date, total rows
- Null checks for critical fields (`ActivityDate`, `PortName`)

### 4) Dimensions
- **Date**: `dim.DimDate` (Year/Month/MonthName/Day/Quarter/ISOWeek/DayOfWeek)
- **Port**: `dim.DimPort` (note: `IS03` is the 3-letter ISO code column in your script)
- **Vessel Type**: `dim.DimVesselType` (fixed list: Container, Dry Bulk, General Cargo, RoRo, Tanker, Cargo Total, All)

### 5) Scope Views (UK & Felixstowe)
- **UK view**: `stg.vw_PortActivity_clean_UK`  
  (filters `IS03='GBR'` or country variants)
- **Felixstowe view**: `stg.vw_PortActivity_clean_Felixstowe`  
  (filters `IS03='GBR'` and `PortName LIKE '%FELIXSTOWE%'` or `PortId='GBFXT'`)

### 6) **Unpivot to Tidy** (long form)
- **Table**: `stg.PortActivity_long_Felixstowe`  
  One row per **Date × Port × VesselType**, built with `CROSS APPLY (VALUES …)` from:
  - `portcalls_*` → `PortCalls`
  - `import_*` → `ImportEst`
  - `export_*` → `ExportEst`

### 7) **Build Fact**
- **Fact**: `fact.FactPortDaily_Felixstowe`  
  Columns: `DateKey`, `PortKey`, `VesselTypeKey`, `PortCalls`, `ImportEst`, `ExportEst`  
  Indexes: `(DateKey)`, `(PortKey)`, `(VesselTypeKey)`

### 8) Data Quality / Governance
- **Validation view**: `stg.vw_Validate_Totals_Felixstowe`  
  Confirms **sum of cargo types ≈ Cargo Total ≈ All** for Calls/Import/Export.
- **Freshness view**: `dbo.vw_Felixstowe_Freshness` (MAX date + row count)

### 9) Reporting View
- **Power BI view**: `dbo.vw_Felixstowe_FactPortDaily`  
  Joins **Fact + DimDate + DimPort + DimVesselType** and exposes the keys for clean relationships.

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



dddd

