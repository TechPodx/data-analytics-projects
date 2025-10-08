# 💊 Pharmaceutical Sales Intelligence Dashboard

## 📌 Project Overview
This project delivers an **executive-ready sales intelligence solution** for pharmaceutical ATC sales data, built with **Excel Power Query** and **Power BI**.  

### Page 1 - Executive Overview
![image1](https://github.com/TechPodx/Style-Repo/blob/f665f16854b56b768c07402dca8702e40ea60985/Gif/Pharmaceutical%20Sales%20Data%20Analysis_gif_1.gif)

**1. Sales Overview**

KPIs: Total Sales, Top ATC Code, Lowest ATC Code
Bar chart: Total Sales by ATC Codes
Line chart: Total Sales over Years
Mix Share Matrix (% contribution per ATC by year)
Table: Top 3 Risers & Fallers

### Page 2 - Forecast & Seasonality
![image1](https://github.com/TechPodx/Style-Repo/blob/f665f16854b56b768c07402dca8702e40ea60985/Gif/Pharmaceutical%20Sales%20Data%20Analysis_gif_2.gif)

**2. Forecasting**

KPIs: Upper Forecast, Average Forecast, Lowest Forecast
Table: Forecast estimates by Month (Upper, Avg, Lower)
Line chart: Forecasted Sales over Years (upper/avg/lower lines)

## Access to Walkthrough Video: [Project Walkthough Video]()
## Access to Live BI Dashboard: [BI Dashboard](https://app.powerbi.com/groups/me/reports/3c199043-3f01-489c-8c54-f57f66b14fd3?ctid=fe8ccb52-ca53-49de-a5b4-50faf33a9cc2&pbi_source=linkShare)

The dataset comes from [Kaggle Pharma Sales Data](https://www.kaggle.com/datasets/milanzdravkovic/pharma-sales-data), containing **Hourly, Daily, Weekly, and Monthly** sales records across multiple ATC (Anatomical Therapeutic Chemical) categories.  

### 🎯 Objectives
- Clean and unify multiple datasets (hourly, daily, weekly, monthly).  
- Create a **FactSales** fact table with dimensions **DimDate** and **DimATC**.  
- Provide insights into:  
  - Total sales growth and YoY trends  
  - Mix share and ATC-level concentration  
  - Top/bottom ATCs (risers & fallers)  
  - Seasonality patterns  
  - Forecasted sales with confidence intervals  

---

## 🛠 Data Preparation (Power Query)

ETL steps implemented in **Excel Power Query**:

1. **Raw imports**: Four CSVs (`sales_hourly`, `sales_daily`, `sales_weekly`, `sales_monthly`) loaded as queries.  
2. **Function Query (`fxTransformTable`)**:
   - Rename `datum` → `Date`  
   - Set type = Date / DateTime depending on grain  
   - Removed helper columns (Year, Month, Hour, Weekday)
   - Unpivot ATC columns → `Date | ATC_Code | Value`  
   - Add `Grain` column = Hourly / Daily / Weekly / Monthly  
   - Add calendar columns: `Year`, `MonthNum`, `MonthName`, `ISOWeek`, `ISOYear`  
3. **Invoked function queries**: `Sales_Hourly`, `Sales_Daily`, `Sales_Weekly`, `Sales_Monthly`.  
4. **Fact table**: `FactSales` created by appending all transformed queries.  
5. **DimDate**: Custom date table created using min/max of FactSales.  
6. **DimATC**: `Didn't use`.  

---

## 💹 Excel

Primerily, I imported data from four seperate CSV files into the excel workbook for analysis and used the power query to create different variations such as different data tables, funcctions 
and group them in folder to organise them. 

**All the Queries & Connections**

![Image](https://github.com/TechPodx/Style-Repo/blob/43c6900700c135bf9e228f397fa50f66956b8bbd/Images/Excel%20Queries%20%26%20Connections.png)

The funcntion I created (`fxTransformTable`) to generate multiple tables based on the same rules is mentioned below with clearly defined steps.  

```m

= (fact as table, GrainName as text) as table =>
let
    // 1) Ensure the date column is named "Date"
    Renamed = Table.TransformColumnNames(fact, each if _ = "datum" then "Date" else _),

    // 2) Set Date/DateTime type depending on grain (Hourly uses datetime)
    TypedDate =
        if GrainName = "Hourly"
        then Table.TransformColumnTypes(Renamed, {{"Date", type datetime}})
        else Table.TransformColumnTypes(Renamed, {{"Date", type date}}),

    // 3) Remove helper columns if they exist (daily/hourly CSVs have these)
    HelperCols = {"Year", "Month", "Hour", "Weekday Name"},
    ExistingHelperCols = List.Intersect({HelperCols, Table.ColumnNames(TypedDate)}),
    RemovedHelpers = if List.Count(ExistingHelperCols) > 0
                     then Table.RemoveColumns(TypedDate, ExistingHelperCols)
                     else TypedDate,

    // 4) Unpivot all ATC columns (keep only "Date")
    Unpivoted = Table.UnpivotOtherColumns(RemovedHelpers, {"Date"}, "ATC_Code", "Value"),

    // 5) Ensure proper types
    CastTypes = Table.TransformColumnTypes(Unpivoted, {{"ATC_Code", type text}, {"Value", type number}}),

    // 6) Add Grain column
    AddGrain = Table.AddColumn(CastTypes, "Grain", each GrainName, type text),

    // 7) Add calendar columns (work off a date-only helper for consistency)
    AddDateOnly = Table.AddColumn(AddGrain, "DateOnly",
                    each if Value.Is([Date], type datetime) then DateTime.Date([Date]) else [Date],
                    type date),
    AddYear = Table.AddColumn(AddDateOnly, "Year", each Date.Year([DateOnly]), Int64.Type),
    AddMonthNum = Table.AddColumn(AddYear, "MonthNum", each Date.Month([DateOnly]), Int64.Type),
    AddMonthName = Table.AddColumn(AddMonthNum, "MonthName", each Date.ToText([DateOnly], "MMM"), type text),

    // 8) Weekly helpers: ISOWeek and ISOYear (valid for any grain; mainly used for Weekly)
    AddISOWeek = Table.AddColumn(AddMonthName, "ISOWeek", each Date.WeekOfYear([DateOnly], Day.Monday), Int64.Type),
    AddISOYear = Table.AddColumn(AddISOWeek, "ISOYear",
                    each Date.Year(Date.AddDays([DateOnly], 3 - Date.DayOfWeek([DateOnly], Day.Monday))), Int64.Type),

    // 9) Clean up helper
    RemovedDateOnly = Table.RemoveColumns(AddISOYear, {"DateOnly"})
in
    RemovedDateOnly

```

After finalizing the mandatory requirements, I analyzed the data and created visualizations using Excel, as shown below.

![Image](https://github.com/TechPodx/Style-Repo/blob/b5305a1749bf1c56709959465ab6212d92d21869/Images/Pharmaceutical%20Sales%20Data%20Analysis_Excel_1.png)
![Image](https://github.com/TechPodx/Style-Repo/blob/b5305a1749bf1c56709959465ab6212d92d21869/Images/Pharmaceutical%20Sales%20Data%20Analysis_Excel_2.png)
![Image](https://github.com/TechPodx/Style-Repo/blob/b5305a1749bf1c56709959465ab6212d92d21869/Images/Pharmaceutical%20Sales%20Data%20Analysis_Excel_3.png)
![Image](https://github.com/TechPodx/Style-Repo/blob/b5305a1749bf1c56709959465ab6212d92d21869/Images/Pharmaceutical%20Sales%20Data%20Analysis_Excel_4.png)
![Image](https://github.com/TechPodx/Style-Repo/blob/b5305a1749bf1c56709959465ab6212d92d21869/Images/Pharmaceutical%20Sales%20Data%20Analysis_Excel_5.png)
![Image](https://github.com/TechPodx/Style-Repo/blob/b5305a1749bf1c56709959465ab6212d92d21869/Images/Pharmaceutical%20Sales%20Data%20Analysis_Excel_6.png)
![Image](https://github.com/TechPodx/Style-Repo/blob/b5305a1749bf1c56709959465ab6212d92d21869/Images/Pharmaceutical%20Sales%20Data%20Analysis_Excel_7.png)

The pivot tables used to produce the above analysis can be found in the ‘Analysis’ tab of the Excel file

---

## 📊 DAX Measures

Key measures used in Power BI:

```DAX
-- Total Sales
Total Sales = SUM('FactSales - Appended'[Value])

-- ATC Yearly Share %
ATC Yearly Share % = 
DIVIDE(
    SUM('FactSales - Appended'[Value]),
    CALCULATE(
        SUM('FactSales - Appended'[Value]),
        ALLEXCEPT('FactSales - Appended', 'FactSales - Appended'[ATC Code])
    )
)

-- AVG Forecasted Sales
AVG Forecasted Sales = SUM('Forecast Summery'[Forecast (AVG)])

-- Lowest ATC Code

Lowest ATC Code = 
    CALCULATE(
        MAX('FactSales - Appended'[ATC Code]),
        TOPN(1,
             VALUES('FactSales - Appended'[ATC Code]),
             CALCULATE(SUM('FactSales - Appended'[Value])),
             ASC
        )
    )

-- Lowest Forecasted Sales
Lowest Forecasted Sales = SUM('Forecast Summery'[Forecast (LOWER)])

-- Top ATC Code

Top ATC Code = 
CALCULATE(
    MAX('FactSales - Appended'[ATC Code]),
    TOPN(
        1,
        VALUES('FactSales - Appended'[ATC Code]),
        CALCULATE(SUM('FactSales - Appended'[Value])),
        DESC
    )
)

-- Upper Forecast Sales
Upper Forecast Sales = SUM('Forecast Summery'[Forecast (UPPER)] )
```


































