import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:html' as html;
import '../models/item.dart';
import '../config/api_config.dart';
import '../auth/services/auth_service.dart';
import 'package:universal_platform/universal_platform.dart';

class ItemService {
  final storage = const FlutterSecureStorage();
  final AuthService _authService = AuthService();

  Future<Map<String, String>> _getHeaders() async {
    final token = await _authService.getToken();
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
        Uri.parse(ApiConfig.getAllItemsUrl),
        headers: headers,
      );

      print('Get All Items Response status: ${response.statusCode}');
      print('Get All Items Response body: ${response.body}');

      if (response.statusCode == 200) {
        final List<dynamic> itemsJson = jsonDecode(response.body);
        return itemsJson.map((json) => Item.fromJson(json)).toList();
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

  // Create a new item
  Future<Item?> createItem(Item item) async {
    try {
      final headers = await _getHeaders();
      final jsonData = item.toJson();
      final jsonBody = jsonEncode(jsonData);
      print("Sending JSON: $jsonBody");

      final response = await http.post(
        Uri.parse(ApiConfig.insertItemUrl),
        headers: headers,
        body: jsonBody,
      );

      print('Create Item Response status: ${response.statusCode}');
      print('Create Item Response body: ${response.body}');

      if (response.statusCode == 200) {
        try {
          final responseJson = jsonDecode(response.body);
          return Item.fromJson(responseJson);
        } catch (e) {
          print('Error parsing response: $e');
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
          } catch (_) {}
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
        Uri.parse('${ApiConfig.getItemByIdUrl}/$itemId'),
        headers: headers,
      );

      print('Get Item by ID Response status: ${response.statusCode}');
      print('Get Item by ID Response body: ${response.body}');

      if (response.statusCode == 200) {
        final responseJson = jsonDecode(response.body);
        return Item.fromJson(responseJson);
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

      // Create multipart request
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('${ApiConfig.uploadImageUrl}/$itemId'),
      );

      // Add auth header
      request.headers.addAll({
        if (headers.containsKey('Authorization'))
          'Authorization': headers['Authorization']!
      });

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

      print('Upload Image Response status: ${response.statusCode}');
      print('Upload Image Response body: ${response.body}');

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
        Uri.parse('${ApiConfig.getImageUrl}/$imageId'),
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

  // Search items
  Future<List<Item>> searchItems({String? itemName, String? locationFound, String? description}) async {
    try {
      final headers = await _getHeaders();

      // Build query parameters
      final queryParams = <String, String>{};
      if (itemName != null && itemName.isNotEmpty) queryParams['itemName'] = itemName;
      if (locationFound != null && locationFound.isNotEmpty) queryParams['locationFound'] = locationFound;
      if (description != null && description.isNotEmpty) queryParams['description'] = description;

      final uri = Uri.parse(ApiConfig.searchItemsUrl).replace(queryParameters: queryParams);

      final response = await http.get(
        uri,
        headers: headers,
      );

      print('Search Items Response status: ${response.statusCode}');
      print('Search Items Response body: ${response.body}');

      if (response.statusCode == 200) {
        final List<dynamic> itemsJson = jsonDecode(response.body);
        return itemsJson.map((json) => Item.fromJson(json)).toList();
      } else {
        print('Failed to search items: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('Error searching items: $e');
      return [];
    }
  }

  // Update an item
  Future<Item?> updateItem(int itemId, Item item) async {
    try {
      final headers = await _getHeaders();
      final jsonData = item.toJson();
      final jsonBody = jsonEncode(jsonData);

      final response = await http.put(
        Uri.parse('${ApiConfig.updateItemUrl}/$itemId'),
        headers: headers,
        body: jsonBody,
      );

      print('Update Item Response status: ${response.statusCode}');
      print('Update Item Response body: ${response.body}');

      if (response.statusCode == 200) {
        final responseJson = jsonDecode(response.body);
        return Item.fromJson(responseJson);
      } else {
        print('Failed to update item: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Error updating item: $e');
      return null;
    }
  }

  // Delete an item
  Future<bool> deleteItem(int itemId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.delete(
        Uri.parse('${ApiConfig.deleteItemUrl}/$itemId'),
        headers: headers,
      );

      print('Delete Item Response status: ${response.statusCode}');
      print('Delete Item Response body: ${response.body}');

      return response.statusCode == 200;
    } catch (e) {
      print('Error deleting item: $e');
      return false;
    }
  }

  // Get items by user
  Future<List<Item>> getItemsByUser(int userId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('${ApiConfig.getItemsByUserUrl}/$userId'),
        headers: headers,
      );

      print('Get Items by User Response status: ${response.statusCode}');
      print('Get Items by User Response body: ${response.body}');

      if (response.statusCode == 200) {
        final List<dynamic> itemsJson = jsonDecode(response.body);
        return itemsJson.map((json) => Item.fromJson(json)).toList();
      } else {
        print('Failed to get items by user: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('Error getting items by user: $e');
      return [];
    }
  }
}