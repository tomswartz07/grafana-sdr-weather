-- Reporting Script intended to be run from something like cron
-- on a monthly basis to provide stats on the previous month.
\set QUIET 1
\timing
\pset footer off
\x on
\set QUIET 0
-- Monthly Stats
SELECT
date_trunc('month', (data ->> 'time')::timestamptz) AS "Outdoor",
MIN(((data -> 'fields') -> 'temperature_F')::numeric) AS "Monthly Low",
MAX(((data -> 'fields') -> 'temperature_F')::numeric) AS "Monthly High",
AVG(((data -> 'fields') -> 'temperature_F')::numeric)::numeric(7,4) AS "Average"
FROM weather
WHERE
(data ->> 'measurement') LIKE '%3n1%'
AND
(data ->> 'time')::timestamptz BETWEEN now() - '1 month'::interval AND now()
GROUP BY 1
ORDER BY 1 ASC
LIMIT 1
;

-- Daily stats
\set QUIET 1
\x auto
\set QUIET 0
SELECT
date_trunc('day', (data ->> 'time')::timestamptz) AS "Date",
MIN(((data -> 'fields') -> 'temperature_F')::numeric) AS "Daily Low",
MAX(((data -> 'fields') -> 'temperature_F')::numeric) AS "Daily High",
AVG(((data -> 'fields') -> 'temperature_F')::numeric)::numeric(7,4) AS "Average Temp"
FROM weather
WHERE
(data ->> 'measurement') LIKE '%3n1%'
AND
(data ->> 'time')::timestamptz BETWEEN now() - '1 month'::interval AND now()
GROUP BY 1
ORDER BY 1 ASC
;

-- Server Room stats
\set QUIET 1
\x on
\set QUIET 0
SELECT
date_trunc('month', (data ->> 'time')::timestamptz) AS "Server Room",
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
(data ->> 'time')::timestamptz BETWEEN now() - '1 month'::interval AND now()
GROUP BY 1
ORDER BY 1 ASC
LIMIT 1
;
