import 'dart:convert';

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
  final bool isOffer;
  final String offerLabel;
  final double? offerPrice;

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
    this.isOffer = false,
    this.offerLabel = 'OFFER',
    this.offerPrice,
  });

  /// Effective price considering whether this product is an active offer with an offer price
  double get effectivePrice {
    if (isOffer && offerPrice != null && offerPrice! > 0) {
      return offerPrice!;
    }
    return price;
  }

  /// True if product is an active offer with a discounted offer price lower than regular price
  bool get hasDiscount {
    return isOffer && offerPrice != null && offerPrice! > 0 && offerPrice! < price;
  }

  /// Discount percentage if applicable
  int? get discountPercentage {
    if (hasDiscount && price > 0) {
      return (((price - offerPrice!) / price) * 100).round();
    }
    return null;
  }

  static final RegExp _offerRegex = RegExp(r'<!--offer:(\{.*?\})-->');

  /// Encode offer metadata into description if database columns are not present
  static String encodeDescriptionWithOffer(
    String description, {
    bool isOffer = false,
    String offerLabel = 'OFFER',
    double? offerPrice,
  }) {
    final cleanDesc = description.replaceAll(_offerRegex, '').trim();
    if (!isOffer) {
      return cleanDesc;
    }
    final Map<String, dynamic> offerData = {
      'is_offer': true,
      'offer_label': offerLabel.trim().isEmpty ? 'OFFER' : offerLabel.trim(),
      if (offerPrice != null && offerPrice > 0) 'offer_price': offerPrice,
    };
    final jsonTag = jsonEncode(offerData);
    return '<!--offer:$jsonTag-->$cleanDesc';
  }

  /// Parse offer metadata and clean description
  static ({String cleanDescription, bool isOffer, String offerLabel, double? offerPrice}) parseOfferData(String rawDescription) {
    final match = _offerRegex.firstMatch(rawDescription);
    if (match != null) {
      try {
        final jsonStr = match.group(1);
        if (jsonStr != null) {
          final Map<String, dynamic> data = jsonDecode(jsonStr);
          final cleanDesc = rawDescription.replaceAll(_offerRegex, '').trim();
          final bool isOffer = data['is_offer'] == true;
          final String offerLabel = (data['offer_label'] ?? 'OFFER').toString();
          final double? offerPrice = data['offer_price'] != null ? (data['offer_price'] as num).toDouble() : null;
          return (cleanDescription: cleanDesc, isOffer: isOffer, offerLabel: offerLabel, offerPrice: offerPrice);
        }
      } catch (_) {}
    }
    return (cleanDescription: rawDescription.trim(), isOffer: false, offerLabel: 'OFFER', offerPrice: null);
  }

  factory ProductModel.fromMap(Map<String, dynamic> data, String id) {
    final rawDescription = (data['description'] ?? '').toString();
    final parsedOffer = parseOfferData(rawDescription);

    bool isOffer = false;
    String offerLabel = 'OFFER';
    double? parsedOfferPrice;

    if (data['is_offer'] != null || data['isOffer'] != null) {
      isOffer = data['is_offer'] == true || data['isOffer'] == true;
    } else {
      isOffer = parsedOffer.isOffer;
    }

    if (data['offer_label'] != null || data['offerLabel'] != null) {
      offerLabel = (data['offer_label'] ?? data['offerLabel'] ?? 'OFFER').toString();
    } else if (parsedOffer.isOffer) {
      offerLabel = parsedOffer.offerLabel;
    }

    if (data['offer_price'] != null) {
      parsedOfferPrice = (data['offer_price'] as num).toDouble();
    } else if (data['offerPrice'] != null) {
      parsedOfferPrice = (data['offerPrice'] as num).toDouble();
    } else if (parsedOffer.isOffer) {
      parsedOfferPrice = parsedOffer.offerPrice;
    }

    return ProductModel(
      id: id,
      name: data['name'] ?? '',
      category: data['category'] ?? '',
      price: (data['price'] ?? 0.0).toDouble(),
      quantity: data['quantity'] ?? 0,
      imageUrl: data['image_url'] ?? data['imageUrl'] ?? '',
      description: parsedOffer.cleanDescription,
      unit: data['unit'] ?? 'kg',
      available: data['available'] ?? true,
      createdDate: _parseDateTime(data['created_at'] ?? data['createdDate']),
      isOffer: isOffer,
      offerLabel: offerLabel,
      offerPrice: parsedOfferPrice,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'category': category,
      'price': price,
      'quantity': quantity,
      'image_url': imageUrl,
      'imageUrl': imageUrl,
      'description': encodeDescriptionWithOffer(
        description,
        isOffer: isOffer,
        offerLabel: offerLabel,
        offerPrice: offerPrice,
      ),
      'unit': unit,
      'available': available,
      'createdDate': createdDate.toIso8601String(),
      'is_offer': isOffer,
      'offer_label': offerLabel,
      'offer_price': offerPrice,
      'isOffer': isOffer,
      'offerLabel': offerLabel,
      'offerPrice': offerPrice,
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
    bool? isOffer,
    String? offerLabel,
    double? offerPrice,
    bool clearOfferPrice = false,
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
      isOffer: isOffer ?? this.isOffer,
      offerLabel: offerLabel ?? this.offerLabel,
      offerPrice: clearOfferPrice ? null : (offerPrice ?? this.offerPrice),
    );
  }
}
