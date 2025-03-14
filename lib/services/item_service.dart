import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/item.dart';
import '../config/api_config.dart';
import '../auth/services/auth_service.dart';

class ItemService {
  final storage = const FlutterSecureStorage();
  final AuthService _authService = AuthService();

  // Improved method to get headers with auth token
  Future<Map<String, String>> _getHeaders() async {
    final token = await _authService.getToken();
    print('Using auth token: ${token != null ? 'Yes' : 'No'}');

    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  // Get all items with better error handling
  Future<List<Item>> getAllItems() async {
    try {
      final headers = await _getHeaders();
      print('Fetching all items with headers: $headers');
      print('URL: ${ApiConfig.getAllItemsUrl}');

      final response = await http.get(
        Uri.parse(ApiConfig.getAllItemsUrl),
        headers: headers,
      );

      print('Get All Items Response status: ${response.statusCode}');

      // Log first 100 chars to avoid huge logs
      final responsePreview = response.body.length > 100
          ? response.body.substring(0, 100) + '...'
          : response.body;
      print('Get All Items Response preview: $responsePreview');

      if (response.statusCode >= 200 && response.statusCode < 300) {
        try {
          final List<dynamic> itemsJson = jsonDecode(response.body);
          return itemsJson.map((json) => Item.fromJson(json)).toList();
        } catch (e) {
          print('JSON parsing error: $e');
          print('Raw response: ${response.body}');
          return [];
        }
      } else {
        print('Failed to load items: ${response.statusCode}');
        print('Response body: ${response.body}');
        return [];
      }
    } catch (e) {
      print('Error getting all items: $e');
      return [];
    }
  }

  // Create a new item with improved error handling
  Future<Item?> createItem(Item item) async {
    try {
      final headers = await _getHeaders();
      final jsonData = item.toJson();
      final jsonBody = jsonEncode(jsonData);

      print("Creating item with URL: ${ApiConfig.insertItemUrl}");
      print("Headers: $headers");
      print("Sending JSON: $jsonBody");

      final response = await http.post(
        Uri.parse(ApiConfig.insertItemUrl),
        headers: headers,
        body: jsonBody,
      );

      print('Create Item Response status: ${response.statusCode}');
      print('Create Item Response body: ${response.body}');

      if (response.statusCode >= 200 && response.statusCode < 300) {
        try {
          final responseJson = jsonDecode(response.body);
          return Item.fromJson(responseJson);
        } catch (e) {
          print('Error parsing create response: $e');

          // Try to extract just the ID if the response format is different
          try {
            final responseJson = jsonDecode(response.body);
            if (responseJson['item_id'] != null) {
              return Item(
                itemId: responseJson['item_id'],
                itemName: item.itemName,
                description: item.description,
                categoryId: item.categoryId,
                locationFound: item.locationFound,
                dateTimeFound: item.dateTimeFound,
                reportedBy: item.reportedBy,
                contactInfo: item.contactInfo,
                status: item.status,
              );
            }
          } catch (_) {
            // Ignore this error if it fails
          }

          // If we at least know it was successful, return the original item
          if (response.statusCode < 300) {
            return Item(
              itemName: item.itemName,
              description: item.description,
              categoryId: item.categoryId,
              locationFound: item.locationFound,
              dateTimeFound: item.dateTimeFound,
              reportedBy: item.reportedBy,
              contactInfo: item.contactInfo,
              status: item.status,
            );
          }

          return null;
        }
      } else {
        print('Failed to create item: ${response.statusCode}');
        print('Response body: ${response.body}');
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
      final headers = await _getHeaders();
      final url = '${ApiConfig.getItemByIdUrl}/$itemId';

      print('Getting item with URL: $url');

      final response = await http.get(
        Uri.parse(url),
        headers: headers,
      );

      print('Get Item by ID Response status: ${response.statusCode}');
      print('Get Item by ID Response preview: ${response.body.substring(0, min(100, response.body.length))}...');

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

  // Upload image for an item with improved error handling
  Future<bool> uploadItemImage(int itemId, List<int> imageBytes, String imageName) async {
    try {
      final headers = await _getHeaders();
      final url = '${ApiConfig.uploadImageUrl}/$itemId';

      print('Uploading image to URL: $url');

      // Create multipart request
      final request = http.MultipartRequest(
        'POST',
        Uri.parse(url),
      );

      // Add auth header
      if (headers.containsKey('Authorization')) {
        request.headers['Authorization'] = headers['Authorization']!;
      }

      // Add content type for the request parts
      request.headers['Accept'] = 'application/json';

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

      print('Upload Image Response status: ${response.statusCode}');
      print('Upload Image Response body: ${response.body}');

      return response.statusCode >= 200 && response.statusCode < 300;
    } catch (e) {
      print('Error uploading image: $e');
      return false;
    }
  }

  // Get image by ID
  Future<List<int>?> getItemImage(int imageId) async {
    try {
      final headers = await _getHeaders();
      final url = '${ApiConfig.getImageUrl}/$imageId';

      print('Getting image from URL: $url');

      final response = await http.get(
        Uri.parse(url),
        headers: headers,
      );

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

  // Helper method for string length safety
  int min(int a, int b) {
    return a < b ? a : b;
  }
}