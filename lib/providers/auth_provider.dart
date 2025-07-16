import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bingebuddy/models/user.dart';
import 'package:bingebuddy/services/api_service.dart';

class AuthProvider with ChangeNotifier {
  User? _user;
  final ApiService _apiService = ApiService();

  User? get user => _user;

  Future<String?> login(String usernameOrEmail, String password) async {
    try {
      final response = await _apiService.login(usernameOrEmail, password);
      if (response['status'] == 'success') {
        _user = User(userId: response['user_id']);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user_id', _user!.userId);
        notifyListeners();
        return null; // Success
      }
      return response['error'] ?? 'Login failed';
    } catch (e) {
      return 'Error: $e';
    }
  }

  Future<String?> register(String username, String email, String password) async {
    try {
      final response = await _apiService.register(username, email, password);
      if (response['status'] == 'success') {
        return null; // Success
      }
      return response['error'] ?? 'Registration failed';
    } catch (e) {
      return 'Error: $e';
    }
  }

  Future<void> loadUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('user_id');
    if (userId != null) {
      _user = User(userId: userId);
      notifyListeners();
    }
  }

  Future<void> logout() async {
    _user = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_id');
    notifyListeners();
  }
}