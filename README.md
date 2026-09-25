# 🚚 End-to-End Delivery Route Optimization & Logistics Analytics in SQL

## 📌 Project Overview
This project performs end-to-end Data Quality Assurance (DQA), comprehensive data cleaning, and advanced business intelligence analysis on a multi-table logistics dataset using **SQL Server (T-SQL)**. 

The goal of this project is to address critical operational issues in supply chain logistics—such as identifying infrastructure bottlenecks, analyzing the impact of weather on delivery times, and evaluating delay propagation across route segments.

---

## 🗂️ Dataset Architecture
The project utilizes 4 relational tables linked via primary/foreign key relationships:
* trips_: Contains trip details including geographic coordinates, travel times, and linked IDs.
* roads: Captures physical road infrastructure attributes (lanes, signal counts, road types).
* traffic: Records real-time traffic levels, hours, and average speeds.
* weather: Logged environmental conditions, temperatures, and visibility metrics.

---

## 🧹 Key Data Cleaning Steps (`01_data_cleaning.sql`)
To ensure total data integrity for analysis, the following cleaning steps were executed:
* **Handling Invalid Strings & Outliers:** Converted non-numeric travel times and impossible sensor anomalies (< 1 min, > 75 min) to NULL using TRY_CAST().
* **Standardizing Data Types:** Applied ALTER TABLE to permanently convert text-based numeric fields into DECIMAL & INT.
* **Date & Time Conversion:** Standardized mixed date strings into uniform DATETIME2 representations using TRY_CONVERT().
* **String Sanitization:** Cleaned leading/trailing spaces and unmapped placeholder text using TRIM().

---

## 📊 Key Analytical Insights (`02_business_analysis.sql`)

### 1. Infrastructure Bottlenecks
* **Urban & Residential Roads:** Exhibited moderate speed reductions primarily driven by high traffic signal density (>4 signals) and low lane counts (1–3 lanes).
* **Highways:** Highways experienced severe relative speed drops despite having >4 lanes and fewer signals, proving high sensitivity to lane-merging friction at high baseline speeds.

### 2. Route & Traffic Performance Analysis
* Applied Common Table Expressions (CTEs) and  CASE statements to classify travel routes into short, medium and long categories.
* Assessed speed degradation during severe weather events (Rain, Fog vs Clear) to aid operational dispatchers in adjusting delivery ETAs.

---

## 🛠️ Tech Stack & SQL Techniques Used
* **Database Management System:** SQL Server (SSMS)
* **SQL Techniques:** CTEs, Window Functions (LAG(), ROW_NUMBER(), AVG()), Data Type Conversion (TRY_CAST, TRY_CONVERT), Conditional Aggregation (CASE statements), Multi-Table Joins(LEFT, INNER).
