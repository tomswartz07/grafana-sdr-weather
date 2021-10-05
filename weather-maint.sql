-- SETUP NOTES:
--
-- 1. Disable/comment check cron job
-- 2. Stop PG ingest script
-- 3. Run RTL_433 manually output data to tmp file separately
-- 4. Run this cleanup script
-- 5. Update permissions on new table using old table
-- 6. Run postgres ingestion script on tmp file
-- 7. Restart standard ingest script
-- 8. Re-enable check cron job
-- 9. Take a new full backup
-- 10. Delete old table
-- 11. vacuumdb

-- Clean up in case of failures
DROP TABLE IF EXISTS weather_new;

-- Create Duplicate table
CREATE TABLE weather_new
(LIKE weather INCLUDING ALL);

-- Insert only one of each data bit
INSERT into weather_new (data, id)
SELECT DISTINCT ON (data) data, id
FROM weather;

-- Show difference
--
-- pre_migrate count should be more than post_migrate count, as duplicates
-- should be removed
SELECT
pre.count1 AS pre_migrate,
post.count2 AS post_migrate,
pre.count1 - post.count2 as removed
FROM
(SELECT count(*) AS count1 FROM weather) AS pre,
(SELECT count(*) AS count2 FROM weather_new) AS post
;

-- Archive table
ALTER TABLE weather
RENAME TO weather_old;

-- Move new table into place
ALTER TABLE weather_new
RENAME TO weather;

ALTER SEQUENCE weather_id_seq OWNED BY weather.id;

-- Fix the permissions
GRANT ALL ON TABLE weather TO tom;
GRANT SELECT ON TABLE weather TO grafana;
GRANT INSERT ON TABLE weather TO swartzremote;

-- Get latest stats now that the big change has happened
ANALYZE weather;

-- Optionally drop the table automatically and clear up data
--DROP TABLE weather_old;
--VACUUM (FULL, FREEZE, ANALYZE)
