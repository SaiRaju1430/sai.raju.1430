import 'dart:async';
import 'package:flutter/material.dart';
import '../models/order_model.dart';
import '../models/personal_request_model.dart';
import '../models/earnings_model.dart';
import '../models/user_model.dart';
import '../core/services/supabase_service.dart';
import '../core/services/notification_service.dart';
import '../core/services/whatsapp_service.dart';

class AdminProvider extends ChangeNotifier {
  final SupabaseService _db = SupabaseService();

  List<OrderModel> _allOrders = [];
  List<PersonalRequestModel> _allRequests = [];
  List<UserModel> _allCustomers = [];
  bool _isOwnerAvailable = true;
  bool _sendNotificationOnNewItem = true;
  bool _isLoading = false;
  String? _errorMessage;

  StreamSubscription<List<OrderModel>>? _ordersSubscription;
  StreamSubscription<List<PersonalRequestModel>>? _requestsSubscription;
  StreamSubscription<List<UserModel>>? _customersSubscription;
  StreamSubscription<bool>? _availabilitySubscription;
  StreamSubscription<bool>? _sendNotificationOnNewItemSubscription;

  List<OrderModel> get allOrders => _allOrders;
  List<PersonalRequestModel> get allRequests => _allRequests;
  List<UserModel> get allCustomers => _allCustomers;
  bool get isOwnerAvailable => _isOwnerAvailable;
  bool get sendNotificationOnNewItem => _sendNotificationOnNewItem;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  AdminProvider() {
    initAdminStreams();
  }

  // Sets to track known IDs and trigger new order/request notifications for admin
  final Set<String> _knownOrderIds = {};
  final Set<String> _knownRequestIds = {};

  void initAdminStreams() {
    _isLoading = true;

    _ordersSubscription?.cancel();
    _ordersSubscription = _db.streamAllOrders().listen((orders) {
      // If known order list is already populated, notify on any new order additions
      if (_knownOrderIds.isNotEmpty) {
        for (var order in orders) {
          if (!_knownOrderIds.contains(order.id)) {
            NotificationService().showSimulatedNotification(
              'New Order Received! 🛒',
              '${order.customerName} ordered ${order.items.length} items to ${order.blockName} Room ${order.roomNumber}.',
            );
          }
        }
      }

      _knownOrderIds.clear();
      _knownOrderIds.addAll(orders.map((o) => o.id));

      _allOrders = orders;
      _isLoading = false;
      notifyListeners();
    });

    _requestsSubscription?.cancel();
    _requestsSubscription = _db.streamAllRequests().listen((reqs) {
      // Notify admin on new custom request additions
      if (_knownRequestIds.isNotEmpty) {
        for (var req in reqs) {
          if (!_knownRequestIds.contains(req.id)) {
            NotificationService().showSimulatedNotification(
              'New Custom Request! 📝',
              '${req.customerName} requested: "${req.description}"',
            );
          }
        }
      }

      _knownRequestIds.clear();
      _knownRequestIds.addAll(reqs.map((r) => r.id));

      _allRequests = reqs;
      _isLoading = false;
      notifyListeners();
    });

    _customersSubscription?.cancel();
    _customersSubscription = _db.streamAllUsers().listen((users) {
      _allCustomers = users.where((u) => u.role == 'customer').toList();
      notifyListeners();
    });

    _availabilitySubscription?.cancel();
    _availabilitySubscription = _db.streamShopAvailability().listen((available) {
      _isOwnerAvailable = available;
      notifyListeners();
    });

    _sendNotificationOnNewItemSubscription?.cancel();
    _sendNotificationOnNewItemSubscription = _db.streamSendNotificationOnNewItem().listen((enabled) {
      _sendNotificationOnNewItem = enabled;
      notifyListeners();
    });
  }

  // --- REVENUE & ANALYTICS CALCULATIONS ---

  EarningsModel get earningsDetails {
    double todayIncome = 0.0;
    double monthlyIncome = 0.0;
    int todayOrdersCount = 0;
    int pendingOrders = 0;
    int pendingReqs = 0;
    int deliveredOrdersCount = 0;

    DateTime now = DateTime.now();
    DateTime todayStart = DateTime(now.year, now.month, now.day);
    DateTime monthStart = DateTime(now.year, now.month, 1);

    for (var order in _allOrders) {
      if (order.status == 'Delivered') {
        if (order.orderDate.isAfter(todayStart)) {
          // Income is calculated specifically from delivery charges
          todayIncome += order.deliveryFee;
          deliveredOrdersCount++;
        }
        if (order.orderDate.isAfter(monthStart)) {
          monthlyIncome += order.deliveryFee;
        }
      }

      if (order.status == 'Pending') {
        pendingOrders++;
      }

      if (order.orderDate.isAfter(todayStart)) {
        todayOrdersCount++;
      }
    }

    for (var req in _allRequests) {
      if (req.status == 'Pending Review' || req.status == 'Payment Verification Pending') {
        pendingReqs++;
      }

      // Personal requests also count as order if confirmed or delivered today
      if (req.status == 'Confirmed' || req.status == 'Delivered') {
        if (req.requestDate.isAfter(todayStart)) {
          todayOrdersCount++;
        }
      }

      // Add personal request delivery charge to income if delivered successfully
      if (req.status == 'Delivered') {
        if (req.requestDate.isAfter(todayStart)) {
          todayIncome += req.deliveryCharge;
          deliveredOrdersCount++;
        }
        if (req.requestDate.isAfter(monthStart)) {
          monthlyIncome += req.deliveryCharge;
        }
      }
    }

    return EarningsModel(
      todayIncome: todayIncome,
      monthlyIncome: monthlyIncome,
      todayOrdersCount: todayOrdersCount,
      pendingOrdersCount: pendingOrders,
      pendingRequestsCount: pendingReqs,
      deliveredOrdersCount: deliveredOrdersCount,
    );
  }

  // --- ORDER PROGRESSIONS & ACTIONS ---

  Future<bool> acceptOrder(String orderId) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _db.updateOrderStatus(orderId, 'Accepted');
      final order = _allOrders.firstWhere((o) => o.id == orderId);
      await _db.sendNotification(
        title: '📦 Order Accepted',
        message: 'Your order has been accepted.',
        targetUserId: order.customerId,
      );
      _isLoading = false;
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> rejectOrder(String orderId) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _db.updateOrderStatus(orderId, 'Rejected');
      final order = _allOrders.firstWhere((o) => o.id == orderId);
      await _db.sendNotification(
        title: '❌ Order Rejected',
        message: 'Your order has been rejected.',
        targetUserId: order.customerId,
      );
      _isLoading = false;
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> shipOrder(String orderId) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _db.updateOrderStatus(orderId, 'Out For Delivery');
      final order = _allOrders.firstWhere((o) => o.id == orderId);
      await _db.sendNotification(
        title: '🚚 Out For Delivery',
        message: 'Your order is on the way.',
        targetUserId: order.customerId,
      );
      _isLoading = false;
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> verifyAndDeliverOrder(String orderId, String inputCode) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      debugPrint("CampusKart Verify: Starting verification for orderId='$orderId', inputCode='$inputCode'");

      // 1. Try Personal Requests
      try {
        final doc = await _db.client
            .from('personal_requests')
            .select()
            .eq('id', orderId)
            .maybeSingle();

        if (doc != null) {
          final matchedReq = PersonalRequestModel.fromMap(doc, doc['id'] ?? '');
          final String storedOtp = matchedReq.verificationCode.toString().trim();
          final String enteredOtp = inputCode.toString().trim();

          if (storedOtp == enteredOtp) {
            await _db.deliverPersonalRequest(orderId);
            try {
              await _db.sendNotification(
                title: '🎉 Order Delivered',
                message: 'Thank you for choosing CampusKart.',
                targetUserId: matchedReq.customerId,
              );
            } catch (e) {
              debugPrint("CampusKart Verify: Notification error: $e");
            }
            _isLoading = false;
            notifyListeners();
            return true;
          } else {
            _errorMessage = 'Invalid Delivery Code. Please verify and try again.';
            _isLoading = false;
            notifyListeners();
            return false;
          }
        }
      } catch (e) {
        debugPrint("Personal request verification query: $e");
      }

      // 2. Try General Orders
      try {
        final orderDoc = await _db.client
            .from('orders')
            .select()
            .eq('id', orderId)
            .maybeSingle();

        if (orderDoc != null) {
          final storedCode = (orderDoc['verification_code'] ?? '').toString().trim();
          if (storedCode == inputCode.trim()) {
            await _db.updateOrderStatus(orderId, 'Delivered');
            final custId = (orderDoc['customer_id'] ?? '').toString();
            if (custId.isNotEmpty) {
              await _db.sendNotification(
                title: '🎉 Order Delivered',
                message: 'Thank you for choosing CampusKart.',
                targetUserId: custId,
              );
            }
            _isLoading = false;
            notifyListeners();
            return true;
          } else {
            _errorMessage = 'Invalid Delivery Code. Please verify and try again.';
            _isLoading = false;
            notifyListeners();
            return false;
          }
        }
      } catch (e) {
        debugPrint("General order verification query: $e");
      }

      // 3. Try Fast Food Orders
      try {
        final ffDoc = await _db.client
            .from('fast_food_orders')
            .select()
            .eq('id', orderId)
            .maybeSingle();

        if (ffDoc != null) {
          final storedCode = (ffDoc['delivery_code'] ?? '').toString().trim();
          if (storedCode == inputCode.trim()) {
            await _db.verifyAndDeliverFastFoodOrder(orderId);
            final custId = (ffDoc['customer_id'] ?? '').toString();
            if (custId.isNotEmpty) {
              await _db.sendNotification(
                title: '🎉 Fast Food Delivered',
                message: 'Thank you for choosing CampusKart.',
                targetUserId: custId,
              );
            }
            _isLoading = false;
            notifyListeners();
            return true;
          } else {
            _errorMessage = 'Invalid Delivery Code. Please verify and try again.';
            _isLoading = false;
            notifyListeners();
            return false;
          }
        }
      } catch (e) {
        debugPrint("Fast food verification query: $e");
      }

      _errorMessage = 'Order/Request not found. Please refresh and try again.';
      _isLoading = false;
      notifyListeners();
      return false;

    } catch (e) {
      _errorMessage = 'Verification failed. Please try again.';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // --- PERSONAL REQUESTS ACTIONS ---

  Future<bool> shipPersonalRequest(String requestId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _db.updatePersonalRequestStatus(requestId, 'Out For Delivery');
      final req = _allRequests.firstWhere((r) => r.id == requestId);
      await _db.sendNotification(
        title: '🚚 Out For Delivery',
        message: 'Your order is on the way.',
        targetUserId: req.customerId,
      );
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

  Future<bool> sendPaymentRequest({
    required String requestId,
    required double productPrice,
    required double deliveryCharge,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final req = _allRequests.firstWhere((r) => r.id == requestId);
      final total = productPrice + deliveryCharge;
      final updatedReq = req.copyWith(
        productPrice: productPrice,
        deliveryCharge: deliveryCharge,
        totalAmount: total,
        status: 'Payment Pending',
      );
      await _db.updatePersonalRequest(updatedReq);
      
      await _db.sendNotification(
        title: '✅ Personal Request Approved',
        message: 'Your personal request has been approved. Please submit payment.',
        targetUserId: req.customerId,
      );

      // Trigger WhatsApp notification
      await WhatsAppService.sendPaymentRequest(
        mobile: req.customerMobile,
        customerName: req.customerName,
        description: req.description,
        productPrice: productPrice,
        deliveryCharge: deliveryCharge,
        totalAmount: total,
      );

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

  Future<bool> confirmPersonalRequestPayment(String requestId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final req = _allRequests.firstWhere((r) => r.id == requestId);
      
      // Generate secure 4-digit verification code
      final verificationCode = (1000 + (DateTime.now().millisecondsSinceEpoch % 9000)).toString();
      
      final updatedReq = req.copyWith(
        status: 'Confirmed',
        verificationCode: verificationCode,
      );
      await _db.updatePersonalRequest(updatedReq);
      
      await _db.sendNotification(
        title: '💳 Payment Verified',
        message: 'Payment verified! Your verification code is $verificationCode.',
        targetUserId: req.customerId,
      );

      // WhatsApp receipt with verification code
      await WhatsAppService.sendVerificationReceipt(
        mobile: req.customerMobile,
        customerName: req.customerName,
        description: req.description,
        verificationCode: verificationCode,
      );

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

  Future<bool> rejectPersonalRequest(String requestId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _db.updatePersonalRequestStatus(requestId, 'Rejected');
      final req = _allRequests.firstWhere((r) => r.id == requestId);
      await _db.sendNotification(
        title: '❌ Personal Request Rejected',
        message: 'Your personal request has been rejected.',
        targetUserId: req.customerId,
      );
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

  // --- SETTINGS AVAILABILITY TOGGLES ---

  Future<void> toggleAvailability(bool available) async {
    await _db.toggleShopAvailability(available);
    await _db.sendNotification(
      title: available ? '🏪 Owner Available' : '🏪 Owner Unavailable',
      message: available
          ? 'The shop owner is now available. You can place orders.'
          : 'The shop owner is currently unavailable.',
    );
  }

  Future<void> toggleOwnerAvailability(bool available) async {
    await toggleAvailability(available);
  }

  Future<void> toggleSendNotificationOnNewItem(bool enabled) async {
    await _db.toggleSendNotificationOnNewItem(enabled);
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _ordersSubscription?.cancel();
    _requestsSubscription?.cancel();
    _customersSubscription?.cancel();
    _availabilitySubscription?.cancel();
    _sendNotificationOnNewItemSubscription?.cancel();
    super.dispose();
  }
}
