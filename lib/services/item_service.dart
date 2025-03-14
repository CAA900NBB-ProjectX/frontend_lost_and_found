import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/item.dart';
import '../config/api_config.dart';
import 'dart:html' as html;

class ItemService {
  final storage = const FlutterSecureStorage();

  // Get token directly from local storage for web
  String? _getToken() {
    if (kIsWeb) {
      // In web, get token directly from localStorage
      final token = html.window.localStorage['jwt_token'];
      print('Token from localStorage: ${token != null ? 'Found' : 'Not found'}');
      return token;
    } else {
      // This won't be called in web but included for completeness
      // For mobile implementations
      return null;
    }
  }

  // Get headers with auth token
  Map<String, String> _getHeaders() {
    final token = _getToken();
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
      print('Using auth token: ${token.length > 10 ? token.substring(0, 10) + '...' : token}');
    } else {
      print('No auth token available');
    }

    return headers;
  }

  // Log response for debugging
  void _logResponse(String operation, http.Response response) {
    print('$operation Response status: ${response.statusCode}');

    // Print first 200 chars of body to avoid huge logs
    final preview = response.body.length > 200
        ? response.body.substring(0, 200) + '...'
        : response.body;
    print('$operation Response preview: $preview');

    // Check for HTML response
    if (response.body.trim().startsWith('<!DOCTYPE') ||
        response.body.trim().startsWith('<html')) {
      print('WARNING: Received HTML response instead of expected JSON');
    }
  }

  // Get all items
  Future<List<Item>> getAllItems() async {
    try {
      final headers = _getHeaders();
      final url = ApiConfig.getAllItemsUrl;
      print('Fetching all items with URL: $url');

      final response = await http.get(
        Uri.parse(url),
        headers: headers,
      );

      _logResponse('Get All Items', response);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        try {
          final List<dynamic> itemsJson = jsonDecode(response.body);
          return itemsJson.map((json) => Item.fromJson(json)).toList();
        } catch (e) {
          print('JSON parsing error: $e');
          return [];
        }
      } else {
        print('Failed to load items: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('Error getting all items: $e');
      return [];
    }
  }

  // Create a new item
  Future<Item?> createItem(Item item) async {
    try {
      final headers = _getHeaders();
      final jsonData = item.toJson();
      final jsonBody = jsonEncode(jsonData);
      final url = ApiConfig.insertItemUrl;

      print("Creating item at URL: $url");
      print("With headers: $headers");
      print("Sending JSON: $jsonBody");

      final response = await http.post(
        Uri.parse(url),
        headers: headers,
        body: jsonBody,
      );

      _logResponse('Create Item', response);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        try {
          final responseJson = jsonDecode(response.body);
          return Item.fromJson(responseJson);
        } catch (e) {
          print('Error parsing response: $e');
          return null;
        }
      } else {
        print('Failed to create item: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Error creating item: $e');
      return null;
    }
  }

  // Get item by ID
  Future<Item?> getItemById(int itemId) async {
    try {
      final headers = _getHeaders();
      final url = '${ApiConfig.getItemByIdUrl}/$itemId';

      print('Getting item with URL: $url');

      final response = await http.get(
        Uri.parse(url),
        headers: headers,
      );

      _logResponse('Get Item By ID', response);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        try {
          final responseJson = jsonDecode(response.body);
          return Item.fromJson(responseJson);
        } catch (e) {
          print('Error parsing item response: $e');
          return null;
        }
      } else {
        print('Failed to get item: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Error getting item: $e');
      return null;
    }
  }

  // Upload image for an item
  Future<bool> uploadItemImage(int itemId, List<int> imageBytes, String imageName) async {
    try {
      final token = _getToken();
      final url = '${ApiConfig.uploadImageUrl}/$itemId';

      print('Uploading image to URL: $url');

      // Create multipart request
      final request = http.MultipartRequest(
        'POST',
        Uri.parse(url),
      );

      // Add auth header
      if (token != null && token.isNotEmpty) {
        request.headers['Authorization'] = 'Bearer $token';
      }

      // Add the image file
      request.files.add(
        http.MultipartFile.fromBytes(
          'image',
          imageBytes,
          filename: imageName,
        ),
      );

      print('Sending upload request...');
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      _logResponse('Upload Image', response);

      return response.statusCode >= 200 && response.statusCode < 300;
    } catch (e) {
      print('Error uploading image: $e');
      return false;
    }
  }

  // Get image by ID
  Future<List<int>?> getItemImage(int imageId) async {
    try {
      final headers = _getHeaders();
      final url = '${ApiConfig.getImageUrl}/$imageId';

      print('Getting image from URL: $url');

      final response = await http.get(
        Uri.parse(url),
        headers: headers,
      );

      _logResponse('Get Image', response);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return response.bodyBytes;
      } else {
        print('Failed to get image: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Error getting image: $e');
      return null;
    }
  }
}