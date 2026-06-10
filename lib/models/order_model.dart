import 'package:cloud_firestore/cloud_firestore.dart';

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
      productId: data['productId'] ?? '',
      productName: data['productName'] ?? '',
      quantity: data['quantity'] ?? 0,
      price: (data['price'] ?? 0.0).toDouble(),
      imageUrl: data['imageUrl'] ?? '',
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
  });

  factory OrderModel.fromMap(Map<String, dynamic> data, String id) {
    var rawItems = data['items'] as List? ?? [];
    List<OrderItemModel> parsedItems = rawItems
        .map((item) => OrderItemModel.fromMap(Map<String, dynamic>.from(item)))
        .toList();

    return OrderModel(
      id: id.isEmpty ? (data['orderId'] ?? '') : id,
      customerId: data['customerId'] ?? '',
      customerName: data['customerName'] ?? '',
      customerMobile: data['customerMobile'] ?? '',
      blockName: data['blockName'] ?? '',
      roomNumber: data['roomNumber'] ?? '',
      items: parsedItems,
      subtotal: (data['subtotal'] ?? 0.0).toDouble(),
      deliveryFee: (data['deliveryFee'] ?? 0.0).toDouble(),
      total: (data['totalAmount'] ?? data['total'] ?? 0.0).toDouble(),
      paymentId: data['paymentId'] ?? '',
      paymentAccountName: data['paymentAccountName'] ?? '',
      paymentMobileNumber: data['paymentMobileNumber'] ?? '',
      verificationCode: data['verificationCode']?.toString() ?? '',
      status: data['status'] ?? 'Pending',
      orderDate: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : data['orderDate'] != null
              ? (data['orderDate'] as Timestamp).toDate()
              : DateTime.now(),
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
      'status': status,
      'orderDate': Timestamp.fromDate(orderDate),
      'createdAt': Timestamp.fromDate(orderDate),
    };
  }
}
