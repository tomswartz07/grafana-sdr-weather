#!/usr/bin/env python3
import json
from json.decoder import JSONDecodeError
import sys
from datetime import datetime
import itertools
import psycopg2


mappings = {
        'maybetemp': None,
        'temperature': None,
        'temperature_C': None,
        'temperature_C1': None,
        'temperature_C2': None,
        'temperature_F': None,
        'ptemperature_C': None,

        'pressure_bar': None,
        'pressure_hPa': None,
        'pressure_PSI': None,

        'humidity': None,
        'phumidity': None,
        'moisture': None,

        'windstrength': None,
        'gust': None,
        'average': None,
        'speed': None,
        'wind_gust': None,
        'wind_speed': None,
        'wind_speed_mph': None,

        'winddirection': None,
        'direction': None,
        'wind_direction': None,
        'wind_dir_deg': None,
        'wind_dir': None,

        'rssi': None,
        'snr': None,

        'battery': None,
        'battery_mV': None,

        'rain': None,
        'rain_rate': None,
        'total_rain': None,
        'rain_total': None,
        'rainfall_accumulation': None,
        'raincounter_raw': None,

        'status': None,
        'state': None,
        'tristate': str,
        'button1': None,
        'button2': None,
        'button3': None,
        'button4': None,
        'flags': lambda x: int(str(x), base=16),
        'event': lambda x: int(str(x), base=16),
        'cmd': None,
        'cmd_id': None,
        'code': None,
        'power0': None,
        'power1': None,
        'power2': None,
        'dim_value': None,
        'depth': None,
        'depth_cm': None,
        'energy': None,
        'data': None,
        'repeat': None,
        'current': None,
        'interval': None,

        'heating': None,
        'heating_temp': None,
        'water': None,
}

def connect_to_db(dbname, user, host, password, port):
    connection = "dbname='%s' user='%s' host='%s' password='%s' port='%s' application_name='%s'" % (
        dbname, user, host, password, port, "RTL433")
    try:
        print("Connecting to db")
        return psycopg2.connect(connection)

    except psycopg2.Error as e:
        print(e.pgcode)
        print(e.pgerror)
        return None

def commit_sql(conn, sql):
    try:
        cur = conn.cursor()
        cur.execute(sql)
        conn.commit()
        conn.close()
        return ['ok', 'success', 'OK']
    except Exception as e:
        print("Issue detected: ", e)
        return ['remove', 'danger', 'Issue Detected']

client = connect_to_db('database', 'user', 'host', 'password', 'port')
print("Connected!")
#test_table = 'CREATE TABLE IF NOT EXISTS weather (id serial PRIMARY KEY, info varchar, data jsonb)'
#commit_sql(client, test_table)

source = sys.stdin
if sys.argv[1:]:
    print("Reading input from file {}".format(sys.argv[1:]))
    files = map(lambda name: open(name, 'r'), sys.argv[1:])
    source = itertools.chain.from_iterable(files)
for line in source:
    try:
        json_in = json.loads(line)
    except JSONDecodeError as e:
        print("error {} decoding {}".format(e, line.strip()), file=sys.stderr)
        continue

    if not 'model' in json_in:
        continue
    time = json_in.pop('time') if 'time' in json_in else datetime.now().isoformat()

    json_out = {
        "measurement": json_in.pop('model'),
        "time": time,
        "tags": {},
        "fields": {},
    }
    for n, mapping in mappings.items():
        if n in json_in:
            mapping = mapping or (lambda x: x)
            try:
                value = json_in.pop(n)
                json_out['fields'][n] = mapping(value)
            except Exception as e:
                print('error {} mapping {}'.format(e, value))
                continue
    json_out['tags'] = json_in # the remainder

    if json_out['fields']:
        continue # invalid: we have no data #TODO: notify about error

    try:
        insert_data = "INSERT INTO %s (info, data) VALUES ('', '%s') ON CONFLICT DO NOTHING" % ("weather", json.dumps(json_out))
        commit_sql(client, insert_data)
    except Exception as e:
        print("error {} writing {}".format(e, json_out), file=sys.stderr)
