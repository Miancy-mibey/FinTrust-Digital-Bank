# HealthConnect Rwanda: Healthcare Operations and Performance Analytics

**Programme:** AnalystLab Africa Experience Lab, Week 6
**Track:** Data Analytics
**Author:** Mercy Chepkemoi Koech (Miancy)

## Project Overview
HealthConnect Rwanda is a synthetic healthcare dataset used for training. This project turns its clinical, operational and financial data into evidence for management: where money is being lost, how care and staffing are distributed, and what patients think of the service. The work uses **PostgreSQL** (database and 40 business queries), **Power BI** (six-page executive dashboard) and **Python** (independent verification and statistical tests).

## Repository Structure
```
HealthConnect_Week6_DataAnalytics_Mercy/
├── Database/        PostgreSQL scripts, load-ready CSV files and the database backup
├── SQL/             40 business questions (04_business_questions_40.sql)
├── Dashboard/       Power BI file (.pbix) and Executive Dashboard PDF
├── Report/          Business Insights Report (PDF)
├── Presentation/    Executive presentation (13 slides)
├── Images/          Screenshots (validation results, query results, dashboard pages)
└── README.md
```

## Deliverables
| Deliverable | File |
|---|---|
| PostgreSQL database backup | `Database/healthconnect_rwanda_backup.sql` |
| Table creation, data load and validation scripts | `Database/01_create_tables.sql`, `02_load_data.sql`, `03_validation_checks.sql` |
| SQL scripts (40 business questions) | `SQL/04_business_questions_40.sql` |
| Power BI dashboard | `Dashboard/HealthConnect_Dashboard.pbix` |
| Executive Dashboard PDF | `Dashboard/HealthConnect_Executive_Dashboard.pdf` |
| Business Insights Report | `Report/HealthConnect_Business_Insights_Report.pdf` |
| Executive presentation | `Presentation/HealthConnect_Executive_Presentation.pptx` |

## How to Rebuild the Database
1. Install PostgreSQL 15 or later and create a database named `healthconnect_rwanda`.
2. Copy the CSV files from `Database/data/` to `C:\HealthConnect\data\` (or change the path in `02_load_data.sql`).
3. Run, in order: `01_create_tables.sql`, `02_load_data.sql`, `03_validation_checks.sql`.
4. The validation script should show **44 PASS rows and no FAIL rows**.
5. Alternatively, restore `healthconnect_rwanda_backup.sql` (a plain SQL backup) with `psql`.

The tables are created in a schema called `hc`, which is set as the default search path for the database.

## Data Model
31 tables: geography (country, province, district, sector, village), facility structure (facilities, departments, rooms, beds, equipment), six staff tables, patients, clinical transactions (appointments, diagnoses, laboratory tests, prescriptions, admissions, referrals) and finance (billing, payments, insurance claims, patient feedback, revenue summary). In Power BI, the Diagnoses table is the hub: it has exactly one row per appointment (60,000) and every other appointment-level table joins to it.

## Validation
- 44 of 44 row-count and total checks pass against the source files.
- All 40 SQL queries were recomputed independently in Python and matched.
- Comparisons between facilities, departments, provinces and diagnoses were tested for statistical significance (chi-square, Kruskal-Wallis), so a difference is reported only if it exceeds random variation.

## Key Findings
- **Billed RWF 9.31bn, collected RWF 8.39bn (90.1%), outstanding RWF 919.9M.** 11,887 bills (19.8%) are short-paid, and 4,042 bills marked "Paid" still carry balances worth RWF 311.2M.
- **50% of insurance claims (21,028, worth RWF 2.44bn) are pending and none is rejected.** Providers are within 2% of each other in claimed value.
- **74.6% of patients have a chronic condition** and 27.4% are over 65.
- **Staffing is uniform** (61 to 64 staff per facility) while appointment volume per facility varies by about 30% in the sample.
- **Clinical mix is even:** five diagnoses at about 20% each, with no monthly trend.
- **Average satisfaction is 2.99 out of 5**, with 40.4% poor ratings and 19.7% excellent. Facility differences are not statistically significant.

## Assumptions and Data Limitations
- The Appointments table supplied has **5,000 rows** (APT000001 to APT005000), while billing, diagnoses and feedback refer to appointments up to APT060000. Only 8.3% of billed value links to a facility, department, doctor or date, so facility, department and monthly analyses describe that sample.
- **No facility master file** was supplied: facilities appear as IDs (HF001 to HF020).
- Staff and appointment records disagree with the department's facility in about 95% of rows. The facility on the record is treated as the hospital, and the department as a department type.
- **Revenue** is payments collected. **Outstanding** is billed minus paid. The Revenue Summary file (RWF 1.13bn) does not reconcile with billing and is used only for the monthly trend.
- **Proxies:** bed utilisation is bed-days used divided by beds times 365; revenue by service uses visit type; claim approval is approved divided by all claims (no rejected claims exist).
- Other gaps: patient phone numbers lost digits at source; only five diagnoses exist; equipment has no availability field; no cost data; dates run to December 2026; the data is synthetic.

## Tools
PostgreSQL 18 and pgAdmin, SQL, Power BI Desktop (DAX), Python (pandas, SciPy), Excel.
