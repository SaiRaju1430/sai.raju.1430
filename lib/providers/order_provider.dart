import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../models/order_model.dart';
import '../models/product_model.dart';
import '../models/personal_request_model.dart';
import '../core/services/firebase_service.dart';
import '../core/services/notification_service.dart';
import '../core/utils/delivery_calculator.dart';
import '../core/constants/app_constants.dart';

class OrderProvider extends ChangeNotifier {
  final FirebaseService _db = FirebaseService();

  // Shopping Cart: Product ID -> OrderItemModel
  final Map<String, OrderItemModel> _cart = {};

  bool _isLoading = false;
  String? _errorMessage;
  String? _lastPlacedOrderId;

  List<OrderModel> _customerOrders = [];
  List<PersonalRequestModel> _customerRequests = [];
  StreamSubscription<List<OrderModel>>? _ordersSubscription;
  StreamSubscription<List<PersonalRequestModel>>? _requestsSubscription;
  StreamSubscription<bool>? _availabilitySubscription;

  bool _isOwnerAvailable = true;

  Map<String, OrderItemModel> get cart => _cart;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get lastPlacedOrderId => _lastPlacedOrderId;
  List<OrderModel> get customerOrders => _customerOrders;
  List<PersonalRequestModel> get customerRequests => _customerRequests;
  bool get isOwnerAvailable => _isOwnerAvailable;

  OrderProvider() {
    _initAvailabilityStream();
  }

  void _initAvailabilityStream() {
    _availabilitySubscription?.cancel();
    _availabilitySubscription = _db.streamShopAvailability().listen((available) {
      _isOwnerAvailable = available;
      notifyListeners();
    });
  }

  // Status tracking maps for contextless notifications
  final Map<String, String> _previousStatuses = {};
  final Map<String, String> _previousRequestStatuses = {};

  void initCustomerStreams(String customerId) {
    _isLoading = true;
    
    _ordersSubscription?.cancel();
    _ordersSubscription = _db.streamCustomerOrders(customerId).listen((orders) {
      // Monitor status changes for customer alerts
      for (var order in orders) {
        final prevStatus = _previousStatuses[order.id];
        if (prevStatus != null && prevStatus != order.status) {
          NotificationService().showSimulatedNotification(
            'Order Status Updated! 📦',
            'Your Order #${order.id.replaceAll("ord_", "").substring(0, min(6, order.id.replaceAll("ord_", "").length)).toUpperCase()} is now ${order.status}.',
          );
        }
        _previousStatuses[order.id] = order.status;
      }
      
      if (_previousStatuses.isEmpty && orders.isNotEmpty) {
        for (var order in orders) {
          _previousStatuses[order.id] = order.status;
        }
      }

      _customerOrders = orders;
      _isLoading = false;
      notifyListeners();
    });

    _requestsSubscription?.cancel();
    _requestsSubscription = _db.streamCustomerRequests(customerId).listen((reqs) {
      // Monitor status changes for personal requests
      for (var req in reqs) {
        final prevStatus = _previousRequestStatuses[req.id];
        if (prevStatus != null && prevStatus != req.status) {
          NotificationService().showSimulatedNotification(
            'Request Status Updated! 📝',
            'Your Custom Request #${req.id.replaceAll("req_", "").substring(0, min(5, req.id.replaceAll("req_", "").length)).toUpperCase()} is now ${req.status}.',
          );

          if (req.status == 'Delivered') {
            final navContext = NotificationService.navigatorKey.currentContext;
            if (navContext != null) {
              showDialog(
                context: navContext,
                barrierDismissible: false,
                builder: (dialogCtx) => AlertDialog(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  title: const Row(
                    children: [
                      Icon(Icons.check_circle_rounded, color: Colors.green, size: 28),
                      SizedBox(width: 10),
                      Text('🎉 Delivery Successful', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  content: const Text(
                    'Your Personal Request has been delivered successfully.\n\nThank you for choosing CampusKart.',
                    style: TextStyle(fontSize: 14, height: 1.5),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () {
                        Navigator.pop(dialogCtx);
                      },
                      child: const Text('OK', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              );
            }
          }
        }
        _previousRequestStatuses[req.id] = req.status;
      }

      if (_previousRequestStatuses.isEmpty && reqs.isNotEmpty) {
        for (var req in reqs) {
          _previousRequestStatuses[req.id] = req.status;
        }
      }

      _customerRequests = reqs;
      _isLoading = false;
      notifyListeners();
    });
  }

  // --- CART MANAGEMENT ---

  void addToCart(ProductModel product) {
    if (_cart.containsKey(product.id)) {
      int newQty = _cart[product.id]!.quantity + 1;
      if (newQty <= product.quantity) {
        _cart[product.id] = OrderItemModel(
          productId: product.id,
          productName: product.name,
          quantity: newQty,
          price: product.price,
          imageUrl: product.imageUrl,
          unit: product.unit,
        );
      }
    } else {
      if (product.quantity > 0) {
        _cart[product.id] = OrderItemModel(
          productId: product.id,
          productName: product.name,
          quantity: 1,
          price: product.price,
          imageUrl: product.imageUrl,
          unit: product.unit,
        );
      }
    }
    notifyListeners();
  }

  void setCartQuantity(ProductModel product, int quantity) {
    if (quantity <= 0) {
      _cart.remove(product.id);
    } else {
      if (quantity <= product.quantity) {
        _cart[product.id] = OrderItemModel(
          productId: product.id,
          productName: product.name,
          quantity: quantity,
          price: product.price,
          imageUrl: product.imageUrl,
          unit: product.unit,
        );
      }
    }
    notifyListeners();
  }

  void removeFromCart(String productId) {
    if (_cart.containsKey(productId)) {
      if (_cart[productId]!.quantity > 1) {
        _cart[productId] = OrderItemModel(
          productId: productId,
          productName: _cart[productId]!.productName,
          quantity: _cart[productId]!.quantity - 1,
          price: _cart[productId]!.price,
          imageUrl: _cart[productId]!.imageUrl,
          unit: _cart[productId]!.unit,
        );
      } else {
        _cart.remove(productId);
      }
    }
    notifyListeners();
  }

  void clearCart() {
    _cart.clear();
    notifyListeners();
  }

  double get cartSubtotal {
    double sub = 0.0;
    _cart.forEach((_, item) {
      sub += item.price * item.quantity;
    });
    return sub;
  }

  /// Calculates the active delivery fee based on the current system time.
  double get deliveryFee {
    return DeliveryCalculator.calculateDeliveryFee(DateTime.now(), cartSubtotal);
  }

  double get cartTotal {
    if (cartSubtotal < AppConstants.minOrderValue) {
      return cartSubtotal;
    }
    return cartSubtotal + deliveryFee;
  }

  bool get isMinOrderSatisfied => cartSubtotal >= AppConstants.minOrderValue;

  Map<String, dynamic> checkServiceAvailability() {
    if (_db.isOfflineMode) {
      return {'available': true, 'reason': ''};
    }
    return DeliveryCalculator.checkServiceAvailability(DateTime.now());
  }

  // --- CHECKOUT & PLACE ORDER ---

  Future<bool> checkoutAndPlaceOrder({
    required String customerId,
    required String customerName,
    required String customerMobile,
    required String blockName,
    required String roomNumber,
    required String paymentId,
    required String paymentAccountName,
    required String paymentMobileNumber,
  }) async {
    if (customerName.trim().isEmpty ||
        customerMobile.trim().isEmpty ||
        blockName.trim().isEmpty ||
        roomNumber.trim().isEmpty ||
        paymentAccountName.trim().isEmpty ||
        paymentMobileNumber.trim().isEmpty) {
      _errorMessage = 'All checkout fields are required, including Account Name and Payment Mobile.';
      notifyListeners();
      return false;
    }

    if (!isMinOrderSatisfied) {
      _errorMessage = 'Minimum order value is ₹100.';
      notifyListeners();
      return false;
    }

    var service = checkServiceAvailability();
    if (!service['available']) {
      _errorMessage = service['reason'];
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Generate a random 4-digit verification code
      Random random = Random();
      String verificationCode = (1000 + random.nextInt(9000)).toString(); // e.g. 4821

      OrderModel newOrder = OrderModel(
        id: '', // Will be assigned by Firebase/Mock
        customerId: customerId,
        customerName: customerName,
        customerMobile: customerMobile,
        blockName: blockName,
        roomNumber: roomNumber,
        items: _cart.values.toList(),
        subtotal: cartSubtotal,
        deliveryFee: deliveryFee,
        total: cartTotal,
        paymentId: paymentId,
        paymentAccountName: paymentAccountName,
        paymentMobileNumber: paymentMobileNumber,
        verificationCode: verificationCode,
        status: 'Pending',
        orderDate: DateTime.now(),
      );

      String orderId = await _db.placeOrder(newOrder);
      _lastPlacedOrderId = orderId;
      _cart.clear(); // Clear cart after successful order
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception:', '').trim();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // --- CUSTOM PERSONAL REQUESTS ---

  Future<bool> submitPersonalRequest({
    required String customerId,
    required String customerName,
    required String customerMobile,
    required String blockName,
    required String roomNumber,
    required String description,
  }) async {
    if (description.trim().isEmpty || blockName.trim().isEmpty || roomNumber.trim().isEmpty) {
      _errorMessage = 'All fields (details, hostel block, room number) are required.';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      PersonalRequestModel newRequest = PersonalRequestModel(
        id: '',
        customerId: customerId,
        customerName: customerName,
        customerMobile: customerMobile,
        blockName: blockName,
        roomNumber: roomNumber,
        description: description,
        imageUrl: '',
        productPrice: 0.0,
        deliveryCharge: 0.0,
        totalAmount: 0.0,
        paymentId: '',
        paymentAccountName: '',
        paymentMobileNumber: '',
        verificationCode: '',
        status: 'Pending Review',
        requestDate: DateTime.now(),
      );

      await _db.submitPersonalRequest(newRequest);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> submitPersonalRequestPayment({
    required String requestId,
    required String paymentId,
    required String paymentAccountName,
    required String paymentMobileNumber,
  }) async {
    if (paymentAccountName.trim().isEmpty ||
        paymentMobileNumber.trim().isEmpty) {
      _errorMessage = 'All payment fields are required, including Account Name and Payment Mobile.';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      PersonalRequestModel req = _customerRequests.firstWhere((r) => r.id == requestId);
      PersonalRequestModel updatedReq = req.copyWith(
        paymentId: paymentId,
        paymentAccountName: paymentAccountName,
        paymentMobileNumber: paymentMobileNumber,
        status: 'Payment Verification Pending',
      );
      await _db.updatePersonalRequest(updatedReq);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  @override
  void dispose() {
    _ordersSubscription?.cancel();
    _requestsSubscription?.cancel();
    _availabilitySubscription?.cancel();
    super.dispose();
  }
}
