import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/item.dart';

class ItemService {
  final storage = const FlutterSecureStorage();

  String get baseUrl {
    // For web
    if (kIsWeb) {
      return 'http://localhost:8081';
    }
    // For Android emulator
    else if (!kIsWeb && Platform.isAndroid) {
      return 'http://10.0.2.2:8081';
    }
    // For iOS simulator
    else if (!kIsWeb && Platform.isIOS) {
      return 'http://localhost:8081';
    }
    // Default fallback
    return 'http://localhost:8081';
  }

  Future<Map<String, String>> _getHeaders() async {
    final token = await storage.read(key: 'jwt_token');
    return {
      'Content-Type': 'application/json',
      'Accept': '*/*',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // Get all items
  Future<List<Item>> getAllItems() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/item/getallitems'),
        headers: headers,
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final List<dynamic> itemsJson = jsonDecode(response.body);
        return itemsJson.map((json) => Item.fromJson(json)).toList();
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
      final headers = await _getHeaders();
      final jsonData = item.toJson();
      final jsonBody = jsonEncode(jsonData);
      print("Sending JSON: $jsonBody");

      final response = await http.post(
        Uri.parse('$baseUrl/item/insertitems'),
        headers: headers,
        body: jsonBody,
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        try {
          final responseJson = jsonDecode(response.body);
          final createdItem = Item.fromJson(responseJson);
          return createdItem;
        } catch (e) {
          print('Error parsing response: $e');
          // Return a basic item with the ID from the response if possible
          try {
            final responseJson = jsonDecode(response.body);
            if (responseJson['item_id'] != null) {
              // Create a copy of the original item but with the ID set
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
            // Ignore this error and fall back to returning null
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
      final response = await http.get(
        Uri.parse('$baseUrl/item/getitems/$itemId'),
        headers: headers,
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        try {
          final responseJson = jsonDecode(response.body);
          final item = Item.fromJson(responseJson);
          return item;
        } catch (e) {
          print('Error parsing response: $e');
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
      final headers = await _getHeaders();
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/item/uploadimage/$itemId'),
      );

      // Add authorization header
      request.headers.addAll(headers);

      // Add the image file
      request.files.add(
        http.MultipartFile.fromBytes(
          'image',
          imageBytes,
          filename: imageName,
        ),
      );

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      return response.statusCode == 200;
    } catch (e) {
      print('Error uploading image: $e');
      return false;
    }
  }

  // Get image by ID
  Future<List<int>?> getItemImage(int imageId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/item/getimage/$imageId'),
        headers: headers,
      );

      if (response.statusCode == 200) {
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