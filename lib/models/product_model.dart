DateTime _parseDateTime(dynamic value) {
  if (value == null) return DateTime.now();
  if (value is DateTime) return value;
  if (value is String) return DateTime.parse(value);
  if (value.runtimeType.toString() == 'Timestamp') {
    return (value as dynamic).toDate();
  }
  return DateTime.now();
}

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
      imageUrl: data['imageUrl'] ?? data['image_url'] ?? '',
      description: data['description'] ?? '',
      unit: data['unit'] ?? 'kg',
      available: data['available'] ?? true,
      createdDate: _parseDateTime(data['createdDate'] ?? data['created_at']),
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
      'createdDate': createdDate.toIso8601String(),
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
