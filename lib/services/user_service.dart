// lib/services/user_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../auth/services/auth_service.dart';

class User {
  final String username;
  final String email;
  final String? address1;
  final String? address2;
  final String? pobox;
  final String? city;
  final String? province;
  final String? country;
  final String? gender;
  final int? phoneno;

  User({
    required this.username,
    required this.email,
    this.address1,
    this.address2,
    this.pobox,
    this.city,
    this.province,
    this.country,
    this.gender,
    this.phoneno,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      username: json['username'] ?? '',
      email: json['email'] ?? '',
      address1: json['address1'],
      address2: json['address2'],
      pobox: json['pobox'],
      city: json['city'],
      province: json['province'],
      country: json['country'],
      gender: json['gender'],
      phoneno: json['phoneno'],
    );
  }
}

class UserService {
  final AuthService _authService = AuthService();

  Future<Map<String, String>> _getHeaders() async {
    final token = await _authService.getToken();
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      "ngrok-skip-browser-warning": "69420",
    };

    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }

    return headers;
  }

  Future<User?> getUserById(int userId) async {
    try {
      final headers = await _getHeaders();
      final url = '${ApiConfig.baseUrl}/user/getuserbyid?userId=$userId';

      final response = await http.get(Uri.parse(url), headers: headers);

      if (response.statusCode == 200) {
        final userData = json.decode(response.body);
        return User.fromJson(userData);
      }
      return null;
    } catch (e) {
      print('Error getting user by ID: $e');
      return null;
    }
  }

  Future<User?> getUserByUserId(String userId) async {
    try {
      final headers = await _getHeaders();
      final url = '${ApiConfig.baseUrl}/user/getuserbyuserid?userId=$userId';

      final response = await http.get(Uri.parse(url), headers: headers);

      if (response.statusCode == 200) {
        final userData = json.decode(response.body);
        return User.fromJson(userData);
      }
      return null;
    } catch (e) {
      print('Error getting user by user ID: $e');
      return null;
    }
  }

  Future<User?> getUserByEmail(String email) async {
    try {
      final headers = await _getHeaders();
      final url = '${ApiConfig.baseUrl}/user/getuserbyemail?email=$email';

      final response = await http.get(Uri.parse(url), headers: headers);

      if (response.statusCode == 200) {
        final userData = json.decode(response.body);
        return User.fromJson(userData);
      }
      return null;
    } catch (e) {
      print('Error getting user by email: $e');
      return null;
    }
  }

  Future<List<User>> getAllUsers() async {
    try {
      final headers = await _getHeaders();
      final url = '${ApiConfig.baseUrl}/user/allusers';

      final response = await http.get(Uri.parse(url), headers: headers);

      if (response.statusCode == 200) {
        final List<dynamic> usersData = json.decode(response.body);
        return usersData.map((userData) => User.fromJson(userData)).toList();
      }
      return [];
    } catch (e) {
      print('Error getting all users: $e');
      return [];
    }
  }
}