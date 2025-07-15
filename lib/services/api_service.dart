import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:bingebuddy/models/watchlist_item.dart';
import 'package:bingebuddy/models/watched_item.dart'; // Add this import

class ApiService {
  static const String baseUrl = 'http://10.0.2.2:8080/api';

  // BingeBuddy: Register user
  Future<Map<String, dynamic>> register(String username, String email, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'username': username,
        'email': email,
        'password': password,
      }),
    );
    return jsonDecode(response.body);
  }

  // BingeBuddy: Login user
  Future<Map<String, dynamic>> login(String usernameOrEmail, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'username_or_email': usernameOrEmail,
        'password': password,
      }),
    );
    return jsonDecode(response.body);
  }

  // BingeBuddy: Fetch trending movies
  Future<Map<String, dynamic>> getTrendingMovies() async {
    final response = await http.get(Uri.parse('$baseUrl/movies/trending'));
    return jsonDecode(response.body);
  }

  // BingeBuddy: Search movies
  Future<Map<String, dynamic>> searchMovies(String query) async {
    final response = await http.get(Uri.parse('$baseUrl/movies/search?query=$query'));
    return jsonDecode(response.body);
  }

  Future<Map<String, dynamic>> getTrendingTv() async {
    final response = await http.get(Uri.parse('$baseUrl/tv/trending'));
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception('Failed to load trending TV shows: ${response.body}');
  }

  Future<Map<String, dynamic>> searchTv(String query) async {
    final response = await http.get(Uri.parse('$baseUrl/tv/search?query=$query'));
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception('Failed to search TV shows: ${response.body}');
  }

  // BingeBuddy: Add to watchlist
  Future<Map<String, dynamic>> addToWatchlist({
    required String userId,
    required String itemId,
    required String itemType,
    required int priority,
    required Map<String, dynamic> metadata,
  }) async {
    final body = {
      'user_id': userId,
      'item_id': itemId,
      'item_type': itemType,
      'priority': priority,
      'metadata': metadata,
    };
    final response = await http.post(
      Uri.parse('$baseUrl/watchlist'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );
    if (response.statusCode == 201) {
      return jsonDecode(response.body);
    }
    throw Exception('Failed to add to watchlist: ${response.body}');
  }

  // BingeBuddy: Get watchlist
  Future<List<WatchlistItem>> getWatchlist(String userId) async {
    final response = await http.get(Uri.parse('$baseUrl/watchlist/$userId?sort=priority'));
    print('Requesting watchlist: ${'$baseUrl/watchlist/$userId?sort=priority'}');
    print('Response status: ${response.statusCode}, body: ${response.body}');
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((item) => WatchlistItem.fromJson(item)).toList();
    }
    throw Exception('Failed to load watchlist: ${response.body}');
  }

  // New method to fetch user details
  Future<Map<String, dynamic>> getUserDetails(String userId) async {
    final response = await http.get(Uri.parse('$baseUrl/user/$userId'));
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception('Failed to load user details: ${response.body}');
  }

  // New method to delete user
  Future<Map<String, dynamic>> deleteUser(String userId) async {
    final response = await http.delete(Uri.parse('$baseUrl/delete_user/$userId'));
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception('Failed to delete user: ${response.body}');
  }

  Future<Map<String, dynamic>> removeFromWatchlist(String userId, String itemId, String itemType) async {
    final response = await http.delete(Uri.parse('$baseUrl/remove_from_watchlist/$userId/$itemId/$itemType'));
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception('Failed to remove from watchlist: ${response.body}');
  }

  Future<Map<String, dynamic>> updateWatchlistItem(String id, WatchlistItem item) async {
    final body = {
      'priority': item.priority,
      'metadata': item.metadata,
    };
    final response = await http.put(
      Uri.parse('$baseUrl/watchlist/$id'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );
    print('Update watchlist response: ${response.body}');
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception('Failed to update watchlist item: ${response.body}');
  }

  // BingeBuddy: Get watched items
  Future<List<WatchedItem>> getWatchedItems(String userId) async {
    final response = await http.get(Uri.parse('$baseUrl/watched/$userId?sort=rating'));
    print('Requesting watched items: ${'$baseUrl/watched/$userId?sort=rating'}');
    print('Response status: ${response.statusCode}, body: ${response.body}');
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((item) => WatchedItem.fromJson(item)).toList();
    }
    throw Exception('Failed to load watched items: ${response.body}');
  }

  // BingeBuddy: Add to watched
  Future<Map<String, dynamic>> addToWatched({
    required String userId,
    required String itemId,
    required String itemType,
    required int rating,
    required Map<String, dynamic> metadata,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/watched'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'user_id': userId,
        'item_id': itemId,
        'item_type': itemType,
        'rating': rating,
        'metadata': metadata,
      }),
    );
    if (response.statusCode == 201) {
      return jsonDecode(response.body);
    }
    throw Exception('Failed to add to watched: ${response.body}');
  }

  // BingeBuddy: Remove from watched
  Future<Map<String, dynamic>> removeFromWatched(String userId, String itemId, String itemType) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/remove_from_watched/$userId/$itemId/$itemType'),
      headers: {'Content-Type': 'application/json'},
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception('Failed to remove from watched: ${response.body}');
  }

  // BingeBuddy: Update watched item
  Future<Map<String, dynamic>> updateWatchedItem(String id, int rating, Map<String, dynamic> metadata) async {
    final response = await http.put(
      Uri.parse('$baseUrl/watched/$id'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'rating': rating, 'metadata': metadata}),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception('Failed to update watched item: ${response.body}');
  }

  // Fetch item details (movie or TV)
  Future<Map<String, dynamic>> getItemDetails(String mediaType, int id) async {
    try {
      final uri = Uri.parse('$baseUrl/$mediaType/$id');
      print('Requesting: $uri');
      final response = await http.get(uri).timeout(Duration(seconds: 10));
      print('Response status: ${response.statusCode}, body: ${response.body}');
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      throw Exception('Failed to load details for $mediaType: ${response.body}');
    } catch (e, stackTrace) {
      print('Network error: $e\nStack trace: $stackTrace');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getMovieRecommendations(int movieId) async {
    final uri = Uri.parse('$baseUrl/movie/$movieId/recommendations');
    print('Requesting movie recommendations: $uri');
    final request = http.Request('GET', uri);
    final client = http.Client();
    try {
      final streamedResponse = await client.send(request).timeout(Duration(seconds: 30));
      final response = await http.Response.fromStream(streamedResponse);
      print('Response status: ${response.statusCode}, body length: ${response.body.length}');
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      throw Exception('Failed to load movie recommendations: ${response.body}');
    } catch (e, stackTrace) {
      print('Error fetching movie recommendations: $e\nStack trace: $stackTrace');
      rethrow;
    } finally {
      client.close();
    }
  }

  Future<Map<String, dynamic>> getTvRecommendations(int tvId) async {
    final uri = Uri.parse('$baseUrl/tv/$tvId/recommendations');
    print('Requesting TV recommendations: $uri');
    final request = http.Request('GET', uri);
    final client = http.Client();
    try {
      final streamedResponse = await client.send(request).timeout(Duration(seconds: 30));
      final response = await http.Response.fromStream(streamedResponse);
      print('Response status: ${response.statusCode}, body length: ${response.body.length}');
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      throw Exception('Failed to load TV recommendations: ${response.body}');
    } catch (e, stackTrace) {
      print('Error fetching TV recommendations: $e\nStack trace: $stackTrace');
      rethrow;
    } finally {
      client.close();
    }
  }


  Future<Map<String, dynamic>> forgotPassword(String email) async {
    final response = await http.post(
      Uri.parse('$baseUrl/forgot_password'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email}),
    );
    print('Forgot password response: ${response.body}'); // Debug log
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception('Failed to send reset code: ${response.body}');
  }

  Future<Map<String, dynamic>> resetPassword(String email, String code, String newPassword) async {
    final response = await http.post(
      Uri.parse('$baseUrl/reset_password'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'code': code,
        'new_password': newPassword,
      }),
    );
    print('Reset password response: ${response.body}'); // Debug log
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception('Failed to reset password: ${response.body}');
  }
}
