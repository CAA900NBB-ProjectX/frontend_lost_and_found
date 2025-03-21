import 'package:flutter/foundation.dart' show kIsWeb;

class ApiConfig {
  static String get baseUrl {
    return 'https://dce8-142-204-17-60.ngrok-free.app';
  }
  static String get wsUrl {
    if (baseUrl.startsWith('https://')) {
      return baseUrl.replaceFirst('https://', 'wss://');
    } else if (baseUrl.startsWith('http://')) {
      return baseUrl.replaceFirst('http://', 'ws://');
    }
    return baseUrl;
  }


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


  static String get itemBaseUrl => '$baseUrl/item';
  static String get getAllItemsUrl => '$itemBaseUrl/getallitems';
  static String get insertItemUrl => '$itemBaseUrl/insertitems';
  static String get getItemByIdUrl => '$itemBaseUrl/getitems';
  static String get uploadImageUrl => '$itemBaseUrl/uploadimage';
  static String get getImageUrl => '$itemBaseUrl/getimage';
  static String get updateItemUrl => '$itemBaseUrl/updateitem';
  static String get deleteItemUrl => '$itemBaseUrl/deleteitem';
  static String get getItemsByUserUrl => '$itemBaseUrl/getitemsbyuser';
  static String get searchItemsUrl => '$itemBaseUrl/search';

  static String get chatApiUrl => '$baseUrl/chats';
  static String get messageApiUrl => '$baseUrl/messages';
  static String get checkChatUrl => '$chatApiUrl/get';
  static String get createChatUrl => '$chatApiUrl/create';
  static String get getChatMessagesUrl => '$messageApiUrl/chat';
  static String get sendMessageUrl => '$messageApiUrl/save';
  static String get getChatListUrl => '$chatApiUrl/getchatlist';


  static String get wsEndpoint => '$wsUrl/ws';

  static Map<String, String> get headers => {
    'Content-Type': 'application/json',
    'Accept': '*/*',
    'ngrok-skip-browser-warning': '69420',
  };
}