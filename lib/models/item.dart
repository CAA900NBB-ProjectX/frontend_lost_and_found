import 'dart:convert';

class Item {
  final int? itemId;
  final String itemName;
  final String description;
  final int categoryId;
  final String locationFound;
  final String dateTimeFound;
  final String reportedBy;
  final String contactInfo;
  final String status;
  final List<int>? imageIdsList;

  Item({
    this.itemId,
    required this.itemName,
    required this.description,
    required this.categoryId,
    required this.locationFound,
    required this.dateTimeFound,
    required this.reportedBy,
    required this.contactInfo,
    this.status = "FOUND",
    this.imageIdsList,
  });

  factory Item.fromJson(Map<String, dynamic> json) {
    // Handle dateTimeFound which can be a List or String
    String parseDateTimeFound(dynamic value) {
      if (value is List) {
        // Convert [2025, 2, 21, 5, 54, 28, 402000000] to a DateTime string
        try {
          final year = value[0];
          final month = value[1];
          final day = value[2];
          final hour = value[3];
          final minute = value[4];
          final second = value[5];

          return '$year-${month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}T' +
              '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}:${second.toString().padLeft(2, '0')}';
        } catch (e) {
          print('Error parsing dateTime array: $e');
          return DateTime.now().toIso8601String();
        }
      } else if (value is String) {
        return value;
      } else {
        return DateTime.now().toIso8601String();
      }
    }

    return Item(
      itemId: json['item_id'],
      itemName: json['itemName'] ?? '',
      description: json['description'] ?? '',
      categoryId: json['categoryId'] ?? 0,
      locationFound: json['locationFound'] ?? '',
      dateTimeFound: parseDateTimeFound(json['dateTimeFound']),
      reportedBy: json['reportedBy'] ?? '',
      contactInfo: json['contactInfo'] ?? '',
      status: json['status'] ?? "FOUND",
      imageIdsList: json['imageIdsList'] != null
          ? (json['imageIdsList'] is List
          ? List<int>.from(json['imageIdsList'])
          : null)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'itemName': itemName,
      'description': description,
      'categoryId': categoryId,
      'locationFound': locationFound,
      'dateTimeFound': dateTimeFound,
      'reportedBy': reportedBy,
      'contactInfo': contactInfo,
      'status': status,
      if (imageIdsList != null) 'imageIdsList': imageIdsList,
    };
  }

  // Helper method to get category name from category ID
  String getCategoryName() {
    switch (categoryId) {
      case 1:
        return 'Electronics';
      case 2:
        return 'Clothing';
      case 3:
        return 'Accessories';
      case 4:
        return 'Documents';
      case 5:
        return 'Other';
      default:
        return 'Unknown';
    }
  }
}
