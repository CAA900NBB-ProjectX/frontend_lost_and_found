// lib/widgets/navigation_drawer.dart
import 'package:flutter/material.dart';
import '../auth/services/auth_service.dart';
import '../services/user_service.dart';

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
  final UserService _userService = UserService();
  User? _currentUser;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  Future<void> _loadUserInfo() async {
    try {
      final user = await _userService.getCurrentUser();
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
      backgroundColor: const Color(0xFF1A1A1A), // Dark background
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
                  title: 'Search Items',
                  icon: Icons.search,
                  route: '/search_items',
                  isSelected: widget.currentRoute == '/search_items',
                ),
                _buildNavItem(
                  context,
                  title: 'Report Lost Item',
                  icon: Icons.help_outline,
                  route: '/upload_item',
                  arguments: {'status': 'LOST'},
                  isSelected: widget.currentRoute == '/upload_item' &&
                      (ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?)?.containsValue('LOST') == true,
                ),
                _buildNavItem(
                  context,
                  title: 'Report Found Item',
                  icon: Icons.check_circle_outline,
                  route: '/upload_item',
                  arguments: {'status': 'FOUND'},
                  isSelected: widget.currentRoute == '/upload_item' &&
                      (ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?)?.containsValue('FOUND') == true,
                ),
                _buildNavItem(
                  context,
                  title: 'My Profile',
                  icon: Icons.person,
                  route: '/profile',
                  isSelected: widget.currentRoute == '/profile',
                ),
                const Divider(color: Color(0xFF3A3A3A)),
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
          const Divider(color: Color(0xFF3A3A3A)),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Logout', style: TextStyle(color: Colors.white)),
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
      decoration: const BoxDecoration(
        color: Color(0xFF8BC34A), // Green accent color
      ),
      accountName: _isLoading
          ? const Text('Loading...')
          : Text(
        _currentUser?.username ?? 'User',
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      accountEmail: _isLoading
          ? const Text('Loading...')
          : Text(
        _currentUser?.email ?? 'user@example.com',
        style: const TextStyle(color: Colors.white),
      ),
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
            color: Color(0xFF8BC34A),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
      BuildContext context, {
        required String title,
        required IconData icon,
        String? route,
        Map<String, dynamic>? arguments,
        bool isSelected = false,
        VoidCallback? onTap,
      }) {
    return ListTile(
      leading: Icon(
        icon,
        color: isSelected ? const Color(0xFF8BC34A) : Colors.white70,
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected ? const Color(0xFF8BC34A) : Colors.white,
        ),
      ),
      selected: isSelected,
      onTap: onTap ?? () {
        Navigator.pop(context);
        if (route != null && (route != widget.currentRoute || arguments != null)) {
          Navigator.pushReplacementNamed(
            context,
            route,
            arguments: arguments,
          );
        }
      },
    );
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF2C2C2C),
          title: const Text(
            'About Found It!',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Found It! is a lost and found app that helps people recover their lost items.',
                style: TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 12),
              const Text(
                'Version: 1.0.0',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              const Text(
                '© 2025 Seneca Polytechnic\nProject X Team',
                style: TextStyle(color: Colors.white70, fontSize: 12),
              ),
              const SizedBox(height: 16),
              Center(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF8BC34A).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.search,
                    color: Color(0xFF8BC34A),
                    size: 48,
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text(
                'Close',
                style: TextStyle(color: Color(0xFF8BC34A)),
              ),
            ),
          ],
        );
      },
    );
  }
}