-- Create a new database for your project (if it doesn't already exist)
CREATE DATABASE IF NOT EXISTS options_portfolio;

-- Tell MySQL to actively use this database
USE options_portfolio;

-- 1. The Database Schema (Raw vs. Clean)

-- (i) Create Staging Table for Raw API Data
CREATE TABLE raw_options_feed (
    entry_id VARCHAR(50) PRIMARY KEY,
    trade_timestamp VARCHAR(100),       -- Messy string: "2026/08/04-09:15:00 AM"
    contract_symbol VARCHAR(50),        -- Messy string: " NIFTY_19500_CE "
    ltp VARCHAR(20),                    -- Last Traded Price (stored as string with currency symbols)
    open_interest INT,
    implied_volatility VARCHAR(20)      -- Contains 'N/A' or '%' symbols
);

-- (ii) Create Production Table for Analytical Queries
CREATE TABLE clean_options_data (
    entry_id VARCHAR(50) PRIMARY KEY,
    trade_date DATE,
    trade_time TIME,
    underlying_index VARCHAR(20),
    strike_price DECIMAL(10,2),
    option_type CHAR(2),                -- 'CE' (Call) or 'PE' (Put)
    ltp DECIMAL(10,2),
    open_interest INT,
    implied_volatility DECIMAL(5,2)
);

-- 2. Data Cleaning & Transformation Operations

-- Insert cleaned data from staging to production
-- 2. Data Cleaning & Transformation Operations
INSERT INTO clean_options_data (
    entry_id, trade_date, trade_time, underlying_index, 
    strike_price, option_type, ltp, open_interest, implied_volatility
)
SELECT 
    entry_id,
    -- (i) Date & Time Parsing
    DATE(STR_TO_DATE(SUBSTRING_INDEX(trade_timestamp, '-', 1), '%Y/%m/%d')) AS trade_date,
    TIME(STR_TO_DATE(SUBSTRING_INDEX(trade_timestamp, '-', -1), '%h:%i:%s %p')) AS trade_time,
    -- (ii) String Manipulation
    TRIM(SUBSTRING_INDEX(contract_symbol, '_', 1)) AS underlying_index,
    -- (iii) Extract Strike Price
    CAST(SUBSTRING_INDEX(SUBSTRING_INDEX(contract_symbol, '_', 2), '_', -1) AS DECIMAL(10,2)) AS strike_price,
    -- (iv) Extract Option Type
    TRIM(SUBSTRING_INDEX(contract_symbol, '_', -1)) AS option_type,
    -- (v) Currency Cleaning
    CAST(REPLACE(REPLACE(ltp, '$', ''), '₹', '') AS DECIMAL(10,2)) AS ltp,
    -- (vi) Null Handling for Open Interest
    COALESCE(open_interest, 0) AS open_interest,
    -- (vii) Percentage Cleaning
    CASE 
        WHEN implied_volatility = 'N/A' THEN NULL
        ELSE CAST(REPLACE(implied_volatility, '%', '') AS DECIMAL(5,2))
    END AS implied_volatility
FROM raw_options_feed
WHERE entry_id IS NOT NULL;

-- 3. Complex Analysis

WITH StrikeAggregates AS (
    -- Aggregate Total Open Interest by Strike and Option Type for the current day
    SELECT 
        trade_date,
        strike_price,
        SUM(CASE WHEN option_type = 'CE' THEN open_interest ELSE 0 END) AS total_call_oi,
        SUM(CASE WHEN option_type = 'PE' THEN open_interest ELSE 0 END) AS total_put_oi,
        AVG(implied_volatility) AS avg_iv
    FROM clean_options_data
    GROUP BY trade_date, strike_price
),
PCR_Calculation AS (
    -- Calculate Put-Call Ratio and find MoM (Minute-over-Minute) changes using Window Functions
    SELECT 
        trade_date,
        strike_price,
        total_call_oi,
        total_put_oi,
        -- Avoid division by zero when calculating PCR
        CASE 
            WHEN total_call_oi = 0 THEN NULL 
            ELSE ROUND((total_put_oi / total_call_oi), 2) 
        END AS put_call_ratio,
        avg_iv
    FROM StrikeAggregates
)
-- Final Output: Rank strikes to find the strongest support (highest Put OI) and resistance (highest Call OI)
SELECT 
    trade_date,
    strike_price,
    total_call_oi,
    total_put_oi,
    put_call_ratio,
    avg_iv,
    -- Rank strikes to identify max pain / heavy resistance areas
    RANK() OVER (PARTITION BY trade_date ORDER BY total_call_oi DESC) as call_oi_rank,
    RANK() OVER (PARTITION BY trade_date ORDER BY total_put_oi DESC) as put_oi_rank
FROM PCR_Calculation
ORDER BY trade_date DESC, strike_price ASC;
-- 1. Enable local data loading on the server
SET GLOBAL local_infile = 1;

-- 4. Load the generated Python CSV into the table
LOAD DATA LOCAL INFILE 'D:/Portfolio/Financial Market Data Wrangler & Options Analytics/raw_options_feed.csv' 
INTO TABLE raw_options_feed
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'  
IGNORE 1 ROWS 
(
    entry_id, 
    trade_timestamp, 
    contract_symbol, 
    ltp, 
    @temp_open_interest,    
    implied_volatility
)
SET 
    -- Transform Pandas 'NaN' or empty strings into true SQL NULLs
    open_interest = CASE 
        WHEN @temp_open_interest = 'NaN' THEN NULL
        WHEN @temp_open_interest = '' THEN NULL
        ELSE CAST(@temp_open_interest AS UNSIGNED)
    END;