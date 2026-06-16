# sql-financial-analysis-adventureworks
SQL analysis of financial KPIs (revenue, costs, gross profit, margin %, ROI %) across 6 markets using JOINs, COALESCE, and aggregate functions. AdventureWorks 2017 dataset.
# Financial Performance Analysis — AdventureWorks 2017

SQL analysis of sales performance, profitability and marketing efficiency across six international markets using AdventureWorks transactional data.

Tools: PostgreSQL | Excel | Business Analysis

Key Skills:
- SQL
- Data Cleaning
- Financial Analysis
- KPI Development
- ROI Analysis
- Business Recommendations
## Context

As a data analyst at AdventureWorks, the CFO needed to understand which markets generate the most revenue and profitability — to decide where to invest the next marketing dollar.

**Business questions:**
1. How much are we earning per country?
2. How profitable is each market considering marketing spend?

---

## Data Model

Four tables joined to build the analysis base:

```
ventas_2017          → sales transactions (order lines)
    ↓ LEFT JOIN
productos            → product catalog (price + unit cost)
    ↓ LEFT JOIN
productos_categorias → category / subcategory hierarchy
    ↓ LEFT JOIN
territorios          → territory → country + continent map
    ↓ LEFT JOIN
campanas             → marketing spend by territory
```

---
## Results

### Financial KPIs by Country

| Country | Revenue | Costs | Campaign Cost | Gross Profit | Margin % | ROI % |
|---|---|---|---|---|---|---|
| United States | $3,353,940 | $1,899,471 | $1,920,000 | $1,454,469 | 43.37% | 75.75% |
| Australia | $2,532,003 | $1,474,958 | $2,150,400 | $1,057,045 | 41.75% | 49.16% |
| United Kingdom | $1,189,637 | $681,509 | $2,304,000 | $508,128 | 42.71% | 22.05% |
| Germany | $1,071,460 | $611,295 | $2,265,600 | $460,165 | 42.95% | 20.31% |
| France | $924,317 | $527,797 | $2,208,000 | $396,520 | 42.90% | 17.96% |
| Canada | $710,205 | $392,326 | $1,824,000 | $317,879 | 44.76% | 17.43% |

**Metric definitions:**
- **Gross Profit** = Revenue − Operating Costs
- **Margin %** = Gross Profit / Revenue × 100
- **ROI %** = Gross Profit / Campaign Cost × 100

---

## Executive Summary (C → F → I)

### Context
Revenue, operating costs, and marketing campaign spend were analyzed by market using 2017 sales data across 6 countries.

### Findings
- United States generated the highest ROI (75.75%) and gross profit ($1.45M).
- Australia delivered the second strongest marketing efficiency (49.16% ROI).
- Canada showed the highest gross margin (44.76%) but one of the lowest marketing returns (17.43% ROI).
- Germany, France and the UK consumed the largest campaign budgets while generating relatively weak returns.

### Implications

**1. Increase investment in United States**
With 75.75% ROI and the highest absolute gross profit ($1.45M), the US is the highest-confidence market for incremental marketing spend.

**2. Investigate Canada's campaign strategy**
Canada's gross margin (44.76%) shows the product is competitive. The problem is campaign efficiency, not product profitability. Reviewing targeting, channels, and messaging could unlock significant ROI improvement without changing the product.

**3. Review campaign strategy in Germany, France, and Canada**
These markets absorb significant campaign spend ($2.2–2.3M each) while delivering 17–20% ROI. A reallocation of part of that budget toward the US or Australia would likely improve overall portfolio ROI.

---

## Analytical Decisions

| Decision | Rationale |
|---|---|
| `COALESCE(price, 0)` | Prevents NULL propagation in revenue/cost calculations |
| `::integer` casting | Improves readability of large monetary totals |
| `NULLIF(revenue, 0)` | Avoids division-by-zero in margin and ROI formulas |
| `LEFT JOIN` on campaigns | Preserves territories with no campaign registered |
| QA checks before analysis | Validates NULLs in keys and invalid quantities/prices |

---

## QA Validation

Three checks run before finalizing the analysis:

```sql
-- 1. NULL check on sales keys → all results must be 0
-- 2. Invalid order quantities (<= 0) → must be 0 rows
-- 3. Negative product prices (< 0) → must be 0 products
```
---

## SQL Structure

| Part | Description |
|---|---|
| Part 1 — Schema exploration | `LIMIT 10` on all 5 source tables |
| Part 2 — Data extraction | 3× LEFT JOIN + COALESCE NULL handling |
| Part 2 — Calculated columns | `ingreso_total` and `costo_total` per order line |
| Part 3 — KPIs by country | Revenue, costs, campaign spend aggregated by territory |
| Part 3 — Financial KPIs | Gross profit, margin %, ROI % with NULLIF guard |
| Part 4 — QA validation | NULL checks + invalid quantity/price detection |
