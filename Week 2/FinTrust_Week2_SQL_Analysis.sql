/*
================================================================================
FinTrust Week 2 — SQL Business Analysis
Data Analytics Track | Miancy (Mercy Chepkemoi Koech)
Environment: Microsoft SQL Server (SSMS) — Database: FINTRUST DATABASES
Tables: dbo.FinTrust_Customer_Data (1,500 rows) | dbo.FinTrust_Transaction_Data (12,000 rows)

NOTE ON DATA TYPES: The Import Wizard auto-typed the Yes/No fields
(Risk_Review_Flag, International_Transaction) as SQL Server 'bit' columns
during CSV import. As a result, all queries below compare these fields to
1 (Yes/True) and 0 (No/False) rather than the string 'Yes'/'No' as they
appear in the raw CSV. This was a deliberate decision documented here rather
than altering the source file.
================================================================================
*/


-- ============================================================
-- QUESTION 1 (Customer Segments / Transaction Value)
-- Which customer segments generate the most transaction value?
-- ============================================================
SELECT c.Customer_Segment, SUM(t.Amount_NGN) AS Total_Value, COUNT(*) AS Txn_Count
FROM dbo.FinTrust_Transaction_Data t
JOIN dbo.FinTrust_Customer_Data c ON t.Customer_ID = c.Customer_ID
GROUP BY c.Customer_Segment
ORDER BY Total_Value DESC;

/*
RESULT:
Everyday   | 258,733,422.34 | 5,644
Student    | 106,786,672.45 | 2,289
Premium    | 105,989,296.88 | 2,361
SME        |  82,647,717.67 | 1,706

BUSINESS INTERPRETATION:
Everyday customers generate by far the most total transaction value —
more than the other three segments combined. This suggests FinTrust's
revenue base is broad and mass-market rather than concentrated in Premium
accounts, so retention strategies should prioritize the Everyday segment
even though Premium/SME customers may be individually higher-value.
*/


-- ============================================================
-- QUESTION 2 (Transaction Status)
-- What is the overall transaction success rate?
-- ============================================================
SELECT Transaction_Status, COUNT(*) AS Count,
       CAST(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER() AS DECIMAL(5,2)) AS Percentage
FROM dbo.FinTrust_Transaction_Data
GROUP BY Transaction_Status;

/*
RESULT:
Pending    |   188 | 1.57%
Reversed   |   326 | 2.72%
Failed     |   630 | 5.25%
Successful | 10,856 | 90.47%

BUSINESS INTERPRETATION:
90.47% of transactions succeed, but a combined 7.97% fail or get reversed
(5.25% Failed, 2.72% Reversed), plus 1.57% still Pending. A near-8%
failure/reversal rate is high enough to warrant investigation — it likely
represents real customer friction (failed payments, disputed transactions)
that could be driving support tickets or churn.
*/


-- ============================================================
-- QUESTION 3 (Transaction Channel)
-- Which channels are used most, and what's their average transaction value?
-- ============================================================
SELECT Channel, COUNT(*) AS Txn_Count, AVG(Amount_NGN) AS Avg_Value
FROM dbo.FinTrust_Transaction_Data
GROUP BY Channel
ORDER BY Txn_Count DESC;

/*
RESULT:
Mobile App | 5,102 | 47,115.51
POS        | 2,393 | 43,591.75
Web        | 1,869 | 47,829.84
ATM        | 1,747 | 47,944.31
USSD       |   889 | 47,559.13

BUSINESS INTERPRETATION:
Mobile App dominates both in volume (5,102 transactions) and ties for
highest average value — confirming FinTrust customers are primarily
digital-first. USSD has the lowest volume, which is worth noting since
USSD typically serves customers with limited smartphone/data access — a
potential financial-inclusion gap worth flagging.
*/


-- ============================================================
-- QUESTION 4 (Transaction Type)
-- Which transaction types are most common, and by what value?
-- ============================================================
SELECT Transaction_Type, COUNT(*) AS Count, SUM(Amount_NGN) AS Total_Value
FROM dbo.FinTrust_Transaction_Data
GROUP BY Transaction_Type
ORDER BY Count DESC;

/*
RESULT:
Transfer         | 3,549 | 235,517,961.50
Card Purchase    | 3,033 |  85,048,780.84
Bill Payment     | 1,475 |  27,988,083.48
Cash Withdrawal  | 1,430 |  66,813,392.14
Deposit          | 1,328 | 129,110,788.18
Airtime/Data     | 1,185 |   9,678,103.20

BUSINESS INTERPRETATION:
Transfers are both the most frequent and highest-value transaction type —
nearly double the next-largest category by value. This positions transfer
functionality as core to the platform's value proposition, meaning any
reliability issues there would have outsized business impact compared to
smaller-volume types like Airtime/Data.
*/


-- ============================================================
-- QUESTION 5 (Risk-Review Patterns / Channel)
-- Do certain channels have higher risk-flag rates?
-- ============================================================
SELECT Channel,
       SUM(CASE WHEN Risk_Review_Flag = 1 THEN 1 ELSE 0 END) AS Flagged,
       COUNT(*) AS Total,
       CAST(SUM(CASE WHEN Risk_Review_Flag = 1 THEN 1 ELSE 0 END) * 100.0 / COUNT(*) AS DECIMAL(5,2)) AS Risk_Rate_Pct
FROM dbo.FinTrust_Transaction_Data
GROUP BY Channel
ORDER BY Risk_Rate_Pct DESC;

/*
RESULT:
Web        | 399 | 1,869 | 21.35%
ATM        | 370 | 1,747 | 21.18%
Mobile App | 990 | 5,102 | 19.40%
POS        | 439 | 2,393 | 18.35%
USSD       | 154 |   889 | 17.32%

BUSINESS INTERPRETATION:
Web (21.35%) and ATM (21.18%) carry the highest risk-flag rates, while
USSD is lowest (17.32%). The spread is fairly narrow (17-21%), so channel
alone isn't a strong risk differentiator — risk drivers appear more tied
to transaction characteristics (e.g. domestic/international, see Q8) than
to the channel used.
*/


-- ============================================================
-- QUESTION 6 (Customer Segments / Risk-Review Patterns)
-- Do certain customer segments have a higher concentration of
-- flagged transactions, once normalized by transaction volume?
-- ============================================================
SELECT c.Customer_Segment,
       SUM(CASE WHEN t.Risk_Review_Flag = 1 THEN 1 ELSE 0 END) AS Flagged_Count,
       COUNT(*) AS Total_Txns,
       CAST(SUM(CASE WHEN t.Risk_Review_Flag = 1 THEN 1 ELSE 0 END) * 100.0 / COUNT(*) AS DECIMAL(5,2)) AS Risk_Rate_Pct
FROM dbo.FinTrust_Transaction_Data t
JOIN dbo.FinTrust_Customer_Data c ON t.Customer_ID = c.Customer_ID
GROUP BY c.Customer_Segment
ORDER BY Risk_Rate_Pct DESC;

/*
RESULT:
Premium  | 480   | 2,361 | 20.33%
Student  | 452   | 2,289 | 19.75%
SME      | 331   | 1,706 | 19.40%
Everyday | 1,089 | 5,644 | 19.29%

BUSINESS INTERPRETATION:
Once normalized by transaction volume, all four segments sit within a
tight ~1-point band (19.29%-20.33%) — segment is not a meaningful risk
differentiator. This is a notable finding on its own: Everyday's high
RAW flagged count (1,089, the largest of any segment) is purely a function
of having the most transactions, not because Everyday customers are
inherently riskier. Raw counts alone would have been misleading here;
normalizing by volume was a necessary and deliberate analytical decision.
*/


-- ============================================================
-- QUESTION 7 (Customer Behaviour / Account Status)
-- What percentage of customers are dormant or restricted?
-- ============================================================
SELECT Account_Status, COUNT(*) AS Count,
       CAST(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER() AS DECIMAL(5,2)) AS Percentage
FROM dbo.FinTrust_Customer_Data
GROUP BY Account_Status;

/*
RESULT:
Active     | 1,367 | 91.13%
Restricted |    26 |  1.73%
Dormant    |   107 |  7.13%

BUSINESS INTERPRETATION:
91.13% of customers are Active, with 7.13% Dormant and 1.73% Restricted.
A ~7% dormancy rate is a reasonable retention target — it represents real
customers who've disengaged and could be prioritized for a reactivation
campaign rather than being left inactive indefinitely.
*/


-- ============================================================
-- QUESTION 8 (Transaction Activity / Risk-Review Patterns)
-- Are international transactions riskier than domestic ones?
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

BUSINESS INTERPRETATION:
This is the standout finding of the analysis. International transactions
are flagged at 36.88% — nearly double the domestic rate of 18.88% —
despite representing a small share of total volume (480 vs 11,520). This
strongly supports weighting risk-monitoring resources more heavily toward
international transaction review, and treating international status as a
high-importance feature in any future risk-scoring model.
*/


-- ============================================================
-- SUMMARY OF KEY FINDINGS ACROSS ALL 8 QUESTIONS
-- ============================================================
/*
1. Everyday segment drives the most transaction value and volume — the
   business is mass-market, not premium-concentrated.
2. 90.47% transaction success rate; ~8% fail/reverse — a real
   operational friction point.
3. Mobile App is the dominant channel by a wide margin.
4. Transfers are the highest-value and most frequent transaction type.
5. Channel is a weak risk differentiator (17-21% range across all).
6. Customer segment is also a weak risk differentiator once normalized
   (~19-20% across all segments) — raw counts would have been misleading.
7. ~7% of customers are dormant — a clear retention opportunity.
8. International transactions are flagged at nearly 2x the domestic
   rate (36.88% vs 18.88%) — the strongest and most actionable risk
   signal in the entire dataset.
*/
