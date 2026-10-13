import re

from db import get_db_connection, create_schema, import_db_data
from dotenv import load_dotenv
from google import genai
from google.genai.errors import ServerError
import os

# Which prompting strategy to test: "zero_shot", "single_domain", or "cross_domain".
PROMPT_STRATEGY = "cross_domain"

# Single-domain: example question/SQL pairs written against this same PMG database.
SINGLE_DOMAIN_EXAMPLES = """
Examples:

Question: Which appointments is Leo Martinez in, and what is the status of each?
SQL:
SELECT la.appointment_id, la.scheduled_at, la.status
FROM person p
JOIN appointment_friend af ON p.person_id = af.friend_id
JOIN lesson_appointment la ON af.appointment_id = la.appointment_id
WHERE p.first_name = 'Leo' AND p.last_name = 'Martinez';

Question: Which members attended lessons with Leo Martinez?
SQL:
SELECT DISTINCT m.first_name, m.last_name, ls.actual_at
FROM person f
JOIN session_friend sf ON f.person_id = sf.friend_id
JOIN lesson_session ls ON sf.session_id = ls.session_id
JOIN session_member sm ON ls.session_id = sm.session_id
JOIN person m ON sm.member_id = m.person_id
WHERE f.first_name = 'Leo' AND f.last_name = 'Martinez';
"""

# Cross-domain: example question/SQL pairs from a different (school) database.
CROSS_DOMAIN_EXAMPLES = """
Examples from a different database (do not use these tables for PMG questions):

Schema:
student(student_id INT PRIMARY KEY, first_name VARCHAR(100), last_name VARCHAR(100))
teacher(teacher_id INT PRIMARY KEY, first_name VARCHAR(100), last_name VARCHAR(100))
class_meeting(meeting_id INT PRIMARY KEY, scheduled_at DATETIME, status VARCHAR(20))
meeting_student(meeting_id INT FOREIGN KEY -> class_meeting.meeting_id, student_id INT FOREIGN KEY -> student.student_id)
meeting_teacher(meeting_id INT FOREIGN KEY -> class_meeting.meeting_id, teacher_id INT FOREIGN KEY -> teacher.teacher_id)

Question: Which class meetings is Ana Lopez in, and what is the status of each?
SQL:
SELECT cm.meeting_id, cm.scheduled_at, cm.status
FROM student s
JOIN meeting_student ms ON s.student_id = ms.student_id
JOIN class_meeting cm ON ms.meeting_id = cm.meeting_id
WHERE s.first_name = 'Ana' AND s.last_name = 'Lopez';

Question: Which teachers have taught Ana Lopez?
SQL:
SELECT DISTINCT t.first_name, t.last_name
FROM student s
JOIN meeting_student ms ON s.student_id = ms.student_id
JOIN meeting_teacher mt ON ms.meeting_id = mt.meeting_id
JOIN teacher t ON mt.teacher_id = t.teacher_id
WHERE s.first_name = 'Ana' AND s.last_name = 'Lopez';
"""

def get_examples():
    if PROMPT_STRATEGY == "single_domain":
        return SINGLE_DOMAIN_EXAMPLES
    if PROMPT_STRATEGY == "cross_domain":
        return CROSS_DOMAIN_EXAMPLES
    return ""

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
    print(f"Connected to Gemini. Giving Gemini PMG Schema ({PROMPT_STRATEGY})...")
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
        {get_examples()}
        """)
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
                # print(f"SQL Result: {result}")
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
    except ServerError as e:
        print("*************************")
        print("Server Error Encountered.")
        print(f"Status Code: {e.code}")         # e.g., 500
        print(f"Message:{e.message}")      # Error description from the server
        print("*************************")

    cursor.close()
    connection.close()
    print("Database connection closed.")

main()