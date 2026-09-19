# FinTrust Business & Data Intelligence Assessment — Week 1
**Track:** Data Analytics
**Intern:** Miancy (Mercy Chepkemoi Koech)

---

## Part A — Business Understanding

**1. What business questions should FinTrust's management be able to answer?**
- How is the customer base performing across segments, account types, and cities?
- What transaction patterns are driving revenue and volume?
- Which channels are customers actually using, and are any underperforming?
- Where is risk exposure concentrated (which customers, channels, transaction types)?
- How many customers are dormant or at risk of churn, and who are they?
- How reliable is the transaction platform (failure/reversal rates)?

**2. What decisions could data analysis support?**
- Targeted retention or reactivation campaigns for dormant/low-engagement customers.
- Channel investment priorities (e.g. doubling down on Mobile App if it dominates usage).
- Risk monitoring resource allocation (which transaction types/channels need tighter review).
- Product and segment strategy (e.g. tailoring offers by income band or segment).
- Operational fixes where failed/reversed transactions cluster.

**3. What stakeholders could benefit from the analytical outputs?**
- **Executive management** — high-level performance and growth view.
- **Risk & compliance team** — risk-flag patterns and exposure monitoring.
- **Marketing/customer experience team** — segment and engagement insights.
- **Operations team** — transaction reliability and channel performance.
- **Product team** — account type and income-band trends to guide offerings.

---

## Part B — Data Understanding / Profiling Report

**Customer_Data** — 1,500 records, 12 columns

| Field | Type | Notes |
|---|---|---|
| Customer_ID | Text (key) | Format FT-C##### |
| Customer_Name | Text | Synthetic, not unique — not a reliable identifier |
| Age | Integer (numerical) | |
| Gender | Category | Male / Female / Prefer not to say |
| City | Category | Lagos, Kano, Abuja, Enugu, Kaduna, Ibadan, Port Harcourt, Benin City |
| Customer_Segment | Category | Premium, Everyday, SME, Student |
| Account_Type | Category | Savings, Current, Premium |
| Tenure_Months | Integer (numerical) | |
| Digital_Engagement_Score | Decimal (numerical) | 0–100 scale |
| Monthly_Income_Band | Category (ordinal) | Below 100k → 1m+ |
| Preferred_Channel | Category | Mobile App, Web, USSD |
| Account_Status | Category | Active, Dormant, Restricted |

**Transaction_Data** — 12,000 records, 11 columns

| Field | Type | Notes |
|---|---|---|
| Transaction_ID | Text (key) | Format FT-T###### |
| Customer_ID | Text (foreign key) | Links to Customer_Data |
| Transaction_DateTime | Date/time | |
| Transaction_Type | Category | Card Purchase, Cash Withdrawal, Transfer, Deposit, Airtime/Data, Bill Payment |
| Amount_NGN | Decimal (numerical) | Transaction value |
| Channel | Category | Mobile App, ATM, POS, Web, USSD |
| Device_Type | Category | Android, iOS, POS Terminal, ATM Terminal, Web Browser |
| Location | Category | Same cities as Customer_Data |
| International_Transaction | Category (binary) | Yes/No |
| Transaction_Status | Category | Successful, Failed, Reversed, Pending |
| Risk_Review_Flag | Category (binary) | Yes/No |

**Relationship between datasets:** One-to-many via `Customer_ID` — each customer can have multiple transactions (average of 8 transactions per customer across the dataset).

**Missing values:** Spot-checked rows show occasional blanks in `Device_Type` and `Location` in Transaction_Data — not yet quantified across the full 12,000 records, flagged for closer profiling in Week 2.

**Data-quality observations:**
- `Customer_Name` is not unique — must use `Customer_ID` for any join or identification.
- `Risk_Review_Flag` is a synthetic educational label, not a real fraud determination — should not be over-interpreted as ground truth.
- No formal cleaning performed yet, per assignment instructions.

---

## Part C — Analytical Questions

1. Which customer segments (Premium, Everyday, SME, Student) show the highest digital engagement, and does engagement correlate with tenure?
2. How does transaction volume vary over time — are there identifiable peak periods?
3. What is the average and total transaction value by customer segment, and which segment contributes most to overall value?
4. Which channels are most used, and does channel preference differ by segment or income band?
5. What proportion of transactions are Failed, Reversed, or Pending, and are certain channels/types more prone to this?
6. Is there a relationship between `Risk_Review_Flag` and transaction amount, channel, or international-transaction status?
7. Do certain segments or account types show a higher concentration of flagged transactions?

---

## Part D — KPI Planning

| KPI | Definition | Why It Matters | Required Data |
|---|---|---|---|
| Total Transaction Value | Sum of Amount_NGN over a period | Measures overall business volume and growth | Amount_NGN, Transaction_DateTime |
| Transaction Success Rate | % of transactions with Status = Successful | Indicates platform/operational reliability | Transaction_Status |
| Average Transaction Value per Customer | Total value ÷ active customers | Reveals where customer value is concentrated | Amount_NGN, Customer_ID |
| Risk Flag Rate | % of transactions flagged for risk review | Tracks risk exposure trend over time | Risk_Review_Flag |
| Channel Adoption Rate | % of transactions per channel | Guides channel investment priorities | Channel |
| Customer Dormancy Rate | % of customers with Account_Status = Dormant | Flags retention/reactivation needs | Account_Status |
| Average Digital Engagement Score | Mean engagement score, by segment | Measures digital adoption across segments | Digital_Engagement_Score, Customer_Segment |
| Failed/Reversed Transaction Rate | % of transactions that are Failed or Reversed | Highlights operational/customer-experience issues | Transaction_Status |

---

## Part E — Dashboard Wireframe

**Sections:**
1. Overview — top-line business health
2. Customer Insights — segment, engagement, dormancy
3. Transaction Insights — volume, value, channels
4. Risk Monitoring — flagged transactions and patterns

**KPI cards (top row):** Total Transaction Value · Transaction Success Rate · Risk Flag Rate · Customer Dormancy Rate

**Charts/visuals:**
- Line chart — transaction volume/value over time
- Bar chart — transactions by channel
- Donut chart — customer segment distribution
- Bar chart — average transaction value by segment
- Bar/heatmap — risk flag rate by channel or transaction type
- Bar chart — failed/reversed rate by channel

**Filters:** Date range · Customer Segment · Channel · City · Transaction Status

**Expected insights:** which segments drive the most value, which channels carry the most risk or failure, how dormancy trends over tenure, and where operational friction (failed/reversed transactions) concentrates.

---

## Deliverable 6 — Initial Analysis Plan

**Week 2:** Data preparation and exploratory analysis — clean and validate both datasets, compute the KPI table in Excel/Python, run initial exploratory analysis against the analytical questions.

**Week 3:** Build the Power BI dashboard — implement the wireframe (KPI cards, charts, filters), validate outputs against the analytical questions, refine based on early findings.

**Week 4:** Finalize and polish — refine visuals, document insights and limitations, prepare a summary narrative for stakeholders, and package the submission professionally.

**Success criteria:** The solution is successful if it (1) accurately answers the analytical questions above, (2) surfaces at least one actionable insight per KPI, (3) is usable by a non-technical stakeholder via filters, and (4) clearly documents data limitations rather than overstating certainty from synthetic data.

**Relevant risks / future dependencies:** Incomplete profiling of missing values could bias KPI calculations; the Data Science track may later want cleaned transaction features from this track's work; dashboard scope could creep beyond Week 1 planning if not scoped tightly.
