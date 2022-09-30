import os
import psycopg2

class Database:
    def __init__(self):
        self.conn = self.connect()

    def connect(self):
        """
        Connect to database and return connection
        """
        print("Connecting to PostgreSQL Database...")
        try:
            conn = psycopg2.connect(
                    host = os.getenv("POSTGRES_HOST"),
                    dbname = os.getenv("POSTGRES_DB"),
                    user = os.getenv("POSTGRES_USER"),
                    password = os.getenv("POSTGRES_PASSWORD"),
                    port = os.getenv("POSTGRES_PORT")
                )
            return conn
        except psycopg2.OperationalError as e:
            print(f"Could not connect to Database: {e}")


    def get_test(self):
        cursor = self.conn.cursor()
        cursor.execute("SELECT * FROM test;")
        return cursor.fetchall()

db = Database()
