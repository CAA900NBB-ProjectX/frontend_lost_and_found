import 'package:flutter/material.dart';
import '../auth/services/auth_service.dart';
import '../auth/models/user.dart';

class AppNavigationDrawer extends StatefulWidget {
  final String currentRoute;

  const AppNavigationDrawer({
    Key? key,
    required this.currentRoute,
  }) : super(key: key);

  @override
  State<AppNavigationDrawer> createState() => _AppNavigationDrawerState();
}

class _AppNavigationDrawerState extends State<AppNavigationDrawer> {
  final AuthService _authService = AuthService();
  User? _currentUser;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  Future<void> _loadUserInfo() async {
    try {
      final user = await _authService.getCurrentUser();
      if (mounted) {
        setState(() {
          _currentUser = user;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _buildNavItem(
                  context,
                  title: 'Home',
                  icon: Icons.home,
                  route: '/home',
                  isSelected: widget.currentRoute == '/home',
                ),
                _buildNavItem(
                  context,
                  title: 'Report Found Item',
                  icon: Icons.add_circle,
                  route: '/upload_item',
                  isSelected: widget.currentRoute == '/upload_item',
                ),
                _buildNavItem(
                  context,
                  title: 'My Profile',
                  icon: Icons.person,
                  route: '/profile',
                  isSelected: widget.currentRoute == '/profile',
                ),
                const Divider(),
                _buildNavItem(
                  context,
                  title: 'About',
                  icon: Icons.info,
                  onTap: () {
                    Navigator.pop(context);
                    _showAboutDialog(context);
                  },
                ),
              ],
            ),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Logout'),
            onTap: () async {
              await _authService.logout();
              if (context.mounted) {
                Navigator.pushReplacementNamed(context, '/login');
              }
            },
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return UserAccountsDrawerHeader(
      accountName: _isLoading
          ? const Text('Loading...')
          : Text(_currentUser?.username ?? 'User'),
      accountEmail: _isLoading
          ? const Text('Loading...')
          : Text(_currentUser?.email ?? 'user@example.com'),
      currentAccountPicture: CircleAvatar(
        backgroundColor: Colors.white,
        child: Text(
          _isLoading
              ? '?'
              : (_currentUser?.username.isNotEmpty ?? false)
              ? _currentUser!.username[0].toUpperCase()
              : 'U',
          style: const TextStyle(
            fontSize: 30,
            fontWeight: FontWeight.bold,
            color: Colors.purple,
          ),
        ),
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor,
      ),
    );
  }

  Widget _buildNavItem(
      BuildContext context, {
        required String title,
        required IconData icon,
        String? route,
        bool isSelected = false,
        VoidCallback? onTap,
      }) {
    return ListTile(
      leading: Icon(
        icon,
        color: isSelected ? Theme.of(context).primaryColor : null,
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected ? Theme.of(context).primaryColor : null,
        ),
      ),
      selected: isSelected,
      onTap: onTap ?? () {
        Navigator.pop(context);
        if (route != null && route != widget.currentRoute) {
          Navigator.pushReplacementNamed(context, route);
        }
      },
    );
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('About Found It!'),
          content: const SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Found It! is a lost and found app that helps people recover their lost items.',
                ),
                SizedBox(height: 12),
                Text(
                  'Version: 1.0.0',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 20),
                Text(
                  '© 2025 Seneca Polytechnic\nProject X Team',
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }
}