import pandas as pd
import random
from datetime import datetime, timedelta

# Set a seed to ensure the random data is somewhat reproducible
random.seed(42)
# Configuration for dummy data
num_rows = 500
records = []
symbols = ['NIFTY', 'BANKNIFTY']
strikes = [19000, 19100, 19200, 19300, 19400, 19500, 19600]
option_types = ['CE', 'PE']

# Set the start time for the trading session
start_time = datetime(2026, 8, 4, 9, 15, 0)

for i in range(1, num_rows + 1):
    entry_id = f"OPT_{1000 + i}"
    
    # Generate messy timestamp format: YYYY/MM/DD-HH:MM:SS AM/PM
    dt = start_time + timedelta(minutes=random.randint(1, 300))
    trade_timestamp = dt.strftime("%Y/%m/%d-%I:%M:%S %p")
    
    # Generate messy contract symbol with trailing and leading spaces
    sym = random.choice(symbols)
    strike = random.choice(strikes)
    opt = random.choice(option_types)
    contract_symbol = f"  {sym}_{strike}_{opt}  "
    
    # Generate Last Traded Price (LTP) with random currency symbols or formatting
    ltp_val = round(random.uniform(10.0, 350.0), 2)
    currency = random.choice(['₹', '$', ''])
    ltp = f"{currency}{ltp_val}"
    
    # Generate open interest with some potential NULL (None) or 0 values
    # (To test the SQL COALESCE function)
    open_interest = random.choice([random.randint(1000, 50000), None, 0])
    
    # Generate implied volatility with '%' signs or 'N/A' text
    # (To test the SQL CASE statements and REPLACE functions)
    if random.random() < 0.15:
        implied_volatility = "N/A"
    else:
        iv_val = round(random.uniform(12.0, 32.0), 2)
        implied_volatility = f"{iv_val}%"
        
    records.append({
        'entry_id': entry_id,
        'trade_timestamp': trade_timestamp,
        'contract_symbol': contract_symbol,
        'ltp': ltp,
        'open_interest': open_interest,
        'implied_volatility': implied_volatility
    })

# Convert to a DataFrame
df = pd.DataFrame(records)

# Save the DataFrame to a CSV file without the index column
csv_filename = 'raw_options_feed.csv'
df.to_csv(csv_filename, index=False)

print(f"Success! Generated {num_rows} rows of messy data.")
print(f"File saved as: {csv_filename}")
print("\nPreview of the first 5 rows:")
print(df.head())