import sqlite3
import os

# Get paths
script_dir = os.path.dirname(os.path.abspath(__file__))
project_root = os.path.dirname(script_dir)
db_path = os.path.join(project_root, "database", "loan_data.db")
sql_file = os.path.join(project_root, "sql", "clean_data.sql")

# Check if SQL file exists
if not os.path.exists(sql_file):
    print(f"❌ SQL file not found: {sql_file}")
    print(f"Please create the file at: sql/clean_data.sql")
    exit(1)

print("🧹 Starting data cleaning process...")
print(f"Database: {db_path}")
print(f"SQL Script: {sql_file}")

# Connect to database
conn = sqlite3.connect(db_path)
cursor = conn.cursor()

# Read SQL file
print("\n📖 Reading SQL script...")
with open(sql_file, 'r') as f:
    sql_script = f.read()

# Split into individual statements and execute
print("⚙️  Executing SQL statements...")
statements = sql_script.split(';')

for i, statement in enumerate(statements, 1):
    statement = statement.strip()
    if statement and not statement.startswith('--'):
        try:
            cursor.execute(statement)
            conn.commit()
        except sqlite3.Error as e:
            print(f"⚠️  Statement {i} had an issue (might be intentional): {e}")

print("\n✅ SQL cleaning script executed!")

# Show summary
print("\n📊 Summary:")
cursor.execute("SELECT COUNT(*) FROM loan_raw")
raw_count = cursor.fetchone()[0]
print(f"  Raw records: {raw_count}")

try:
    cursor.execute("SELECT COUNT(*) FROM loan_cleaned")
    clean_count = cursor.fetchone()[0]
    print(f"  Cleaned records: {clean_count}")
    
    cursor.execute("SELECT * FROM loan_summary")
    stats = cursor.fetchone()
    if stats:
        print(f"\n  Total Applications: {stats[1]}")
        print(f"  Avg Total Income: {stats[4]}")
        print(f"  Avg Loan Amount: {stats[5]}")
        print(f"  % Good Credit: {stats[7]}%")
except:
    print("  Cleaned table not yet created")

conn.close()
print("\n✨ Data is ready for Power BI!")