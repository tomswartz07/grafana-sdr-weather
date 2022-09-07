-- Reporting Script intended to be run from something like cron
-- on a monthly basis to provide stats on the previous month.
\set QUIET 1
\timing off
\pset footer off
\x on
\set QUIET 0
-- Monthly Stats
SELECT
date_trunc('month', (data ->> 'time')::timestamptz)::date AS "Outdoor",
MIN(((data -> 'fields') -> 'temperature_F')::numeric) AS "Monthly Low",
MAX(((data -> 'fields') -> 'temperature_F')::numeric) AS "Monthly High",
AVG(((data -> 'fields') -> 'temperature_F')::numeric)::numeric(7,4) AS "Average",
MAX(((data -> 'fields') -> 'wind_speed_mph')::numeric) AS "Max Wind"
FROM weather
WHERE
(data ->> 'measurement') LIKE '%3n1%'
AND
(data ->> 'time')::timestamptz BETWEEN date_trunc('month', current_date - interval '1 month') and date_trunc('month', current_date)
GROUP BY 1
ORDER BY 1 ASC
LIMIT 1
;

-- Daily stats
\set QUIET 1
\x auto
\set QUIET 0
SELECT
date_trunc('day', (data ->> 'time')::timestamptz)::date AS "Date",
MIN(((data -> 'fields') -> 'temperature_F')::numeric) AS "Daily Low",
MAX(((data -> 'fields') -> 'temperature_F')::numeric) AS "Daily High",
AVG(((data -> 'fields') -> 'temperature_F')::numeric)::numeric(7,4) AS "Average Temp",
MAX(((data -> 'fields') -> 'wind_speed_mph')::numeric) AS "Max Wind",
AVG(((data -> 'fields') -> 'wind_speed_mph')::numeric)::numeric(7,4) AS "Avg Wind"
FROM weather
WHERE
(data ->> 'measurement') LIKE '%3n1%'
AND
(data ->> 'time')::timestamptz BETWEEN date_trunc('month', CURRENT_DATE - interval '1 month') and date_trunc('month', CURRENT_DATE)
GROUP BY 1
ORDER BY 1 ASC
;

-- Highs and Lows
\set QUIET 1
\x on
\set QUIET 0
WITH stats AS (
        SELECT
        date_trunc('day', (data ->> 'time')::timestamptz)::date AS "Outdoor",
        MAX(((data -> 'fields') -> 'temperature_F')::numeric) AS "High"
        FROM weather
        WHERE
        (data ->> 'measurement') LIKE '%3n1%'
        AND
        (data ->> 'time')::timestamptz BETWEEN date_trunc('month', current_date - interval '1 month') and date_trunc('month', current_date)
        GROUP BY 1
        HAVING MAX(((data -> 'fields') -> 'temperature_F')::numeric) > 89
        ORDER BY 1 ASC
)
SELECT
COUNT(*) AS "Days above 90"
FROM stats
;
\set QUIET 1
\x off
\set QUIET 0
SELECT
date_trunc('day', (data ->> 'time')::timestamptz)::date AS "Outdoor",
MAX(((data -> 'fields') -> 'temperature_F')::numeric) AS "High"
FROM weather
WHERE
(data ->> 'measurement') LIKE '%3n1%'
AND
(data ->> 'time')::timestamptz BETWEEN date_trunc('month', current_date - interval '1 month') and date_trunc('month', current_date)
GROUP BY 1
HAVING MAX(((data -> 'fields') -> 'temperature_F')::numeric) > 89
ORDER BY 1 ASC
;

\set QUIET 1
\x on
\set QUIET 0
WITH stats AS (
        SELECT
        date_trunc('day', (data ->> 'time')::timestamptz)::date AS "Outdoor",
        MIN(((data -> 'fields') -> 'temperature_F')::numeric) AS "Low"
        FROM weather
        WHERE
        (data ->> 'measurement') LIKE '%3n1%'
        AND
        (data ->> 'time')::timestamptz BETWEEN date_trunc('month', current_date - interval '1 month') and date_trunc('month', current_date)
        GROUP BY 1
        HAVING MIN(((data -> 'fields') -> 'temperature_F')::numeric) < 33
        ORDER BY 1 ASC
)
SELECT
COUNT(*) AS "Days below freezing"
FROM stats
;
\set QUIET 1
\x off
\set QUIET 0
SELECT
date_trunc('day', (data ->> 'time')::timestamptz)::date AS "Outdoor",
MIN(((data -> 'fields') -> 'temperature_F')::numeric) AS "Low"
FROM weather
WHERE
(data ->> 'measurement') LIKE '%3n1%'
AND
(data ->> 'time')::timestamptz BETWEEN date_trunc('month', current_date - interval '1 month') and date_trunc('month', current_date)
GROUP BY 1
HAVING MIN(((data -> 'fields') -> 'temperature_F')::numeric) < 33
ORDER BY 1 ASC
;


-- Living Room stats
\set QUIET 1
\x on
\set QUIET 0
SELECT
date_trunc('month', (data ->> 'time')::timestamptz)::date AS "Living Room",
MIN(((data -> 'fields') -> 'temperature_F')::numeric) AS "Monthly Low",
MAX(((data -> 'fields') -> 'temperature_F')::numeric) AS "Monthly High",
AVG(((data -> 'fields') -> 'temperature_F')::numeric)::numeric(7,4) AS "Average Temp",
MIN(((data -> 'fields') -> 'humidity')::numeric) AS "Min Humidity",
MAX(((data -> 'fields') -> 'humidity')::numeric) AS "Max Humidity",
AVG(((data -> 'fields') -> 'humidity')::numeric)::numeric(7,4) AS "Avg Humidity"
FROM weather
WHERE
(data -> 'tags' ->> 'id') like '11855'
AND
(data ->> 'time')::timestamptz BETWEEN date_trunc('month', CURRENT_DATE - interval '1 month') and date_trunc('month', CURRENT_DATE)
GROUP BY 1
ORDER BY 1 ASC
;

-- Server Room stats
\set QUIET 1
\x on
\set QUIET 0
SELECT
date_trunc('month', (data ->> 'time')::timestamptz)::date AS "Server Room",
MIN(((data -> 'fields') -> 'temperature_F')::numeric) AS "Monthly Low",
MAX(((data -> 'fields') -> 'temperature_F')::numeric) AS "Monthly High",
AVG(((data -> 'fields') -> 'temperature_F')::numeric)::numeric(7,4) AS "Average Temp",
MIN(((data -> 'fields') -> 'humidity')::numeric) AS "Min Humidity",
MAX(((data -> 'fields') -> 'humidity')::numeric) AS "Max Humidity",
AVG(((data -> 'fields') -> 'humidity')::numeric)::numeric(7,4) AS "Avg Humidity"
FROM weather
WHERE
(data -> 'tags' ->> 'id') like '13064'
AND
(data ->> 'time')::timestamptz BETWEEN date_trunc('month', CURRENT_DATE - interval '1 month') and date_trunc('month', CURRENT_DATE)
GROUP BY 1
ORDER BY 1 ASC
;

-- Garage stats
SELECT
date_trunc('month', (data ->> 'time')::timestamptz)::date AS "Garage",
MIN(((data -> 'fields') -> 'temperature_F')::numeric) AS "Monthly Low",
MAX(((data -> 'fields') -> 'temperature_F')::numeric) AS "Monthly High",
AVG(((data -> 'fields') -> 'temperature_F')::numeric)::numeric(7,4) AS "Average Temp"
FROM weather
WHERE
(data -> 'tags' ->> 'id') like '9359'
AND
(data ->> 'time')::timestamptz BETWEEN date_trunc('month', CURRENT_DATE - interval '1 month') and date_trunc('month', CURRENT_DATE)
GROUP BY 1
ORDER BY 1 ASC
;

-- Shed stats
SELECT
date_trunc('month', (data ->> 'time')::timestamptz)::date AS "Shed",
MIN(((data -> 'fields') -> 'temperature_F')::numeric) AS "Monthly Low",
MAX(((data -> 'fields') -> 'temperature_F')::numeric) AS "Monthly High",
AVG(((data -> 'fields') -> 'temperature_F')::numeric)::numeric(7,4) AS "Average Temp",
MIN(((data -> 'fields') -> 'humidity')::numeric) AS "Min Humidity",
MAX(((data -> 'fields') -> 'humidity')::numeric) AS "Max Humidity",
AVG(((data -> 'fields') -> 'humidity')::numeric)::numeric(7,4) AS "Avg Humidity"
FROM weather
WHERE
(data -> 'tags' ->> 'id') like '3377'
AND
(data ->> 'time')::timestamptz BETWEEN date_trunc('month', CURRENT_DATE - interval '1 month') and date_trunc('month', CURRENT_DATE)
GROUP BY 1
ORDER BY 1 ASC
;

-- ADS/B Stats
\set QUIET 1
\x off
\c adsb
\set QUIET 0
SELECT
date_trunc('day', parsed_time::timestamptz)::date AS "ADS/B Stats",
COUNT("transmission_type") as "Messages"
FROM adsb.adsb_messages
WHERE
parsed_time::timestamptz between date_trunc('month', CURRENT_DATE - interval '1 month') and date_trunc('month', CURRENT_DATE)
GROUP BY
1
ORDER BY
1 ASC
;
