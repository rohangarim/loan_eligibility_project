import sqlite3
import os
import pandas as pd
from datetime import datetime

# Get paths
script_dir = os.path.dirname(os.path.abspath(__file__))
project_root = os.path.dirname(script_dir)
db_path = os.path.join(project_root, "database", "loan_data.db")
analysis_file = os.path.join(project_root, "sql", "analysis_queries.sql")

# Create output file
output_dir = os.path.join(project_root, "analysis_results")
os.makedirs(output_dir, exist_ok=True)
timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
output_file = os.path.join(output_dir, f"statistical_insights_{timestamp}.txt")

print("📊 Running Statistical Analysis...")
print(f"Database: {db_path}")
print(f"Saving results to: {output_file}\n")

# Open output file
with open(output_file, 'w') as f:
    f.write("="*80 + "\n")
    f.write("LOAN ELIGIBILITY STATISTICAL ANALYSIS\n")
    f.write(f"Generated: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}\n")
    f.write("="*80 + "\n\n")

# Connect to database
conn = sqlite3.connect(db_path)

def print_and_save(text, file_handle):
    """Print to console and save to file"""
    print(text)
    file_handle.write(text + "\n")

with open(output_file, 'a') as f:
    # Overall Statistics
    print_and_save("="*80, f)
    print_and_save("OVERALL STATISTICS", f)
    print_and_save("="*80, f)
    query = """
    SELECT 
        COUNT(*) as Total_Applications,
        ROUND(AVG(TotalIncome), 2) as Avg_Total_Income,
        ROUND(AVG(LoanAmount), 2) as Avg_Loan_Amount,
        ROUND(AVG(Loan_to_Income_Ratio), 2) as Avg_LTI_Ratio,
        ROUND(SUM(CASE WHEN Credit_History = 1 THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) as Pct_Good_Credit
    FROM loan_cleaned
    """
    df = pd.read_sql_query(query, conn)
    print_and_save(df.to_string(index=False), f)
    
    # Gender Analysis
    print_and_save("\n" + "="*80, f)
    print_and_save("GENDER DISTRIBUTION", f)
    print_and_save("="*80, f)
    df = pd.read_sql_query("SELECT * FROM demographics_by_gender", conn)
    print_and_save(df.to_string(index=False), f)
    
    # Education Analysis
    print_and_save("\n" + "="*80, f)
    print_and_save("EDUCATION ANALYSIS", f)
    print_and_save("="*80, f)
    df = pd.read_sql_query("SELECT * FROM demographics_by_education", conn)
    print_and_save(df.to_string(index=False), f)
    
    # Property Area
    print_and_save("\n" + "="*80, f)
    print_and_save("PROPERTY AREA DISTRIBUTION", f)
    print_and_save("="*80, f)
    df = pd.read_sql_query("SELECT * FROM demographics_by_property", conn)
    print_and_save(df.to_string(index=False), f)
    
    # Income Categories
    print_and_save("\n" + "="*80, f)
    print_and_save("INCOME CATEGORIES", f)
    print_and_save("="*80, f)
    df = pd.read_sql_query("SELECT * FROM analysis_by_income", conn)
    print_and_save(df.to_string(index=False), f)
    
    # Credit History
    print_and_save("\n" + "="*80, f)
    print_and_save("CREDIT HISTORY IMPACT", f)
    print_and_save("="*80, f)
    df = pd.read_sql_query("SELECT * FROM analysis_by_credit", conn)
    print_and_save(df.to_string(index=False), f)
    
    # Marital Status
    print_and_save("\n" + "="*80, f)
    print_and_save("MARITAL STATUS ANALYSIS", f)
    print_and_save("="*80, f)
    df = pd.read_sql_query("SELECT * FROM analysis_by_marital_status", conn)
    print_and_save(df.to_string(index=False), f)
    
    # Employment
    print_and_save("\n" + "="*80, f)
    print_and_save("EMPLOYMENT STATUS", f)
    print_and_save("="*80, f)
    df = pd.read_sql_query("SELECT * FROM analysis_by_employment", conn)
    print_and_save(df.to_string(index=False), f)
    
    # Dependents
    print_and_save("\n" + "="*80, f)
    print_and_save("DEPENDENTS ANALYSIS", f)
    print_and_save("="*80, f)
    df = pd.read_sql_query("SELECT * FROM analysis_by_dependents", conn)
    print_and_save(df.to_string(index=False), f)
    
    # Risk Distribution
    print_and_save("\n" + "="*80, f)
    print_and_save("RISK DISTRIBUTION", f)
    print_and_save("="*80, f)
    query = """
    SELECT 
        Risk_Category,
        COUNT(*) as Count,
        ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM risk_segments), 2) as Percentage
    FROM risk_segments
    GROUP BY Risk_Category
    ORDER BY Count DESC
    """
    df = pd.read_sql_query(query, conn)
    print_and_save(df.to_string(index=False), f)
    
    # Top Insights
    print_and_save("\n" + "="*80, f)
    print_and_save("TOP 10 HIGHEST INCOME APPLICANTS", f)
    print_and_save("="*80, f)
    query = """
    SELECT Loan_ID, Gender, Education, TotalIncome, LoanAmount, 
           Loan_to_Income_Ratio, Credit_Category
    FROM loan_cleaned
    ORDER BY TotalIncome DESC
    LIMIT 10
    """
    df = pd.read_sql_query(query, conn)
    print_and_save(df.to_string(index=False), f)
    
    print_and_save("\n" + "="*80, f)
    print_and_save("TOP 10 LARGEST LOAN REQUESTS", f)
    print_and_save("="*80, f)
    query = """
    SELECT Loan_ID, Gender, Education, TotalIncome, LoanAmount, 
           Loan_to_Income_Ratio, Credit_Category
    FROM loan_cleaned
    ORDER BY LoanAmount DESC
    LIMIT 10
    """
    df = pd.read_sql_query(query, conn)
    print_and_save(df.to_string(index=False), f)

conn.close()
print("\n" + "="*80)
print(f"✨ Analysis complete!")
print(f"📄 Full report saved to: {output_file}")
print(f"💡 Open the file to see all insights!")
print("="*80)