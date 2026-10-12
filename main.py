import re

from db import get_db_connection, create_schema, import_db_data
from dotenv import load_dotenv
from google import genai
from google.genai.errors import ServerError
import os

def setup_db():
    try:
        conn = get_db_connection()
    except Exception as e:
        print(f"An error occurred while connecting to the database: {e}")
        conn = None
    if conn:
        create_schema(conn)
        import_db_data(conn)
        return conn
        
    else:
        print("Failed to connect to the PMG database. Please check your database configuration and make sure that MySQL is running.")
        return None

def get_schema_text(cursor, database_name):
    cursor.execute(
        """
        SELECT
            c.TABLE_NAME,
            c.COLUMN_NAME,
            c.COLUMN_TYPE,
            c.IS_NULLABLE,
            c.COLUMN_KEY,
            k.REFERENCED_TABLE_NAME,
            k.REFERENCED_COLUMN_NAME
        FROM INFORMATION_SCHEMA.COLUMNS AS c
        LEFT JOIN INFORMATION_SCHEMA.KEY_COLUMN_USAGE AS k
          ON k.TABLE_SCHEMA = c.TABLE_SCHEMA
         AND k.TABLE_NAME = c.TABLE_NAME
         AND k.COLUMN_NAME = c.COLUMN_NAME
         AND k.REFERENCED_TABLE_NAME IS NOT NULL
        WHERE c.TABLE_SCHEMA = %s
        ORDER BY c.TABLE_NAME, c.ORDINAL_POSITION
        """,
        (database_name,),
    )

    tables = {}

    for table, column, column_type, nullable, key, ref_table, ref_column in cursor.fetchall():
        details = f"{column} {column_type}"
        if key == "PRI":
            details += " PRIMARY KEY"
        if ref_table:
            details += f" FOREIGN KEY -> {ref_table}.{ref_column}"
        if nullable == "NO":
            details += " NOT NULL"

        tables.setdefault(table, []).append(details)

    return "\n".join(
        f"{table}({', '.join(columns)})"
        for table, columns in tables.items()
    )

def extract_sql(text):
    match = re.search(r"```(?:sql)?\s*(.*?)```", text, flags=re.IGNORECASE | re.DOTALL)
    return match.group(1).strip() if match else text.strip()



def main():
    load_dotenv()
    connection = setup_db()
    cursor = connection.cursor()

    schema = get_schema_text(cursor, "pmg")

    print("Connecting to Gemini API...")
    client = genai.Client(api_key=os.getenv("GEMINI_API_KEY"))
    chat = client.chats.create(model="gemini-3.1-flash-lite")
    print("Connected to Gemini. Giving Gemini PMG Schema...")
    # Send the schema once when this chat starts.
    try:
        chat.send_message(f"""
        You write read-only MySQL 8.0 SELECT queries.
        Use only the schema below; do not invent tables or columns.
        For each question, return the SQL query only.

        Schema:
        {schema}

        Business rule:
        Actively progressing means a completed lesson in the last 7 days
        or a commitment kept in the last 7 days.
        """)
    except ServerError as e:
        print("Server Error Encountered.")
        print(f"Status Code: {e.code}")         # e.g., 500
        print(f"Message:     {e.message}")      # Error description from the server

    while True:
        question = input("Ask about your database (or type 'quit'): ").strip()
        if question.lower() == "quit":
            break

        response = chat.send_message(question)
        print("-----------------------------------------")
        print(response.text)
        print("-----------------------------------------")
        confirmation = input("Would you like to execute this query? (Y/N): ").strip().lower()
        if confirmation == 'y':
            sql_query = extract_sql(response.text)
            cursor.execute(sql_query)
            result = cursor.fetchall()
            interpreted = chat.send_message(f"""This is the result that was given from that query. 
            What does this result mean? For example,
            if I had asked "How many friends do I have?" and I got "[(3,)]", I would return the 
            interpreted message as "You have 3 friends."
            Result: {result}
            """)
            print(interpreted.text)
            # return True
        elif confirmation == 'n':
            print("We won't execute this query.")
            # return False
        else:
            print("Invalid input. Please enter 'y' or 'n'.")

    cursor.close()
    connection.close()
    print("Database connection closed.")

main()