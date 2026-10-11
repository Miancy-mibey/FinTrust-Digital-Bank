/*
================================================================================
FinTrust Week 4 — Part B: Final SQL Analysis
Data Analytics Track | Miancy (Mercy Chepkemoi Koech)
Environment: Microsoft SQL Server (SSMS) — Database: FINTRUST DATABASES
Tables: dbo.FinTrust_Customer_Data (1,500 rows) | dbo.FinTrust_Transaction_Data (12,000 rows)

PURPOSE OF THIS FILE:
Weeks 2 and 3 produced 16 SQL analyses in total (8 foundational + 8 advanced).
This file reviews that full body of work and selects the 8 most important,
business-critical queries as FinTrust's final analytical output — refined for
clarity and, in one case (Query 1), enhanced with an additional technique.
Together, these 8 queries deliberately demonstrate every required SQL
technique: JOIN, GROUP BY, CASE, aggregations, a subquery, CTEs, and window
functions.

NOTE ON THE AMOUNT_NGN IMPORT (found in Week 4):
128 transactions with whole-number amounts were imported as NULL (total NGN
6,320,246) and the column was stored as float. Run FinTrust_SQL_Amount_Repair.sql
first. After the repair, SUM(Amount_NGN) is 560,477,355.91 (NGN 1.06 above the CSV
total because of float rounding in the original import). The
results in this file are the raw-CSV figures. Counts and rates were never
affected.

NOTE ON DATA TYPES (carried forward from Week 2/3, still valid):
Risk_Review_Flag and International_Transaction are stored as SQL Server
'bit' columns (1/0), not the string 'Yes'/'No' from the raw CSV. All
queries below compare against 1/0 accordingly.
================================================================================
*/


-- ============================================================
-- QUERY 1 — Customer Segment Value & Share of Total
-- Techniques: JOIN · GROUP BY · Aggregation · Window Function
-- Refined for Week 4: added Pct_Of_Total_Value using SUM() OVER(),
-- so segment value is shown both in absolute and relative terms —
-- a small enhancement over the Week 2 original.
-- ============================================================
SELECT c.Customer_Segment,
       SUM(t.Amount_NGN) AS Total_Value,
       COUNT(*) AS Txn_Count,
       CAST(SUM(t.Amount_NGN) * 100.0 / SUM(SUM(t.Amount_NGN)) OVER() AS DECIMAL(5,2)) AS Pct_Of_Total_Value
FROM dbo.FinTrust_Transaction_Data t
JOIN dbo.FinTrust_Customer_Data c ON t.Customer_ID = c.Customer_ID
GROUP BY c.Customer_Segment
ORDER BY Total_Value DESC;

/*
RESULT (verified against the raw CSVs, total NGN 560,477,354.85):
Everyday | 261,458,920.99 | 5,644 | 46.65%
Premium  | 107,751,195.82 | 2,361 | 19.22%
Student  | 107,475,866.33 | 2,289 | 19.18%
SME      |  83,791,371.71 | 1,706 | 14.95%

WHAT IT REVEALS:
Everyday customers generate 46.65% of transaction value, roughly in line
with their 47.4% share of customers (711 of 1,500). The lead comes from
headcount, not higher spend: value per customer is similar in every segment
(about NGN 365K to 388K). FinTrust's value base is broad and mass-market,
so reliability investment should be judged by customer numbers rather than
by assuming any one segment is more valuable per head.
*/


-- ============================================================
-- QUERY 2 — International vs. Domestic Risk Rate
-- Techniques: GROUP BY · CASE · Aggregation
-- The single strongest standalone risk signal found across the project.
-- ============================================================
SELECT International_Transaction,
       SUM(CASE WHEN Risk_Review_Flag = 1 THEN 1 ELSE 0 END) AS Flagged,
       COUNT(*) AS Total,
       CAST(SUM(CASE WHEN Risk_Review_Flag = 1 THEN 1 ELSE 0 END) * 100.0 / COUNT(*) AS DECIMAL(5,2)) AS Risk_Rate_Pct
FROM dbo.FinTrust_Transaction_Data
GROUP BY International_Transaction;

/*
RESULT:
Domestic (0)      | 2,175 | 11,520 | 18.88%
International (1) |   177 |    480 | 36.88%

WHAT IT REVEALS:
International transactions are flagged at nearly double the domestic rate
— despite making up under 4% of total volume. This is the clearest,
single most actionable risk signal in the dataset and should carry high
weight in any future automated risk-scoring model.
*/


-- ============================================================
-- QUERY 3 — Compound Risk: International Status × Channel
-- Techniques: CASE · GROUP BY · Aggregation
-- Tests whether international risk differs by channel group (Week 4 result: it does not).
-- ============================================================
SELECT
    CASE WHEN International_Transaction = 1 AND Channel IN ('Web','ATM') THEN 'International + Web/ATM'
         WHEN International_Transaction = 1 THEN 'International + Other Channel'
         WHEN Channel IN ('Web','ATM') THEN 'Domestic + Web/ATM'
         ELSE 'Domestic + Other Channel' END AS Risk_Combo,
    COUNT(*) AS Total_Txns,
    SUM(CASE WHEN Risk_Review_Flag = 1 THEN 1 ELSE 0 END) AS Flagged,
    CAST(SUM(CASE WHEN Risk_Review_Flag = 1 THEN 1 ELSE 0 END) * 100.0 / COUNT(*) AS DECIMAL(5,2)) AS Risk_Rate_Pct
FROM dbo.FinTrust_Transaction_Data
GROUP BY CASE WHEN International_Transaction = 1 AND Channel IN ('Web','ATM') THEN 'International + Web/ATM'
              WHEN International_Transaction = 1 THEN 'International + Other Channel'
              WHEN Channel IN ('Web','ATM') THEN 'Domestic + Web/ATM'
              ELSE 'Domestic + Other Channel' END
ORDER BY Risk_Rate_Pct DESC;

/*
RESULT:
International + Web/ATM       |   132 |  53 flagged | 40.15%
International + Other Channel |   348 | 124 flagged | 35.63%
Domestic + Web/ATM             | 3,484 | 716 flagged | 20.55%
Domestic + Other Channel       | 8,036 |1,459 flagged | 18.16%

WHAT IT REVEALS:
International status roughly doubles the risk rate in both channel groups
(about 1.95x for Web/ATM and 1.96x for other channels), so the effect is
consistent rather than compounding. Within international transactions, the
Web/ATM vs other-channel difference is not significant (40.15% vs 35.63%,
n = 132, chi-square p = 0.42). Web/ATM has a modestly higher domestic
baseline (20.55% vs 18.16%, p = 0.003). The supported rule: treat
international status as the risk driver, and do not single out a channel.
*/


-- ============================================================
-- QUERY 4 — Failure/Reversal Rate by Channel + Type
-- Techniques: GROUP BY · HAVING · CASE · Aggregation
-- ============================================================
SELECT Channel, Transaction_Type,
       COUNT(*) AS Total_Txns,
       SUM(CASE WHEN Transaction_Status IN ('Failed','Reversed') THEN 1 ELSE 0 END) AS Failed_Reversed,
       CAST(SUM(CASE WHEN Transaction_Status IN ('Failed','Reversed') THEN 1 ELSE 0 END) * 100.0 / COUNT(*) AS DECIMAL(5,2)) AS Fail_Rev_Rate_Pct
FROM dbo.FinTrust_Transaction_Data
GROUP BY Channel, Transaction_Type
HAVING COUNT(*) > 50
ORDER BY Fail_Rev_Rate_Pct DESC;

/*
RESULT (top rows):
USSD + Cash Withdrawal     | 100 txns | 10 failed/reversed | 10.00%
USSD + Deposit             | 130 txns | 13 failed/reversed | 10.00%
USSD + Airtime/Data        |  92 txns |  9 failed/reversed |  9.78%
Web + Cash Withdrawal      | 229 txns | 22 failed/reversed |  9.61%

WHAT IT REVEALS:
The highest channel-and-type combinations (USSD Cash Withdrawal and USSD
Deposit, 10.0%) sit only slightly above the platform average of 7.97%, and
these groups are small (100 and 130 transactions). The difference is within
normal variation (binomial p = 0.46 and 0.42), and failure rates across the
five channels are not significantly different (chi-square p = 0.07). Failure
and reversal is a platform-wide rate of about 8%, not a USSD-specific gap.
*/


-- ============================================================
-- QUERY 5 — Customer Spend Ranking
-- Techniques: CTE · Window Function (RANK)
-- ============================================================
WITH Customer_Txn_Summary AS (
    SELECT Customer_ID, COUNT(*) AS Txn_Count, SUM(Amount_NGN) AS Total_Spend
    FROM dbo.FinTrust_Transaction_Data
    GROUP BY Customer_ID
)
SELECT Customer_ID, Txn_Count, Total_Spend,
       RANK() OVER (ORDER BY Total_Spend DESC) AS Spend_Rank
FROM Customer_Txn_Summary
ORDER BY Spend_Rank;

/*
RESULT (top 2 of 1,500):
FT-C01075 | 10 txns | 1,713,942.51 | Rank 1
FT-C00357 | 18 txns | 1,713,516.28 | Rank 2
Overall: avg 8.0 txns/customer, avg spend NGN 373,651.57.

WHAT IT REVEALS:
Spend and frequency are not the same thing — the top-ranked customer
reaches the highest total with fewer transactions than the second-ranked
customer. FinTrust can use this to distinguish "high-frequency, moderate-
value" customers from "low-frequency, high-value" customers, which calls
for different engagement strategies (loyalty programs vs. relationship
management) rather than one-size-fits-all segmentation.
*/


-- ============================================================
-- QUERY 6 — High-Value Transaction Risk (Top 1%)
-- Techniques: CTE · Window Function (NTILE)
-- ============================================================
WITH Ranked AS (
    SELECT *, NTILE(100) OVER (ORDER BY Amount_NGN DESC) AS Percentile_Bucket
    FROM dbo.FinTrust_Transaction_Data
)
SELECT CASE WHEN Percentile_Bucket = 1 THEN 'Top 1% by Value' ELSE 'Remaining 99%' END AS Value_Group,
       COUNT(*) AS Txn_Count,
       AVG(Amount_NGN) AS Avg_Value,
       SUM(CASE WHEN Risk_Review_Flag = 1 THEN 1 ELSE 0 END) AS Flagged,
       CAST(SUM(CASE WHEN Risk_Review_Flag = 1 THEN 1 ELSE 0 END) * 100.0 / COUNT(*) AS DECIMAL(5,2)) AS Risk_Rate_Pct
FROM Ranked
GROUP BY CASE WHEN Percentile_Bucket = 1 THEN 'Top 1% by Value' ELSE 'Remaining 99%' END;

/*
RESULT:
Top 1% by Value | 120 txns    | Avg NGN 518,389.74 | 43 flagged   | 35.83%
Remaining 99%    | 11,880 txns | Avg NGN 41,941.97  | 2,309 flagged | 19.44%

WHAT IT REVEALS:
Transaction value itself is a strong, standalone risk indicator — the
highest-value 1% of transactions are flagged at nearly double the rate of
everything else. This is independent of, and compounds with, the
international-transaction finding (Queries 2-3), confirming FinTrust's
existing risk process is reasonably well-calibrated to large transactions.
*/


-- ============================================================
-- QUERY 7 — Above-Average Spenders by Segment
-- Techniques: Subquery (correlated HAVING comparison) · JOIN · GROUP BY
-- ============================================================
SELECT c.Customer_Segment, COUNT(DISTINCT t.Customer_ID) AS High_Value_Customers
FROM dbo.FinTrust_Transaction_Data t
JOIN dbo.FinTrust_Customer_Data c ON t.Customer_ID = c.Customer_ID
WHERE t.Customer_ID IN (
    SELECT Customer_ID FROM dbo.FinTrust_Transaction_Data
    GROUP BY Customer_ID
    HAVING AVG(Amount_NGN) > (SELECT AVG(Amount_NGN) FROM dbo.FinTrust_Transaction_Data)
)
GROUP BY c.Customer_Segment
ORDER BY High_Value_Customers DESC;

/*
RESULT (605 of 1,500 customers qualify as "above-average spenders"):
Everyday | 281 customers (~40% of segment)
Student  | 117 customers (~42% of segment)
Premium  | 108 customers (~37% of segment)
SME      |  99 customers (~46% of segment)

WHAT IT REVEALS:
Even among above-average spenders, the proportion within each segment is
similar (~37-46%) — high-value spending behaviour is not concentrated
differently by segment. This confirms, via an independent method (a
subquery rather than normalized GROUP BY), that segment alone is a weak
differentiator for value, same as it is for risk (see Week 2 Query 6).
Targeting should use transaction-level behaviour, not segment membership.
*/


-- ============================================================
-- QUERY 8 — Segment × Transaction Type Matrix
-- Techniques: JOIN · CASE · GROUP BY · Aggregation
-- ============================================================
SELECT c.Customer_Segment,
       SUM(CASE WHEN t.Transaction_Type = 'Transfer' THEN t.Amount_NGN ELSE 0 END) AS Transfer_Value,
       SUM(CASE WHEN t.Transaction_Type = 'Card Purchase' THEN t.Amount_NGN ELSE 0 END) AS Card_Purchase_Value,
       SUM(CASE WHEN t.Transaction_Type = 'Deposit' THEN t.Amount_NGN ELSE 0 END) AS Deposit_Value,
       SUM(CASE WHEN t.Transaction_Type = 'Cash Withdrawal' THEN t.Amount_NGN ELSE 0 END) AS Cash_Withdrawal_Value
FROM dbo.FinTrust_Transaction_Data t
JOIN dbo.FinTrust_Customer_Data c ON t.Customer_ID = c.Customer_ID
GROUP BY c.Customer_Segment
ORDER BY Transfer_Value DESC;

/*
RESULT:
Everyday | Transfer 114,072,900 | Card Purchase 40,674,673 | Deposit 57,750,306 | Cash Withdrawal 30,919,044
Premium  | Transfer  45,319,780 | Card Purchase 15,957,705 | Deposit 26,008,510 | Cash Withdrawal 13,766,829
Student  | Transfer  43,512,170 | Card Purchase 15,051,758 | Deposit 27,948,712 | Cash Withdrawal 13,246,026
SME      | Transfer  35,011,840 | Card Purchase 14,179,277 | Deposit 19,277,531 | Cash Withdrawal  9,840,464

WHAT IT REVEALS:
Transfer dominates spending in every single segment, not just in
aggregate — a universal behaviour rather than an artifact of Everyday's
size. Premium and Student have nearly identical Transfer totals (NGN 45.3M
vs NGN 43.5M), despite Premium typically being assumed "higher value" —
a nuance only visible by breaking value down by segment AND type together.
*/


-- ============================================================
-- TECHNIQUE COVERAGE SUMMARY (Part B requirement)
-- ============================================================
/*
JOIN                : Queries 1, 7, 8
GROUP BY            : Queries 1, 2, 3, 4, 7, 8
CASE                : Queries 2, 3, 4, 6, 8
Aggregations        : All 8 queries (SUM, COUNT, AVG)
Subquery            : Query 7
CTE                 : Queries 5, 6
Window Functions    : Query 1 (SUM() OVER), Query 5 (RANK), Query 6 (NTILE)
*/


-- ============================================================
-- WHY THESE 8 WERE SELECTED AS FINAL
-- ============================================================
/*
Out of 16 total queries written across Weeks 2-3, these 8 were selected
because each either (a) drives a specific Week 4 business recommendation,
(b) demonstrates a required SQL technique not otherwise covered, or (c)
represents a finding that was independently validated by Python and/or
Power BI, making it safe to present as final. The remaining 8 queries
(transaction status breakdown, channel volume/value, dormancy rate,
channel-only risk rate, day-of-week pattern, monthly running total)
remain in the Week 2/3 files as supporting analysis but were not
duplicated here to keep the final set focused on the most decision-
relevant results.
*/
