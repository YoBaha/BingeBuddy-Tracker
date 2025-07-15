from flask import Flask, jsonify, request
from dotenv import load_dotenv
import os
import requests
import json
import uuid
import sqlite3
from database import init_db, add_metadata_column, add_timestamp_column, register_user, authenticate_user, save_to_cache, get_from_cache

app = Flask(__name__)

# Load environment variables
load_dotenv()
TMDB_API_KEY = os.getenv('TMDB_API_KEY')
TMDB_BASE_URL = os.getenv('TMDB_BASE_URL')

# Initialize database
init_db()
add_metadata_column()
add_timestamp_column()

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
    priority = data.get('priority', 1)  # Default to 1 if not provided
    metadata = data.get('metadata', {})

    valid_item_types = ['movie', 'tv']
    if not user_id or not item_id or not item_type or item_type not in valid_item_types:
        return jsonify({'error': 'user_id, item_id, and valid item_type (movie, tv) are required'}), 400

    try:
        conn = sqlite3.connect('cache.db')
        cursor = conn.cursor()
        cursor.execute(
            'INSERT INTO watchlist (user_id, item_id, item_type, priority, metadata) VALUES (?, ?, ?, ?, ?)',
            (user_id, item_id, item_type, priority, json.dumps(metadata))
        )
        conn.commit()
        new_id = cursor.lastrowid
        conn.close()
        return jsonify({'status': 'success', 'id': new_id}), 201
    except sqlite3.Error as e:
        return jsonify({'error': str(e)}), 500

# Get user watchlist
@app.route('/api/watchlist/<user_id>', methods=['GET'])
def get_watchlist(user_id):
    sort_by = request.args.get('sort', 'priority')
    valid_sort_fields = ['priority', 'item_id', 'item_type']
    if sort_by not in valid_sort_fields:
        return jsonify({'error': 'Invalid sort field'}), 400

    try:
        conn = sqlite3.connect('cache.db')
        cursor = conn.cursor()
        cursor.execute(
            'SELECT id, item_id, item_type, priority, metadata FROM watchlist WHERE user_id = ? ORDER BY ?',
            (user_id, sort_by)
        )
        items = cursor.fetchall()
        conn.close()
        watchlist = [
            {
                'id': item[0],
                'item_id': item[1],
                'item_type': item[2],
                'priority': item[3],
                'metadata': json.loads(item[4]) if item[4] else {}
            } for item in items
        ]
        return jsonify(watchlist)
    except sqlite3.Error as e:
        return jsonify({'error': str(e)}), 500

# Add to watched
@app.route('/api/watched', methods=['POST'])
def add_to_watched():
    data = request.json
    user_id = data.get('user_id')
    item_id = data.get('item_id')
    item_type = data.get('item_type')
    rating = data.get('rating', 1)  # Default to 1 if not provided, range 1-5
    metadata = data.get('metadata', {})

    valid_item_types = ['movie', 'tv']
    if not user_id or not item_id or not item_type or item_type not in valid_item_types or rating not in range(1, 6):
        return jsonify({'error': 'user_id, item_id, valid item_type (movie, tv), and rating (1-5) are required'}), 400

    try:
        conn = sqlite3.connect('cache.db')
        cursor = conn.cursor()
        cursor.execute(
            'INSERT INTO watched (user_id, item_id, item_type, rating, metadata) VALUES (?, ?, ?, ?, ?)',
            (user_id, item_id, item_type, rating, json.dumps(metadata))
        )
        conn.commit()
        new_id = cursor.lastrowid
        conn.close()
        return jsonify({'status': 'success', 'id': new_id}), 201
    except sqlite3.Error as e:
        return jsonify({'error': str(e)}), 500

# Get user watched items
@app.route('/api/watched/<user_id>', methods=['GET'])
def get_watched(user_id):
    sort_by = request.args.get('sort', 'rating')
    valid_sort_fields = ['rating', 'item_id', 'item_type']
    if sort_by not in valid_sort_fields:
        return jsonify({'error': 'Invalid sort field'}), 400

    try:
        conn = sqlite3.connect('cache.db')
        cursor = conn.cursor()
        cursor.execute(
            'SELECT id, item_id, item_type, rating, metadata FROM watched WHERE user_id = ? ORDER BY ?',
            (user_id, sort_by)
        )
        items = cursor.fetchall()
        conn.close()
        watched = [
            {
                'id': item[0],
                'item_id': item[1],
                'item_type': item[2],
                'rating': item[3],
                'metadata': json.loads(item[4]) if item[4] else {}
            } for item in items
        ]
        return jsonify(watched)
    except sqlite3.Error as e:
        return jsonify({'error': str(e)}), 500

# Remove from watched
@app.route('/api/remove_from_watched/<user_id>/<item_id>/<item_type>', methods=['DELETE'])
def remove_from_watched(user_id, item_id, item_type):
    valid_item_types = ['movie', 'tv']
    if item_type not in valid_item_types:
        return jsonify({'error': 'Invalid item_type (must be movie or tv)'}), 400

    try:
        conn = sqlite3.connect('cache.db')
        cursor = conn.cursor()
        cursor.execute(
            'DELETE FROM watched WHERE user_id = ? AND item_id = ? AND item_type = ?',
            (user_id, item_id, item_type)
        )
        if cursor.rowcount == 0:
            conn.close()
            return jsonify({'error': 'Item not found in watched list'}), 404
        conn.commit()
        conn.close()
        return jsonify({'status': 'success'}), 200
    except sqlite3.Error as e:
        return jsonify({'error': str(e)}), 500

# Update watched item rating
@app.route('/api/watched/<id>', methods=['PUT'])
def update_watched_item(id):
    data = request.json
    rating = data.get('rating', 1)  # Update rating, range 1-5
    metadata = data.get('metadata', {})

    if rating not in range(1, 6):
        return jsonify({'error': 'Rating must be between 1 and 5'}), 400

    try:
        conn = sqlite3.connect('cache.db')
        cursor = conn.cursor()
        cursor.execute(
            'UPDATE watched SET rating = ?, metadata = ? WHERE id = ?',
            (rating, json.dumps(metadata), id)
        )
        if cursor.rowcount == 0:
            conn.close()
            return jsonify({'error': 'Item not found in watched list'}), 404
        conn.commit()
        conn.close()
        return jsonify({'status': 'success'}), 200
    except sqlite3.Error as e:
        return jsonify({'error': str(e)}), 500

# Get user details
@app.route('/api/user/<user_id>', methods=['GET'])
def get_user_details(user_id):
    try:
        conn = sqlite3.connect('cache.db')
        cursor = conn.cursor()
        cursor.execute('SELECT username, email FROM users WHERE user_id = ?', (user_id,))
        user = cursor.fetchone()
        conn.close()
        if user:
            return jsonify({
                'status': 'success',
                'username': user[0],
                'email': user[1]
            })
        return jsonify({'error': 'User not found'}), 404
    except sqlite3.Error as e:
        return jsonify({'error': str(e)}), 500

# Delete user
@app.route('/api/delete_user/<user_id>', methods=['DELETE'])
def delete_user(user_id):
    try:
        conn = sqlite3.connect('cache.db')
        cursor = conn.cursor()
        cursor.execute('DELETE FROM users WHERE user_id = ?', (user_id,))
        if cursor.rowcount == 0:
            conn.close()
            return jsonify({'error': 'User not found'}), 404
        cursor.execute('DELETE FROM watchlist WHERE user_id = ?', (user_id,))
        cursor.execute('DELETE FROM watched WHERE user_id = ?', (user_id,))  # Clean up watched items
        conn.commit()
        conn.close()
        return jsonify({'status': 'success'}), 200
    except sqlite3.Error as e:
        return jsonify({'error': str(e)}), 500

# Remove from watchlist
@app.route('/api/remove_from_watchlist/<user_id>/<item_id>/<item_type>', methods=['DELETE'])
def remove_from_watchlist(user_id, item_id, item_type):
    valid_item_types = ['movie', 'tv']
    if item_type not in valid_item_types:
        return jsonify({'error': 'Invalid item_type (must be movie or tv)'}), 400

    try:
        conn = sqlite3.connect('cache.db')
        cursor = conn.cursor()
        cursor.execute(
            'DELETE FROM watchlist WHERE user_id = ? AND item_id = ? AND item_type = ?',
            (user_id, item_id, item_type)
        )
        if cursor.rowcount == 0:
            conn.close()
            return jsonify({'error': 'Item not found in watchlist'}), 404
        conn.commit()
        conn.close()
        return jsonify({'status': 'success'}), 200
    except sqlite3.Error as e:
        return jsonify({'error': str(e)}), 500

# Update watchlist item
@app.route('/api/watchlist/<id>', methods=['PUT'])
def update_watchlist_item(id):
    data = request.json
    priority = data.get('priority', 1)  # Use priority as rating
    metadata = data.get('metadata', {})

    try:
        conn = sqlite3.connect('cache.db')
        cursor = conn.cursor()
        cursor.execute(
            'UPDATE watchlist SET priority = ?, metadata = ? WHERE id = ?',
            (priority, json.dumps(metadata), id)
        )
        if cursor.rowcount == 0:
            conn.close()
            return jsonify({'error': 'Item not found in watchlist'}), 404
        conn.commit()
        conn.close()
        return jsonify({'status': 'success'}), 200
    except sqlite3.Error as e:
        return jsonify({'error': str(e)}), 500


# Fetch movie details
@app.route('/api/movie/<movie_id>', methods=['GET'])
def get_movie_details(movie_id):
    cache_key = f'movie_details_{movie_id}'
    cached_data = get_from_cache(cache_key)
    if cached_data:
        return jsonify(json.loads(cached_data))
    try:
        url = f'{TMDB_BASE_URL}/movie/{movie_id}?api_key={TMDB_API_KEY}'  # Removed append_to_response
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

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=8080, debug=True)