import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/item.dart';
import '../config/api_config.dart';
import 'dart:html' as html;

class ItemService {
  final storage = const FlutterSecureStorage();


  String? _getToken() {
    if (kIsWeb) {

      final token = html.window.localStorage['jwt_token'];
      print('Token from localStorage: ${token != null ? 'Found' : 'Not found'}');
      return token;
    } else {

      return null;
    }
  }


  Future<List<int>?> getItemImage(int imageId) async {
    print('Warning: getItemImage is deprecated. Images are now stored as base64 in the item.');
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


  Map<String, String> _getHeaders() {
    final token = _getToken();
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      "ngrok-skip-browser-warning": "69420",
    };

    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
      print('Using auth token: ${token.length > 10 ? token.substring(0, 10) + '...' : token}');
    } else {
      print('No auth token available');
    }

    return headers;
  }


  void _logResponse(String operation, http.Response response) {
    print('$operation Response status: ${response.statusCode}');


    final preview = response.body.length > 200
        ? response.body.substring(0, 200) + '...'
        : response.body;
    print('$operation Response preview: $preview');


    if (response.body.trim().startsWith('<!DOCTYPE') ||
        response.body.trim().startsWith('<html')) {
      print('WARNING: Received HTML response instead of expected JSON');
    }
  }


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


  Future<Item?> createItem(Item item, {List<Uint8List>? imageBytes, List<String>? imageNames}) async {
    try {
      final headers = _getHeaders();


      if (imageBytes != null && imageBytes.isNotEmpty) {
        final List<ItemImage> images = [];

        for (int i = 0; i < imageBytes.length; i++) {
          final String base64Image = base64Encode(imageBytes[i]);
          final String imageName = i < imageNames!.length ? imageNames[i] : 'image_${i+1}.jpg';

          images.add(ItemImage(
            description: 'Image of ${item.itemName}',
            image: 'data:image/jpeg;base64,$base64Image',
            locationFound: item.locationFound,
            dateTime: DateTime.now().toIso8601String().substring(11, 19), // HH:MM:SS
            status: item.status,
          ));
        }


        final newItem = Item(
          itemId: item.itemId,
          itemName: item.itemName,
          description: item.description,
          categoryId: item.categoryId,
          locationFound: item.locationFound,
          dateTimeFound: item.dateTimeFound,
          reportedBy: item.reportedBy,
          contactInfo: item.contactInfo,
          status: item.status,
          images: images,
        );


        item = newItem;
      }

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


  Future<Item?> updateItem(int itemId, Item updatedItem) async {
    try {
      final headers = _getHeaders();
      final jsonData = updatedItem.toJson();
      final jsonBody = jsonEncode(jsonData);
      final url = '${ApiConfig.updateItemUrl}/$itemId';

      print('Updating item at URL: $url');
      print('With headers: $headers');
      print('Sending JSON: $jsonBody');

      final response = await http.put(
        Uri.parse(url),
        headers: headers,
        body: jsonBody,
      );

      _logResponse('Update Item', response);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        try {
          final responseJson = jsonDecode(response.body);
          return Item.fromJson(responseJson);
        } catch (e) {
          print('Error parsing response: $e');
          return null;
        }
      } else {
        print('Failed to update item: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Error updating item: $e');
      return null;
    }
  }

  Future<bool> deleteItem(int itemId) async {
    try {
      final headers = _getHeaders();
      final url = '${ApiConfig.deleteItemUrl}/$itemId';

      print('Deleting item with URL: $url');

      final response = await http.delete(
        Uri.parse(url),
        headers: headers,
      );

      _logResponse('Delete Item', response);

      return response.statusCode >= 200 && response.statusCode < 300;
    } catch (e) {
      print('Error deleting item: $e');
      return false;
    }
  }

  Future<List<Item>> searchItems(String? itemName, String? locationFound, String? description) async {
    try {
      final headers = _getHeaders();
      final queryParams = <String, String>{};

      if (itemName != null && itemName.isNotEmpty) {
        queryParams['itemName'] = itemName;
      }
      if (locationFound != null && locationFound.isNotEmpty) {
        queryParams['locationFound'] = locationFound;
      }
      if (description != null && description.isNotEmpty) {
        queryParams['description'] = description;
      }

      final uri = Uri.parse(ApiConfig.searchItemsUrl).replace(queryParameters: queryParams);

      print('Searching items with URL: $uri');

      final response = await http.get(
        uri,
        headers: headers,
      );

      _logResponse('Search Items', response);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        try {
          final List<dynamic> itemsJson = jsonDecode(response.body);
          return itemsJson.map((json) => Item.fromJson(json)).toList();
        } catch (e) {
          print('JSON parsing error: $e');
          return [];
        }
      } else {
        print('Failed to search items: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('Error searching items: $e');
      return [];
    }
  }

  Future<bool> uploadItemImage(int itemId, List<int> imageBytes, String imageName) async {
    try {

      final item = await getItemById(itemId);
      if (item == null) {
        print('Failed to get item for image upload');
        return false;
      }


      final String base64Image = base64Encode(imageBytes);


      final newImage = ItemImage(
        description: 'Image of ${item.itemName}',
        image: 'data:image/jpeg;base64,$base64Image',
        locationFound: item.locationFound,
        dateTime: DateTime.now().toIso8601String().substring(11, 19), // HH:MM:SS
        status: item.status,
      );

      // Add image to the item's images list
      final List<ItemImage> updatedImages = item.images?.toList() ?? [];
      updatedImages.add(newImage);

      // Create updated item
      final updatedItem = Item(
        itemId: item.itemId,
        itemName: item.itemName,
        description: item.description,
        categoryId: item.categoryId,
        locationFound: item.locationFound,
        dateTimeFound: item.dateTimeFound,
        reportedBy: item.reportedBy,
        contactInfo: item.contactInfo,
        status: item.status,
        images: updatedImages,
      );

      // Update the item with the new image
      final headers = _getHeaders();
      final jsonData = updatedItem.toJson();
      final jsonBody = jsonEncode(jsonData);
      final url = '${ApiConfig.updateItemUrl}/${item.itemId}';

      print('Uploading image to URL: $url');
      print('With headers: $headers');
      print('Sending JSON with image: ${jsonBody.substring(0, min(100, jsonBody.length))}...');

      final response = await http.put(
        Uri.parse(url),
        headers: headers,
        body: jsonBody,
      );

      _logResponse('Upload Image', response);

      return response.statusCode >= 200 && response.statusCode < 300;
    } catch (e) {
      print('Error uploading image: $e');
      return false;
    }
  }


  int min(int a, int b) {
    return a < b ? a : b;
  }
}