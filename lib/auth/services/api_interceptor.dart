import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../config/api_config.dart';

class ApiInterceptor {
  static const storage = FlutterSecureStorage();

  static Future<Map<String, String>> getHeaders() async {
    final token = await storage.read(key: 'jwt_token');
    return {
      ...ApiConfig.headers,
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  static Future<http.Response> get(String url) async {
    final headers = await getHeaders();
    return await http.get(Uri.parse(url), headers: headers);
  }

  static Future<http.Response> post(String url, {Object? body}) async {
    final headers = await getHeaders();
    return await http.post(
      Uri.parse(url),
      headers: headers,
      body: body,
    );
  }
}