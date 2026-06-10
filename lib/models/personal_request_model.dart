import 'package:cloud_firestore/cloud_firestore.dart';

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
  });

  factory PersonalRequestModel.fromMap(Map<String, dynamic> data, String id) {
    return PersonalRequestModel(
      id: id,
      customerId: data['customerId'] ?? '',
      customerName: data['customerName'] ?? '',
      customerMobile: data['mobileNumber'] ?? data['customerMobile'] ?? '',
      blockName: data['blockName'] ?? '',
      roomNumber: data['roomNumber'] ?? '',
      description: data['description'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
      productPrice: (data['productPrice'] ?? 0.0).toDouble(),
      deliveryCharge: (data['deliveryCharge'] ?? 0.0).toDouble(),
      totalAmount: (data['totalAmount'] ?? 0.0).toDouble(),
      paymentId: data['paymentId'] ?? '',
      paymentAccountName: data['paymentAccountName'] ?? '',
      paymentMobileNumber: data['paymentMobileNumber'] ?? '',
      verificationCode: data['verificationCode']?.toString() ?? '',
      status: data['status'] ?? 'Pending Review',
      requestDate: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : data['requestDate'] != null
              ? (data['requestDate'] as Timestamp).toDate()
              : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
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
      'status': status,
      'createdAt': Timestamp.fromDate(requestDate),
      'requestDate': Timestamp.fromDate(requestDate),
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
    );
  }
}
