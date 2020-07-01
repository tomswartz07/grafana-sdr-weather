-- SETUP NOTES:
--
-- 1. Disable/comment check cron job
-- 2. Stop PG ingest script
-- 3. Run RTL_433 manually output data to tmp file separately
-- 4. Run this cleanup script
-- 5. Run postgres ingestion script on tmp file
-- 6. Restart standard ingest script
-- 7. Re-enable check cron job

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
