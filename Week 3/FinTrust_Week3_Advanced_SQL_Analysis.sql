/*
================================================================================
FinTrust Week 3 — Part B: Advanced SQL Analysis
Data Analytics Track | Miancy (Mercy Chepkemoi Koech)
Environment: Microsoft SQL Server (SSMS) — Database: FINTRUST DATABASES
Tables: dbo.FinTrust_Customer_Data (1,500 rows) | dbo.FinTrust_Transaction_Data (12,000 rows)

This file extends the Week 2 SQL analysis with 8 deeper analyses, each using
at least one advanced technique (CTE, window function, subquery, or
multi-dimensional CASE/GROUP BY). Queries 1-3 directly address the gaps
identified in Part A (Gap Analysis). Queries 4-8 add further business depth.

NOTE: As documented in Week 2, Risk_Review_Flag and International_Transaction
are stored as bit (1/0) in SQL Server due to the Import Wizard's auto-typing.
Queries below compare against 1/0 accordingly, NOT the string 'Yes'/'No'.
================================================================================
*/


-- ============================================================
-- QUESTION 1 (addresses Gap #2: failures never broken down further)
-- Where do failed/reversed transactions concentrate — by Channel AND
-- Transaction_Type together?
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
USSD + Cash Withdrawal      | 100 txns | 10 failed/reversed | 10.00%
USSD + Deposit              | 130 txns | 13 failed/reversed | 10.00%
USSD + Airtime/Data         |  92 txns |  9 failed/reversed |  9.78%
Web + Cash Withdrawal       | 229 txns | 22 failed/reversed |  9.61%
Mobile App + Airtime/Data   | 514 txns | 48 failed/reversed |  9.34%
POS + Bill Payment          | 291 txns | 27 failed/reversed |  9.28%
Mobile App + Card Purchase  |1263 txns |116 failed/reversed |  9.18%

BUSINESS INTERPRETATION:
Failures are NOT evenly spread — USSD combinations show the highest
failure/reversal rates (~10%), notably higher than the ~8% overall average
found in Week 2. This directly answers the gap identified in Part A: the
friction is concentrated in USSD transactions specifically, which likely
reflects the channel's more limited connectivity/reliability compared to
Mobile App or Web. FinTrust should prioritize USSD platform reliability
improvements, even though USSD carries the lowest overall transaction volume.
*/


-- ============================================================
-- QUESTION 2 (addresses Gap #1: monthly trend was too coarse)
-- Does transaction activity vary by day of week?
-- ============================================================
SELECT DATENAME(WEEKDAY, Transaction_DateTime) AS Day_Of_Week,
       COUNT(*) AS Txn_Count,
       SUM(Amount_NGN) AS Total_Value
FROM dbo.FinTrust_Transaction_Data
GROUP BY DATENAME(WEEKDAY, Transaction_DateTime)
ORDER BY Txn_Count DESC;

/*
RESULT:
Saturday  | 1,734 | 86,263,695.17
Sunday    | 1,734 | 77,205,386.41
Thursday  | 1,733 | 81,785,423.79
Tuesday   | 1,733 | 78,717,126.24
Friday    | 1,732 | 84,254,979.16
Monday    | 1,732 | 77,379,989.44
Wednesday | 1,602 | 74,870,754.64

BUSINESS INTERPRETATION:
This directly addresses the gap from Week 2's coarse 3-month trend. Volume
is remarkably even across the week (1,602-1,734 transactions/day) — there is
NO strong weekday/weekend split, which is somewhat unexpected for a retail
banking platform. Wednesday is marginally the lowest for both volume and
value, but the difference (~8% below the average day) is modest, not a
dramatic anomaly. This suggests the earlier Jan-Mar monthly dip (Week 2,
Feb) is NOT explained by a recurring weekly pattern — it is more likely a
month-level fluctuation, supporting the Week 2 documentation's note that
3 months of data is insufficient to confirm seasonality.
*/


-- ============================================================
-- QUESTION 3 (addresses Gap #3: risk factors analyzed in isolation only)
-- Do risk factors compound? Is the combination of international
-- transaction + high-risk channel (Web/ATM) riskier than either alone?
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
International + Web/ATM        |   132 |  53 flagged | 40.15%
International + Other Channel  |   348 | 124 flagged | 35.63%
Domestic + Web/ATM              | 3,484 | 716 flagged | 20.55%
Domestic + Other Channel        | 8,036 |1,459 flagged | 18.16%

BUSINESS INTERPRETATION:
Risk factors DO compound. International transactions specifically on
Web/ATM channels hit a 40.15% risk rate — higher than international
transactions alone (36.88% from Week 2) and far higher than domestic
transactions on any channel (18-21%). This refines the Week 2 finding:
it's not just "international transactions are risky" — the combination of
international status with certain channels is the sharpest risk signal.
This should directly inform a compound risk rule (e.g. auto-flag or
prioritize for manual review any international transaction on Web or ATM).
*/


-- ============================================================
-- QUESTION 4 (Customer-level transaction frequency — CTE + window function)
-- Which customers transact most frequently and generate the most spend?
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
RESULT (top 5 of 1,500):
FT-C01075 | 10 txns | 1,713,942.51 | Rank 1
FT-C00357 | 18 txns | 1,713,516.28 | Rank 2
FT-C00816 | 17 txns | 1,611,209.24 | Rank 3
FT-C00690 | 12 txns | 1,522,279.61 | Rank 4
FT-C00023 | 11 txns | 1,440,772.53 | Rank 5

Overall per-customer stats: min 1 txn, max 20 txns, avg 8.0 txns/customer;
min spend 615.15, max spend 1,713,942.51, avg spend 373,651.57.

BUSINESS INTERPRETATION:
The top-spending customer (FT-C01075) achieves the highest total spend with
only 10 transactions — notably fewer than FT-C00357's 18 transactions for a
nearly identical total. This shows spend and frequency are NOT the same
thing: some high-value customers transact rarely but in large amounts,
while others reach similar totals through many smaller transactions. FinTrust
could use this to distinguish "high-frequency, moderate-value" customers
from "low-frequency, high-value" customers for different engagement
strategies (e.g. loyalty programs vs. premium relationship management).
*/


-- ============================================================
-- QUESTION 5 (High-value transaction patterns — window function/NTILE)
-- Do the highest-value transactions (top 1%) carry different risk than
-- the rest?
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
Top 1% by Value | 120 txns    | Avg ₦518,389.74 | 43 flagged  | 35.83%
Remaining 99%    | 11,880 txns | Avg ₦41,941.97  | 2,309 flagged | 19.44%

BUSINESS INTERPRETATION:
The highest-value transactions (top 1%, averaging over ₦500,000) are
flagged for risk review at nearly double the rate of all other transactions
(35.83% vs 19.44%) — a pattern independent of, and compounding with, the
international-transaction finding. This confirms transaction value itself
is a strong, standalone risk indicator, reinforcing that FinTrust's current
risk-review process is already reasonably well-calibrated to flag large
transactions, and this signal should be preserved/strengthened in any
future automated risk model.
*/


-- ============================================================
-- QUESTION 6 (Trend analysis — running total via window function)
-- What does the cumulative transaction value trend look like month
-- over month?
-- ============================================================
WITH Monthly AS (
    SELECT FORMAT(Transaction_DateTime, 'yyyy-MM') AS Txn_Month, SUM(Amount_NGN) AS Monthly_Value
    FROM dbo.FinTrust_Transaction_Data
    GROUP BY FORMAT(Transaction_DateTime, 'yyyy-MM')
)
SELECT Txn_Month, Monthly_Value,
       SUM(Monthly_Value) OVER (ORDER BY Txn_Month) AS Running_Total
FROM Monthly
ORDER BY Txn_Month;

/*
RESULT:
2026-01 | 188,489,400 | Running Total: 188,489,400
2026-02 | 175,786,900 | Running Total: 364,276,300
2026-03 | 196,201,000 | Running Total: 560,477,400

BUSINESS INTERPRETATION:
The running total confirms the overall ₦560.48M figure builds steadily
across all 3 months with no single month dominating disproportionately.
Combined with Q2's finding (no strong weekly pattern), this suggests the
Feb dip is most plausibly a genuine (if moderate) month-level fluctuation
rather than a data quality issue or a recurring weekly effect. FinTrust
should continue tracking this running total as a simple, board-ready
growth indicator going into Week 4.
*/


-- ============================================================
-- QUESTION 7 (Customer segment x transaction type matrix — CASE + JOIN)
-- How does spending by transaction type differ across customer segments?
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

BUSINESS INTERPRETATION:
Transfer is the dominant transaction type across EVERY segment, not just
in aggregate — confirming this is a universal behaviour rather than an
artifact of the Everyday segment's large size. Notably, Premium and
Student segments have nearly identical Transfer values (₦45.3M vs ₦43.5M)
despite Premium typically being assumed to be the "higher value" segment
— this nuance would be lost without breaking value down by segment AND
transaction type together.
*/


-- ============================================================
-- QUESTION 8 (High-value customer identification — subquery)
-- Which segments contain the most "above-average spender" customers?
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
RESULT (605 total customers out of 1,500 qualify as "above-average spenders"):
Everyday | 281 customers
Student  | 117 customers
Premium  | 108 customers
SME      |  99 customers

BUSINESS INTERPRETATION:
Even among "above-average spenders" (customers whose average transaction
exceeds the platform-wide average), Everyday still leads in raw count
(281) — but as a PROPORTION of segment size, this is only ~40% of Everyday
customers (281/711), while Premium's 108 represents ~37% of Premium
customers (108/295) — very similar proportions. This means high-value
spending behaviour is NOT concentrated differently across segments in
relative terms, reinforcing Week 2's finding that segment alone is a weak
differentiator — for value OR risk. FinTrust should look to transaction-
level factors (channel, type, international status) rather than segment
membership when targeting either premium engagement or risk review.
*/


-- ============================================================
-- SUMMARY OF KEY FINDINGS FROM ADVANCED ANALYSIS
-- ============================================================
/*
1. USSD transactions show the highest failure/reversal rates (~10%) when
   broken down by channel + type — a specific, actionable reliability gap.
2. No strong day-of-week pattern exists — the Week 2 monthly dip is likely
   a genuine month-level fluctuation, not a recurring weekly effect.
3. Risk factors COMPOUND: international transactions on Web/ATM specifically
   reach a 40.15% risk rate, the highest combination found across the project.
4. Spend and transaction frequency are distinct customer behaviours — some
   high-value customers transact rarely but in large amounts.
5. Transaction value itself is a strong risk indicator — top 1% by value
   are flagged at nearly double the rate of all other transactions.
6. The monthly running total confirms steady growth with no single month
   dominating — supporting the "moderate fluctuation" read on Feb's dip.
7. Transfer dominates spending in EVERY segment, not just in aggregate.
8. High-value spending behaviour is proportionally similar across all
   segments (~37-40%) — reinforcing that segment alone is a weak
   differentiator for both risk and value.
*/
