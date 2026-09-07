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

class PersonalRequestModel {
  final String id; // maps to requestId
  final String customerId;
  final String customerName;
  final String customerMobile; // maps to mobileNumber
  final String blockName;
  final String roomNumber;
  final String description;
  final String imageUrl;
  final double productPrice;
  final double deliveryCharge;
  final double totalAmount;
  final String paymentId;
  final String paymentAccountName; // NEW
  final String paymentMobileNumber; // NEW
  final String verificationCode;
  final String status;
  final DateTime requestDate; // maps to createdAt
  final bool deliveryVerified;
  final DateTime? deliveredAt;
  final DateTime? rejectedAt;
  final DateTime? completedAt;
  final DateTime? deleteAfter;

  String get itemName => description;
  double? get quotedPrice => productPrice > 0 ? productPrice : null;

  PersonalRequestModel({
    required this.id,
    required this.customerId,
    required this.customerName,
    required this.customerMobile,
    required this.blockName,
    required this.roomNumber,
    required this.description,
    required this.imageUrl,
    required this.productPrice,
    required this.deliveryCharge,
    required this.totalAmount,
    required this.paymentId,
    required this.paymentAccountName,
    required this.paymentMobileNumber,
    required this.verificationCode,
    required this.status,
    required this.requestDate,
    this.deliveryVerified = false,
    this.deliveredAt,
    this.rejectedAt,
    this.completedAt,
    this.deleteAfter,
  });

  factory PersonalRequestModel.fromMap(Map<String, dynamic> data, String id) {
    return PersonalRequestModel(
      id: id.isEmpty ? (data['id'] ?? '') : id,
      customerId: data['customerId'] ?? data['customer_id'] ?? '',
      customerName: data['customerName'] ?? data['customer_name'] ?? '',
      customerMobile: data['mobileNumber'] ?? data['customerMobile'] ?? data['customer_mobile'] ?? '',
      blockName: data['blockName'] ?? data['block_name'] ?? '',
      roomNumber: data['roomNumber'] ?? data['room_number'] ?? '',
      description: data['description'] ?? '',
      imageUrl: data['imageUrl'] ?? data['image_url'] ?? '',
      productPrice: (data['productPrice'] ?? data['product_price'] ?? 0.0).toDouble(),
      deliveryCharge: (data['deliveryCharge'] ?? data['delivery_charge'] ?? 0.0).toDouble(),
      totalAmount: (data['totalAmount'] ?? data['total_amount'] ?? 0.0).toDouble(),
      paymentId: data['paymentId'] ?? data['payment_id'] ?? '',
      paymentAccountName: data['paymentAccountName'] ?? data['payment_account_name'] ?? '',
      paymentMobileNumber: data['paymentMobileNumber'] ?? data['payment_mobile_number'] ?? '',
      verificationCode: data['verificationCode']?.toString() ?? data['verification_code']?.toString() ?? '',
      status: data['status'] ?? 'Pending Review',
      requestDate: _parseDateTime(data['createdAt'] ?? data['created_at'] ?? data['requestDate'] ?? data['request_date']),
      deliveryVerified: data['deliveryVerified'] ?? data['delivery_verified'] ?? data['otpVerified'] ?? false,
      deliveredAt: _parseDateTimeNullable(data['deliveredAt'] ?? data['delivered_at']),
      rejectedAt: _parseDateTimeNullable(data['rejectedAt'] ?? data['rejected_at']),
      completedAt: _parseDateTimeNullable(data['completedAt'] ?? data['completed_at']),
      deleteAfter: _parseDateTimeNullable(data['deleteAfter'] ?? data['delete_after']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'customerId': customerId,
      'customerName': customerName,
      'mobileNumber': customerMobile,
      'customerMobile': customerMobile,
      'blockName': blockName,
      'roomNumber': roomNumber,
      'description': description,
      'imageUrl': imageUrl,
      'productPrice': productPrice,
      'deliveryCharge': deliveryCharge,
      'totalAmount': totalAmount,
      'paymentId': paymentId,
      'paymentAccountName': paymentAccountName,
      'paymentMobileNumber': paymentMobileNumber,
      'verificationCode': verificationCode,
      'verification_code': verificationCode,
      'status': status,
      'createdAt': requestDate.toIso8601String(),
      'requestDate': requestDate.toIso8601String(),
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

  PersonalRequestModel copyWith({
    String? id,
    String? customerId,
    String? customerName,
    String? customerMobile,
    String? blockName,
    String? roomNumber,
    String? description,
    String? imageUrl,
    double? productPrice,
    double? deliveryCharge,
    double? totalAmount,
    String? paymentId,
    String? paymentAccountName,
    String? paymentMobileNumber,
    String? verificationCode,
    String? status,
    DateTime? requestDate,
    bool? deliveryVerified,
    DateTime? deliveredAt,
    DateTime? rejectedAt,
    DateTime? completedAt,
    DateTime? deleteAfter,
  }) {
    return PersonalRequestModel(
      id: id ?? this.id,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      customerMobile: customerMobile ?? this.customerMobile,
      blockName: blockName ?? this.blockName,
      roomNumber: roomNumber ?? this.roomNumber,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      productPrice: productPrice ?? this.productPrice,
      deliveryCharge: deliveryCharge ?? this.deliveryCharge,
      totalAmount: totalAmount ?? this.totalAmount,
      paymentId: paymentId ?? this.paymentId,
      paymentAccountName: paymentAccountName ?? this.paymentAccountName,
      paymentMobileNumber: paymentMobileNumber ?? this.paymentMobileNumber,
      verificationCode: verificationCode ?? this.verificationCode,
      status: status ?? this.status,
      requestDate: requestDate ?? this.requestDate,
      deliveryVerified: deliveryVerified ?? this.deliveryVerified,
      deliveredAt: deliveredAt ?? this.deliveredAt,
      rejectedAt: rejectedAt ?? this.rejectedAt,
      completedAt: completedAt ?? this.completedAt,
      deleteAfter: deleteAfter ?? this.deleteAfter,
    );
  }
}
