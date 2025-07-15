from pymongo import MongoClient
from werkzeug.security import generate_password_hash, check_password_hash
from dotenv import load_dotenv
import os
from datetime import datetime, timedelta

# Load environment variables
load_dotenv()
MONGO_URI = os.getenv('MONGO_URI')

# Initialize MongoDB client
client = MongoClient(MONGO_URI)
db = client['bingebuddy']  # Database name

def init_db():
    # Create indexes for efficient queries and uniqueness
    db.users.create_index("username", unique=True)
    db.users.create_index("email", unique=True)
    db.watchlist.create_index([("user_id", 1), ("item_id", 1), ("item_type", 1)], unique=True)
    db.watched.create_index([("user_id", 1), ("item_id", 1), ("item_type", 1)], unique=True)
    db.cache.create_index("type", unique=True)
    db.reset_codes.create_index("email", unique=True)  # Index for reset codes
    db.reset_codes.create_index("created_at", expireAfterSeconds=600)  # Codes expire after 10 minutes
    print("Initialized MongoDB collections with indexes")

def register_user(user_id, username, email, password):
    password_hash = generate_password_hash(password)
    try:
        db.users.insert_one({
            "user_id": user_id,
            "username": username,
            "email": email,
            "password_hash": password_hash
        })
        return True
    except Exception as e:
        if "E11000 duplicate key error" in str(e):
            return False
        raise e

def authenticate_user(username_or_email, password):
    user = db.users.find_one({"$or": [{"username": username_or_email}, {"email": username_or_email}]})
    if user and check_password_hash(user['password_hash'], password):
        return user['user_id']
    return None

def save_to_cache(type, data):
    db.cache.replace_one(
        {"type": type},
        {"type": type, "data": data, "timestamp": datetime.utcnow()},
        upsert=True
    )

def get_from_cache(type):
    cache_entry = db.cache.find_one({"type": type})
    if cache_entry:
        # Check if cache is less than 1 day old
        if cache_entry['timestamp'] > datetime.utcnow() - timedelta(days=1):
            return cache_entry['data']
    return None

def store_reset_code(email, code):
    """Store a 4-digit code for the given email, replacing any existing code."""
    try:
        db.reset_codes.replace_one(
            {"email": email},
            {
                "email": email,
                "code": code,
                "created_at": datetime.utcnow()
            },
            upsert=True
        )
        return True
    except Exception as e:
        print(f"Error storing reset code: {str(e)}")
        return False

def verify_reset_code(email, code):
    """Verify if the provided code matches the stored code for the email."""
    reset_entry = db.reset_codes.find_one({"email": email})
    if reset_entry and reset_entry['code'] == code:
        # Code is valid; TTL index handles expiration
        return True
    return False

def update_user_password(email, new_password):
    """Update the user's password by email."""
    password_hash = generate_password_hash(new_password)
    try:
        result = db.users.update_one(
            {"email": email},
            {"$set": {"password_hash": password_hash}}
        )
        if result.matched_count == 0:
            return False
        # Delete the used reset code
        db.reset_codes.delete_one({"email": email})
        return True
    except Exception as e:
        print(f"Error updating password: {str(e)}")
        return False