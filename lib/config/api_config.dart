import 'package:flutter/foundation.dart' show kIsWeb;

class ApiConfig {
  static String get baseUrl {
    return 'http://172.206.240.144:8085';
  }
  static String get authBaseUrl => '$baseUrl/auth';
  static String get loginUrl => '$authBaseUrl/login';
  static String get signupUrl => '$authBaseUrl/signup';
  static String get verifyUrl => '$authBaseUrl/verify';
  static String get resendCodeUrl => '$authBaseUrl/resend';

  static String get userBaseUrl => '$baseUrl/user';
  static String get userMeUrl => '$userBaseUrl/me';


  static Map<String, String> get headers => {
    'Content-Type': 'application/json',
    'Accept': '*/*',
  };
}