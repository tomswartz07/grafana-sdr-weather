#!/usr/bin/python
# encoding: utf-8

import socket
import sys
import datetime
import argparse
import time
import psycopg2
from psycopg2 import sql

# Dump1090
dumphost = "localhost"
dumpport = 30003
# Database
dbname = "database"
dbschema = "adsb"
dbtable = "adsb_messages"
dbhost = "localhost"
dbport = "5433"
dbuser = "user"
dbpassword = ""
BUFFER_SIZE = 10000
BATCH_SIZE = 1
CONNECT_ATTEMPT_LIMIT = 10
CONNECT_ATTEMPT_DELAY = 5.0
verbose = False

def args_parse():
    parser = argparse.ArgumentParser(description="A program to process\
            dump1090 messages then insert them into a database")
    parser.add_argument("--dump1090",
                        type=str, default=dumphost,
                        help="This is the network location of your dump1090 broadcast.\
                                Defaults to %s" % (dumphost,))
    parser.add_argument("--port",
                        type=int, default=dumpport,
                        help="The port broadcasting dump1090 messages in\
                                SBS-1 BaseStation format.\
                                Defaults to %s" % (dumpport,))
    parser.add_argument("-d", "--dbname",
                        type=str, default=dbname,
                        help="The location of a database file to use or create.\
                                Defaults to %s" % (dbname,))
    parser.add_argument("--dbhost",
                        type=str, default=dbhost,
                        help="The host of the database. Defaults to %s" % (dbhost,))
    parser.add_argument("--dbport",
                        type=str, default=dbport,
                        help="The port of the database. Defaults to %s" % (dbport,))
    parser.add_argument("-U", "--dbuser",
                        type=str, default=dbuser,
                        help="The user with which to connect to the database\
                                Defaults to %s" % (dbuser,))
    parser.add_argument("--dbschema",
                        type=str, default=dbschema)
    parser.add_argument("--dbpass",
                        type=str, default=dbpassword)
    parser.add_argument("--buffer-size",
                        type=int, default=BUFFER_SIZE,
                        help="An integer of the number of bytes to read at a time from the stream.\
                                Defaults to %s" % (BUFFER_SIZE,))
    parser.add_argument("--batch-size",
                        type=int, default=BATCH_SIZE,
                        help="An integer of the number of rows to write to the database at a time.\
                                Defaults to %s" % (BATCH_SIZE,))
    parser.add_argument("--connect-attempt-limit",
                        type=int, default=CONNECT_ATTEMPT_LIMIT,
                        help="An integer of the number of times to try (and fail) to connect\
                                to the dump1090 broadcast before quitting.\
                                Defaults to %s" % (CONNECT_ATTEMPT_LIMIT,))
    parser.add_argument("--connect-attempt-delay",
                        type=float, default=CONNECT_ATTEMPT_DELAY,
                        help="The number of seconds to wait after a failed connection attempt\
                                before trying again.\
                                Defaults to %s" % (CONNECT_ATTEMPT_DELAY,))
    parser.add_argument("--verbose",
                        action="store_true", default=verbose,
                        help="Print out the messages as they're received.\
                                Defaults to quiet mode.")

    # parse command line options
    args = parser.parse_args()
    return args

def commit_data(conn, data, datestamp, args):
    "Inserts data into database, multiple transactions"
    cur = conn.cursor()
    keys = ['message_type', 'transmission_type', 'session_id', 'aircraft_id',\
            'hex_ident', 'flight_id', 'generated_date', 'generated_time', 'logged_date',\
            'logged_time', 'callsign', 'altitude', 'ground_speed', 'track', 'lat', 'lon',\
            'vertical_rate', 'squawk', 'alert', 'emergency', 'spi', 'is_on_ground', 'parsed_time']
    for d in data:
        d = d.strip("\r")
        line = d.split(",")
        if len(line) == 22:
            line.append(datestamp)
            if args.verbose:
                print(line)
            data_dict = dict(zip(keys, line))
            for key, value in data_dict.items():
                if value == '':
                    data_dict[key] = None
            insert_str = sql.SQL("insert into {} ({}) values ({})").format(
                sql.Identifier(dbtable),
                sql.SQL(', ').join(map(sql.Identifier, keys)),
                sql.SQL(', ').join(map(sql.Placeholder, keys)))
            try:
                cur.execute(insert_str, data_dict)
                conn.commit()
                return None
            except psycopg2.errors.lookup("22P02") as e:
                # Sometimes we get bad data in the correct number
                # Just roll it back, forget about it, and keep going.
                if args.verbose:
                    print(e.pgcode)
                    print(e.pgerror)
                conn.rollback()
            except psycopg2.Error as e:
                print(e.pgcode)
                print(e.pgerror)
                return sys.exit()
            except Exception as e:
                print("Issue detected: ", e)
                return None
    return None

def commit_sql(conn, sql_statement):
    "Handles committing queries to the db, single transactions"
    try:
        cur = conn.cursor()
        cur.execute(sql_statement)
        conn.commit()
        return ['ok', 'success', 'OK']
    except Exception as e:
        print("Issue detected: ", e)
        return ['remove', 'danger', 'Issue Detected']

def connect_to_db(db, user, host, password, port, schema):
    "Handle connecting to db"
    connection = "dbname='%s' user='%s' host='%s' password='%s' port='%s' application_name='%s' options='-csearch_path=%s'" % (
        db, user, host, password, port, "dump1090 ADS-B Loader", schema
        )
    try:
        print("Connecting to db")
        return psycopg2.connect(connection)

    except psycopg2.Error as e:
        print(e.pgcode)
        print(e.pgerror)
        return None

def connect_to_socket(loc, port):
    "Grab data from dump1090 socket"
    s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    s.connect((loc, port))
    return s

def main():
    "The meat of the program"
    args = args_parse()
    client = connect_to_db(args.dbname, args.dbuser, args.dbhost, args.dbpass, args.dbport, args.dbschema)
    schema_setup = "CREATE SCHEMA IF NOT EXISTS %s" % (args.dbschema)
    table_setup = """CREATE TABLE IF NOT EXISTS %s.%s(
                        message_type TEXT,
                        transmission_type INT,
                        session_id TEXT,
                        aircraft_id TEXT,
                        hex_ident TEXT,
                        flight_id TEXT,
                        generated_date TEXT,
                        generated_time TEXT,
                        logged_date TEXT,
                        logged_time TEXT,
                        callsign TEXT,
                        altitude INT,
                        ground_speed INT,
                        track INT,
                        lat REAL,
                        lon REAL,
                        vertical_rate REAL,
                        squawk TEXT,
                        alert INT,
                        emergency INT,
                        spi INT,
                        is_on_ground INT,
                        parsed_time TEXT
                );
        """ % (args.dbschema, dbtable)

    callsign_view = """CREATE OR REPLACE VIEW callsigns AS
                       SELECT callsign,
                       hex_ident,
                       date(parsed_time) date_seen,
                       max(parsed_time) last_seen,
                       min(parsed_time) first_seen
                       FROM %s
                       WHERE callsign <> ''
                       GROUP BY callsign, hex_ident, date_seen;
        """ % (dbtable)

    locations_view = """CREATE OR REPLACE VIEW locations AS
                        SELECT hex_ident,
                        parsed_time,
                        lon,
                        lat,
                        altitude
                        FROM %s
                        WHERE lat IS NOT NULL;
        """ % (dbtable)

    flights_view = """CREATE OR REPLACE VIEW flights AS
                      SELECT DISTINCT l.*, cs.callsign
                      FROM locations l JOIN callsigns cs
                      ON (l.hex_ident = cs.hex_ident
                      and l.parsed_time::timestamp <= (cs.last_seen::timestamp + '10 minutes'::interval)
                      and l.parsed_time::timestamp >= (cs.first_seen::timestamp - '10 minutes'::interval));
        """
    commit_sql(client, schema_setup)
    commit_sql(client, table_setup)
    commit_sql(client, callsign_view)
    commit_sql(client, locations_view)
    commit_sql(client, flights_view)

    count_failed_connection_attempts = 1

    while count_failed_connection_attempts < args.connect_attempt_limit:
        try:
            s = connect_to_socket(args.dump1090, args.port)
            count_failed_connection_attempts = 1
            print("Connected to dump1090 broadcast")
            break
        except socket.error:
            count_failed_connection_attempts += 1
            print("Cannot connect to dump1090 broadcast.\
                    Making attempt %s." % (count_failed_connection_attempts))
            time.sleep(args.connect_attempt_delay)
    else:
        print("Failed to get socket connection")
        sys.exit()

    data_str = ""

    try:
        #loop until an exception
        while True:
            #get current time
            cur_time = datetime.datetime.utcnow()
            ds = cur_time.isoformat()
            ts = cur_time.strftime("%H:%M:%S")
            data_str = ""

            # receive a stream message
            try:
                message = ""
                message = s.recv(args.buffer_size).decode('UTF-8')
                data_str += message.strip("\n")
            except socket.error:
                # this happens if there is no connection and is dealt with below
                pass

            if not message:
                print((ts, "No broadcast received. Attempting to reconnect"))
                time.sleep(args.connect_attempt_delay)
                s.close()
                while count_failed_connection_attempts < args.connect_attempt_limit:
                    try:
                        s = connect_to_socket(args.dump1090, args.port)
                        count_failed_connection_attempts = 1
                        print("Reconnected!")
                        break
                    except socket.error:
                        count_failed_connection_attempts += 1
                        print("The attempt failed.\
                                Making attempt %s." % (count_failed_connection_attempts))
                        time.sleep(args.connect_attempt_delay)
                else:
                    sys.exit()
                continue
            data = data_str.split("\n")
            commit_data(client, data, ds, args)
    except KeyboardInterrupt:
        print("\n%s Closing connection" % (ts,))
        s.close()
        client.commit()
        client.close()

if __name__ == '__main__':
    main()
