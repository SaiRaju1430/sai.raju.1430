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

class FastFoodOrderItemModel {
  final String name;
  final int quantity;
  final double price;

  FastFoodOrderItemModel({
    required this.name,
    required this.quantity,
    required this.price,
  });

  factory FastFoodOrderItemModel.fromMap(Map<String, dynamic> data) {
    return FastFoodOrderItemModel(
      name: data['name'] ?? '',
      quantity: data['quantity'] ?? 0,
      price: (data['price'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'quantity': quantity,
      'price': price,
    };
  }
}

class FastFoodOrderModel {
  final String orderId;
  final String customerId; // to stream for specific customer
  final String customerName;
  final String mobile;
  final String blockName;
  final String roomNumber;
  final List<FastFoodOrderItemModel> items;
  final double subtotal;
  final double deliveryFee;
  final double totalAmount;
  final String paymentId;
  final String status;
  final DateTime createdAt;

  // New fields
  final double foodTotal;
  final double deliveryCharge;
  final double codCharge;
  final String paymentMethod;
  final double grandTotal;

  // Delivery code fields
  final String deliveryCode;
  final bool deliveryVerified;
  final DateTime? deliveredAt;
  final DateTime? rejectedAt;
  final DateTime? completedAt;
  final DateTime? deleteAfter;

  FastFoodOrderModel({
    required this.orderId,
    required this.customerId,
    required this.customerName,
    required this.mobile,
    this.blockName = '',
    this.roomNumber = '',
    required this.items,
    required this.subtotal,
    required this.deliveryFee,
    required this.totalAmount,
    required this.paymentId,
    required this.status,
    required this.createdAt,
    required this.foodTotal,
    required this.deliveryCharge,
    required this.codCharge,
    required this.paymentMethod,
    required this.grandTotal,
    this.deliveryCode = '',
    this.deliveryVerified = false,
    this.deliveredAt,
    this.rejectedAt,
    this.completedAt,
    this.deleteAfter,
  });

  factory FastFoodOrderModel.fromMap(Map<String, dynamic> data, String id) {
    var rawItems = data['items'] as List? ?? [];
    List<FastFoodOrderItemModel> parsedItems = rawItems
        .map((item) => FastFoodOrderItemModel.fromMap(Map<String, dynamic>.from(item)))
        .toList();

    double parsedSubtotal = (data['foodTotal'] ?? data['food_total'] ?? data['subtotal'] ?? 0.0).toDouble();
    double parsedDeliveryFee = (data['deliveryCharge'] ?? data['delivery_charge'] ?? data['deliveryFee'] ?? 0.0).toDouble();
    double parsedCodCharge = (data['codCharge'] ?? data['cod_charge'] ?? 0.0).toDouble();
    String parsedPaymentMethod = data['paymentMethod'] ?? data['payment_method'] ?? 'Online';
    double parsedGrandTotal = (data['grandTotal'] ?? data['grand_total'] ?? data['totalAmount'] ?? data['total_amount'] ?? 0.0).toDouble();

    String parsedDeliveryCode = data['deliveryOtp'] ?? data['deliveryCode'] ?? data['delivery_code'] ?? data['verificationOtp'] ?? '';
    bool parsedDeliveryVerified = data['otpVerified'] ?? data['deliveryVerified'] ?? data['delivery_verified'] ?? data['otpUsed'] ?? false;
    DateTime? parsedDeliveredAt = _parseDateTimeNullable(data['deliveredAt'] ?? data['delivered_at']);
    DateTime? parsedRejectedAt = _parseDateTimeNullable(data['rejectedAt'] ?? data['rejected_at']);
    DateTime? parsedCompletedAt = _parseDateTimeNullable(data['completedAt'] ?? data['completed_at']);
    DateTime? parsedDeleteAfter = _parseDateTimeNullable(data['deleteAfter'] ?? data['delete_after']);

    return FastFoodOrderModel(
      orderId: id.isEmpty ? (data['orderId'] ?? data['id'] ?? '') : id,
      customerId: data['customerId'] ?? data['customer_id'] ?? '',
      customerName: data['customerName'] ?? data['customer_name'] ?? '',
      mobile: data['mobile'] ?? '',
      blockName: data['blockName'] ?? data['block_name'] ?? '',
      roomNumber: data['roomNumber'] ?? data['room_number'] ?? '',
      items: parsedItems,
      subtotal: parsedSubtotal,
      deliveryFee: parsedDeliveryFee,
      totalAmount: parsedGrandTotal,
      paymentId: data['paymentId'] ?? data['payment_id'] ?? '',
      status: data['status'] ?? 'Pending',
      createdAt: _parseDateTime(data['createdAt'] ?? data['created_at']),
      foodTotal: parsedSubtotal,
      deliveryCharge: parsedDeliveryFee,
      codCharge: parsedCodCharge,
      paymentMethod: parsedPaymentMethod,
      grandTotal: parsedGrandTotal,
      deliveryCode: parsedDeliveryCode,
      deliveryVerified: parsedDeliveryVerified,
      deliveredAt: parsedDeliveredAt,
      rejectedAt: parsedRejectedAt,
      completedAt: parsedCompletedAt,
      deleteAfter: parsedDeleteAfter,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'orderId': orderId,
      'customerId': customerId,
      'customerName': customerName,
      'mobile': mobile,
      'blockName': blockName,
      'roomNumber': roomNumber,
      'items': items.map((item) => item.toMap()).toList(),
      'subtotal': subtotal,
      'deliveryFee': deliveryFee,
      'totalAmount': totalAmount,
      'paymentId': paymentId,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
      'foodTotal': foodTotal,
      'deliveryCharge': deliveryCharge,
      'codCharge': codCharge,
      'paymentMethod': paymentMethod,
      'grandTotal': grandTotal,
      'deliveryCode': deliveryCode,
      'deliveryOtp': deliveryCode,
      'delivery_code': deliveryCode,
      'deliveryVerified': deliveryVerified,
      'delivery_verified': deliveryVerified,
      'otpVerified': deliveryVerified,
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

  FastFoodOrderModel copyWith({
    String? orderId,
    String? customerId,
    String? customerName,
    String? mobile,
    String? blockName,
    String? roomNumber,
    List<FastFoodOrderItemModel>? items,
    double? subtotal,
    double? deliveryFee,
    double? totalAmount,
    String? paymentId,
    String? status,
    DateTime? createdAt,
    double? foodTotal,
    double? deliveryCharge,
    double? codCharge,
    String? paymentMethod,
    double? grandTotal,
    String? deliveryCode,
    bool? deliveryVerified,
    DateTime? deliveredAt,
    DateTime? rejectedAt,
    DateTime? completedAt,
    DateTime? deleteAfter,
  }) {
    return FastFoodOrderModel(
      orderId: orderId ?? this.orderId,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      mobile: mobile ?? this.mobile,
      blockName: blockName ?? this.blockName,
      roomNumber: roomNumber ?? this.roomNumber,
      items: items ?? this.items,
      subtotal: subtotal ?? this.subtotal,
      deliveryFee: deliveryFee ?? this.deliveryFee,
      totalAmount: totalAmount ?? this.totalAmount,
      paymentId: paymentId ?? this.paymentId,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      foodTotal: foodTotal ?? this.foodTotal,
      deliveryCharge: deliveryCharge ?? this.deliveryCharge,
      codCharge: codCharge ?? this.codCharge,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      grandTotal: grandTotal ?? this.grandTotal,
      deliveryCode: deliveryCode ?? this.deliveryCode,
      deliveryVerified: deliveryVerified ?? this.deliveryVerified,
      deliveredAt: deliveredAt ?? this.deliveredAt,
      rejectedAt: rejectedAt ?? this.rejectedAt,
      completedAt: completedAt ?? this.completedAt,
      deleteAfter: deleteAfter ?? this.deleteAfter,
    );
  }
}
