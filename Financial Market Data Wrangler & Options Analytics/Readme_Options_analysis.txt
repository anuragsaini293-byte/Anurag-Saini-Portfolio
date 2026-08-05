# Financial Market Data Wrangler & Options Analytics 📊

## Project Overview
Raw financial data feeds from exchanges and broker APIs are rarely clean. They often contain concatenated strings, inconsistent timestamps, and missing values. This project demonstrates an end-to-end **ETL (Extract, Transform, Load)** and analytics pipeline using advanced **MySQL**. 

It takes messy, unformatted National Stock Exchange (NSE) options data, normalizes it into a production-ready database schema, and utilizes advanced SQL functions to calculate critical market sentiment metrics like the **Put-Call Ratio (PCR)** and **Support/Resistance Zones** based on Open Interest (OI).

As a fresher holding a Microsoft and MSME-backed certification in data analytics, I built this project to demonstrate my ability to handle complex real-world datasets. I am highly eager to learn and tackle the kind of messy data challenges frequently faced in algorithmic trading, fintech, and asset management.

## 🛠️ Tech Stack & Skills Demonstrated
*   **Database:** MySQL
*   **Data Wrangling:** String Manipulation (`SUBSTRING_INDEX`, `REPLACE`, `TRIM`), Date/Time formatting, Type Casting.
*   **Advanced SQL:** Common Table Expressions (CTEs), Window Functions (`RANK() OVER`), Conditional Aggregation (`CASE WHEN`).
*   **Domain Knowledge:** Options Trading, Open Interest (OI), Put-Call Ratio (PCR), Market Max Pain Levels.

## 📂 The Problem vs. The Solution

### 1. The Raw Data (The Problem)
Options data often arrives with crucial information combined into a single, unformatted text string (e.g., `" NIFTY_19500_CE "` or `NIFTY24AUG19500CE`).
*   Strike prices and option types are trapped inside text strings.
*   Numeric values contain commas or currency symbols.
*   Missing data is represented by empty strings or 'NaN' text instead of true SQL `NULL` values.

### 2. Data Cleaning & Transformation (The Solution)
The first phase of the SQL script handles the extraction and normalization before the data ever reaches the production tables:
*   Parses the `contract_symbol` string to isolate the **Underlying Asset**, **Strike Price**, and **Option Type** (CE/PE).
*   Converts poorly formatted string timestamps into strict `DATETIME` formats.
*   Cleans Open Interest and Volume columns by removing non-numeric characters and casting them as `UNSIGNED INT` or `DECIMAL`.

### 3. Analytics & Market Sentiment
Once the data is pristine, the project runs a complex analytical query utilizing CTEs and Window functions to deliver actionable trading insights:
*   **Aggregates Open Interest:** Calculates total Call OI and Put OI for specific strike prices.
*   **Put-Call Ratio (PCR):** Calculates the PCR dynamically to gauge market bullish/bearish sentiment.
*   **Support & Resistance Mapping:** Ranks the strikes by Open Interest volume to identify the heaviest zones of option writing (Max Pain).

## 🚀 How to Run This Project

Ensure your MySQL server allows local file loading:
SET GLOBAL local_infile = 1;

Run options_analysis.sql in your preferred SQL client (e.g., VS Code Database Client, MySQL Workbench).
Ensure you update the file path in the LOAD DATA LOCAL INFILE command to point to the exact location of the included raw_options_feed.csv file on your local machine.