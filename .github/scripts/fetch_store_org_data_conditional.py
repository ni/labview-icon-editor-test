import requests
import mysql.connector
import os
from datetime import datetime

# Environment variables
GITHUB_TOKEN = os.getenv("GITHUB_TOKEN")
ORG_NAME = os.getenv("ORG_NAME")
REQUIRED_TOPIC = os.getenv("REQUIRED_TOPIC")
MYSQL_HOST = os.getenv("MYSQL_HOST")
MYSQL_USER = os.getenv("MYSQL_USER")
MYSQL_PASSWORD = os.getenv("MYSQL_PASSWORD")
MYSQL_DATABASE = os.getenv("MYSQL_DATABASE")
HEADERS = {"Authorization": f"Bearer {GITHUB_TOKEN}"}

# MySQL connection
def connect_to_mysql():
    try:
        conn = mysql.connector.connect(
            host=MYSQL_HOST,
            user=MYSQL_USER,
            password=MYSQL_PASSWORD,
            database=MYSQL_DATABASE
        )
        return conn
    except mysql.connector.Error as err:
        print(f"Error connecting to MySQL: {err}")
        raise

# Create tables if not exist
def create_tables(cursor):
    cursor.execute("""
        CREATE TABLE IF NOT EXISTS traffic_views (
            id INT AUTO_INCREMENT PRIMARY KEY,
            repo_owner VARCHAR(255),
            repo_name VARCHAR(255),
            timestamp DATETIME,
            count INT,
            uniques INT
        )
    """)
    cursor.execute("""
        CREATE TABLE IF NOT EXISTS traffic_clones (
            id INT AUTO_INCREMENT PRIMARY KEY,
            repo_owner VARCHAR(255),
            repo_name VARCHAR(255),
            timestamp DATETIME,
            count INT,
            uniques INT
        )
    """)
    cursor.execute("""
        CREATE TABLE IF NOT EXISTS stargazers (
            id INT AUTO_INCREMENT PRIMARY KEY,
            repo_owner VARCHAR(255),
            repo_name VARCHAR(255),
            user VARCHAR(255),
            starred_at DATETIME
        )
    """)

# Fetch data from GitHub API
def fetch_data(url):
    print(f"Fetching data from: {url}")  # Debug: log the API URL
    response = requests.get(url, headers=HEADERS)
    print(f"Response status: {response.status_code}")  # Debug: log response status
    if response.status_code == 200:
        return response.json()
    else:
        print(f"Error fetching data from {url}: {response.text}")  # Debug: log response error
        return None

# Fetch all repositories under the organization
def fetch_org_repositories(org_name):
    url = f"https://api.github.com/orgs/{org_name}/repos"
    repos = []
    page = 1
    while True:
        response = fetch_data(f"{url}?per_page=100&page={page}")
        if not response:
            break
        repos.extend(response)  # Append repositories
        if len(response) < 100:  # End of pagination
            break
        page += 1
    print(f"Fetched {len(repos)} repositories from organization '{org_name}'")  # Debug: log total repos
    return repos

# Check if a repository has the required topic
def has_required_topic(owner, repo, required_topic):
    url = f"https://api.github.com/repos/{owner}/{repo}/topics"
    response = fetch_data(url)
    if response and "names" in response:
        topics = response["names"]
        print(f"Repository '{owner}/{repo}' topics: {topics}")  # Debug: log topics
        return required_topic in topics
    print(f"Failed to fetch topics for '{owner}/{repo}'")  # Debug: log failure
    return False

# Insert data into MySQL
def store_traffic_views(data, owner, repo, cursor):
    for view in data.get("views", []):
        cursor.execute("""
            INSERT INTO traffic_views (repo_owner, repo_name, timestamp, count, uniques)
            VALUES (%s, %s, %s, %s, %s)
        """, (owner, repo, view["timestamp"], view["count"], view["uniques"]))

def store_traffic_clones(data, owner, repo, cursor):
    for clone in data.get("clones", []):
        cursor.execute("""
            INSERT INTO traffic_clones (repo_owner, repo_name, timestamp, count, uniques)
            VALUES (%s, %s, %s, %s, %s)
        """, (owner, repo, clone["timestamp"], clone["count"], clone["uniques"]))

def store_stargazers(data, owner, repo, cursor):
    for stargazer in data:
        cursor.execute("""
            INSERT INTO stargazers (repo_owner, repo_name, user, starred_at)
            VALUES (%s, %s, %s, %s)
        """, (owner, repo, stargazer["user"]["login"], stargazer["starred_at"]))

# Process a single repository
def process_repository(owner, repo, cursor):
    base_url = f"https://api.github.com/repos/{owner}/{repo}"
    traffic_views_url = f"{base_url}/traffic/views"
    traffic_clones_url = f"{base_url}/traffic/clones"
    stargazers_url = f"{base_url}/stargazers"

    # Fetch and store traffic views
    traffic_views = fetch_data(traffic_views_url)
    if traffic_views:
        print(f"Storing traffic views for '{owner}/{repo}'")  # Debug: log data store action
        store_traffic_views(traffic_views, owner, repo, cursor)

    # Fetch and store traffic clones
    traffic_clones = fetch_data(traffic_clones_url)
    if traffic_clones:
        print(f"Storing traffic clones for '{owner}/{repo}'")  # Debug: log data store action
        store_traffic_clones(traffic_clones, owner, repo, cursor)

    # Fetch and store stargazers
    stargazers = fetch_data(stargazers_url)
    if stargazers:
        print(f"Storing stargazers for '{owner}/{repo}'")  # Debug: log data store action
        store_stargazers(stargazers, owner, repo, cursor)

# Main function
def main():
    # Fetch repositories under the organization
    repos = fetch_org_repositories(ORG_NAME)

    # Connect to MySQL
    conn = connect_to_mysql()
    cursor = conn.cursor()

    # Create tables
    create_tables(cursor)

    detected_repos = []  # List to track repositories with the required topic
    skipped_repos = []   # List to track repositories skipped

    # Process repositories with the required topic
    for repo in repos:
        owner = repo.get("owner", {}).get("login")  # Get repository owner
        repo_name = repo.get("name")  # Get repository name
        if owner and repo_name and has_required_topic(owner, repo_name, REQUIRED_TOPIC):
            print(f"Processing repository: {owner}/{repo_name}")  # Debug: log processing
            detected_repos.append(f"{owner}/{repo_name}")  # Add to detected list
            process_repository(owner, repo_name, cursor)
        else:
            reason = "Missing required topic" if owner and repo_name else "Invalid repository data"
            print(f"Skipping repository: {repo_name} ({reason})")  # Debug: log skip reason
            skipped_repos.append(f"{repo_name}: {reason}")

    # Commit and close
    conn.commit()
    cursor.close()
    conn.close()

    # Summary report
    print("\n--- Summary Report ---")
    print(f"Repositories with the topic '{REQUIRED_TOPIC}': {detected_repos}")
    print(f"Skipped repositories: {skipped_repos}")
    print("\nData stored successfully!")

if __name__ == "__main__":
    main()
