import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../config/api_config.dart';

class VerificationPage extends StatefulWidget {
  final String email;
  const VerificationPage({super.key, required this.email});

  @override
  State<VerificationPage> createState() => _VerificationPageState();
}

class _VerificationPageState extends State<VerificationPage> {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _verifyCode() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await http.post(
        Uri.parse(ApiConfig.verifyUrl),
        headers: ApiConfig.headers,
        body: json.encode({
          'email': widget.email,
          'verificationCode': _codeController.text,
        }),
      );

      if (response.statusCode == 200) {
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/login');
        }
      } else {
        final error = json.decode(response.body);
        setState(() {
          _errorMessage = error['message'] ?? 'Verification failed';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Connection error. Please try again.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _resendCode() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await http.post(
        Uri.parse(ApiConfig.resendCodeUrl),
        headers: ApiConfig.headers,
        body: widget.email,
      );

      if (response.statusCode == 200) {
        setState(() {
          _errorMessage = 'Verification code sent';
        });
      } else {
        final error = json.decode(response.body);
        setState(() {
          _errorMessage = error['message'] ?? 'Failed to send code';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Connection error. Please try again.';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 800;

    return Scaffold(
      backgroundColor: Color(0xFF1A1A1A),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: 450,
              ),
              margin: EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      "Verify Your Email",
                      style: TextStyle(
                        fontFamily: 'Helvetica',
                        fontSize: isDesktop ? 32 : 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 20),
                    Text(
                      "A verification code has been sent to ${widget.email}",
                      style: TextStyle(
                        fontFamily: 'Helvetica',
                        fontSize: 16,
                        color: Colors.grey[300],
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 30),
                    if (_errorMessage != null)
                      Container(
                        padding: EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                        decoration: BoxDecoration(
                          color: _errorMessage!.contains('sent')
                              ? Colors.green.withOpacity(0.1)
                              : Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _errorMessage!,
                          style: TextStyle(
                            fontFamily: 'Helvetica',
                            color: _errorMessage!.contains('sent')
                                ? Colors.green[400]
                                : Colors.red[400],
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    SizedBox(height: 24),
                    Text(
                      "Verification Code",
                      style: TextStyle(
                        fontFamily: 'Helvetica',
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey[300],
                      ),
                      textAlign: TextAlign.left,
                    ),
                    SizedBox(height: 8),
                    TextFormField(
                      controller: _codeController,
                      style: TextStyle(
                        fontFamily: 'Helvetica',
                        color: Colors.white,
                      ),
                      decoration: InputDecoration(
                        hintText: "Enter Verification Code",
                        hintStyle: TextStyle(
                          fontFamily: 'Helvetica',
                          color: Colors.grey[600],
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        fillColor: Color(0xFF2C2C2C),
                        filled: true,
                        prefixIcon: Icon(
                          Icons.security,
                          color: Colors.grey[500],
                        ),
                        contentPadding: EdgeInsets.symmetric(
                          vertical: 16,
                          horizontal: 16,
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter verification code';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 24),
                    SizedBox(
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _verifyCode,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFF8BC34A),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 2,
                          shadowColor: Color(0xFF8BC34A).withOpacity(0.5),
                        ),
                        child: _isLoading
                            ? SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                            : Text(
                          "Verify Email",
                          style: TextStyle(
                            fontFamily: 'Helvetica',
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 16),
                    TextButton(
                      onPressed: _isLoading ? null : _resendCode,
                      style: TextButton.styleFrom(
                        foregroundColor: Color(0xFF8BC34A),
                      ),
                      child: Text(
                        "Resend Code",
                        style: TextStyle(
                          fontFamily: 'Helvetica',
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}