import 'package:cloud_firestore/cloud_firestore.dart';

class FastFoodItemModel {
  final String id;
  final String name;
  final String description;
  final String category;
  final double price;
  final String imageUrl;
  final bool available;
  final DateTime createdAt;

  FastFoodItemModel({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.price,
    required this.imageUrl,
    required this.available,
    required this.createdAt,
  });

  factory FastFoodItemModel.fromMap(Map<String, dynamic> data, String id) {
    return FastFoodItemModel(
      id: id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      category: data['category'] ?? '',
      price: (data['price'] ?? 0.0).toDouble(),
      imageUrl: data['imageUrl'] ?? '',
      available: data['available'] ?? true,
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] is Timestamp 
              ? (data['createdAt'] as Timestamp).toDate()
              : DateTime.parse(data['createdAt']))
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'category': category,
      'price': price,
      'imageUrl': imageUrl,
      'available': available,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  FastFoodItemModel copyWith({
    String? id,
    String? name,
    String? description,
    String? category,
    double? price,
    String? imageUrl,
    bool? available,
    DateTime? createdAt,
  }) {
    return FastFoodItemModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      category: category ?? this.category,
      price: price ?? this.price,
      imageUrl: imageUrl ?? this.imageUrl,
      available: available ?? this.available,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
