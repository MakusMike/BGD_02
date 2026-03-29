# Sleep, Screen Time & Stress — ELT Pipeline

## Problem Statement

Modern mobile usage has raised concerns about its impact on sleep health and mental wellbeing. This project investigates **how daily screen time, phone usage before sleep, and stress levels affect sleep quality and mental fatigue** across 15,000 users with varying occupations, ages, and lifestyles.

Using a **medallion ELT pipeline** (Bronze > Silver > Gold) built on PostgreSQL, the raw CSV data is ingested as-is, then progressively cleaned, typed, and aggregated into analytical summaries. The goal is to produce reliable, query-ready datasets that answer questions such as:

- Do people with more screen time sleep worse?
- Which occupations show the highest stress and lowest sleep quality?
- How does sleep quality differ across age groups?
- What differs a high-stress user compared to a low-stress one?

---

## Dataset

| Property | Value |
|---|---|
| Source | https://www.kaggle.com/datasets/jayjoshi37/sleep-screen-time-and-stress-analysis/data |
| Rows | 15,000 users |
| Columns | 13 |
| Age range | 18–59 |
| Occupations | Designer, Doctor, Freelancer, Manager, Researcher, Software Engineer, Student, Teacher |
| Genders | Female, Male, Other |


### Gold layer tables

| Table | Description |
|---|---|
| gold.sleep_by_occupation | Sleep & stress KPIs grouped by job |
| gold.sleep_by_age_group | Sleep patterns across age bands (18–25, 26–35, etc.) |
| gold.screen_time_impact | Screen time buckets (Low / Moderate / High / Very High) vs. sleep quality |
| gold.high_stress_profile | Side-by-side comparison of high-stress vs. lower-stress users |

---

## Data Quality Risks

### Risk 1 - Schema mismatch at ingestion (Bronze)
**Layer:** Bronze | **Type:** Ingestion

The CSV column names must match the DDL column list in the COPY statement exactly. If the source file is regenerated or renamed (e.g. daily_screen_time_hours > screen_time_hours), the load will silently fail or map data to the wrong columns with no error raised by PostgreSQL

**Countermeasure:** Column names in 1_bronze.sql are explicitly listed in the COPY statement and match the CSV header exactly.

---

### Risk 2 - Ceiling-hugging values mask real outliers (Transformation)
**Layer:** Silver | **Type:** Data Integrity

Over 25% of rows have stress_level = 10.0 and over 16% have mental_fatigue_score = 10.0. When the scale tops out at 10, users who would score 11 or 12 are clamped to 10, compressing the distribution and making extreme cases indistinguishable. This inflates the average and hides the true severity of the worst-affected users.

**Countermeasure:** Flag ceiling-touching records in Silver using a derived boolean column (e.g. stress_at_ceiling, fatigue_at_ceiling) so Gold-layer queries can optionally exclude or annotate them.

---

### Risk 3 - Self-reported scores introduce systematic bias (Scale / Reliability)
**Layer:** Silver → Gold | **Type:** Scale / Measurement

The scores for sleep_quality_score, stress_level, and mental_fatigue_score are all **self-reported on a 1–10 scale**. Different occupations and demographics may interpret the scale differently — a Doctor's "7 stress" is not necessarily the same as a Student's "7 stress". Additionally, caffeine_intake_cups is in cups, making cross-dataset comparisons unreliable since cup sizes vary.

**Countermeasure:** Document the unit and collection method for each subjective column. Treat Gold-layer comparisons across groups as indicative rather than causal.

---

## How to Run

### Prerequisites
- Docker & Docker Compose installed

### Steps

```bash
# 1. Clone the repo
git clone https://github.com/MakusMike/BGD_02
cd BGD_02

# 4. Download the data from kaggle
Go to https://www.kaggle.com/datasets/jayjoshi37/sleep-screen-time-and-stress-analysis/data

# 3. Place the CSV in the data/ folder
mkdir -p data
cp sleep_mobile_stress_dataset_15000.csv data/

# 4. Place SQL scripts in the sql/ folder
mkdir -p sql
cp 1_bronze.sql 2_silver.sql 3_gold.sql sql/

# 5. Start PostgreSQL — scripts run automatically on first boot
docker-compose up -d

# 6. Check logs to confirm all layers loaded
docker logs sleep_db

# 7. Connect and explore
docker exec -it sleep_db psql -U admin -d sleep_analytics
```

### Useful queries to verify

```sql
-- Row counts per layer
SELECT COUNT(*) FROM raw.sleep_raw;
SELECT COUNT(*) FROM clean.sleep_clean;

-- Gold: sleep quality by occupation
SELECT * FROM gold.sleep_by_occupation;

-- Gold: high vs low stress comparison
SELECT * FROM gold.high_stress_profile;
```

---

## Project Structure

```
.
├── data/
│   └── sleep_mobile_stress_dataset_15000.csv
├── sql/
│   ├── 1_bronze.sql      
│   ├── 2_silver.sql      
│   └── 3_gold.sql        
├── docker-compose.yml    
└── README.md
```

---

## Technologies

| Tool | Purpose |
|---|---|
| PostgreSQL 16 | Database engine |
| Docker / Docker Compose | Reproducible local environment |
| SQL (DDL + DML) | All transformation logic |

---

## Author

Michał Makus — [GitHub](https://github.com/MakusMike)