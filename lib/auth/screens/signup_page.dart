import 'package:flutter/material.dart';
import 'dart:convert';
import '../services/auth_service.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _authService = AuthService();

  bool _isLoading = false;
  String? _errorMessage;
  bool _isPasswordHidden = true;
  bool _isConfirmPasswordHidden = true;

  Future<void> _signup() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await _authService.register(
        _emailController.text,
        _passwordController.text,
        _usernameController.text,
      );

      if (mounted) {
        if (result['success']) {
          Navigator.pushReplacementNamed(
            context,
            '/verification',
            arguments: _emailController.text,
          );
        } else {
          setState(() {
            _errorMessage = result['message'];
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          if (e.toString().contains('User is already registered')) {
            _errorMessage = 'User is already registered';
          } else {
            _errorMessage = 'Connection error. Please try again.';
          }
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 800;

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Container(
              width: isDesktop ? 450 : screenWidth * 0.9,
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: _buildSignupForm(isDesktop),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildSignupForm(bool isDesktop) {
    return [
      Text(
        "Create Account",
        style: TextStyle(
          fontSize: isDesktop ? 28 : 24,
          fontWeight: FontWeight.bold,
          color: Colors.white,
          fontFamily: 'Helvetica',
        ),
        textAlign: TextAlign.center,
      ),
      const SizedBox(height: 8),
      Text(
        "Sign up to get started",
        style: TextStyle(
          fontSize: isDesktop ? 16 : 14,
          color: Colors.grey[400],
          fontFamily: 'Helvetica',
        ),
        textAlign: TextAlign.center,
      ),
      const SizedBox(height: 24),
      if (_errorMessage != null)
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.red.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            _errorMessage!,
            style: TextStyle(
              color: Colors.red[300],
              fontFamily: 'Helvetica',
            ),
            textAlign: TextAlign.center,
          ),
        ),
      if (_errorMessage != null) const SizedBox(height: 16),
      _buildInputLabel("Username"),
      const SizedBox(height: 8),
      _buildTextField(
        controller: _usernameController,
        hintText: "Enter your username",
        icon: Icons.person,
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Please enter username';
          }
          return null;
        },
      ),
      const SizedBox(height: 16),
      _buildInputLabel("Email"),
      const SizedBox(height: 8),
      _buildTextField(
        controller: _emailController,
        hintText: "Enter your email",
        icon: Icons.email,
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Please enter email';
          }
          if (!value.contains('@')) {
            return 'Please enter a valid email';
          }
          return null;
        },
      ),
      const SizedBox(height: 16),
      _buildInputLabel("Password"),
      const SizedBox(height: 8),
      _buildTextField(
        controller: _passwordController,
        hintText: "Enter your password",
        icon: Icons.lock,
        isPassword: true,
        isPasswordHidden: _isPasswordHidden,
        onTogglePassword: () {
          setState(() {
            _isPasswordHidden = !_isPasswordHidden;
          });
        },
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Please enter password';
          }
          if (value.length < 6) {
            return 'Password must be at least 6 characters';
          }
          return null;
        },
      ),
      const SizedBox(height: 16),
      _buildInputLabel("Confirm Password"),
      const SizedBox(height: 8),
      _buildTextField(
        controller: _confirmPasswordController,
        hintText: "Confirm your password",
        icon: Icons.lock,
        isPassword: true,
        isPasswordHidden: _isConfirmPasswordHidden,
        onTogglePassword: () {
          setState(() {
            _isConfirmPasswordHidden = !_isConfirmPasswordHidden;
          });
        },
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Please confirm password';
          }
          if (value != _passwordController.text) {
            return 'Passwords do not match';
          }
          return null;
        },
      ),
      const SizedBox(height: 24),
      SizedBox(
        height: 50,
        child: ElevatedButton(
          onPressed: _isLoading ? null : _signup,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF8BC34A), // Green accent
            foregroundColor: Colors.black,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 2,
          ),
          child: _isLoading
              ? const SizedBox(
            height: 24,
            width: 24,
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
              strokeWidth: 2,
            ),
          )
              : Text(
            "Sign up",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              fontFamily: 'Helvetica',
            ),
          ),
        ),
      ),
      const SizedBox(height: 20),
      Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            "Already have an account?",
            style: TextStyle(
              color: Colors.grey[400],
              fontFamily: 'Helvetica',
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pushReplacementNamed(context, '/login');
            },
            child: Text(
              "Login",
              style: TextStyle(
                color: const Color(0xFF8BC34A),
                fontWeight: FontWeight.bold,
                fontFamily: 'Helvetica',
              ),
            ),
          ),
        ],
      ),
    ];
  }

  Widget _buildInputLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        label,
        style: TextStyle(
          color: Colors.grey[300],
          fontWeight: FontWeight.w500,
          fontSize: 14,
          fontFamily: 'Helvetica',
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    bool isPassword = false,
    bool? isPasswordHidden,
    VoidCallback? onTogglePassword,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: isPassword ? (isPasswordHidden ?? true) : false,
      style: const TextStyle(
        color: Colors.white,
        fontFamily: 'Helvetica',
      ),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(
          color: Colors.grey[500],
          fontFamily: 'Helvetica',
        ),
        errorStyle: const TextStyle(
          color: Color(0xFFF44336),
          fontFamily: 'Helvetica',
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        fillColor: const Color(0xFF2C2C2C),
        filled: true,
        prefixIcon: Icon(
          icon,
          color: Colors.grey[400],
        ),
        suffixIcon: isPassword
            ? IconButton(
          icon: Icon(
            isPasswordHidden ?? true
                ? Icons.visibility
                : Icons.visibility_off,
            color: Colors.grey[400],
          ),
          onPressed: onTogglePassword,
        )
            : null,
        contentPadding: const EdgeInsets.symmetric(
          vertical: 16,
          horizontal: 16,
        ),
      ),
      validator: validator,
    );
  }


}