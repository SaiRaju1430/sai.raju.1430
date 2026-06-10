import 'package:cloud_firestore/cloud_firestore.dart';

class ProductModel {
  final String id;
  final String name;
  final String category;
  final double price;
  final int quantity;
  final String imageUrl;
  final String description; // NEW
  final String unit; // NEW
  final bool available;
  final DateTime createdDate;

  ProductModel({
    required this.id,
    required this.name,
    required this.category,
    required this.price,
    required this.quantity,
    required this.imageUrl,
    required this.description,
    required this.unit,
    required this.available,
    required this.createdDate,
  });

  factory ProductModel.fromMap(Map<String, dynamic> data, String id) {
    return ProductModel(
      id: id,
      name: data['name'] ?? '',
      category: data['category'] ?? '',
      price: (data['price'] ?? 0.0).toDouble(),
      quantity: data['quantity'] ?? 0,
      imageUrl: data['imageUrl'] ?? '',
      description: data['description'] ?? '',
      unit: data['unit'] ?? 'kg',
      available: data['available'] ?? true,
      createdDate: data['createdDate'] != null 
          ? (data['createdDate'] as Timestamp).toDate() 
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'category': category,
      'price': price,
      'quantity': quantity,
      'imageUrl': imageUrl,
      'description': description,
      'unit': unit,
      'available': available,
      'createdDate': Timestamp.fromDate(createdDate),
    };
  }

  ProductModel copyWith({
    String? id,
    String? name,
    String? category,
    double? price,
    int? quantity,
    String? imageUrl,
    String? description,
    String? unit,
    bool? available,
    DateTime? createdDate,
  }) {
    return ProductModel(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      price: price ?? this.price,
      quantity: quantity ?? this.quantity,
      imageUrl: imageUrl ?? this.imageUrl,
      description: description ?? this.description,
      unit: unit ?? this.unit,
      available: available ?? this.available,
      createdDate: createdDate ?? this.createdDate,
    );
  }
}
