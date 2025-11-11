import sqlite3
import pandas as pd
import os

# Get paths
script_dir = os.path.dirname(os.path.abspath(__file__))
project_root = os.path.dirname(script_dir)
db_path = os.path.join(project_root, "database", "loan_data.db")

# Create exports folder
export_dir = os.path.join(project_root, "powerbi_exports")
os.makedirs(export_dir, exist_ok=True)

print("📊 Exporting data for Power BI...")

# Connect to database
conn = sqlite3.connect(db_path)

# Export main cleaned table
print("\n1. Exporting loan_cleaned table...")
df = pd.read_sql_query("SELECT * FROM loan_cleaned", conn)
output_path = os.path.join(export_dir, "loan_cleaned.csv")
df.to_csv(output_path, index=False)
print(f"   ✅ Saved: {output_path}")
print(f"   📊 Records: {len(df)}")

# Export demographics by gender
print("\n2. Exporting demographics_by_gender...")
df = pd.read_sql_query("SELECT * FROM demographics_by_gender", conn)
output_path = os.path.join(export_dir, "demographics_by_gender.csv")
df.to_csv(output_path, index=False)
print(f"   ✅ Saved: {output_path}")

# Export demographics by education
print("\n3. Exporting demographics_by_education...")
df = pd.read_sql_query("SELECT * FROM demographics_by_education", conn)
output_path = os.path.join(export_dir, "demographics_by_education.csv")
df.to_csv(output_path, index=False)
print(f"   ✅ Saved: {output_path}")

# Export demographics by property
print("\n4. Exporting demographics_by_property...")
df = pd.read_sql_query("SELECT * FROM demographics_by_property", conn)
output_path = os.path.join(export_dir, "demographics_by_property.csv")
df.to_csv(output_path, index=False)
print(f"   ✅ Saved: {output_path}")

# Export income analysis
print("\n5. Exporting analysis_by_income...")
df = pd.read_sql_query("SELECT * FROM analysis_by_income", conn)
output_path = os.path.join(export_dir, "analysis_by_income.csv")
df.to_csv(output_path, index=False)
print(f"   ✅ Saved: {output_path}")

# Export credit analysis
print("\n6. Exporting analysis_by_credit...")
df = pd.read_sql_query("SELECT * FROM analysis_by_credit", conn)
output_path = os.path.join(export_dir, "analysis_by_credit.csv")
df.to_csv(output_path, index=False)
print(f"   ✅ Saved: {output_path}")

# Export marital status
print("\n7. Exporting analysis_by_marital_status...")
df = pd.read_sql_query("SELECT * FROM analysis_by_marital_status", conn)
output_path = os.path.join(export_dir, "analysis_by_marital_status.csv")
df.to_csv(output_path, index=False)
print(f"   ✅ Saved: {output_path}")

# Export employment analysis
print("\n8. Exporting analysis_by_employment...")
df = pd.read_sql_query("SELECT * FROM analysis_by_employment", conn)
output_path = os.path.join(export_dir, "analysis_by_employment.csv")
df.to_csv(output_path, index=False)
print(f"   ✅ Saved: {output_path}")

# Export risk segments
print("\n9. Exporting risk_segments...")
df = pd.read_sql_query("SELECT * FROM risk_segments", conn)
output_path = os.path.join(export_dir, "risk_segments.csv")
df.to_csv(output_path, index=False)
print(f"   ✅ Saved: {output_path}")

# Export risk distribution summary
print("\n10. Exporting risk_distribution_summary...")
query = """
SELECT 
    Risk_Category,
    COUNT(*) as Count,
    ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM risk_segments), 2) as Percentage,
    ROUND(AVG(TotalIncome), 2) as Avg_Income,
    ROUND(AVG(LoanAmount), 2) as Avg_Loan,
    ROUND(AVG(Loan_to_Income_Ratio), 2) as Avg_LTI
FROM risk_segments
GROUP BY Risk_Category
"""
df = pd.read_sql_query(query, conn)
output_path = os.path.join(export_dir, "risk_distribution.csv")
df.to_csv(output_path, index=False)
print(f"   ✅ Saved: {output_path}")

conn.close()

print("\n" + "="*80)
print("✨ All data exported for Power BI!")
print(f"📁 Location: {export_dir}")
print("="*80)
print("\nNext steps:")
print("1. Open Power BI Desktop")
print("2. Get Data → Text/CSV")
print("3. Navigate to the powerbi_exports folder")
print("4. Import all CSV files")
print("5. Build your dashboard!")
print("="*80)