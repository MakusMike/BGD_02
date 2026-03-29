-- ============================================================
--                      Silver Layer
-- Input  : raw.sleep_raw         (13 cols, all TEXT, from bronze layer)
-- Output : clean.sleep_clean     (typed, validated, documented)
--
-- Rules applied:
--   TRIM + NULLIF to strip whitespace and empty strings
--   Range guards reject biologically impossible values → NULL
--   gender normalised to lowercase
-- ============================================================

DROP TABLE IF EXISTS clean.sleep_clean;

CREATE TABLE clean.sleep_clean AS
SELECT


    NULLIF(TRIM(user_id), '')::INT                              AS user_id,


    CASE
        WHEN NULLIF(TRIM(age), '')::INT BETWEEN 1 AND 120
        THEN NULLIF(TRIM(age), '')::INT
        ELSE NULL
    END                                                         AS age,

    LOWER(TRIM(NULLIF(gender, '')))                             AS gender,
    TRIM(NULLIF(occupation, ''))                                AS occupation,


    CASE
        WHEN NULLIF(TRIM(daily_screen_time_hours), '')::NUMERIC
             BETWEEN 0 AND 24
        THEN NULLIF(TRIM(daily_screen_time_hours), '')::NUMERIC
        ELSE NULL
    END                                                         AS daily_screen_time_hours,

    CASE
        WHEN NULLIF(TRIM(phone_usage_before_sleep_minutes), '')::NUMERIC
             BETWEEN 0 AND 1440
        THEN NULLIF(TRIM(phone_usage_before_sleep_minutes), '')::NUMERIC
        ELSE NULL
    END                                                         AS phone_usage_before_sleep_minutes,


    CASE
        WHEN NULLIF(TRIM(sleep_duration_hours), '')::NUMERIC
             BETWEEN 0 AND 24
        THEN NULLIF(TRIM(sleep_duration_hours), '')::NUMERIC
        ELSE NULL
    END                                                         AS sleep_duration_hours,

    CASE
        WHEN NULLIF(TRIM(sleep_quality_score), '')::NUMERIC
             BETWEEN 1 AND 10
        THEN NULLIF(TRIM(sleep_quality_score), '')::NUMERIC
        ELSE NULL
    END                                                         AS sleep_quality_score,


    CASE
        WHEN NULLIF(TRIM(stress_level), '')::NUMERIC
             BETWEEN 1 AND 10
        THEN NULLIF(TRIM(stress_level), '')::NUMERIC
        ELSE NULL
    END                                                         AS stress_level,

    CASE
        WHEN NULLIF(TRIM(caffeine_intake_cups), '')::NUMERIC >= 0
        THEN NULLIF(TRIM(caffeine_intake_cups), '')::NUMERIC
        ELSE NULL
    END                                                         AS caffeine_intake_cups,

    CASE
        WHEN NULLIF(TRIM(physical_activity_minutes), '')::NUMERIC >= 0
        THEN NULLIF(TRIM(physical_activity_minutes), '')::NUMERIC
        ELSE NULL
    END                                                         AS physical_activity_minutes,


    CASE
        WHEN NULLIF(TRIM(notifications_received_per_day), '')::INT >= 0
        THEN NULLIF(TRIM(notifications_received_per_day), '')::INT
        ELSE NULL
    END                                                         AS notifications_received_per_day,


    CASE
        WHEN NULLIF(TRIM(mental_fatigue_score), '')::NUMERIC
             BETWEEN 1 AND 10
        THEN NULLIF(TRIM(mental_fatigue_score), '')::NUMERIC
        ELSE NULL
    END                                                         AS mental_fatigue_score,


    CASE
        WHEN NULLIF(TRIM(age), '')::INT BETWEEN 18 AND 25 THEN '18-25'
        WHEN NULLIF(TRIM(age), '')::INT BETWEEN 26 AND 35 THEN '26-35'
        WHEN NULLIF(TRIM(age), '')::INT BETWEEN 36 AND 45 THEN '36-45'
        WHEN NULLIF(TRIM(age), '')::INT BETWEEN 46 AND 59 THEN '46-59'
        ELSE NULL
    END                                                         AS age_group,


    loaded_at,
    NOW()                                                       AS cleaned_at

FROM raw.sleep_raw;


CREATE INDEX idx_sleep_clean_user       ON clean.sleep_clean(user_id);
CREATE INDEX idx_sleep_clean_gender     ON clean.sleep_clean(gender);
CREATE INDEX idx_sleep_clean_occupation ON clean.sleep_clean(occupation);
CREATE INDEX idx_sleep_clean_age_group  ON clean.sleep_clean(age_group);


DO $$
DECLARE
    total_rows          INT;
    null_sleep_dur      INT;
    null_sleep_quality  INT;
    null_stress         INT;
    null_screen         INT;
    null_fatigue        INT;
    null_age            INT;
    null_gender         INT;
BEGIN
    SELECT COUNT(*)                                                    INTO total_rows         FROM clean.sleep_clean;
    SELECT COUNT(*) FILTER (WHERE sleep_duration_hours IS NULL)        INTO null_sleep_dur     FROM clean.sleep_clean;
    SELECT COUNT(*) FILTER (WHERE sleep_quality_score  IS NULL)        INTO null_sleep_quality FROM clean.sleep_clean;
    SELECT COUNT(*) FILTER (WHERE stress_level         IS NULL)        INTO null_stress        FROM clean.sleep_clean;
    SELECT COUNT(*) FILTER (WHERE daily_screen_time_hours IS NULL)     INTO null_screen        FROM clean.sleep_clean;
    SELECT COUNT(*) FILTER (WHERE mental_fatigue_score IS NULL)        INTO null_fatigue       FROM clean.sleep_clean;
    SELECT COUNT(*) FILTER (WHERE age    IS NULL)                      INTO null_age           FROM clean.sleep_clean;
    SELECT COUNT(*) FILTER (WHERE gender IS NULL)                      INTO null_gender        FROM clean.sleep_clean;

    RAISE NOTICE '====== [Silver] clean.sleep_clean quality report ======';
    RAISE NOTICE 'Total rows                : %',          total_rows;
    RAISE NOTICE 'NULL sleep_duration_hours : % (%.1f%%)', null_sleep_dur,
        ROUND(null_sleep_dur::NUMERIC      / NULLIF(total_rows,0) * 100, 1);
    RAISE NOTICE 'NULL sleep_quality_score  : % (%.1f%%)', null_sleep_quality,
        ROUND(null_sleep_quality::NUMERIC  / NULLIF(total_rows,0) * 100, 1);
    RAISE NOTICE 'NULL stress_level         : % (%.1f%%)', null_stress,
        ROUND(null_stress::NUMERIC         / NULLIF(total_rows,0) * 100, 1);
    RAISE NOTICE 'NULL daily_screen_time    : % (%.1f%%)', null_screen,
        ROUND(null_screen::NUMERIC         / NULLIF(total_rows,0) * 100, 1);
    RAISE NOTICE 'NULL mental_fatigue_score : % (%.1f%%)', null_fatigue,
        ROUND(null_fatigue::NUMERIC        / NULLIF(total_rows,0) * 100, 1);
    RAISE NOTICE 'NULL age                  : % (%.1f%%)', null_age,
        ROUND(null_age::NUMERIC            / NULLIF(total_rows,0) * 100, 1);
    RAISE NOTICE 'NULL gender               : % (%.1f%%)', null_gender,
        ROUND(null_gender::NUMERIC         / NULLIF(total_rows,0) * 100, 1);
    RAISE NOTICE '=======================================================';
END $$;