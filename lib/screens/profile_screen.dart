// lib/screens/profile_screen.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import '../auth/services/auth_service.dart';
import '../auth/models/user.dart' as AuthUser;
import '../services/user_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final UserService _userService = UserService();
  final AuthService _authService = AuthService();
  bool _isLoading = true;
  User? _currentUser;
  String? _errorMessage;
  String? _debugInfo;  // For development only - remove in production

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _debugInfo = null;
    });

    try {
      // First check for token
      final token = await _authService.getToken();
      if (token == null) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'You must be logged in to view your profile';
        });
        return;
      }

      // Try to get user info from UserService
      User? user = await _userService.getCurrentUser();
      _debugInfo = 'Tried UserService.getCurrentUser()';

      // If that fails, try to create a user from token data
      if (user == null) {
        final parts = token.split('.');
        if (parts.length == 3) {
          try {
            final payload = parts[1];
            final normalized = base64Url.normalize(payload);
            final decoded = utf8.decode(base64Url.decode(normalized));
            final data = json.decode(decoded);

            _debugInfo = '$_debugInfo → Created minimal user from token data';

            // Extract a username and email-like value from token
            final username = data['preferred_username'] ??
                data['nickname'] ??
                data['name'] ??
                data['sub'] ??
                'User';

            final email = data['email'] ??
                data['mail'] ??
                (data['sub'] != null && data['sub'].toString().contains('@') ? data['sub'] : null) ??
                '$username@example.com';

            // Create a minimal user object
            user = User(
              username: username.toString(),
              email: email.toString(),
            );
          } catch (e) {
            _debugInfo = '$_debugInfo → Failed to create user from token: $e';
          }
        }
      }

      if (mounted) {
        setState(() {
          _currentUser = user;
          _isLoading = false;
          if (user == null) {
            _errorMessage = 'Could not retrieve user profile';
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load profile: $e';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      appBar: AppBar(
        title: const Text('My Profile'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF8BC34A)))
          : _errorMessage != null
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _errorMessage!,
              style: const TextStyle(color: Colors.red),
              textAlign: TextAlign.center,
            ),
            if (_debugInfo != null) ...[
              const SizedBox(height: 8),
              Text(
                'Debug info: $_debugInfo',
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ],
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadUserProfile,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF8BC34A),
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      )
          : _buildProfileContent(),
    );
  }

  Widget _buildProfileContent() {
    if (_currentUser == null) {
      return const Center(
        child: Text('User profile not available', style: TextStyle(color: Colors.white)),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Profile avatar
          CircleAvatar(
            radius: 50,
            backgroundColor: const Color(0xFF8BC34A),
            child: Text(
              _getInitials(_currentUser!.username),
              style: const TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 16),

          // User name and email
          Text(
            _currentUser!.username,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          Text(
            _currentUser!.email,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[400],
            ),
          ),
          if (_debugInfo != null) ...[
            const SizedBox(height: 8),
            Text(
              'Debug info: $_debugInfo',
              style: TextStyle(color: Colors.grey[600], fontSize: 10),
              textAlign: TextAlign.center,
            ),
          ],
          const SizedBox(height: 32),

          // Account information card
          Card(
            color: const Color(0xFF2C2C2C),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Account Information',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const Divider(color: Colors.grey),
                  _buildInfoRow('Email', _currentUser!.email),
                  if (_currentUser!.address1 != null)
                    _buildInfoRow('Address', _currentUser!.address1!),
                  if (_currentUser!.city != null)
                    _buildInfoRow('City', _currentUser!.city!),
                  if (_currentUser!.province != null)
                    _buildInfoRow('Province', _currentUser!.province!),
                  if (_currentUser!.country != null)
                    _buildInfoRow('Country', _currentUser!.country!),
                  if (_currentUser!.phoneno != null)
                    _buildInfoRow('Phone', _currentUser!.phoneno.toString()),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Logout button
          ElevatedButton.icon(
            icon: const Icon(Icons.logout),
            label: const Text('Logout'),
            onPressed: () async {
              await _authService.logout();
              if (mounted) {
                Navigator.pushReplacementNamed(context, '/login');
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey[400],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  String _getInitials(String username) {
    if (username.isEmpty) return '';
    return username.substring(0, 1).toUpperCase();
  }
}