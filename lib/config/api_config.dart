import 'package:flutter/foundation.dart' show kIsWeb;

class ApiConfig {
  static String get baseUrl {
    return 'http://foundit.eastus.cloudapp.azure.com:8085';
  }

  // Helper to check if we're in development
  static bool get isDevelopment {
    return baseUrl.contains('localhost') || baseUrl.contains('ngrok');
  }

  static String get authBaseUrl => '$baseUrl/auth';
  static String get loginUrl => '$authBaseUrl/login';
  static String get signupUrl => '$authBaseUrl/signup';
  static String get verifyUrl => '$authBaseUrl/verify';
  static String get resendCodeUrl => '$authBaseUrl/resend';

  static String get userBaseUrl => '$baseUrl/user';
  static String get userMeUrl => '$userBaseUrl/me';

  // Item API endpoints
  static String get itemBaseUrl => '$baseUrl/item';
  static String get getAllItemsUrl => '$itemBaseUrl/getallitems';
  static String get insertItemUrl => '$itemBaseUrl/insertitems';
  static String get getItemByIdUrl => '$itemBaseUrl/getitems'; // Will append /{id}
  static String get uploadImageUrl => '$itemBaseUrl/uploadimage'; // Will append /{itemId}
  static String get getImageUrl => '$itemBaseUrl/getimage'; // Will append /{imageId}
  static String get updateItemUrl => '$itemBaseUrl/updateitem'; // Will append /{id}
  static String get deleteItemUrl => '$itemBaseUrl/deleteitem'; // Will append /{id}
  static String get getItemsByUserUrl => '$itemBaseUrl/getitemsbyuser'; // Will append /{userId}
  static String get searchItemsUrl => '$itemBaseUrl/search'; // Will use query parameters

  static Map<String, String> get headers => {
    'Content-Type': 'application/json',
    'Accept': '*/*',  // Request JSON responses
  };
}