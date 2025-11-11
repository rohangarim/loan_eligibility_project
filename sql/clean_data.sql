-- ============================================
-- LOAN DATA CLEANING SCRIPT
-- ============================================
-- This script cleans the raw loan test data
-- Ready for analysis and prediction in Power BI
-- ============================================

-- Step 1: Explore the raw data
SELECT 'Total Records' as Metric, COUNT(*) as Value FROM loan_raw
UNION ALL
SELECT 'Unique Loan IDs', COUNT(DISTINCT Loan_ID) FROM loan_raw;

-- Step 2: Check for NULL/missing values in each column
SELECT 
    COUNT(*) as total_rows,
    SUM(CASE WHEN Gender IS NULL OR Gender = '' THEN 1 ELSE 0 END) as missing_gender,
    SUM(CASE WHEN Married IS NULL OR Married = '' THEN 1 ELSE 0 END) as missing_married,
    SUM(CASE WHEN Dependents IS NULL OR Dependents = '' THEN 1 ELSE 0 END) as missing_dependents,
    SUM(CASE WHEN Education IS NULL OR Education = '' THEN 1 ELSE 0 END) as missing_education,
    SUM(CASE WHEN Self_Employed IS NULL OR Self_Employed = '' THEN 1 ELSE 0 END) as missing_self_employed,
    SUM(CASE WHEN ApplicantIncome IS NULL THEN 1 ELSE 0 END) as missing_applicant_income,
    SUM(CASE WHEN CoapplicantIncome IS NULL THEN 1 ELSE 0 END) as missing_coapplicant_income,
    SUM(CASE WHEN LoanAmount IS NULL THEN 1 ELSE 0 END) as missing_loan_amount,
    SUM(CASE WHEN Loan_Amount_Term IS NULL THEN 1 ELSE 0 END) as missing_loan_term,
    SUM(CASE WHEN Credit_History IS NULL THEN 1 ELSE 0 END) as missing_credit_history,
    SUM(CASE WHEN Property_Area IS NULL OR Property_Area = '' THEN 1 ELSE 0 END) as missing_property_area
FROM loan_raw;

-- ============================================
-- Step 3: Create cleaned table with imputation
-- ============================================

DROP TABLE IF EXISTS loan_cleaned;

CREATE TABLE loan_cleaned AS
SELECT 
    Loan_ID,
    
    -- Gender: Fill missing with 'Unknown'
    CASE 
        WHEN Gender IS NULL OR Gender = '' THEN 'Unknown'
        ELSE Gender 
    END as Gender,
    
    -- Married: Fill missing with 'Unknown'
    CASE 
        WHEN Married IS NULL OR Married = '' THEN 'Unknown'
        ELSE Married 
    END as Married,
    
    -- Dependents: Convert 3+ to 3, fill missing with 0
    CASE 
        WHEN Dependents IS NULL OR Dependents = '' THEN '0'
        WHEN Dependents = '3+' THEN '3'
        ELSE Dependents 
    END as Dependents,
    
    -- Convert to numeric for analysis
    CASE 
        WHEN Dependents IS NULL OR Dependents = '' THEN 0
        WHEN Dependents = '3+' THEN 3
        ELSE CAST(Dependents AS INTEGER)
    END as Dependents_Num,
    
    -- Education: Fill missing with mode (Graduate is most common)
    CASE 
        WHEN Education IS NULL OR Education = '' THEN 'Graduate'
        ELSE Education 
    END as Education,
    
    -- Self_Employed: Fill missing with 'No' (most common)
    CASE 
        WHEN Self_Employed IS NULL OR Self_Employed = '' THEN 'No'
        ELSE Self_Employed 
    END as Self_Employed,
    
    -- ApplicantIncome: Keep as is (no nulls expected, but handle 0)
    COALESCE(ApplicantIncome, 0) as ApplicantIncome,
    
    -- CoapplicantIncome: Keep as is
    COALESCE(CoapplicantIncome, 0) as CoapplicantIncome,
    
    -- Total Income: Derived field
    COALESCE(ApplicantIncome, 0) + COALESCE(CoapplicantIncome, 0) as TotalIncome,
    
    -- LoanAmount: Fill with median (128 from visual inspection)
    COALESCE(LoanAmount, 128) as LoanAmount,
    
    -- Loan_Amount_Term: Fill with 360 (most common)
    COALESCE(Loan_Amount_Term, 360) as Loan_Amount_Term,
    
    -- Credit_History: Fill missing with 1 (most have credit history)
    COALESCE(Credit_History, 1) as Credit_History,
    
    -- Property_Area: Fill missing with 'Semiurban' (most common)
    CASE 
        WHEN Property_Area IS NULL OR Property_Area = '' THEN 'Semiurban'
        ELSE Property_Area 
    END as Property_Area,
    
    -- ============================================
    -- DERIVED FIELDS FOR ANALYSIS
    -- ============================================
    
    -- Income Category
    CASE 
        WHEN (COALESCE(ApplicantIncome, 0) + COALESCE(CoapplicantIncome, 0)) < 4000 THEN 'Low Income'
        WHEN (COALESCE(ApplicantIncome, 0) + COALESCE(CoapplicantIncome, 0)) < 8000 THEN 'Medium Income'
        ELSE 'High Income'
    END as Income_Category,
    
    -- Loan Amount Category
    CASE 
        WHEN COALESCE(LoanAmount, 128) < 100 THEN 'Small Loan'
        WHEN COALESCE(LoanAmount, 128) < 200 THEN 'Medium Loan'
        ELSE 'Large Loan'
    END as Loan_Category,
    
    -- Loan to Income Ratio (monthly)
    CASE 
        WHEN (COALESCE(ApplicantIncome, 0) + COALESCE(CoapplicantIncome, 0)) > 0 
        THEN ROUND(
            CAST(COALESCE(LoanAmount, 128) * 1000 AS REAL) / 
            (COALESCE(ApplicantIncome, 0) + COALESCE(CoapplicantIncome, 0)),
            2
        )
        ELSE NULL 
    END as Loan_to_Income_Ratio,
    
    -- Monthly Payment Estimate (simple calculation)
    CASE 
        WHEN COALESCE(Loan_Amount_Term, 360) > 0
        THEN ROUND(
            CAST(COALESCE(LoanAmount, 128) * 1000 AS REAL) / 
            COALESCE(Loan_Amount_Term, 360),
            2
        )
        ELSE NULL
    END as Estimated_Monthly_Payment,
    
    -- Income to Payment Ratio
    CASE 
        WHEN COALESCE(Loan_Amount_Term, 360) > 0 
        AND (COALESCE(ApplicantIncome, 0) + COALESCE(CoapplicantIncome, 0)) > 0
        THEN ROUND(
            (CAST(COALESCE(LoanAmount, 128) * 1000 AS REAL) / COALESCE(Loan_Amount_Term, 360)) /
            (COALESCE(ApplicantIncome, 0) + COALESCE(CoapplicantIncome, 0)) * 100,
            2
        )
        ELSE NULL
    END as Payment_to_Income_Pct,
    
    -- Has Coapplicant Income?
    CASE 
        WHEN COALESCE(CoapplicantIncome, 0) > 0 THEN 'Yes'
        ELSE 'No'
    END as Has_Coapplicant_Income,
    
    -- Credit Score Category
    CASE 
        WHEN COALESCE(Credit_History, 1) = 1 THEN 'Good Credit'
        ELSE 'Poor/No Credit'
    END as Credit_Category

FROM loan_raw;

-- ============================================
-- Step 4: Data Quality Report
-- ============================================

SELECT 'Data Cleaning Complete!' as Status;

SELECT 
    'Records in cleaned table' as Metric,
    COUNT(*) as Value
FROM loan_cleaned;

-- Verify no missing critical values
SELECT 
    'Records with missing Loan Amount' as Check_Type,
    SUM(CASE WHEN LoanAmount IS NULL THEN 1 ELSE 0 END) as Count
FROM loan_cleaned
UNION ALL
SELECT 
    'Records with missing Income',
    SUM(CASE WHEN TotalIncome = 0 THEN 1 ELSE 0 END)
FROM loan_cleaned;

-- ============================================
-- Step 5: Summary Statistics
-- ============================================

DROP TABLE IF EXISTS loan_summary;

CREATE TABLE loan_summary AS
SELECT 
    'All Applicants' as Segment,
    COUNT(*) as Total_Count,
    ROUND(AVG(ApplicantIncome), 2) as Avg_Applicant_Income,
    ROUND(AVG(CoapplicantIncome), 2) as Avg_Coapplicant_Income,
    ROUND(AVG(TotalIncome), 2) as Avg_Total_Income,
    ROUND(AVG(LoanAmount), 2) as Avg_Loan_Amount,
    ROUND(AVG(Loan_to_Income_Ratio), 2) as Avg_Loan_to_Income_Ratio,
    ROUND(SUM(CASE WHEN Credit_History = 1 THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) as Pct_Good_Credit
FROM loan_cleaned;

-- ============================================
-- Step 6: Analysis Views for Power BI
-- ============================================

-- Demographics by Gender
DROP VIEW IF EXISTS demographics_by_gender;
CREATE VIEW demographics_by_gender AS
SELECT 
    Gender,
    COUNT(*) as Application_Count,
    ROUND(AVG(TotalIncome), 2) as Avg_Total_Income,
    ROUND(AVG(LoanAmount), 2) as Avg_Loan_Amount,
    ROUND(AVG(Loan_to_Income_Ratio), 2) as Avg_LTI_Ratio,
    ROUND(SUM(CASE WHEN Credit_History = 1 THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) as Pct_Good_Credit
FROM loan_cleaned
GROUP BY Gender
ORDER BY Application_Count DESC;

-- Demographics by Education
DROP VIEW IF EXISTS demographics_by_education;
CREATE VIEW demographics_by_education AS
SELECT 
    Education,
    COUNT(*) as Application_Count,
    ROUND(AVG(TotalIncome), 2) as Avg_Total_Income,
    ROUND(AVG(LoanAmount), 2) as Avg_Loan_Amount,
    ROUND(AVG(Loan_to_Income_Ratio), 2) as Avg_LTI_Ratio,
    ROUND(SUM(CASE WHEN Credit_History = 1 THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) as Pct_Good_Credit
FROM loan_cleaned
GROUP BY Education;

-- Demographics by Property Area
DROP VIEW IF EXISTS demographics_by_property;
CREATE VIEW demographics_by_property AS
SELECT 
    Property_Area,
    COUNT(*) as Application_Count,
    ROUND(AVG(TotalIncome), 2) as Avg_Total_Income,
    ROUND(AVG(LoanAmount), 2) as Avg_Loan_Amount,
    ROUND(AVG(Loan_to_Income_Ratio), 2) as Avg_LTI_Ratio,
    ROUND(SUM(CASE WHEN Credit_History = 1 THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) as Pct_Good_Credit
FROM loan_cleaned
GROUP BY Property_Area
ORDER BY Application_Count DESC;

-- Income Category Analysis
DROP VIEW IF EXISTS analysis_by_income;
CREATE VIEW analysis_by_income AS
SELECT 
    Income_Category,
    COUNT(*) as Application_Count,
    MIN(TotalIncome) as Min_Income,
    ROUND(AVG(TotalIncome), 2) as Avg_Income,
    MAX(TotalIncome) as Max_Income,
    ROUND(AVG(LoanAmount), 2) as Avg_Loan_Amount,
    ROUND(AVG(Loan_to_Income_Ratio), 2) as Avg_LTI_Ratio
FROM loan_cleaned
GROUP BY Income_Category
ORDER BY 
    CASE Income_Category 
        WHEN 'Low Income' THEN 1 
        WHEN 'Medium Income' THEN 2 
        WHEN 'High Income' THEN 3 
    END;

-- Credit History Analysis
DROP VIEW IF EXISTS analysis_by_credit;
CREATE VIEW analysis_by_credit AS
SELECT 
    Credit_Category,
    COUNT(*) as Application_Count,
    ROUND(AVG(TotalIncome), 2) as Avg_Total_Income,
    ROUND(AVG(LoanAmount), 2) as Avg_Loan_Amount,
    ROUND(AVG(Loan_to_Income_Ratio), 2) as Avg_LTI_Ratio
FROM loan_cleaned
GROUP BY Credit_Category;

-- Marital Status Analysis
DROP VIEW IF EXISTS analysis_by_marital_status;
CREATE VIEW analysis_by_marital_status AS
SELECT 
    Married,
    COUNT(*) as Application_Count,
    ROUND(AVG(TotalIncome), 2) as Avg_Total_Income,
    ROUND(AVG(LoanAmount), 2) as Avg_Loan_Amount,
    ROUND(SUM(CASE WHEN Has_Coapplicant_Income = 'Yes' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) as Pct_With_Coapplicant
FROM loan_cleaned
WHERE Married != 'Unknown'
GROUP BY Married;

-- Employment Status Analysis
DROP VIEW IF EXISTS analysis_by_employment;
CREATE VIEW analysis_by_employment AS
SELECT 
    Self_Employed,
    COUNT(*) as Application_Count,
    ROUND(AVG(TotalIncome), 2) as Avg_Total_Income,
    ROUND(AVG(LoanAmount), 2) as Avg_Loan_Amount,
    ROUND(SUM(CASE WHEN Credit_History = 1 THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) as Pct_Good_Credit
FROM loan_cleaned
WHERE Self_Employed != 'Unknown'
GROUP BY Self_Employed;

-- Dependents Analysis
DROP VIEW IF EXISTS analysis_by_dependents;
CREATE VIEW analysis_by_dependents AS
SELECT 
    Dependents,
    COUNT(*) as Application_Count,
    ROUND(AVG(TotalIncome), 2) as Avg_Total_Income,
    ROUND(AVG(LoanAmount), 2) as Avg_Loan_Amount,
    ROUND(AVG(Payment_to_Income_Pct), 2) as Avg_Payment_to_Income_Pct
FROM loan_cleaned
GROUP BY Dependents
ORDER BY Dependents_Num;

-- ============================================
-- Step 7: Risk Segmentation
-- ============================================

DROP VIEW IF EXISTS risk_segments;
CREATE VIEW risk_segments AS
SELECT 
    Loan_ID,
    Gender,
    Married,
    Education,
    TotalIncome,
    LoanAmount,
    Credit_History,
    Loan_to_Income_Ratio,
    Payment_to_Income_Pct,
    -- Risk Score (simple heuristic)
    CASE 
        WHEN Credit_History = 0 THEN 'High Risk'
        WHEN Payment_to_Income_Pct > 40 THEN 'High Risk'
        WHEN Loan_to_Income_Ratio > 5 THEN 'Medium-High Risk'
        WHEN Payment_to_Income_Pct > 30 THEN 'Medium Risk'
        WHEN Loan_to_Income_Ratio > 3 THEN 'Medium-Low Risk'
        ELSE 'Low Risk'
    END as Risk_Category
FROM loan_cleaned;

-- Risk Distribution
SELECT 
    Risk_Category,
    COUNT(*) as Count,
    ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM loan_cleaned), 2) as Percentage
FROM risk_segments
GROUP BY Risk_Category
ORDER BY Count DESC;

-- ============================================
-- DONE! All tables and views ready for Power BI
-- ============================================

SELECT '✅ Data cleaning complete!' as Status;
SELECT 'Main table: loan_cleaned' as Info;
SELECT 'Analysis views created: 8' as Info;
SELECT 'Ready for Power BI visualization!' as Info;