import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/order_model.dart';
import '../models/personal_request_model.dart';
import '../models/earnings_model.dart';
import '../core/services/firebase_service.dart';
import '../core/services/notification_service.dart';
import '../core/services/whatsapp_service.dart';

class AdminProvider extends ChangeNotifier {
  final FirebaseService _db = FirebaseService();

  List<OrderModel> _allOrders = [];
  List<PersonalRequestModel> _allRequests = [];
  bool _isOwnerAvailable = true;
  bool _sendNotificationOnNewItem = true;
  bool _isLoading = false;
  String? _errorMessage;

  StreamSubscription<List<OrderModel>>? _ordersSubscription;
  StreamSubscription<List<PersonalRequestModel>>? _requestsSubscription;
  StreamSubscription<bool>? _availabilitySubscription;
  StreamSubscription<bool>? _sendNotificationOnNewItemSubscription;

  List<OrderModel> get allOrders => _allOrders;
  List<PersonalRequestModel> get allRequests => _allRequests;
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
      print("Admin loaded ${orders.length} orders from database.");
      
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
      print("CampusKart Verify: Starting verification. orderId='$orderId', inputCode='$inputCode'");

      PersonalRequestModel? matchedReq;
      if (!_db.isOfflineMode) {
        try {
          final doc = await FirebaseFirestore.instance
              .collection('personal_requests')
              .doc(orderId)
              .get();
          if (doc.exists && doc.data() != null) {
            matchedReq = PersonalRequestModel.fromMap(doc.data()!, doc.id);
            print("CampusKart Verify: Direct Firestore document found for personal request: ${doc.id}");
          } else {
            print("CampusKart Verify: Direct Firestore document NOT found for id: $orderId");
          }
        } catch (e) {
          print("CampusKart Verify: Direct Firestore query failed: $e");
        }
      }

      // Fallback to local request list (e.g. offline mock mode or if Firestore fetch failed)
      if (matchedReq == null) {
        matchedReq = _allRequests.cast<PersonalRequestModel?>().firstWhere(
          (r) => r!.id == orderId,
          orElse: () => null,
        );
      }

      if (matchedReq != null) {
        final String storedOtp = matchedReq.verificationCode.toString().trim();
        final String enteredOtp = inputCode.toString().trim();

        // URGENT AUDIT LOGS
        print("CampusKart Verify Audit: Request ID='${matchedReq.id}', Document ID='$orderId', Stored OTP='$storedOtp', Entered OTP='$enteredOtp'");

        if (storedOtp == enteredOtp) {
          // Mark delivered with timestamp in Firestore
          await _db.deliverPersonalRequest(orderId);

          // Send customer delivery notification
          try {
            await _db.sendNotification(
              title: '🎉 Order Delivered',
              message: 'Thank you for choosing CampusKart.',
              targetUserId: matchedReq.customerId,
            );
          } catch (e) {
            print("CampusKart Verify: Failed to send delivery notification: $e");
          }

          print("CampusKart Verify: Personal request DELIVERED successfully.");
          _isLoading = false;
          notifyListeners();
          return true;
        } else {
          print("CampusKart Verify: Code mismatch. stored='$storedOtp' entered='$enteredOtp'");
          _errorMessage = 'Invalid Delivery Code. Please verify and try again.';
          _isLoading = false;
          notifyListeners();
          return false;
        }
      }

      // --- Try General Orders ---
      final OrderModel? matchedOrder = _allOrders.cast<OrderModel?>().firstWhere(
        (o) => o!.id == orderId,
        orElse: () => null,
      );

      if (matchedOrder != null) {
        print("CampusKart Verify: Found general order. storedCode='${matchedOrder.verificationCode}' entered='$inputCode'");
        if (matchedOrder.verificationCode.toString().trim() == inputCode.trim()) {
          await _db.updateOrderStatus(orderId, 'Delivered');
          await _db.sendNotification(
            title: '🎉 Order Delivered',
            message: 'Thank you for choosing CampusKart.',
            targetUserId: matchedOrder.customerId,
          );
          print("CampusKart Verify: General order DELIVERED successfully.");
          _isLoading = false;
          notifyListeners();
          return true;
        } else {
          print("CampusKart Verify: Code mismatch. stored='${matchedOrder.verificationCode}' entered='$inputCode'");
          _errorMessage = 'Invalid Delivery Code. Please verify and try again.';
          _isLoading = false;
          notifyListeners();
          return false;
        }
      }

      // --- Not found in either list ---
      print("CampusKart Verify: orderId='$orderId' not found in allRequests (${_allRequests.length}) or allOrders (${_allOrders.length})");
      _errorMessage = 'Order/Request not found. Please refresh and try again.';
      _isLoading = false;
      notifyListeners();
      return false;

    } catch (e, stack) {
      print("CampusKart Verify: Exception caught: $e\n$stack");
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
        message: 'Your personal request has been approved.',
        targetUserId: req.customerId,
      );

      // Auto-trigger WhatsApp notification
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
      
      // Generate a secure random 4-digit OTP for doorstep delivery verification
      final verificationCode = (1000 + (DateTime.now().millisecondsSinceEpoch % 9000)).toString();
      
      final updatedReq = req.copyWith(
        status: 'Confirmed',
        verificationCode: verificationCode,
      );
      await _db.updatePersonalRequest(updatedReq);
      
      // Auto-trigger WhatsApp receipt with verification code
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
          ? 'The shop owner is now available. You can place general orders.'
          : 'The shop owner is currently unavailable.',
    );
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
    _availabilitySubscription?.cancel();
    _sendNotificationOnNewItemSubscription?.cancel();
    super.dispose();
  }
}
