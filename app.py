from flask import Flask, jsonify, request
from dotenv import load_dotenv
import os
import requests
import json
import uuid
import smtplib  # Add for email sending
import random   # Add for 4-digit code generation
from datetime import datetime, timedelta
from pymongo import MongoClient
from bson import ObjectId
from email.mime.text import MIMEText  # Add for email formatting
from database import (  # Import required database functions
    init_db,
    register_user,
    authenticate_user,
    save_to_cache,
    get_from_cache,
    store_reset_code,
    verify_reset_code,
    update_user_password
)

app = Flask(__name__)

# Load environment variables
load_dotenv()
TMDB_API_KEY = os.getenv('TMDB_API_KEY')
TMDB_BASE_URL = os.getenv('TMDB_BASE_URL')
MONGO_URI = os.getenv('MONGO_URI')
SMTP_HOST = os.getenv('SMTP_HOST')
SMTP_PORT = int(os.getenv('SMTP_PORT', 587))
SMTP_EMAIL = os.getenv('SMTP_EMAIL')
SMTP_PASSWORD = os.getenv('SMTP_PASSWORD')

# Initialize MongoDB client
client = MongoClient(MONGO_URI)
db = client['bingebuddy']

# Initialize database
init_db()


# Health check endpoint to keep Render service awake
@app.route('/healthz', methods=['GET'])
def healthz():
    return jsonify({'status': 'OK'}), 200

# Register a new user
@app.route('/api/register', methods=['POST'])
def register():
    data = request.json
    username = data.get('username')
    email = data.get('email')
    password = data.get('password')
    if not username or not email or not password:
        return jsonify({'error': 'Username, email, and password are required'}), 400
    
    user_id = str(uuid.uuid4())
    if register_user(user_id, username, email, password):
        return jsonify({'status': 'success', 'user_id': user_id}), 201
    return jsonify({'error': 'Username or email already exists'}), 409

# Login user
@app.route('/api/login', methods=['POST'])
def login():
    data = request.json
    username_or_email = data.get('username_or_email')
    password = data.get('password')
    if not username_or_email or not password:
        return jsonify({'error': 'Username/email and password are required'}), 400
    
    user_id = authenticate_user(username_or_email, password)
    if user_id:
        return jsonify({'status': 'success', 'user_id': user_id}), 200
    return jsonify({'error': 'Invalid credentials'}), 401

# Fetch trending movies
@app.route('/api/movies/trending', methods=['GET'])
def get_trending_movies():
    cache_key = 'trending_movies'
    cached_data = get_from_cache(cache_key)
    if cached_data:
        return jsonify(json.loads(cached_data))

    try:
        url = f'{TMDB_BASE_URL}/trending/movie/week?api_key={TMDB_API_KEY}'
        response = requests.get(url)
        response.raise_for_status()
        data = response.json()
        save_to_cache(cache_key, json.dumps(data))
        return jsonify(data)
    except requests.exceptions.RequestException as e:
        return jsonify({'error': str(e)}), 500

# Search movies
@app.route('/api/movies/search', methods=['GET'])
def search_movies():
    query = request.args.get('query', '')
    if not query:
        return jsonify({'error': 'Query parameter is required'}), 400

    cache_key = f'search_movies_{query}'
    cached_data = get_from_cache(cache_key)
    if cached_data:
        return jsonify(json.loads(cached_data))

    try:
        url = f'{TMDB_BASE_URL}/search/movie?api_key={TMDB_API_KEY}&query={query}'
        response = requests.get(url)
        response.raise_for_status()
        data = response.json()
        save_to_cache(cache_key, json.dumps(data))
        return jsonify(data)
    except requests.exceptions.RequestException as e:
        return jsonify({'error': str(e)}), 500

# Fetch trending TV shows
@app.route('/api/tv/trending', methods=['GET'])
def get_trending_tv():
    cache_key = 'trending_tv'
    cached_data = get_from_cache(cache_key)
    if cached_data:
        return jsonify(json.loads(cached_data))

    try:
        url = f'{TMDB_BASE_URL}/trending/tv/week?api_key={TMDB_API_KEY}'
        response = requests.get(url)
        response.raise_for_status()
        data = response.json()
        save_to_cache(cache_key, json.dumps(data))
        return jsonify(data)
    except requests.exceptions.RequestException as e:
        return jsonify({'error': str(e)}), 500

# Search TV shows
@app.route('/api/tv/search', methods=['GET'])
def search_tv():
    query = request.args.get('query', '')
    if not query:
        return jsonify({'error': 'Query parameter is required'}), 400

    cache_key = f'search_tv_{query}'
    cached_data = get_from_cache(cache_key)
    if cached_data:
        return jsonify(json.loads(cached_data))

    try:
        url = f'{TMDB_BASE_URL}/search/tv?api_key={TMDB_API_KEY}&query={query}'
        response = requests.get(url)
        response.raise_for_status()
        data = response.json()
        save_to_cache(cache_key, json.dumps(data))
        return jsonify(data)
    except requests.exceptions.RequestException as e:
        return jsonify({'error': str(e)}), 500

# Add to watchlist
@app.route('/api/watchlist', methods=['POST'])
def add_to_watchlist():
    data = request.json
    user_id = data.get('user_id')
    item_id = data.get('item_id')
    item_type = data.get('item_type')
    priority = data.get('priority', 1)
    metadata = data.get('metadata', {})

    valid_item_types = ['movie', 'tv']
    if not user_id or not item_id or not item_type or item_type not in valid_item_types:
        return jsonify({'error': 'user_id, item_id, and valid item_type (movie, tv) are required'}), 400

    try:
        result = db.watchlist.insert_one({
            'user_id': user_id,
            'item_id': item_id,
            'item_type': item_type,
            'priority': priority,
            'metadata': metadata
        })
        return jsonify({'status': 'success', 'id': str(result.inserted_id)}), 201
    except Exception as e:
        if "E11000 duplicate key error" in str(e):
            return jsonify({'error': 'Item already exists in watchlist'}), 409
        return jsonify({'error': str(e)}), 500

# Get user watchlist
@app.route('/api/watchlist/<user_id>', methods=['GET'])
def get_watchlist(user_id):
    sort_by = request.args.get('sort', 'priority')
    valid_sort_fields = ['priority', 'item_id', 'item_type']
    if sort_by not in valid_sort_fields:
        return jsonify({'error': 'Invalid sort field'}), 400

    try:
        sort_order = -1 if sort_by == 'priority' else 1  # Descending for priority
        items = db.watchlist.find({'user_id': user_id}).sort(sort_by, sort_order)
        watchlist = [
            {
                'id': str(item['_id']),
                'item_id': item['item_id'],
                'item_type': item['item_type'],
                'priority': item['priority'],
                'metadata': item['metadata']
            } for item in items
        ]
        return jsonify(watchlist)
    except Exception as e:
        return jsonify({'error': str(e)}), 500

# Add to watched
@app.route('/api/watched', methods=['POST'])
def add_to_watched():
    data = request.json
    user_id = data.get('user_id')
    item_id = data.get('item_id')
    item_type = data.get('item_type')
    rating = data.get('rating', 1)
    metadata = data.get('metadata', {})

    valid_item_types = ['movie', 'tv']
    if not user_id or not item_id or not item_type or item_type not in valid_item_types or rating not in range(1, 6):
        return jsonify({'error': 'user_id, item_id, valid item_type (movie, tv), and rating (1-5) are required'}), 400

    try:
        result = db.watched.insert_one({
            'user_id': user_id,
            'item_id': item_id,
            'item_type': item_type,
            'rating': rating,
            'metadata': metadata
        })
        return jsonify({'status': 'success', 'id': str(result.inserted_id)}), 201
    except Exception as e:
        if "E11000 duplicate key error" in str(e):
            return jsonify({'error': 'Item already exists in watched list'}), 409
        return jsonify({'error': str(e)}), 500

# Get user watched items
@app.route('/api/watched/<user_id>', methods=['GET'])
def get_watched(user_id):
    sort_by = request.args.get('sort', 'rating')
    valid_sort_fields = ['rating', 'item_id', 'item_type']
    if sort_by not in valid_sort_fields:
        return jsonify({'error': 'Invalid sort field'}), 400

    try:
        sort_order = -1 if sort_by == 'rating' else 1  # Descending for rating
        items = db.watched.find({'user_id': user_id}).sort(sort_by, sort_order)
        watched = [
            {
                'id': str(item['_id']),
                'item_id': item['item_id'],
                'item_type': item['item_type'],
                'rating': item['rating'],
                'metadata': item['metadata']
            } for item in items
        ]
        return jsonify(watched)
    except Exception as e:
        return jsonify({'error': str(e)}), 500

# Remove from watched
@app.route('/api/remove_from_watched/<user_id>/<item_id>/<item_type>', methods=['DELETE'])
def remove_from_watched(user_id, item_id, item_type):
    valid_item_types = ['movie', 'tv']
    if item_type not in valid_item_types:
        return jsonify({'error': 'Invalid item_type (must be movie or tv)'}), 400

    try:
        result = db.watched.delete_one({
            'user_id': user_id,
            'item_id': item_id,
            'item_type': item_type
        })
        if result.deleted_count == 0:
            return jsonify({'error': 'Item not found in watched list'}), 404
        return jsonify({'status': 'success'}), 200
    except Exception as e:
        return jsonify({'error': str(e)}), 500

# Update watched item rating
@app.route('/api/watched/<id>', methods=['PUT'])
def update_watched_item(id):
    data = request.json
    rating = data.get('rating', 1)
    metadata = data.get('metadata', {})

    if rating not in range(1, 6):
        return jsonify({'error': 'Rating must be between 1 and 5'}), 400

    try:
        from bson import ObjectId
        result = db.watched.update_one(
            {'_id': ObjectId(id)},
            {'$set': {'rating': rating, 'metadata': metadata}}
        )
        if result.matched_count == 0:
            return jsonify({'error': 'Item not found in watched list'}), 404
        return jsonify({'status': 'success'}), 200
    except Exception as e:
        return jsonify({'error': str(e)}), 500

# Get user details
@app.route('/api/user/<user_id>', methods=['GET'])
def get_user_details(user_id):
    try:
        user = db.users.find_one({'user_id': user_id})
        if user:
            return jsonify({
                'status': 'success',
                'username': user['username'],
                'email': user['email']
            })
        return jsonify({'error': 'User not found'}), 404
    except Exception as e:
        return jsonify({'error': str(e)}), 500

# Delete user
@app.route('/api/delete_user/<user_id>', methods=['DELETE'])
def delete_user(user_id):
    try:
        user_result = db.users.delete_one({'user_id': user_id})
        if user_result.deleted_count == 0:
            return jsonify({'error': 'User not found'}), 404
        db.watchlist.delete_many({'user_id': user_id})
        db.watched.delete_many({'user_id': user_id})
        return jsonify({'status': 'success'}), 200
    except Exception as e:
        return jsonify({'error': str(e)}), 500

# Remove from watchlist
@app.route('/api/remove_from_watchlist/<user_id>/<item_id>/<item_type>', methods=['DELETE'])
def remove_from_watchlist(user_id, item_id, item_type):
    valid_item_types = ['movie', 'tv']
    if item_type not in valid_item_types:
        return jsonify({'error': 'Invalid item_type (must be movie or tv)'}), 400

    try:
        result = db.watchlist.delete_one({
            'user_id': user_id,
            'item_id': item_id,
            'item_type': item_type
        })
        if result.deleted_count == 0:
            return jsonify({'error': 'Item not found in watchlist'}), 404
        return jsonify({'status': 'success'}), 200
    except Exception as e:
        return jsonify({'error': str(e)}), 500

# Update watchlist item
@app.route('/api/watchlist/<id>', methods=['PUT'])
def update_watchlist_item(id):
    data = request.json
    priority = data.get('priority', 1)
    metadata = data.get('metadata', {})

    try:
        from bson import ObjectId
        result = db.watchlist.update_one(
            {'_id': ObjectId(id)},
            {'$set': {'priority': priority, 'metadata': metadata}}
        )
        if result.matched_count == 0:
            return jsonify({'error': 'Item not found in watchlist'}), 404
        return jsonify({'status': 'success'}), 200
    except Exception as e:
        return jsonify({'error': str(e)}), 500

# Fetch movie details
@app.route('/api/movie/<movie_id>', methods=['GET'])
def get_movie_details(movie_id):
    cache_key = f'movie_details_{movie_id}'
    cached_data = get_from_cache(cache_key)
    if cached_data:
        return jsonify(json.loads(cached_data))
    try:
        url = f'{TMDB_BASE_URL}/movie/{movie_id}?api_key={TMDB_API_KEY}'
        response = requests.get(url)
        response.raise_for_status()
        data = response.json()
        save_to_cache(cache_key, json.dumps(data))
        return jsonify(data)
    except requests.exceptions.RequestException as e:
        return jsonify({'error': str(e)}), 500

# Fetch TV show details
@app.route('/api/tv/<tv_id>', methods=['GET'])
def get_tv_details(tv_id):
    cache_key = f'tv_details_{tv_id}'
    cached_data = get_from_cache(cache_key)
    if cached_data:
        return jsonify(json.loads(cached_data))

    try:
        url = f'{TMDB_BASE_URL}/tv/{tv_id}?api_key={TMDB_API_KEY}&append_to_response=credits,videos'
        response = requests.get(url)
        response.raise_for_status()
        data = response.json()
        save_to_cache(cache_key, json.dumps(data))
        return jsonify(data)
    except requests.exceptions.RequestException as e:
        return jsonify({'error': str(e)}), 500

# Fetch movie recommendations
@app.route('/api/movie/<movie_id>/recommendations', methods=['GET'])
def get_movie_recommendations(movie_id):
    cache_key = f'movie_recommendations_{movie_id}'
    cached_data = get_from_cache(cache_key)
    if cached_data:
        return jsonify(json.loads(cached_data))
    try:
        url = f'{TMDB_BASE_URL}/movie/{movie_id}/recommendations?api_key={TMDB_API_KEY}&language=en-US'
        response = requests.get(url)
        response.raise_for_status()
        data = response.json()
        save_to_cache(cache_key, json.dumps(data))
        return jsonify(data)
    except requests.exceptions.RequestException as e:
        return jsonify({'error': str(e)}), 500

# Fetch TV show recommendations
@app.route('/api/tv/<tv_id>/recommendations', methods=['GET'])
def get_tv_recommendations(tv_id):
    cache_key = f'tv_recommendations_{tv_id}'
    cached_data = get_from_cache(cache_key)
    if cached_data:
        return jsonify(json.loads(cached_data))
    try:
        url = f'{TMDB_BASE_URL}/tv/{tv_id}/recommendations?api_key={TMDB_API_KEY}&language=en-US'
        response = requests.get(url)
        response.raise_for_status()
        data = response.json()
        save_to_cache(cache_key, json.dumps(data))
        return jsonify(data)
    except requests.exceptions.RequestException as e:
        return jsonify({'error': str(e)}), 500

# Forgot Password
def send_reset_code_email(email, code):
    """Send a 4-digit reset code to the user's email."""
    try:
        msg = MIMEText(f"Your BingeBuddy password reset code is: {code}\nThis code is valid for 10 minutes.")
        msg['Subject'] = 'BingeBuddy Password Reset Code'
        msg['From'] = SMTP_EMAIL
        msg['To'] = email

        with smtplib.SMTP(SMTP_HOST, SMTP_PORT) as server:
            server.starttls()
            server.login(SMTP_EMAIL, SMTP_PASSWORD)
            server.sendmail(SMTP_EMAIL, email, msg.as_string())
        return True
    except Exception as e:
        print(f"Error sending email: {str(e)}")
        return False

@app.route('/api/forgot_password', methods=['POST'])
def forgot_password():
    data = request.json
    email = data.get('email')
    if not email:
        return jsonify({'error': 'Email is required'}), 400

    # Check if user exists
    user = db.users.find_one({"email": email})
    if not user:
        return jsonify({'error': 'Email not found'}), 404

    # Generate 4-digit code
    code = f"{random.randint(0, 9999):04d}"  # e.g., "1234"
    if store_reset_code(email, code):
        if send_reset_code_email(email, code):
            return jsonify({'status': 'success', 'message': 'Reset code sent to email'}), 200
        else:
            return jsonify({'error': 'Failed to send reset code'}), 500
    return jsonify({'error': 'Failed to generate reset code'}), 500

@app.route('/api/reset_password', methods=['POST'])
def reset_password():
    data = request.json
    email = data.get('email')
    code = data.get('code')
    new_password = data.get('new_password')
    if not email or not code or not new_password:
        return jsonify({'error': 'Email, code, and new password are required'}), 400

    if len(new_password) < 6:
        return jsonify({'error': 'New password must be at least 6 characters'}), 400

    if verify_reset_code(email, code):
        if update_user_password(email, new_password):
            return jsonify({'status': 'success', 'message': 'Password reset successfully'}), 200
        else:
            return jsonify({'error': 'Failed to update password'}), 500
    return jsonify({'error': 'Invalid or expired reset code'}), 400


# Get user watchlist and watched counts
@app.route('/api/user/<user_id>/counts', methods=['GET'])
def get_user_counts(user_id):
    try:
        # Count watchlist items
        watchlist_movies = db.watchlist.count_documents({
            'user_id': user_id,
            'item_type': 'movie'
        })
        watchlist_tv = db.watchlist.count_documents({
            'user_id': user_id,
            'item_type': 'tv'
        })

        # Count watched items
        watched_movies = db.watched.count_documents({
            'user_id': user_id,
            'item_type': 'movie'
        })
        watched_tv = db.watched.count_documents({
            'user_id': user_id,
            'item_type': 'tv'
        })

        return jsonify({
            'status': 'success',
            'data': {
                'watchlist': {
                    'movies': watchlist_movies,
                    'tvShows': watchlist_tv
                },
                'watched': {
                    'movies': watched_movies,
                    'tvShows': watched_tv
                }
            }
        }), 200
    except Exception as e:
        return jsonify({'error': f'Failed to fetch counts: {str(e)}'}), 500



# Add to watched logs
@app.route('/api/logs', methods=['POST'])
def add_log():
    data = request.json
    user_id = data.get('user_id')
    name = data.get('name')
    season = data.get('season')  # Can be null
    episode = data.get('episode')
    timestamp = data.get('timestamp')  # Can be null

    if not user_id or not name or episode is None:
        return jsonify({'error': 'user_id, name, and episode are required'}), 400

    try:
        result = db.logs.insert_one({
            'user_id': user_id,
            'name': name,
            'season': season,
            'episode': episode,
            'timestamp': timestamp,
            'created_at': datetime.utcnow()
        })
        return jsonify({'status': 'success', 'id': str(result.inserted_id)}), 201
    except Exception as e:
        return jsonify({'error': str(e)}), 500

# Get user logs
@app.route('/api/logs/<user_id>', methods=['GET'])
def get_logs(user_id):
    try:
        logs = db.logs.find({'user_id': user_id}).sort('created_at', -1)  # Sort by newest first
        log_list = [
            {
                'id': str(log['_id']),
                'name': log['name'],
                'season': log.get('season'),
                'episode': log['episode'],
                'timestamp': log.get('timestamp'),
                'created_at': log['created_at'].isoformat()
            } for log in logs
        ]
        return jsonify(log_list), 200
    except Exception as e:
        return jsonify({'error': str(e)}), 500


@app.route('/api/logs/<log_id>', methods=['DELETE'])
def delete_log(log_id):
    try:
        result = db.logs.delete_one({'_id': ObjectId(log_id)})
        if result.deleted_count == 0:
            return jsonify({'error': 'Log not found'}), 404
        return jsonify({'status': 'success'}), 200
    except Exception as e:
        return jsonify({'error': str(e)}), 500


if __name__ == '__main__':
    app.run(host='0.0.0.0', port=8080)