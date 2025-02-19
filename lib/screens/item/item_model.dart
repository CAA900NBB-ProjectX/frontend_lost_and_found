// lib/screens/item/item_model.dart
class ItemModel {
  final String id;
  final String title;
  final String location;
  final String finderName;
  final String finderRole;
  final DateTime postedTime;
  final String? imageUrl;
  final String? description;

  ItemModel({
    required this.id,
    required this.title,
    required this.location,
    required this.finderName,
    required this.finderRole,
    required this.postedTime,
    this.imageUrl,
    this.description,
  });

  // need to be replaced with actual backend data mapping (now just using for demo)
  factory ItemModel.fromJson(Map<String, dynamic> json) {
    return ItemModel(
      id: json['id'],
      title: json['title'],
      location: json['location'],
      finderName: json['finderName'],
      finderRole: json['finderRole'],
      postedTime: DateTime.parse(json['postedTime']),
      imageUrl: json['imageUrl'],
      description: json['description'],
    );
  }
}