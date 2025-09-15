# Renewable Traceability & Carbon Performance (GB, Half-Hourly)

![Executive Overview](https://github.com/TechPodx/Style-Repo/blob/main/Images/energy_gif.gif)

## 📽️Link to the demonstration: https://youtu.be/tO1_Sv4kwm4


Power BI portfolio project demonstrating **24/7 renewable matching**, **generation mix analysis**, and **market-based emissions** reporting using half-hourly GB data.

> **Report pages implemented**
> 1) **Executive Overview (KPIs + trends)**  
> 2) **Generation Mix & Carbon**  
> 3) **24/7 Traceability (Heatmap)**  
> *(Roadmap at the end shows planned pages: Scenario Studio & Energy Label.)*

---

## 📸 Screenshots (add your images)

**Executive Overview (KPIs + trends)**  
![Executive Overview](https://github.com/TechPodx/Style-Repo/blob/8efb3f7306c66188057385e2b22c869fca93ef73/Images/Executive%20Overview.png)

**Generation Mix & Carbon**  
![Generation Mix & Carbon](https://github.com/TechPodx/Style-Repo/blob/main/Images/Generation%20Mix%20%26%20Carbon.png)

**24/7 Traceability (Heatmap)**  
![24/7 Traceability](https://github.com/TechPodx/Style-Repo/blob/main/Images/24.7%20Traceability.png)

---

## 1) About the Project

### 👉 Why This project

- Showcases **BI Analyst** skills in **Power BI, Power Query, and DAX**, focused on renewable energy traceability.
- Translates half-hourly grid data into **business-ready KPIs**: CFE% (24/7), residual load, and emissions (location vs market).
- Presents a **client-style dashboard** suitable for corporate energy and sustainability reporting.

### 👉 Business Problem

Large corporate energy buyers are under pressure to:

- Prove that their electricity consumption is genuinely matched by renewables, 24/7, not just on a yearly average.
- Report carbon emissions under Scope 2 (location-based vs market-based) with confidence for regulators, investors, and sustainability ratings.
- Understand when and why shortfalls occur (residual demand not covered by renewables) so they can plan PPAs, storage, or demand shifting.

Traditional reporting only shows an annual renewable %, which hides the real hourly gaps and prevents businesses from making operational or procurement decisions.

### 👉 What This Project Solves

This BI dashboard demonstrates how SmartestEnergy (or a similar supplier) could provide business clients with:

- 24/7 Traceability: interval-level matching between customer demand and renewable generation.
- Clear KPIs (CFE%, Residual MWh, Avoided Emissions): making carbon reporting more transparent and audit-ready.
- Fuel Mix Transparency: showing how different sources (wind, solar, gas, imports, etc.) drive performance and emissions.
- Emissions Accounting: direct comparison of location-based vs market-based emissions, aligned with Scope 2 guidance.

### 👉 Business Impact

- Trust & Differentiation: Builds confidence with corporate clients that SmartestEnergy is delivering true 24/7 renewable coverage, not just averages.
- Decision Support: Helps sustainability and procurement teams target the worst hours/days with new contracts (PPAs), storage, or load-shifting strategies.
- Regulatory Compliance: Simplifies Scope 2 carbon reporting by providing both location-based and market-based emissions transparently.
- Competitive Edge: Positions the company as a partner for net-zero journeys, offering data-driven insights that most suppliers cannot.
- Financial Impact: Better renewable matching reduces exposure to carbon costs, enhances reputation, and helps retain/attract clients seeking renewable guarantees.

---

## 2) Dataset

- **File from Kaggle:** [Data File](https://www.kaggle.com/datasets/danielparke/uk-energy-data-2020-23?resource=download&select=UK_Fuel_Mix.csv)
- **Granularity:** 30-minute intervals (48 per day)  
- **Key columns used:**  
  `DATETIME`, `NET_DEMAND`, `GENERATION`, `RENEWABLE`, `FOSSIL`,  
  `GAS`, `COAL`, `NUCLEAR`, `UK_WIND`, `HYDRO`, `SOLAR`, `BIOMASS`, `IMPORTS`, `OTHER`, `STORAGE`,  
  `CARBON_INTENSITY` (gCO₂/kWh)

> **Unit convention:** Each row is MW for a 30-minute period → **MWh = MW × 0.5**.

---

## 3) Tools & Skills

- **Power BI Desktop** (Modeling & Visuals)
- **Power Query (M)** for import, type assignment, and feature engineering
- **DAX** measures for energy math, 24/7 matching, and emissions
- **Design**: Consistent theme, accessible color choices, exportable layout

---

## 4) Data Model

**Facts**
- `Fact_Interval` (wide): one row per half-hour with load/generation totals, renewable/fossil, carbon intensity, and helper columns `Date`, `Time`, `HalfHourSlot`.
- `Fact_GenLong` (long): unpivoted generation by `FuelType` with `MW`, plus `Date`, `HalfHourSlot`.

**Dimensions**
- `Dim_Date` (marked as Date table): `Date`, `Year`, `MonthNo`, `Month`, `YearMonth`, `Quarter`, `Week`, `Day`, `DayOfWeekNo`, `DayName`, `IsWeekend`, `Season`.
- `Dim_Time`: `SettlementPeriod` (1–48), `TimeText` (00:00…23:30).
- `Dim_Source`: `FuelType` → `IsRenewable` (TRUE/FALSE), `CarbonGroup` (ZeroCarbon/LowCarbon/Fossil/Other).

**Relationships**
- `Dim_Date[Date]` → `Fact_Interval[Date]` (1:*)
- `Dim_Date[Date]` → `Fact_GenLong[Date]` (1:*)
- `Dim_Time[SettlementPeriod]` → `Fact_Interval[HalfHourSlot]` (1:*)
- `Dim_Time[SettlementPeriod]` → `Fact_GenLong[HalfHourSlot]` (1:*)
- `Dim_Source[FuelType]` → `Fact_GenLong[FuelType]` (1:*)

> Cross-filter direction: **Single** (Dim → Fact).  
> Hide `Date/Time/HalfHourSlot` inside facts to force slicing from dimensions.

---

## 5) KPI Definitions

- **Load (MWh):** `SUM(NET_DEMAND) × 0.5`
- **Renewable Energy (MWh):** `SUM(RENEWABLE) × 0.5`
- **CFE% (24/7):** `Matched_MWh ÷ Load_MWh`
- **Matched_MWh (24/7):** `Σ MIN(Load, Renewable) × 0.5` by interval
- **Residual_MWh:** `Σ MAX(Load − Renewable, 0)` by interval
- **Location-based Emissions (tCO₂):** `Load_MWh × CarbonIntensity(g/kWh) ÷ 1000`
- **Market-based Emissions (tCO₂):** `Residual_MWh × CarbonIntensity(g/kWh) ÷ 1000`
- **Emissions Intensity (tCO₂/MWh):** `Market-based tCO₂ ÷ Load_MWh`

---

## 6) Report Pages

### 6.1 Executive Overview (KPIs + trends)
**Answers:** “How are we doing overall? What’s our renewable coverage and emissions?”

**Visuals**
- KPI cards:  
  - **CFE% (24/7)**  
  - **Load (MWh)**  
  - **Renewable Energy (MWh)**  
  - **Market-based Emissions (tCO₂)**  
  - **Emissions Intensity (tCO₂/MWh)**
- Combo chart: **Load (MWh)** bars by `YearMonth` with **CFE%** line.
- Top-N column chart: **Top 10 days by Residual (MWh)** *(or Market-based tCO₂)*.
- Two-bar comparison: **Emissions by Accounting Method (tCO₂)** — Location vs Market.
- Monthly table: `YearMonth`, `CFE% (24/7)`, `Avg Carbon Intensity`, `Market-based Emissions (tCO₂)`.

**Slicers**
- `Dim_Date[YearMonth]` (Dropdown)  
- `Dim_Date[Date]` (Between)

**Screenshot placeholder**  
![Executive Overview](https://github.com/TechPodx/Style-Repo/blob/8efb3f7306c66188057385e2b22c869fca93ef73/Images/Executive%20Overview.png)

---

### 6.2 Generation Mix & Carbon
**Answers:** “Which fuels drive the mix and carbon outcomes?”

**Visuals**
- Stacked area (or column): `MWh by Fuel` by `YearMonth` (Legend = `FuelType`).
- Ribbon chart: **Fuel ranking by month** (Value = `MWh by Fuel`).
- Line chart: **Carbon intensity trend** (`Avg Carbon Intensity` by `YearMonth`).
- Donut: **Share by CarbonGroup** (Value = `MWh by Fuel`).

**Slicers**
- `Dim_Date[YearMonth]` (Dropdown)  
- `Dim_Date[Season]` (Tile) *(optional)*

**Screenshot placeholder**  
![Generation Mix & Carbon](https://github.com/TechPodx/Style-Repo/blob/main/Images/Generation%20Mix%20%26%20Carbon.png)

---

### 6.3 24/7 Traceability (Heatmap)
**Answers:** “At which hours are we covered by renewables vs shortfall?”

**Visuals**
- Matrix heatmap: Rows = `Dim_Time[TimeText]`, Cols = `Dim_Date[Date]`, Values = **`Match % 24/7`** (conditional color 0→100%).
- Line: **Average intraday match profile (%)** (`Match % 24/7` by `TimeText`).
- *(Optional)* Scatter: **Interval Load vs Renewable Energy (MWh)** with tooltip showing `Match % 24/7` & `Avg Carbon Intensity`.

**Slicers**
- `Dim_Date[YearMonth]` (Single select)

**Screenshot placeholder**  
![24/7 Traceability](https://github.com/TechPodx/Style-Repo/blob/main/Images/24.7%20Traceability.png)

---

## 7) How to Use

1. Select **Year-Month** to focus the period.  
2. Use **Quater** to focus the specific quater.  
3. Read KPIs on the Overview; inspect **Top 10 residual days**.  
4. Drill into **Heatmap** to spot worst **half-hours**.  
5. Use **Generation Mix** to understand fuel drivers and carbon trends.

---

## 8) Assumptions & Methodology

- **Granularity:** 30-minute settlement periods; all KPIs aggregate from interval level.  
- **CFE% (24/7):** interval-by-interval matching (`min(load, renewable)`), not just annual renewable share.  
- **Emissions accounting:**  
  - *Location-based* = total load × grid average carbon intensity.  
  - *Market-based* = **residual** load (unmatched by renewables) × grid average carbon intensity.  
- **Grouping:** `Dim_Source` assigns fuels to **CarbonGroup** and **IsRenewable** for visual rollups.

---

## 9) Data Quality & Validation

- **Completeness:** enforced 48 intervals/day via `HalfHourSlot` (1–48).  
- **Type safety:** `DATETIME` as Date/Time; all metrics **Decimal Number** in Power Query.  
- **Reconciliation:** Long-table fuels sum close to `GENERATION` (small differences may arise from excluded categories).

---

## 10) Refresh & Automation (suggested)

- Manual: **Refresh** in Power BI Desktop.  
- Future: Schedule refresh in **Power BI Service** and email a PDF of the **Energy Label** page via **Power Automate**.

---

## 11) Limitations

- Uses GB system-level data; no customer smart-meter load in this demo.  
- Market-based logic assumes zero emissions for matched renewable energy (no certificate/REGO tracking here).  
- Imports are treated as a single category without origin-specific intensities.

---

## 12) Roadmap (next pages to add)

- **Scenario Studio (What-If):**  
  - Parameter **ContractCoverage %** (0–120).  
  - Measures: `Contract_CFE %`, `Contract_MarketEmissions_tCO2`, `Emissions_Delta_tCO2`, `CFE_Uplift_pp`.  
  - Visuals: KPI row, **Baseline vs Contract** bars or **Waterfall**, line of **CFE% vs Scenario** by month.

- **Energy Label (printable 1-pager):**  
  - Cards: **CFE% (24/7)**, **Load (MWh)**, **Renewable (MWh)**, **Market tCO₂**, **Avoided tCO₂** (if scenario shown).  
  - Donut/bar: **Fuel share**.  
  - Small monthly table & **methodology** text.  
  - Export: **File → Export → PDF**.

---

## Appendix A — Core DAX (copy-paste)

```DAX
// Energy (MWh) from half-hourly MW
Load_MWh := SUM(Fact_Interval[NET_DEMAND]) * 0.5
Gen_MWh  := SUM(Fact_Interval[GENERATION]) * 0.5
Renewable_MWh := SUM(Fact_Interval[RENEWABLE]) * 0.5
Fossil_MWh := SUM(Fact_Interval[FOSSIL]) * 0.5

// 24/7 matching
Matched_MWh :=
SUMX(Fact_Interval, MIN(Fact_Interval[NET_DEMAND], Fact_Interval[RENEWABLE]) * 0.5)

Match % 24/7 := DIVIDE([Matched_MWh], [Load_MWh])

Residual_MWh :=
SUMX(
  Fact_Interval,
  VAR load_mwh = Fact_Interval[NET_DEMAND] * 0.5
  VAR ren_mwh  = Fact_Interval[RENEWABLE] * 0.5
  RETURN IF(load_mwh > ren_mwh, load_mwh - ren_mwh, 0)
)

// Emissions
LocationEmissions_tCO2 :=
SUMX(
  Fact_Interval,
  (Fact_Interval[NET_DEMAND]*0.5) * Fact_Interval[CARBON_INTENSITY] / 1000
)

MarketEmissions_tCO2 :=
SUMX(
  Fact_Interval,
  VAR load_mwh = Fact_Interval[NET_DEMAND] * 0.5
  VAR ren_mwh  = Fact_Interval[RENEWABLE] * 0.5
  VAR residual = IF(load_mwh > ren_mwh, load_mwh - ren_mwh, 0)
  RETURN residual * Fact_Interval[CARBON_INTENSITY] / 1000
)

Avg Carbon Intensity := AVERAGE(Fact_Interval[CARBON_INTENSITY])
EmissionsIntensity_tCO2_per_MWh := DIVIDE([MarketEmissions_tCO2], [Load_MWh])

// Long-table fuels
MW by Fuel := SUM(Fact_GenLong[MW])
MWh by Fuel := [MW by Fuel] * 0.5

// Optional: Accounting method selector
AccountingMethod =
DATATABLE("Method", STRING, { {"Location-based"}, {"Market-based"} })

Emissions_By_Method :=
VAR m = SELECTEDVALUE(AccountingMethod[Method])
RETURN SWITCH(m,
  "Location-based", [LocationEmissions_tCO2],
  "Market-based", [MarketEmissions_tCO2]
)

