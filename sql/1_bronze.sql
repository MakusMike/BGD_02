-- ============================================================
--                      Bronze Layer
-- Creates the raw schema and ingests the CSV as-is.
-- All columns stored as TEXT to preserve exact source values.
-- ============================================================

CREATE SCHEMA IF NOT EXISTS raw;
CREATE SCHEMA IF NOT EXISTS clean;
CREATE SCHEMA IF NOT EXISTS gold;

DROP TABLE IF EXISTS raw.sleep_raw;

CREATE TABLE raw.sleep_raw (
    user_id                          TEXT,
    age                              TEXT,
    gender                           TEXT,
    occupation                       TEXT,
    daily_screen_time_hours          TEXT,
    phone_usage_before_sleep_minutes TEXT,
    sleep_duration_hours             TEXT,
    sleep_quality_score              TEXT,
    stress_level                     TEXT,
    caffeine_intake_cups             TEXT,
    physical_activity_minutes        TEXT,
    notifications_received_per_day   TEXT,
    mental_fatigue_score             TEXT,

    loaded_at TIMESTAMP DEFAULT NOW()
);


COPY raw.sleep_raw (
    user_id,
    age,
    gender,
    occupation,
    daily_screen_time_hours,
    phone_usage_before_sleep_minutes,
    sleep_duration_hours,
    sleep_quality_score,
    stress_level,
    caffeine_intake_cups,
    physical_activity_minutes,
    notifications_received_per_day,
    mental_fatigue_score
)
FROM 'data/sleep_mobile_stress_dataset_15000.csv'
DELIMITER ','
CSV HEADER;


DO $$
DECLARE row_count INT;
BEGIN
    SELECT COUNT(*) INTO row_count FROM raw.sleep_raw;
    RAISE NOTICE '>>> [Bronze] raw.sleep_raw loaded: % rows', row_count;
END $$;