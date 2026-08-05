import pandas as pd
import numpy as np
import os
from sklearn.impute import SimpleImputer
from sklearn.preprocessing import StandardScaler, MinMaxScaler
from sklearn.decomposition import PCA

print("Loading Master Pharma Dataset...")
script_dir = os.path.dirname(os.path.abspath(__file__))
csv_path = os.path.join(script_dir, 'Master_Pharma_Data.csv')
df = pd.read_csv(csv_path)

# 1. Define the Feature Sets for the 3 Indices
chronic_features = [
    'Average GDP', 
    'total facilities',
    'Male Blood sugar level  high or very high (>140 mg/dl) or taking medicine to con',
    'Male Elevated blood pressure or taking medicine to control blood pressure (%)'
]

acute_features = [
    'Average GDP', 
    'total facilities',
    'Age_Group_0_29',
    'Population'
]

# Overall combines all unique features from both acute and chronic
overall_features = list(set(chronic_features + acute_features))

# 2. Define a reusable PCA function
def run_pca_model(dataframe, features, score_column_name):
    print(f"Calculating {score_column_name}...")
    
    # Isolate the data
    data = dataframe[features].copy()
    
    # Impute missing values
    imputer = SimpleImputer(strategy='median')
    data_imputed = imputer.fit_transform(data)
    
    # Scale features (Z-scores)
    scaler = StandardScaler()
    data_scaled = scaler.fit_transform(data_imputed)
    
    # Run PCA (Extract PC1)
    pca = PCA(n_components=1)
    pc1_scores = pca.fit_transform(data_scaled)
    
    # Ensure positive correlation (higher GDP/Population = higher score)
    if pca.components_[0][0] < 0:
        pc1_scores = pc1_scores * -1
        
    # Scale final score 0-100
    min_max_scaler = MinMaxScaler(feature_range=(0, 100))
    dataframe[score_column_name] = min_max_scaler.fit_transform(pc1_scores).round(2)
    
    return dataframe

# 3. Execute the 3 Models
df = run_pca_model(df, chronic_features, 'Chronic_MAI')
df = run_pca_model(df, acute_features, 'Acute_MAI')
df = run_pca_model(df, overall_features, 'Overall_MAI')

# 4. Sort by the Overall Index to find the absolute best markets
df = df.sort_values(by='Overall_MAI', ascending=False).reset_index(drop=True)

# 5. Export the Final 3-Index Model
output_filename = os.path.join(script_dir, 'Final_Sun_Pharma_3_Indices.csv')
df.to_csv(output_filename, index=False)

print(f"\nSuccess! 3-Index Model complete. Saved to:\n{output_filename}\n")
print("--- TOP 5 DISTRICTS (OVERALL) ---")
print(df[['State name', 'District name', 'Overall_MAI', 'Chronic_MAI', 'Acute_MAI']].head())