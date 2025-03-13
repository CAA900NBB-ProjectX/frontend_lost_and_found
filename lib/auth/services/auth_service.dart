import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../models/user.dart';
import '../responses/login_response.dart';
import '../../config/api_config.dart';
import 'dart:html' if (dart.library.io) 'dart:io' as platform;

class AuthService {
  Map<String, String> get _headers => ApiConfig.headers;
  final storage = const FlutterSecureStorage();


  Future<void> storeToken(String token, int expiryTime) async {
    if (kIsWeb) {

      platform.window.localStorage['jwt_token'] = token;
      platform.window.localStorage['token_expiry'] = expiryTime.toString();
    } else {

      await storage.write(key: 'jwt_token', value: token);
      await storage.write(key: 'token_expiry', value: expiryTime.toString());
    }
  }


  Future<String?> getToken() async {
    if (kIsWeb) {
      return platform.window.localStorage['jwt_token'];
    } else {
      return await storage.read(key: 'jwt_token');
    }
  }


  Future<bool> isLoggedIn() async {
    final token = kIsWeb
        ? platform.window.localStorage['jwt_token']
        : await storage.read(key: 'jwt_token');

    return token != null;
  }


  Future<void> logout() async {
    if (kIsWeb) {
      platform.window.localStorage.remove('jwt_token');
      platform.window.localStorage.remove('token_expiry');
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

      if (response.statusCode == 200) {
        try {
          final data = json.decode(response.body);
          if (data['token'] != null && data['expiresIn'] != null) {
            await storeToken(
                data['token'],
                DateTime.now().millisecondsSinceEpoch + data['expiresIn']
            );
            return {'success': true, 'data': data};
          } else {

            return {'success': false, 'message': 'Invalid server response: missing token data'};
          }
        } catch (e) {

          return {'success': false, 'message': 'Failed to process server response'};
        }
      } else {
        return {'success': false, 'message': 'Login failed'};
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

      if (response.statusCode == 200) {
        return User.fromJson(json.decode(response.body));
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}