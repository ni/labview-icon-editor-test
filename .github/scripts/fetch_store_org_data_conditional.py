import requests
import mysql.connector
import os
from datetime import datetime

# Environment variables from GitHub Actions
GITHUB_TOKEN = os.getenv("GITHUB_TOKEN")
REPO_OWNER = os.getenv("REPO_OWNER")
REPO_NAME = os.getenv("REPO_NAME")
MYSQL_HOST = os.getenv("MYSQL_HOST")
MYSQL_USER = os.getenv("MYSQL_USER")
MYSQL_PASSWORD = os.getenv("MYSQL_PASSWORD")
MYSQL_DATABASE = os.getenv("MYSQL_DATABASE")
HEADERS = {"Authorization": f"Bearer {GITHUB_TOKEN}"}

# API URLs
BASE_URL = f"https://api.github.com/repos/{REPO_OWNER}/{REPO_NAME}"
TRAFFIC_VIEWS_URL = f"{BASE_URL}/traffic/views"
TRAFFIC_CLONES_URL = f"{BASE_URL}/traffic/clones"
STARGAZERS_URL = f"{BASE_URL}/stargazers"

# Connect to MySQL database
def connect_to_mysql():
    try:
        # Attempt to connect to the specified database
        return mysql.connector.connect(
            host=MYSQL_HOST,
            user=MYSQL_USER,
            password=MYSQL_PASSWORD,
            database=MYSQL_DATABASE
        )
    except mysql.connector.errors.ProgrammingError as e:
        # Check for "Unknown database" error
        if "Unknown database" in str(e):
            print(f"Database '{MYSQL_DATABASE}' does not exist. Creating it...")
            # Connect to MySQL without specifying a database
            conn = mysql.connector.connect(
                host=MYSQL_HOST,
                user=MYSQL_USER,
                password=MYSQL_PASSWORD
            )
            cursor = conn.cursor()
            # Create the database
            cursor.execute(f"CREATE DATABASE {MYSQL_DATABASE}")
            conn.commit()
            cursor.close()
            conn.close()
            # Reconnect to the newly created database
            return mysql.connector.connect(
                host=MYSQL_HOST,
                user=MYSQL_USER,
                password=MYSQL_PASSWORD,
                database=MYSQL_DATABASE
            )
        else:
            raise

# Create tables if not exist
def create_tables(cursor):
    cursor.execute("""
        CREATE TABLE IF NOT EXISTS traffic_views (
            id INT AUTO_INCREMENT PRIMARY KEY,
            timestamp DATETIME,
            count INT,
            uniques INT
        )
    """)
    cursor.execute("""
        CREATE TABLE IF NOT EXISTS traffic_clones (
            id INT AUTO_INCREMENT PRIMARY KEY,
            timestamp DATETIME,
            count INT,
            uniques INT
        )
    """)
    cursor.execute("""
        CREATE TABLE IF NOT EXISTS stargazers (
            id INT AUTO_INCREMENT PRIMARY KEY,
            user VARCHAR(255),
            starred_at DATETIME
        )
    """)

# Fetch data from GitHub API
def fetch_data(url):
    response = requests.get(url, headers=HEADERS)
    if response.status_code == 200:
        return response.json()
    else:
        print(f"Error fetching {url}: {response.status_code}")
        return None

# Insert traffic views into MySQL
def store_traffic_views(data, cursor):
    for view in data.get("views", []):
        cursor.execute("""
            INSERT INTO traffic_views (timestamp, count, uniques)
            VALUES (%s, %s, %s)
        """, (view["timestamp"], view["count"], view["uniques"]))

# Insert traffic clones into MySQL
def store_traffic_clones(data, cursor):
    for clone in data.get("clones", []):
        cursor.execute("""
            INSERT INTO traffic_clones (timestamp, count, uniques)
            VALUES (%s, %s, %s)
        """, (clone["timestamp"], clone["count"], clone["uniques"]))

# Insert stargazers into MySQL
def store_stargazers(data, cursor):
    for stargazer in data:
        cursor.execute("""
            INSERT INTO stargazers (user, starred_at)
            VALUES (%s, %s)
        """, (stargazer["user"]["login"], stargazer["starred_at"]))

# Main function
def main():
    # Connect to MySQL
    conn = connect_to_mysql()
    cursor = conn.cursor()

    # Create tables
    create_tables(cursor)

    # Fetch and store traffic views
    traffic_views = fetch_data(TRAFFIC_VIEWS_URL)
    if traffic_views:
        store_traffic_views(traffic_views, cursor)

    # Fetch and store traffic clones
    traffic_clones = fetch_data(TRAFFIC_CLONES_URL)
    if traffic_clones:
        store_traffic_clones(traffic_clones, cursor)

    # Fetch and store stargazers
    stargazers = fetch_data(STARGAZERS_URL)
    if stargazers:
        store_stargazers(stargazers, cursor)

    # Commit and close
    conn.commit()
    cursor.close()
    conn.close()
    print("Data stored successfully!")

if __name__ == "__main__":
    main()