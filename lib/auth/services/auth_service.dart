import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
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

  Future<User?> getCurrentUser() async {
    final token = await getToken();
    if (token == null) return null;

    try {
      final response = await http.get(
        Uri.parse(ApiConfig.userMeUrl),
        headers: {
          ..._headers,
          'Authorization': 'Bearer $token'
        },
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return User.fromJson(json.decode(response.body));
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}