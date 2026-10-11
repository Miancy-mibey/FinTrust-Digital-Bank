# FinTrust Digital Bank: Experience Lab Project

## Project Overview
This repository documents my work on the **FinTrust Digital Bank Experience Lab** project, a 4-week internship project under **AnalystLab Africa**. FinTrust is a fictional digital bank, and the project uses synthetic customer and transaction data for educational purposes.

**My track:** Data Analytics

The goal was to turn FinTrust's customer and transaction data into business intelligence that supports management decisions, risk monitoring and digital customer support, through SQL analysis, Python analysis and Power BI dashboards.

## Repository Structure
```
FinTrust-Digital-Bank/
├── Week 1/   Understand and Plan: business understanding, data profiling, analytical questions, KPI plan, dashboard wireframe
├── Week 2/   Execute: data quality workbook, SQL analysis, Python EDA, Power BI dashboard, business findings
├── Week 3/   Advanced BI: gap analysis, advanced SQL (CTEs, window functions), advanced Python, expanded dashboard, validated findings
└── Week 4/   Final solution: final SQL, notebook, dashboard, insights, validation evidence, project documentation
```

## Week 4 Deliverables
| Deliverable | File |
|---|---|
| Final Power BI dashboard (2 pages) | `FinTrust_Week4_Final_Dashboard.pbix` |
| Final SQL scripts | `FinTrust_Week4_Final_SQL_Analysis.sql` |
| SQL data repair (see Data Note) | `FinTrust_SQL_Amount_Repair.sql` |
| Final Python notebook | `Fintrust_Week2_Data_Analysis.ipynb` + two CSV snapshots |
| Final business insights and recommendations | `FinTrust_Week4_PartD_Final_Business_Insights.pdf` |
| Validation evidence | `FinTrust_Week4_PartE_Final_Validation.pdf`, `FinTrust_Week4_Validation_Checks.py`, `FinTrust_Week4_Validation_Output.txt` |
| Review of Weeks 1-3 | `FinTrust_Week4_PartA_Final_Review.pdf` |
| KPI, data quality and final documentation | `FinTrust_Week4_Final_Project_Documentation.pdf` |

## Key Findings
Each finding was validated against the raw data with significance tests.
- **International transactions are flagged for risk review about twice as often:** 36.9% vs 18.9% for domestic.
- **Risk-review rate rises with transaction value:** about 18% below NGN 50K, 41% above NGN 250K.
- **About 8% of transactions fail or reverse, in every channel** (ATM 6.9% to USSD 8.7%), which points to a platform-wide reliability issue rather than one weak channel.
- **Customer segments differ in size, not behaviour:** spend per customer is similar in every segment (NGN 365K to 388K).
- **Mobile App carries 42.5% of transactions and Transfer carries 42.4% of value.**
- **The February dip is a calendar effect:** February has 28 days, and daily activity is flat to slightly rising.

Three conclusions from earlier weeks changed after validation (ATM + International as the top risk hotspot, failures concentrated in USSD, and the February dip). They are documented in the Part E validation file.

## Tools Used
Excel, SQL Server (SSMS), Python (Pandas, NumPy, SciPy, Matplotlib, Seaborn, Jupyter in VS Code), Power BI

## How to Reproduce
1. **SQL:** import the two CSVs into SQL Server, then run `FinTrust_SQL_Amount_Repair.sql` (see Data Note). Run `FinTrust_Week4_Final_SQL_Analysis.sql`.
2. **Notebook:** open `Fintrust_Week2_Data_Analysis.ipynb`. It reads from SQL Server, or from the two `_export.csv` snapshots if no database is available. Keep the snapshots in the same folder as the notebook.
3. **Validation:** place the two raw CSVs next to `FinTrust_Week4_Validation_Checks.py`, run `pip install pandas numpy scipy`, then run the script. Its saved output is in `FinTrust_Week4_Validation_Output.txt`.

## Data
The datasets (`FinTrust_Customer_Data`, `FinTrust_Transaction_Data`) are **synthetic**, created by AnalystLab Africa for educational purposes. They do not represent real customers or transactions.

- Customer_Data: 1,500 customers (1,501 rows including the header)
- Transaction_Data: 12,000 transactions (12,001 rows including the header), January to March 2026

**Data note:** when I imported the transaction file into SQL Server, 128 transactions with whole-number amounts were imported as NULL, so the SQL total was 554.16M against 560.48M in the CSV. I found this by reconciling totals and fixed it with the repair script. Row counts and rates were never affected.

## Limitations
- Three months of data, so seasonality and long-term trends cannot be assessed
- Synthetic data
- The risk flag marks transactions sent for review, not confirmed fraud
- No failure-reason field, so the analysis shows how often transactions fail but not why
- International transactions number 480, so breakdowns within them are small-sample
- The analysis shows association, not cause

## Status
✅ Weeks 1 to 4 complete.

