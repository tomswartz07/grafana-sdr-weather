# dump1090 stream parser

This software takes a [dump1090](https://github.com/antirez/dump1090) stream of
[ADS-B](https://en.wikipedia.org/wiki/Automatic_dependent_surveillance_%E2%80%93_broadcast)
messages and plops them into a database with a timestamp.

## Usage

You'll need a dump1090 instance running somewhere accessible on your network

If dump1090 is running on your current machine running the command
below will create and start populating a Postgres database table named
`adsb_messages` in the default database.

```
python dump1090-postgres.py
```

Stop the stream by hitting control + c.

### Complete usage and options

```
usage: dump1090-postgres.py [-h] [--dump1090 DUMP1090] [--port PORT]
                            [-d DBNAME] [--dbhost DBHOST] [--dbport DBPORT]
                            [-U DBUSER] [--dbpass DBPASS]
                            [--buffer-size BUFFER_SIZE]
                            [--batch-size BATCH_SIZE]
                            [--connect-attempt-limit CONNECT_ATTEMPT_LIMIT]
                            [--connect-attempt-delay CONNECT_ATTEMPT_DELAY]
                            [--verbose VERBOSE]

A program to process dump1090 messages then insert them into a database

optional arguments:
  -h, --help            show this help message and exit
  --dump1090 DUMP1090   This is the network location of your dump1090
                        broadcast. Defaults to 127.0.0.1
  --port PORT           The port broadcasting dump1090 messages in SBS-1
                        BaseStation format. Defaults to 30003
  -d DBNAME, --dbname DBNAME
                        The location of a database file to use or create.
                        Defaults to magrathea
  --dbhost DBHOST       The host of the database. Defaults to 127.0.0.1
  --dbport DBPORT       The port of the database. Defaults to 5433
  -U DBUSER, --dbuser DBUSER
                        The user with which to connect to the database
                        Defaults to postgres
  --dbpass DBPASS
  --buffer-size BUFFER_SIZE
                        An integer of the number of bytes to read at a time
                        from the stream. Defaults to 100
                        NOT CURRENTLY IMPLEMENTED
  --batch-size BATCH_SIZE
                        An integer of the number of rows to write to the
                        database at a time. Defaults to 1
                        NOT CURRENTLY IMPLEMENTED
  --connect-attempt-limit CONNECT_ATTEMPT_LIMIT
                        An integer of the number of times to try (and fail) to
                        connect to the dump1090 broadcast before quitting.
                        Defaults to 10
  --connect-attempt-delay CONNECT_ATTEMPT_DELAY
                        The number of seconds to wait after a failed
                        connection attempt before trying again. Defaults to
                        5.0
  --verbose             Print out the messages as they're received. Defaults
                        to quiet output.

```

## Examples

Connecting to dump1090 instance running on a raspberry pi on your local network

```sh
python dump1090-stream-parser.py --dump1090 raspberrypi.local
```

Specifying a different database

```sh
python dump1090-stream-parser.py -d myCustomDatabase
```

## Data Format Overview

SBS-1 messages are in a simple comma-delimited format.
Here are some examples of the messages this module parses:

```
SEL,,496,2286,4CA4E5,27215,2010/02/19,18:06:07.710,2010/02/19,18:06:07.710,RYR1427
ID,,496,7162,405637,27928,2010/02/19,18:06:07.115,2010/02/19,18:06:07.115,EZY691A
AIR,,496,5906,400F01,27931,2010/02/19,18:06:07.128,2010/02/19,18:06:07.128
STA,,5,179,400AE7,10103,2008/11/28,14:58:51.153,2008/11/28,14:58:51.153,RM
CLK,,496,-1,,-1,2010/02/19,18:18:19.036,2010/02/19,18:18:19.036
MSG,1,145,256,7404F2,11267,2008/11/28,23:48:18.611,2008/11/28,23:53:19.161,RJA1118,,,,,,,,,,,
MSG,2,496,603,400CB6,13168,2008/10/13,12:24:32.414,2008/10/13,12:28:52.074,,,0,76.4,258.3,54.05735,-4.38826,,,,,,0
MSG,3,496,211,4CA2D6,10057,2008/11/28,14:53:50.594,2008/11/28,14:58:51.153,,37000,,,51.45735,-1.02826,,,0,0,0,0
MSG,4,496,469,4CA767,27854,2010/02/19,17:58:13.039,2010/02/19,17:58:13.368,,,288.6,103.2,,,-832,,,,,
MSG,5,496,329,394A65,27868,2010/02/19,17:58:12.644,2010/02/19,17:58:13.368,,10000,,,,,,,0,,0,0
MSG,6,496,237,4CA215,27864,2010/02/19,17:58:12.846,2010/02/19,17:58:13.368,,33325,,,,,,0271,0,0,0,0
MSG,7,496,742,51106E,27929,2011/03/06,07:57:36.523,2011/03/06,07:57:37.054,,3775,,,,,,,,,,0
MSG,8,496,194,405F4E,27884,2010/02/19,17:58:13.244,2010/02/19,17:58:13.368,,,,,,,,,,,,0
```

There's some documentation of the message format at
http://woodair.net/SBS/Article/Barebones42_Socket_Data.htm

## Parsed messages

Parsed messages have the following fields:

| Field               | Description                                                           |
| -----------------   | --------------------------------------------------------------------- |
| `message_type`      | `String`. See [MessageType](#MessageType).                            |
| `transmission_type` | `String`. See [TransmissionType](#TransmissionType).                  |
| `session_id`        | `String`. Database session record number.                             |
| `aircraft_id`       | `String`. Database aircraft record number.                            |
| `hex_ident`         | `String`. 24-bit ICACO ID, in hex.                                    |
| `flight_id`         | `String`. Database flight record number.                              |
| `generated_date`    | `String`. Date the message was generated.                             |
| `generated_time`    | `String`. Time the message was generated.                             |
| `logged_date`       | `String`. Date the message was logged.                                |
| `logged_time`       | `String`. Time the message was logged.                                |
| `callsign`          | `String`. Eight character flight ID or callsign.                      |
| `altitude`          | `Integer`. [Mode C][1] Altitude relative to 1013 mb (29.92" Hg).      |
| `ground_speed`      | `Integer`. Speed over ground.                                         |
| `track`             | `Integer`. Ground track angle.                                        |
| `lat`               | `Float`. Latitude.                                                    |
| `lon`               | `Float`. Longitude                                                    |
| `vertical_rate`     | `Integer`. Climb rate.                                                |
| `squawk`            | `String`. Assigned [Mode A] [1] squawk code.                          |
| `alert`             | `Boolean`. Flag to indicate that squawk has changed.                  |
| `emergency`         | `Boolean`. Flag to indicate emergency code has been set.              |
| `spi`               | `Boolean`. Flag to indicate Special Position Indicator has been set.  |
| `is_on_ground`      | `Boolean`. Flag to indicate ground squat switch is active.            |

[1]: http://en.wikipedia.org/wiki/Aviation_transponder_interrogation_modes#Mode_A_and_Mode_C

Not all message/transmission types will have values for all fields, as per the
specification.
Missing values will be represented by `null` or `undefined` (an empty
comma-delimited value is `null`).

## Message Type

There are 6 types of SBS-1 messages represented by the `MessageType`:

|Enum              |Value   |
|------------------|--------|
|`SELECTION_CHANGE`|`"SEL"` |
|`NEW_ID`          |`"ID"`  |
|`NEW_AIRCRAFT`    |`"AIR"` |
|`STATUS_AIRCRAFT` |`"STA"` |
|`CLICK`           |`"CLK"` |
|`TRANSMISSION`    |`"MSG"` |

`SELECTION_CHANGE`, `NEW_ID`, `NEW_AIRCRAFT`, `STATUS_CHANGE`, and
`CLK` indicate changes in the state of the SBS-1 software and aren't
typically used by other systems.
Dump1090 typically does not generate these message types, but if this tool is
used to ingest SBS-1 data from another source, it will be handled appropriately.

`TRANSMISSION` messages contain information sent by aircraft.

## Transmission Type

There are 8 subtypes of transmission messages, specified by the
`TransmissionType`:

|Enum                   |Value|Description                    |Spec        |
|-----------------------|-----|-------------------------------|------------|
|`ES_IDENT_AND_CATEGORY`|`1`  |ES identification and category |DF17 BDS 0,8|
|`ES_SURFACE_POS`       |`2`  |ES surface position message    |DF17 BDS 0,6|
|`ES_AIRBORNE_POS`      |`3`  |ES airborne position message   |DF17 BDS 0,5|
|`ES_AIRBORNE_VEL`      |`4`  |ES airborne velocity message   |DF17 BDS 0,9|
|`SURVEILLANCE_ALT`     |`5`  |Surveillance alt message       |DF4, DF20   |
|`SURVEILLANCE_ID`      |`6`  |Surveillance ID message        |DF5, DF21   |
|`AIR_TO_AIR`           |`7`  |Air-to-air message             |DF16        |
|`ALL_CALL_REPLY`       |`8`  |All call reply                 |DF11        |

Only `ES_SURFACE_POS` and `ES_AIRBORNE_POS` transmissions will have position
(latitude and longitude) information.

## Accessing the data

You can access your data via `psql` or `pgadmin`

*Display the most recent 5 entries*
```sql
select * from adsb_messages limit 5;
```

```
"MSG" 4 "111" "11111" "A6893C" "111111" "2019/12/02" "16:26:50.628" "2019/12/02" "16:26:50.605" 372 107 -1216 0 "2019-12-02T21:26:49.565624"
"MSG" 7 "111" "11111" "ADC934" "111111" "2019/12/02" "16:26:50.709" "2019/12/02" "16:26:50.674" 33975 0 "2019-12-02T21:26:50.622853"
"MSG" 8 "111" "11111" "A6893C" "111111" "2019/12/02" "16:26:50.886" "2019/12/02" "16:26:50.866" 0 "2019-12-02T21:26:50.690414"
"MSG" 8 "111" "11111" "ADC934" "111111" "2019/12/02" "16:26:50.916" "2019/12/02" "16:26:50.922" 0 "2019-12-02T21:26:50.881606"
"MSG" 7 "111" "11111" "ADC934" "111111" "2019/12/02" "16:26:51.165" "2019/12/02" "16:26:51.132" 34000 0 "2019-12-02T21:26:50.938408"
```

Aircraft often only broadcast some of its flight data in each transmission.
Convenience views are provided to make combining broadcasts from the same aircraft easier.

### Callsigns view

The view `callsigns` provides a per-day mapping of callsigns to the
hex_ident that should be present in every message.

To help disambiguate airline flights made by different planes with the same
flight number this view provides `first_seen` and `last_seen` columns to help
isolate which times particular callsigns were associated with particular
hex_idents.

For example, say you want to know when FedEx flights were seen in your area:
```sql
select callsign, hex_ident, date_seen, first_seen, last_seen
from callsigns
where callsign like 'FDX%'
limit 5;
```
Returns:
```
"FDX1212 "	"A119AF"	"2019-11-13"	"2019-11-13T03:02:51.430840"	"2019-11-13T03:06:51.313447"
"FDX1294 "	"A04A6D"	"2019-11-13"	"2019-11-13T03:01:13.529217"	"2019-11-13T03:01:13.529217"
"FDX26   "	"AC498C"	"2019-11-14"	"2019-11-14T22:39:50.828477"	"2019-11-14T22:39:50.828477"
"FDX3600 "	"ACF8BD"	"2019-11-13"	"2019-11-13T15:26:20.611313"	"2019-11-13T15:30:51.029379"
"FDX3601 "	"A8D62A"	"2019-11-13"	"2019-11-13T15:22:05.470790"	"2019-11-13T15:24:35.901465"
```

### Locations view

The view `locations` provides a list of locations (latitude, longitude and
altitude) mapped to the hex_ident and time the entry was parsed. Not every
hex_ident is guaranteed to be associated with a callsign, but most will be.

For example, If you wanted to track where the FedEx flight `FDX1167` went on
December 2nd- you'd use its hex_ident (A6893C) from the `callsigns` view to
isolate it:

```sql
select hex_ident, parsed_time, lon, lat, altitude
from locations
where hex_ident = 'A6893C'
limit 10;
```
Returns:
```
"hex_ident"	"parsed_time"	              "lon"	    "lat"	  "altitude"
"A6893C"	"2019-12-02T21:26:53.361368"	-76.4915	40.1673	14300
"A6893C"	"2019-12-02T21:26:54.225644"	-76.4894	40.1668	14275
"A6893C"	"2019-12-02T21:26:57.238380"	-76.4829	40.1653	14225
"A6893C"	"2019-12-02T21:27:01.167140"	-76.4743	40.1632	14125
"A6893C"	"2019-12-02T21:27:04.525464"	-76.4675	40.1615	14075
"A6893C"	"2019-12-02T21:27:09.427526"	-76.4567	40.159	13975
"A6893C"	"2019-12-02T21:27:10.410627"	-76.4548	40.1586	13950
"A6893C"	"2019-12-02T21:27:10.998482"	-76.4537	40.1583	13925
"A6893C"	"2019-12-02T21:27:12.843365"	-76.4494	40.1573	13900
```

If you have PostGIS, the geography/GIS extension installed on the
database, you can perform very powerful queries with the location data.

For example, a simple map, making points of all observed aircraft locations
in the past 24 hours:

```sql
SELECT hex_ident, ST_SetSRID(ST_MakePoint(lon, lat), 4326) FROM locations
WHERE parsed_time::timestamptz BETWEEN now() - INTERVAL '24h' AND now();
```

A display showing lines for each individual craft, for example:
```sql
select hex_ident, num, ST_MAKELINE(ST_SetSRID, geom2) 
from
(
  select hex_ident, row_number()
  over w
  as num, ST_SetSRID(ST_MakePoint(lon, lat), 4326), 
  lead(ST_SetSRID(ST_MakePoint(lon, lat), 4326)) over w as geom2
  from locations window w as (partition by hex_ident order by parsed_time)
) as q
where geom2 is not null;
```
