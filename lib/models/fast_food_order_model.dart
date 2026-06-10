import 'package:cloud_firestore/cloud_firestore.dart';

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
  });

  factory FastFoodOrderModel.fromMap(Map<String, dynamic> data, String id) {
    var rawItems = data['items'] as List? ?? [];
    List<FastFoodOrderItemModel> parsedItems = rawItems
        .map((item) => FastFoodOrderItemModel.fromMap(Map<String, dynamic>.from(item)))
        .toList();

    double parsedSubtotal = (data['foodTotal'] ?? data['subtotal'] ?? 0.0).toDouble();
    double parsedDeliveryFee = (data['deliveryCharge'] ?? data['deliveryFee'] ?? 0.0).toDouble();
    double parsedCodCharge = (data['codCharge'] ?? 0.0).toDouble();
    String parsedPaymentMethod = data['paymentMethod'] ?? 'Online';
    double parsedGrandTotal = (data['grandTotal'] ?? data['totalAmount'] ?? 0.0).toDouble();

    String parsedDeliveryCode = data['deliveryOtp'] ?? data['deliveryCode'] ?? data['verificationOtp'] ?? '';
    bool parsedDeliveryVerified = data['otpVerified'] ?? data['deliveryVerified'] ?? data['otpUsed'] ?? false;
    DateTime? parsedDeliveredAt = data['deliveredAt'] != null
        ? (data['deliveredAt'] is Timestamp 
            ? (data['deliveredAt'] as Timestamp).toDate()
            : DateTime.parse(data['deliveredAt']))
        : null;

    return FastFoodOrderModel(
      orderId: id.isEmpty ? (data['orderId'] ?? '') : id,
      customerId: data['customerId'] ?? '',
      customerName: data['customerName'] ?? '',
      mobile: data['mobile'] ?? '',
      blockName: data['blockName'] ?? '',
      roomNumber: data['roomNumber'] ?? '',
      items: parsedItems,
      subtotal: parsedSubtotal,
      deliveryFee: parsedDeliveryFee,
      totalAmount: parsedGrandTotal,
      paymentId: data['paymentId'] ?? '',
      status: data['status'] ?? 'Pending',
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] is Timestamp 
              ? (data['createdAt'] as Timestamp).toDate()
              : DateTime.parse(data['createdAt']))
          : DateTime.now(),
      foodTotal: parsedSubtotal,
      deliveryCharge: parsedDeliveryFee,
      codCharge: parsedCodCharge,
      paymentMethod: parsedPaymentMethod,
      grandTotal: parsedGrandTotal,
      deliveryCode: parsedDeliveryCode,
      deliveryVerified: parsedDeliveryVerified,
      deliveredAt: parsedDeliveredAt,
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
      'createdAt': Timestamp.fromDate(createdAt),
      'foodTotal': foodTotal,
      'deliveryCharge': deliveryCharge,
      'codCharge': codCharge,
      'paymentMethod': paymentMethod,
      'grandTotal': grandTotal,
      'deliveryCode': deliveryCode,
      'deliveryOtp': deliveryCode,
      'deliveryVerified': deliveryVerified,
      'otpVerified': deliveryVerified,
      'deliveredAt': deliveredAt != null ? Timestamp.fromDate(deliveredAt!) : null,
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
    );
  }
}
