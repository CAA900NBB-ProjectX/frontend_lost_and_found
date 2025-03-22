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
    // Add debugging for the response format
    print('Parsing user from JSON: $json');

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
      final url = '${ApiConfig.userBaseUrl}/getuserbyid?userId=$userId';

      print('Fetching user by ID from: $url');

      final response = await http.get(Uri.parse(url), headers: headers);
      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

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
      final url = '${ApiConfig.userBaseUrl}/getuserbyuserid?userId=$userId';

      print('Fetching user by user ID from: $url');

      final response = await http.get(Uri.parse(url), headers: headers);
      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

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
      // Ensure email is properly formatted
      if (!email.contains('@')) {
        print('Invalid email format: $email');
        return null;
      }

      final headers = await _getHeaders();
      final url = '${ApiConfig.userBaseUrl}/getuserbyemail?email=$email';

      print('Fetching user by email from: $url');

      final response = await http.get(Uri.parse(url), headers: headers);
      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final userData = json.decode(response.body);
        return User.fromJson(userData);
      } else {
        print('Failed to get user by email. Status: ${response.statusCode}, Body: ${response.body}');
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
      final url = '${ApiConfig.userBaseUrl}/allusers';

      print('Fetching all users from: $url');

      final response = await http.get(Uri.parse(url), headers: headers);
      print('Response status: ${response.statusCode}');

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

  // This function will attempt to get the current user using token info
  Future<User?> getCurrentUser() async {
    try {
      // First, get the authentication token
      final token = await _authService.getToken();
      if (token == null) {
        print('No authentication token available');
        return null;
      }

      // Try to get user from backend API first
      try {
        final headers = await _getHeaders();
        final url = '${ApiConfig.userMeUrl}';

        print('Fetching current user profile from: $url');

        final response = await http.get(Uri.parse(url), headers: headers);

        if (response.statusCode == 200) {
          final userData = json.decode(response.body);
          return User.fromJson(userData);
        }
      } catch (e) {
        print('Error fetching user profile from API: $e');
        // Fall through to token extraction as backup
      }

      // Decode the token to extract claims as backup
      final tokenData = _authService.decodeToken(token);
      print('Token payload: $tokenData');

      // Try to find an email in the token
      String? email;
      String? username;

      // Extract username and email more aggressively
      username = tokenData['preferred_username'] ??
          tokenData['username'] ??
          tokenData['nickname'] ??
          tokenData['name'] ??
          tokenData['sub'];

      email = tokenData['email'] ??
          tokenData['mail'] ??
          tokenData['user_email'] ??
          (tokenData['sub']?.toString().contains('@') ? tokenData['sub'] : null);

      // Create user with best information available
      return User(
        username: username?.toString() ?? 'User',
        email: email?.toString() ?? 'user@example.com',
      );
    } catch (e) {
      print('Error getting current user: $e');
      return null;
    }
  }
}