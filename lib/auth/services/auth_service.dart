// lib/auth/services/auth_service.dart
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:universal_platform/universal_platform.dart';
import '../models/user.dart';
import '../responses/login_response.dart';
import '../../config/api_config.dart';
import 'dart:html' as html;

class AuthService {
  Map<String, String> get _headers => ApiConfig.headers;
  final storage = const FlutterSecureStorage();

  Future<void> storeToken(String token, int expiryTime) async {
    if (UniversalPlatform.isWeb) {
      html.window.localStorage['jwt_token'] = token;
      html.window.localStorage['token_expiry'] = expiryTime.toString();
    } else {
      await storage.write(key: 'jwt_token', value: token);
      await storage.write(key: 'token_expiry', value: expiryTime.toString());
    }
  }

  Future<String?> getToken() async {
    if (UniversalPlatform.isWeb) {
      return html.window.localStorage['jwt_token'];
    } else {
      return await storage.read(key: 'jwt_token');
    }
  }

  Future<bool> isLoggedIn() async {
    if (UniversalPlatform.isWeb) {
      final token = html.window.localStorage['jwt_token'];
      return token != null && token.isNotEmpty;
    } else {
      final token = await storage.read(key: 'jwt_token');
      return token != null;
    }
  }

  Future<void> logout() async {
    if (UniversalPlatform.isWeb) {
      html.window.localStorage.remove('jwt_token');
      html.window.localStorage.remove('token_expiry');
    } else {
      await storage.delete(key: 'jwt_token');
      await storage.delete(key: 'token_expiry');
    }
  }

  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConfig.loginUrl),
        headers: _headers,
        body: json.encode({
          'email': email,
          'password': password,
        }),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = json.decode(response.body);

        if (data['token'] != null && data['expiresIn'] != null) {
          await storeToken(
              data['token'],
              DateTime.now().millisecondsSinceEpoch + (data['expiresIn'] as num).toInt()
          );
        }

        return {'success': true, 'data': data};
      } else {

        return {'success': false, 'message': 'Server error'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Connection error'};
    }
  }

  Future<Map<String, dynamic>> register(String email, String password, String username) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConfig.signupUrl),
        headers: _headers,
        body: json.encode({
          'email': email,
          'password': password,
          'username': username,
        }),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = json.decode(response.body);
        return {'success': true, 'data': data};
      } else {
        return {'success': false, 'message': 'Registration failed'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Connection error'};
    }
  }

  Future<Map<String, dynamic>> verifyEmail(String email, String code) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConfig.verifyUrl),
        headers: _headers,
        body: json.encode({
          'email': email,
          'verificationCode': code,
        }),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return {'success': true};
      } else {
        return {'success': false, 'message': 'Verification failed'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Connection error'};
    }
  }

  // Helper method to decode the JWT token for use by other services
  Map<String, dynamic> decodeToken(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return {};

      final payload = parts[1];
      final normalized = base64Url.normalize(payload);
      final decoded = utf8.decode(base64Url.decode(normalized));
      return json.decode(decoded);
    } catch (e) {
      print('Error decoding token: $e');
      return {};
    }
  }

  // Helper method to extract email from token data
  String? extractEmailFromToken(String token) {
    final tokenData = decodeToken(token);

    // Try common JWT claim fields that might contain email
    final possibleEmailFields = ['email', 'mail', 'user_email', 'sub'];

    for (final field in possibleEmailFields) {
      if (tokenData.containsKey(field)) {
        final value = tokenData[field];
        if (value is String && value.contains('@')) {
          return value; // Found a valid email
        }
      }
    }

    // If no email found in common fields, try to scan all fields for an email-like value
    for (final entry in tokenData.entries) {
      final value = entry.value;
      if (value is String && value.contains('@')) {
        return value; // Found something that looks like an email
      }
    }

    return null;
  }

  // Get a username from the token
  String? getUsernameFromToken(String token) {
    final tokenData = decodeToken(token);

    // Try common fields that might contain a username
    return tokenData['preferred_username'] ??
        tokenData['nickname'] ??
        tokenData['name'] ??
        tokenData['sub'] ??
        tokenData['userId'] ??
        null;
  }
}