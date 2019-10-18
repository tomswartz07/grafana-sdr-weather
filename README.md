# RTL-SDR Weather

This project aims to make a simple adapter to convert output between 
an RTL-SDR software defined radio and a PostgreSQL database.

This allows for Grafana to query and display interesting and insightful graphs.

![](https://i.imgur.com/NgZUObX.png)


## Requirements

- [rtl_433](https://github.com/merbanan/rtl_433)
- Python3
- psycopg2
- PostgreSQL
- Grafana

## Usage

This program operates as a 'middleware' for `RTL_433` and can receive JSON output.

Edit the `postgres-433.py` script, line 104, to enter the relevant credentials.

Initiate the program as such:
```
rtl_433 -c ~/.config.conf -F json | tee /dev/stderr | ./postgres-433.py
```

This will direct `rtl_433` to output the information as json,
then the data is `tee`d to the terminal (so received signals may be monitored)
and finally passed into the script.

If no errors are presented, then the data should be streaming to the Postgres DB.

From there, you may run Grafana and query the data for graphing.
An example dashboard `weather.json` file has been included for quick reference.

