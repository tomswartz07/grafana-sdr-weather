\set QUIET 1
\timing
\pset footer off
\x off
\set QUIET 0

SELECT
DISTINCT (data -> 'tags' ->> 'id') as "DeviceID",
(data ->> 'measurement') as "Low Battery Device"
FROM weather
WHERE
(data -> 'tags' ->> 'battery_low')::boolean = true
AND
((data ->> 'time'))::timestamptz BETWEEN now() - interval '5d' AND now();

--with series as (
--        SELECT * FROM (
--        select
--        (data -> 'fields' ->> 'temperature_F')::decimal as n
--        from weather
--        where
--        --(data -> 'tags' ->> 'id') like '9359'
--        (data ->> 'measurement') like 'Acurite 3n1%'
--        and
--        (data ->> 'time')::timestamptz BETWEEN now() - '24 hours'::interval AND now() - interval '12h'
--        order by date_trunc('hour', (data ->> 'time')::timestamptz) desc limit 1000
--) AS n),
--bounds AS (
--   SELECT
--       avg(n) - stddev(n) AS lower_bound,
--       avg(n) + stddev(n) AS upper_bound
--   FROM
--       series
--),
--stats AS (
--   SELECT
--       avg(n) series_mean,
--       stddev(n) as series_stddev
--   FROM
--       series
--),
--zscores AS (
--   SELECT
--       series.n,
--       (series.n - series_mean) / series_stddev AS zscore
--   FROM
--       series,
--       stats
--)
--SELECT
--   series.n,
--   lower_bound,
--   upper_bound,
--   (series.n - series_mean) / series_stddev as zscore,
--   series.n NOT BETWEEN lower_bound AND upper_bound AS is_anomaly,
--   zscore NOT BETWEEN -1.5 AND 1.5 AS zscore_anomaly
--FROM
--   series,
--   stats,
--   zscores,
--   bounds
-- WHERE
-- series.n NOT BETWEEN lower_bound AND upper_bound = true
-- LIMIT 100;
--
