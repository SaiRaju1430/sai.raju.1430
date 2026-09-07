DateTime _parseDateTime(dynamic value) {
  if (value == null) return DateTime.now();
  if (value is DateTime) return value;
  if (value is String) return DateTime.parse(value);
  if (value.runtimeType.toString() == 'Timestamp') {
    return (value as dynamic).toDate();
  }
  return DateTime.now();
}

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
      imageUrl: data['imageUrl'] ?? data['image_url'] ?? '',
      available: data['available'] ?? true,
      createdAt: _parseDateTime(data['createdAt'] ?? data['created_at']),
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
      'createdAt': createdAt.toIso8601String(),
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
