import re

import mysql.connector
from dotenv import load_dotenv
import os

load_dotenv()

def get_db_connection():
    try:
        conn=mysql.connector.connect(
            host=os.getenv("DB_HOST"),
            port=os.getenv("DB_PORT"),
            user=os.getenv("DB_USER"),
            password=os.getenv("DB_PASSWORD"),
            database=os.getenv("DB_NAME")
        )
        conn.cursor().execute(f"CREATE DATABASE IF NOT EXISTS {os.getenv('DB_NAME')}")
        if conn.is_connected():
            print("Connected to MySQL PMG Database")
            return conn
    except mysql.connector.Error as err:
        print(f"Error: {err}")
        return None

def create_schema(conn):
    with open('db_schema.sql','r') as f:
        create_table_queries = f.read().split(';')
    cursor = conn.cursor()
    print("Creating tables...")
    for statement in create_table_queries:
        clean_statement = statement.strip() #strip whitespace, tabs, newlines
        if clean_statement:
            match = re.search(r'(?i)CREATE\s+TABLE\s+(?:IF\s+NOT\s+EXISTS\s+)?[`"\']?([a-zA-Z0-9_]+)', clean_statement)
            if match:
                table_name = match.group(1)
            else:
                table_name = clean_statement
            try:
                cursor.execute(clean_statement)
                print(f"Added table:{table_name}")
            except mysql.connector.Error as err:
                print(f"Error executing statement: {clean_statement}\nError: {err}")
    conn.commit()
    cursor.close()
    print("Database schema created successfully.")

def import_db_data(conn):
    with open('db_data.sql','r') as f:
        insert_data_queries = f.read().split(';')
    cursor = conn.cursor()
    print("Inserting data...")
    for statement in insert_data_queries:
            clean_statement = statement.strip() #strip whitespace, tabs, newlines
            if clean_statement:
                try:
                    cursor.execute(clean_statement)
                except mysql.connector.Error as err:
                    print(f"Error executing statement: {clean_statement}\nError: {err}")
    print(f"Inserted {cursor.rowcount} rows into the database.")
    conn.commit()
    cursor.close()
