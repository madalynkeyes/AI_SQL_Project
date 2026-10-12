from db import get_db_connection, create_schema, import_db_data
def main():
    try:
        conn = get_db_connection()
    except Exception as e:
        print(f"An error occurred while connecting to the database: {e}")
        conn = None
    if conn:
        try:
            create_schema(conn)
            # import_db_data(conn)
        finally:
            conn.close()
    else:
        print("Failed to connect to the PMG database. Please check your database configuration and make sure that MySQL is running.")

main()