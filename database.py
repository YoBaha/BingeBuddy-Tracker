import sqlite3
from werkzeug.security import generate_password_hash, check_password_hash

def init_db():
    conn = sqlite3.connect('cache.db')
    cursor = conn.cursor()
    # Users table
    cursor.execute('''
        CREATE TABLE IF NOT EXISTS users (
            user_id TEXT PRIMARY KEY,
            username TEXT UNIQUE NOT NULL,
            email TEXT UNIQUE NOT NULL,
            password_hash TEXT NOT NULL
        )
    ''')
    # Cache table with timestamp
    cursor.execute('''
        CREATE TABLE IF NOT EXISTS cache (
            type TEXT PRIMARY KEY,
            data TEXT,
            timestamp DATETIME DEFAULT CURRENT_TIMESTAMP
        )
    ''')
    # Watchlist table
    cursor.execute('''
        CREATE TABLE IF NOT EXISTS watchlist (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            user_id TEXT,
            item_id TEXT,
            item_type TEXT,
            priority INTEGER,
            metadata TEXT,
            FOREIGN KEY (user_id) REFERENCES users (user_id)
        )
    ''')
    # Watched table
    cursor.execute('''
        CREATE TABLE IF NOT EXISTS watched (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            user_id TEXT,
            item_id TEXT,
            item_type TEXT,
            rating INTEGER,  -- Rating from 1 to 5
            metadata TEXT,
            FOREIGN KEY (user_id) REFERENCES users (user_id)
        )
    ''')
    conn.commit()
    conn.close()

def add_metadata_column():
    try:
        conn = sqlite3.connect('cache.db')
        cursor = conn.cursor()
        cursor.execute('ALTER TABLE watchlist ADD COLUMN metadata TEXT')
        cursor.execute('ALTER TABLE watched ADD COLUMN metadata TEXT')  # Add to watched table
        conn.commit()
        conn.close()
        print("Added metadata column to watchlist and watched tables")
    except sqlite3.OperationalError as e:
        if "duplicate column name" in str(e):
            print("Metadata column already exists")
        else:
            raise e

def add_timestamp_column():
    try:
        conn = sqlite3.connect('cache.db')
        cursor = conn.cursor()
        cursor.execute('ALTER TABLE cache ADD COLUMN timestamp DATETIME DEFAULT CURRENT_TIMESTAMP')
        conn.commit()
        conn.close()
        print("Added timestamp column to cache table")
    except sqlite3.OperationalError as e:
        if "duplicate column name" in str(e):
            print("Timestamp column already exists")
        else:
            raise e

def register_user(user_id, username, email, password):
    password_hash = generate_password_hash(password)
    try:
        conn = sqlite3.connect('cache.db')
        cursor = conn.cursor()
        cursor.execute('INSERT INTO users (user_id, username, email, password_hash) VALUES (?, ?, ?, ?)',
                       (user_id, username, email, password_hash))
        conn.commit()
        conn.close()
        return True
    except sqlite3.IntegrityError:
        return False  

def authenticate_user(username_or_email, password):
    conn = sqlite3.connect('cache.db')
    cursor = conn.cursor()
    cursor.execute('SELECT user_id, password_hash FROM users WHERE username = ? OR email = ?',
                   (username_or_email, username_or_email))
    user = cursor.fetchone()
    conn.close()
    if user and check_password_hash(user[1], password):
        return user[0]  
    return None

def save_to_cache(type, data):
    conn = sqlite3.connect('cache.db')
    cursor = conn.cursor()
    cursor.execute('INSERT OR REPLACE INTO cache (type, data, timestamp) VALUES (?, ?, CURRENT_TIMESTAMP)', (type, data))
    conn.commit()
    conn.close()

def get_from_cache(type):
    conn = sqlite3.connect('cache.db')
    cursor = conn.cursor()
    cursor.execute('SELECT data FROM cache WHERE type = ? AND timestamp > datetime("now", "-1 day")', (type,))
    result = cursor.fetchone()
    conn.close()
    return result[0] if result else None