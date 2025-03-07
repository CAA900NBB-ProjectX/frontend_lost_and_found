import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../models/user.dart';
import '../responses/login_response.dart';

class AuthService {
  // Dynamic base URL based on platform
  static String get baseUrl {
    if (kIsWeb) {
      return 'http://172.172.229.186:8085/auth';
    } else {
      return 'http://172.172.229.186:8085/auth';
    }
  }

  final storage = const FlutterSecureStorage();


  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'Accept': '*/*',
  };

  Future<Map<String, dynamic>> login(String email, String password) async {
    // try {
      print('Attempting login to: ${Uri.parse('$baseUrl/login')}');

      final response = await http.post(
        Uri.parse('$baseUrl/login'),
        headers: _headers,
        body: json.encode({
          'email': email,
          'password': password,
        }),
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        await storage.write(key: 'jwt_token', value: data['token']);
        await storage.write(
            key: 'token_expiry',
            value: (DateTime.now().millisecondsSinceEpoch + data['expiresIn']).toString()
        );
        return {'success': true, 'data': data};
      } else {
        final error = json.decode(response.body);
        return {
          'success': false,
          'message': error['message'] ?? 'Login failed'
        };
      }
    // } catch (e) {
    //   print('Login error: $e');
    //   return {
    //     'success': false,
    //     'message': 'Connection error. Please try again.'
    //   };
    // }
  }

  Future<Map<String, dynamic>> register(String email, String password, String username) async {

    try {
      print('Attempting registration to: ${Uri.parse('$baseUrl/signup')}');

      final response = await http.post(
        Uri.parse('$baseUrl/signup'),
        headers: _headers,
        body: json.encode({
          'email': email,
          'password': password,
          'username': username,
        }),
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        return {'success': true, 'data': json.decode(response.body)};
      } else {
        // Try to parse the error response
        try {
          final error = json.decode(response.body);
          return {
            'success': false,
            'message': error['message'] ??
                error['error'] ??
                error['exception'] ??
                'Registration failed'
          };
        } catch (parseError) {

          if (response.body.contains('already registered')) {
            return {
              'success': false,
              'message': 'Email is already registered'
            };
          }
          return {
            'success': false,
            'message': 'Registration failed: ${response.body}'
          };
        }
      }
    } catch (e) {
      print('Registration error: $e');
      return {
        'success': false,
        'message': 'Connection error. Please try again.'
      };
    }
  }

  Future<Map<String, dynamic>> verifyEmail(String email, String code) async {
    try {
      print('Attempting verification to: ${Uri.parse('$baseUrl/verify')}');

      final response = await http.post(
        Uri.parse('$baseUrl/verify'),
        headers: _headers,
        body: json.encode({
          'email': email,
          'verificationCode': code,
        }),
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        return {'success': true};
      } else {
        final error = json.decode(response.body);
        return {
          'success': false,
          'message': error['message'] ?? 'Verification failed'
        };
      }
    } catch (e) {
      print('Verification error: $e');
      return {
        'success': false,
        'message': 'Connection error. Please try again.'
      };
    }
  }

  Future<String?> getToken() async {
    return await storage.read(key: 'jwt_token');
  }

  Future<bool> isLoggedIn() async {
    final token = await getToken();
    if (token == null) return false;

    // Check token expiration
    final expiryString = await storage.read(key: 'token_expiry');
    if (expiryString == null) return false;

    final expiry = int.parse(expiryString);
    return DateTime.now().millisecondsSinceEpoch < expiry;
  }

  Future<void> logout() async {
    await storage.delete(key: 'jwt_token');
    await storage.delete(key: 'token_expiry');
  }

  Future<User?> getCurrentUser() async {
    try {
      print('Attempting to get current user');

      final response = await http.get(
        Uri.parse('$baseUrl/user/me'),
        headers: {
          ..._headers,
          'Authorization': 'Bearer ${await getToken()}'
        },
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        return User.fromJson(json.decode(response.body));
      }
      return null;
    } catch (e) {
      print('Get current user error: $e');
      return null;
    }
  }
}