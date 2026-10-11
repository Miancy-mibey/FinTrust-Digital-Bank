"""FinTrust Week 4 - Final validation checks.
Recomputes key findings from the raw CSVs and tests them statistically.
Requires: pandas, numpy, scipy  (pip install scipy)
Place next to FinTrust_Customer_Data.csv and FinTrust_Transaction_Data.csv, then run.
"""
import pandas as pd, numpy as np
from scipy import stats

c = pd.read_csv("FinTrust_Customer_Data.csv")
t = pd.read_csv("FinTrust_Transaction_Data.csv")
t["risk"] = (t["Risk_Review_Flag"] == "Yes").astype(int)
t["intl"] = (t["International_Transaction"] == "Yes")
t["bad"] = t["Transaction_Status"].isin(["Failed", "Reversed"]).astype(int)
t["succ"] = (t["Transaction_Status"] == "Successful").astype(int)
t["date"] = pd.to_datetime(t["Transaction_DateTime"])
m = t.merge(c[["Customer_ID", "Customer_Segment"]], on="Customer_ID")
p = lambda x: f"{x:.2e}" if x < 0.001 else f"{x:.3f}"

print("V1 KPI reconciliation")
print("  customers", len(c), "| transactions", len(t))
print("  total value", round(t.Amount_NGN.sum(), 2), "| avg", round(t.Amount_NGN.mean(), 2))
print("  success rate %", round(t.succ.mean() * 100, 2), "| risk rate %", round(t.risk.mean() * 100, 2))

print("V2 International vs domestic risk")
g = t.groupby("intl").risk.agg(["mean", "sum", "count"]); print(g.round(4))
print("  chi-square p =", p(stats.chi2_contingency(pd.crosstab(t.intl, t.risk))[1]))

print("V3 Segment vs risk, and spend per customer")
print((m.groupby("Customer_Segment").risk.mean() * 100).round(2).to_dict())
print("  chi-square p =", p(stats.chi2_contingency(pd.crosstab(m.Customer_Segment, m.risk))[1]))
cs = m.groupby(["Customer_Segment", "Customer_ID"]).Amount_NGN.sum().reset_index()
print("  spend per customer:", cs.groupby("Customer_Segment").Amount_NGN.mean().round(0).to_dict())
print("  Kruskal-Wallis p (spend by segment) =", p(stats.kruskal(*[d.Amount_NGN for _, d in cs.groupby("Customer_Segment")])[1]))

print("V4 Value vs risk")
t["vr"] = pd.cut(t.Amount_NGN, [0, 10000, 50000, 100000, 250000, t.Amount_NGN.max()])
print((t.groupby("vr", observed=True).risk.mean() * 100).round(1).to_dict())
print("  chi-square p =", p(stats.chi2_contingency(pd.crosstab(t.vr, t.risk))[1]))
t["q"] = pd.qcut(t.Amount_NGN.rank(method="first"), 100, labels=False)
print("  top1% flagged", round(t[t.q == 99].risk.mean() * 100, 2), "| rest", round(t[t.q < 99].risk.mean() * 100, 2),
      "| p =", p(stats.chi2_contingency(pd.crosstab(t.q == 99, t.risk))[1]))

print("V5 Failure/reversal by channel")
print((t.groupby("Channel").bad.mean() * 100).round(2).to_dict())
print("  chi-square p (channel) =", p(stats.chi2_contingency(pd.crosstab(t.Channel, t.bad))[1]))
base = t.bad.mean()
for ch, ty in [("USSD", "Cash Withdrawal"), ("USSD", "Deposit")]:
    s = t[(t.Channel == ch) & (t.Transaction_Type == ty)]
    print(f"  {ch} {ty}: n={len(s)}, rate={s.bad.mean()*100:.1f}%, binomial p vs overall = {p(stats.binomtest(int(s.bad.sum()), len(s), base).pvalue)}")

print("V6 ATM + International")
i = t[t.intl]; a = i[i.Channel == "ATM"]; r = a.risk.mean(); se = np.sqrt(r * (1 - r) / len(a))
print(f"  n={len(a)}, rate={r*100:.1f}%, 95% CI {100*(r-1.96*se):.1f}% to {100*(r+1.96*se):.1f}%")
print("  channel vs risk within international, chi-square p =", p(stats.chi2_contingency(pd.crosstab(i.Channel, i.risk))[1]))

print("V7 Monthly trend per day")
mm = t.groupby(t.date.dt.to_period("M")).agg(value=("Amount_NGN", "sum"), n=("Transaction_ID", "count"), days=("date", lambda x: x.dt.date.nunique()))
mm["value_per_day_M"] = (mm.value / mm.days / 1e6).round(3); mm["txn_per_day"] = (mm.n / mm.days).round(1)
print(mm[["days", "value_per_day_M", "txn_per_day"]])

print("V8 Success rate by value range")
print((t.groupby("vr", observed=True).succ.mean() * 100).round(1).to_dict())
print("  chi-square p =", p(stats.chi2_contingency(pd.crosstab(t.vr, t.succ))[1]))
