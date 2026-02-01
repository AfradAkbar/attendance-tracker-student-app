import 'dart:convert';
import 'package:attendance_tracker_frontend/constants.dart';
import 'package:attendance_tracker_frontend/notifiers/user_notifier.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

// Global navigator key for logout from anywhere
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class ApiService {
  // Get token from SharedPreferences
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('jwt_token');
  }

  // Save token to SharedPreferences
  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('jwt_token', token);
  }

  // Clear token and user data (logout)
  static Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('jwt_token');
    await prefs.remove('user_data');
  }

  // Logout and go to login screen
  static Future<void> logout() async {
    await clearToken();
    navigatorKey.currentState?.pushNamedAndRemoveUntil(
      '/login',
      (route) => false,
    );
  }

  // GET request with auto token handling
  static Future<void> loadProfile() async {
    try {
      final data = await get(kMyDetails);
      if (data != null && data['user'] != null) {
        final user = data['user'] as Map<String, dynamic>;
        userNotifier.value = UserModel.fromJson(user);
      }
    } catch (e) {
      print("[ApiService] Error loading profile: $e");
    }
  }

  // Track consecutive connection errors
  static int _connectionErrorCount = 0;
  static const int _maxConnectionErrors = 5;

  // Reset error count on successful request
  static void _resetErrorCount() {
    _connectionErrorCount = 0;
  }

  // Handle connection error - logout after too many failures
  static Future<void> _handleConnectionError() async {
    _connectionErrorCount++;
    if (_connectionErrorCount >= _maxConnectionErrors) {
      print('[ApiService] Too many connection errors, logging out...');
      _connectionErrorCount = 0;
      await logout();
    }
  }

  static Future<Map<String, dynamic>?> get(String url) async {
    final token = await getToken();
    print("Token: $token");

    if (token == null || token.isEmpty) {
      await logout();
      return null;
    }

    try {
      final res = await http
          .get(
            Uri.parse(url),
            headers: {'Authorization': 'Bearer $token'},
          )
          .timeout(const Duration(seconds: 10));

      print("Response: ${res.body}");

      // Token expired or invalid
      if (res.statusCode == 401) {
        await logout();
        return null;
      }

      if (res.statusCode == 200) {
        _resetErrorCount(); // Success - reset error count
        return jsonDecode(res.body);
      }
    } catch (e) {
      print('API Error: $e');
      await _handleConnectionError();
    }
    return null;
  }

  // POST request with auto token handling
  static Future<Map<String, dynamic>?> post(
    String url,
    Map<String, dynamic> body,
  ) async {
    final token = await getToken();

    if (token == null || token.isEmpty) {
      await logout();
      return null;
    }

    try {
      final res = await http
          .post(
            Uri.parse(url),
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 10));

      // Token expired or invalid
      if (res.statusCode == 401) {
        await logout();
        return null;
      }

      if (res.statusCode == 200 || res.statusCode == 201) {
        _resetErrorCount();
        return jsonDecode(res.body);
      }
    } catch (e) {
      print('API Error: $e');
      await _handleConnectionError();
    }
    return null;
  }

  // PUT request with auto token handling
  static Future<Map<String, dynamic>?> put(
    String url, [
    Map<String, dynamic>? body,
  ]) async {
    final token = await getToken();

    if (token == null || token.isEmpty) {
      await logout();
      return null;
    }

    try {
      final res = await http
          .put(
            Uri.parse(url),
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(const Duration(seconds: 10));

      // Token expired or invalid
      if (res.statusCode == 401) {
        await logout();
        return null;
      }

      if (res.statusCode == 200) {
        _resetErrorCount();
        return jsonDecode(res.body);
      }
    } catch (e) {
      print('API Error: $e');
      await _handleConnectionError();
    }
    return null;
  }
}
