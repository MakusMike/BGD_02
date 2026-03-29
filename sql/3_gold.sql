-- ============================================================
--                         Gold Layer
-- Input  : clean.sleep_clean
-- Output : four analytical summary tables ready for dashboards
--
-- Tables created:
--   gold.sleep_by_occupation  - sleep & stress KPIs per job
--   gold.sleep_by_age_group   - sleep patterns across age bands
--   gold.screen_time_impact   - screen time buckets vs sleep quality
--   gold.high_stress_profile  - profile of high-stress users (stress >= 7)
-- ============================================================

-- 1. Sleep & stress KPIs by occupation
-- Shows which jobs correlate with poor sleep or high stress.
-- Uses GROUP BY aggregation.


DROP TABLE IF EXISTS gold.sleep_by_occupation;

CREATE TABLE gold.sleep_by_occupation AS
SELECT
    occupation,
    COUNT(*)                                    AS user_count,
    ROUND(AVG(sleep_duration_hours)::NUMERIC, 2)    AS avg_sleep_hours,
    ROUND(AVG(sleep_quality_score)::NUMERIC,  2)    AS avg_sleep_quality,
    ROUND(AVG(stress_level)::NUMERIC,         2)    AS avg_stress_level,
    ROUND(AVG(mental_fatigue_score)::NUMERIC,  2)   AS avg_mental_fatigue,
    ROUND(AVG(daily_screen_time_hours)::NUMERIC, 2) AS avg_screen_time_hours,
    ROUND(AVG(caffeine_intake_cups)::NUMERIC,  2)   AS avg_caffeine_cups,
    ROUND(AVG(physical_activity_minutes)::NUMERIC, 1) AS avg_activity_min
FROM clean.sleep_clean
WHERE occupation IS NOT NULL
GROUP BY occupation
ORDER BY avg_sleep_quality DESC;


-- 2. Sleep patterns by age group
-- Reveals how sleep quality and stress shift across life stages.
-- Uses the derived age_group column from Silver layer.


DROP TABLE IF EXISTS gold.sleep_by_age_group;

CREATE TABLE gold.sleep_by_age_group AS
SELECT
    age_group,
    COUNT(*)                                          AS user_count,
    ROUND(AVG(sleep_duration_hours)::NUMERIC,  2)     AS avg_sleep_hours,
    ROUND(AVG(sleep_quality_score)::NUMERIC,   2)     AS avg_sleep_quality,
    ROUND(AVG(stress_level)::NUMERIC,          2)     AS avg_stress_level,
    ROUND(AVG(mental_fatigue_score)::NUMERIC,  2)     AS avg_mental_fatigue,
    ROUND(AVG(phone_usage_before_sleep_minutes)::NUMERIC, 1) AS avg_phone_before_sleep_min,
    ROUND(AVG(notifications_received_per_day)::NUMERIC, 1)   AS avg_notifications
FROM clean.sleep_clean
WHERE age_group IS NOT NULL
GROUP BY age_group
ORDER BY age_group;


-- 3. Screen time buckets vs sleep quality
-- Buckets daily screen time and shows sleep quality impact.
-- Demonstrates CASE bucketing + GROUP BY.


DROP TABLE IF EXISTS gold.screen_time_impact;

CREATE TABLE gold.screen_time_impact AS
SELECT
    CASE
        WHEN daily_screen_time_hours < 3  THEN '1_Low (< 3h)'
        WHEN daily_screen_time_hours < 6  THEN '2_Moderate (3–6h)'
        WHEN daily_screen_time_hours < 9  THEN '3_High (6–9h)'
        ELSE                                   '4_Very High (9h+)'
    END                                                  AS screen_time_bucket,
    COUNT(*)                                             AS user_count,
    ROUND(AVG(sleep_quality_score)::NUMERIC,  2)         AS avg_sleep_quality,
    ROUND(AVG(sleep_duration_hours)::NUMERIC, 2)         AS avg_sleep_hours,
    ROUND(AVG(stress_level)::NUMERIC,         2)         AS avg_stress_level,
    ROUND(AVG(mental_fatigue_score)::NUMERIC, 2)         AS avg_mental_fatigue,
    ROUND(AVG(phone_usage_before_sleep_minutes)::NUMERIC, 1) AS avg_phone_before_sleep_min
FROM clean.sleep_clean
WHERE daily_screen_time_hours IS NOT NULL
GROUP BY screen_time_bucket
ORDER BY screen_time_bucket;


-- 4. High-stress user profile
-- Compares high-stress users (stress >= 7) vs. the rest.
-- Uses a JOIN-style UNION to place both groups side by side.


DROP TABLE IF EXISTS gold.high_stress_profile;

CREATE TABLE gold.high_stress_profile AS
SELECT
    'High Stress (>= 7)'                             AS stress_group,
    COUNT(*)                                         AS user_count,
    ROUND(AVG(sleep_duration_hours)::NUMERIC,  2)    AS avg_sleep_hours,
    ROUND(AVG(sleep_quality_score)::NUMERIC,   2)    AS avg_sleep_quality,
    ROUND(AVG(mental_fatigue_score)::NUMERIC,  2)    AS avg_mental_fatigue,
    ROUND(AVG(daily_screen_time_hours)::NUMERIC, 2)  AS avg_screen_time_hours,
    ROUND(AVG(caffeine_intake_cups)::NUMERIC,   2)   AS avg_caffeine_cups,
    ROUND(AVG(physical_activity_minutes)::NUMERIC, 1) AS avg_activity_min,
    ROUND(AVG(notifications_received_per_day)::NUMERIC, 1) AS avg_notifications
FROM clean.sleep_clean
WHERE stress_level >= 7

UNION ALL

SELECT
    'Lower Stress (< 7)'                             AS stress_group,
    COUNT(*)                                         AS user_count,
    ROUND(AVG(sleep_duration_hours)::NUMERIC,  2)    AS avg_sleep_hours,
    ROUND(AVG(sleep_quality_score)::NUMERIC,   2)    AS avg_sleep_quality,
    ROUND(AVG(mental_fatigue_score)::NUMERIC,  2)    AS avg_mental_fatigue,
    ROUND(AVG(daily_screen_time_hours)::NUMERIC, 2)  AS avg_screen_time_hours,
    ROUND(AVG(caffeine_intake_cups)::NUMERIC,   2)   AS avg_caffeine_cups,
    ROUND(AVG(physical_activity_minutes)::NUMERIC, 1) AS avg_activity_min,
    ROUND(AVG(notifications_received_per_day)::NUMERIC, 1) AS avg_notifications
FROM clean.sleep_clean
WHERE stress_level < 7;
