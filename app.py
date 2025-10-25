import os
import logging
from flask import Flask
import psycopg2
from datetime import datetime

app = Flask(__name__)

# Настройка логирования
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler('/app/logs/app.log'),
        logging.StreamHandler()
    ]
)

# Настройки базы данных из переменных окружения
DB_CONFIG = {
    "host": os.getenv("DB_HOST"),
    "database": os.getenv("DB_NAME"),
    "user": os.getenv("DB_USER"),
    "password": os.getenv("DB_PASSWORD")
}

def get_db_connection():
    """Создание соединения с базой данных"""
    try:
        conn = psycopg2.connect(**DB_CONFIG)
        return conn
    except Exception as e:
        logging.error(f"Database connection error: {e}")
        raise

@app.route("/")
def index():
    try:
        logging.info(f"Request to index page at {datetime.now()}")

        with get_db_connection() as conn:
            with conn.cursor() as cur:
                cur.execute("SELECT name FROM users;")
                users = [row[0] for row in cur.fetchall()]

        logging.info(f"Successfully retrieved {len(users)} users from database")

    except Exception as e:
        logging.error(f"Database error: {e}")
        return f"❌ Database error: {e}"

    users_html = "<br>".join(f"- {name}" for name in users)
    return f"""
    👋 Hello from Flask + PostgreSQL!<br>
    Current users in DB:<br>
    {users_html}<br>
    """

@app.route("/add/<name>")
def add_user(name):
    """Добавление нового пользователя в базу"""
    try:
        logging.info(f"Adding new user: {name}")

        with get_db_connection() as conn:
            with conn.cursor() as cur:
                cur.execute("INSERT INTO users (name) VALUES (%s);", (name,))
                conn.commit()

        logging.info(f"Successfully added user: {name}")
        return f"✅ User '{name}' added successfully!"

    except Exception as e:
        logging.error(f"Error adding user: {e}")
        return f"❌ Error adding user: {e}"

if __name__ == "__main__":
    # Проверка наличия всех необходимых переменных окружения
    required_vars = ['DB_HOST', 'DB_USER', 'DB_PASSWORD', 'DB_NAME']
    missing_vars = [var for var in required_vars if not os.getenv(var)]

    if missing_vars:
        logging.error(f"Missing environment variables: {', '.join(missing_vars)}")
        raise ValueError(f"Missing environment variables: {', '.join(missing_vars)}")

    app.run(host="0.0.0.0", port=5000)
