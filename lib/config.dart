import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;

class Config {
  static String apiBaseUrl = '';

  static Future<void> loadConfig() async {
    try {
      final configString = await rootBundle.loadString('assets/config.json');
      final config = json.decode(configString);
      apiBaseUrl = config['apiBaseUrl'];
    } catch (e) {
      print('Error loading config: $e');
      apiBaseUrl = 'https://bingebuddy-tracker1.onrender.com/api'; // Fallback
    }
  }
}