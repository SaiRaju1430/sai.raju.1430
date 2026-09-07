DateTime? _parseDateTimeNullable(dynamic value) {
  if (value == null) return null;
  if (value is DateTime) return value;
  if (value is String) return DateTime.tryParse(value);
  if (value.runtimeType.toString() == 'Timestamp') {
    return (value as dynamic).toDate();
  }
  return null;
}

DateTime _parseDateTime(dynamic value) {
  return _parseDateTimeNullable(value) ?? DateTime.now();
}

class OrderItemModel {
  final String productId;
  final String productName;
  final int quantity;
  final double price;
  final String imageUrl;
  final String unit; // NEW

  OrderItemModel({
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.price,
    required this.imageUrl,
    required this.unit,
  });

  factory OrderItemModel.fromMap(Map<String, dynamic> data) {
    return OrderItemModel(
      productId: data['productId'] ?? data['product_id'] ?? '',
      productName: data['productName'] ?? data['product_name'] ?? '',
      quantity: data['quantity'] ?? 0,
      price: (data['price'] ?? 0.0).toDouble(),
      imageUrl: data['imageUrl'] ?? data['image_url'] ?? '',
      unit: data['unit'] ?? 'kg',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'productName': productName,
      'quantity': quantity,
      'price': price,
      'imageUrl': imageUrl,
      'unit': unit,
    };
  }
}

class OrderModel {
  final String id;
  final String customerId;
  final String customerName;
  final String customerMobile;
  final String blockName;
  final String roomNumber;
  final List<OrderItemModel> items;
  final double subtotal;
  final double deliveryFee;
  final double total;
  final String paymentId;
  final String paymentAccountName; // NEW
  final String paymentMobileNumber; // NEW
  final String verificationCode;
  final String status; // Pending, Accepted, Out For Delivery, Delivered, Rejected
  final DateTime orderDate;
  final bool deliveryVerified;
  final DateTime? deliveredAt;
  final DateTime? rejectedAt;
  final DateTime? completedAt;
  final DateTime? deleteAfter;

  String get orderId => id;
  double get totalAmount => total;

  OrderModel({
    required this.id,
    required this.customerId,
    required this.customerName,
    required this.customerMobile,
    required this.blockName,
    required this.roomNumber,
    required this.items,
    required this.subtotal,
    required this.deliveryFee,
    required this.total,
    required this.paymentId,
    required this.paymentAccountName,
    required this.paymentMobileNumber,
    required this.verificationCode,
    required this.status,
    required this.orderDate,
    this.deliveryVerified = false,
    this.deliveredAt,
    this.rejectedAt,
    this.completedAt,
    this.deleteAfter,
  });

  factory OrderModel.fromMap(Map<String, dynamic> data, String id) {
    var rawItems = data['items'] as List? ?? [];
    List<OrderItemModel> parsedItems = rawItems
        .map((item) => OrderItemModel.fromMap(Map<String, dynamic>.from(item)))
        .toList();

    return OrderModel(
      id: id.isEmpty ? (data['orderId'] ?? data['id'] ?? '') : id,
      customerId: data['customerId'] ?? data['customer_id'] ?? '',
      customerName: data['customerName'] ?? data['customer_name'] ?? '',
      customerMobile: data['customerMobile'] ?? data['customer_mobile'] ?? '',
      blockName: data['blockName'] ?? data['block_name'] ?? '',
      roomNumber: data['roomNumber'] ?? data['room_number'] ?? '',
      items: parsedItems,
      subtotal: (data['subtotal'] ?? 0.0).toDouble(),
      deliveryFee: (data['deliveryFee'] ?? data['delivery_fee'] ?? 0.0).toDouble(),
      total: (data['totalAmount'] ?? data['total'] ?? 0.0).toDouble(),
      paymentId: data['paymentId'] ?? data['payment_id'] ?? '',
      paymentAccountName: data['paymentAccountName'] ?? data['payment_account_name'] ?? '',
      paymentMobileNumber: data['paymentMobileNumber'] ?? data['payment_mobile_number'] ?? '',
      verificationCode: data['verificationCode']?.toString() ?? data['verification_code']?.toString() ?? '',
      status: data['status'] ?? 'Pending',
      orderDate: _parseDateTime(data['createdAt'] ?? data['created_at'] ?? data['orderDate'] ?? data['order_date']),
      deliveryVerified: data['deliveryVerified'] ?? data['delivery_verified'] ?? data['otpVerified'] ?? false,
      deliveredAt: _parseDateTimeNullable(data['deliveredAt'] ?? data['delivered_at']),
      rejectedAt: _parseDateTimeNullable(data['rejectedAt'] ?? data['rejected_at']),
      completedAt: _parseDateTimeNullable(data['completedAt'] ?? data['completed_at']),
      deleteAfter: _parseDateTimeNullable(data['deleteAfter'] ?? data['delete_after']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'orderId': id,
      'customerId': customerId,
      'customerName': customerName,
      'customerMobile': customerMobile,
      'blockName': blockName,
      'roomNumber': roomNumber,
      'items': items.map((item) => item.toMap()).toList(),
      'subtotal': subtotal,
      'deliveryFee': deliveryFee,
      'total': total,
      'totalAmount': total,
      'paymentId': paymentId,
      'paymentAccountName': paymentAccountName,
      'paymentMobileNumber': paymentMobileNumber,
      'verificationCode': verificationCode,
      'verification_code': verificationCode,
      'status': status,
      'orderDate': orderDate.toIso8601String(),
      'createdAt': orderDate.toIso8601String(),
      'deliveryVerified': deliveryVerified,
      'delivery_verified': deliveryVerified,
      'deliveredAt': deliveredAt?.toIso8601String(),
      'delivered_at': deliveredAt?.toIso8601String(),
      'rejectedAt': rejectedAt?.toIso8601String(),
      'rejected_at': rejectedAt?.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
      'completed_at': completedAt?.toIso8601String(),
      'deleteAfter': deleteAfter?.toIso8601String(),
      'delete_after': deleteAfter?.toIso8601String(),
    };
  }

  OrderModel copyWith({
    String? id,
    String? customerId,
    String? customerName,
    String? customerMobile,
    String? blockName,
    String? roomNumber,
    List<OrderItemModel>? items,
    double? subtotal,
    double? deliveryFee,
    double? total,
    String? paymentId,
    String? paymentAccountName,
    String? paymentMobileNumber,
    String? verificationCode,
    String? status,
    DateTime? orderDate,
    bool? deliveryVerified,
    DateTime? deliveredAt,
    DateTime? rejectedAt,
    DateTime? completedAt,
    DateTime? deleteAfter,
  }) {
    return OrderModel(
      id: id ?? this.id,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      customerMobile: customerMobile ?? this.customerMobile,
      blockName: blockName ?? this.blockName,
      roomNumber: roomNumber ?? this.roomNumber,
      items: items ?? this.items,
      subtotal: subtotal ?? this.subtotal,
      deliveryFee: deliveryFee ?? this.deliveryFee,
      total: total ?? this.total,
      paymentId: paymentId ?? this.paymentId,
      paymentAccountName: paymentAccountName ?? this.paymentAccountName,
      paymentMobileNumber: paymentMobileNumber ?? this.paymentMobileNumber,
      verificationCode: verificationCode ?? this.verificationCode,
      status: status ?? this.status,
      orderDate: orderDate ?? this.orderDate,
      deliveryVerified: deliveryVerified ?? this.deliveryVerified,
      deliveredAt: deliveredAt ?? this.deliveredAt,
      rejectedAt: rejectedAt ?? this.rejectedAt,
      completedAt: completedAt ?? this.completedAt,
      deleteAfter: deleteAfter ?? this.deleteAfter,
    );
  }
}
