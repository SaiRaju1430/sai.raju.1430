import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../models/fast_food_item_model.dart';
import '../models/fast_food_order_model.dart';
import '../core/services/supabase_service.dart';
import '../core/services/notification_service.dart';

class FastFoodProvider extends ChangeNotifier {
  final SupabaseService _db = SupabaseService();

  List<FastFoodItemModel> _items = [];
  List<FastFoodOrderModel> _customerOrders = [];
  List<FastFoodOrderModel> _allOrders = [];
  bool _isLoading = false;
  String? _errorMessage;
  String _lastDeliveryCode = '';

  StreamSubscription<Map<String, dynamic>>? _timerSubscription;
  Map<String, dynamic> _timerData = {};
  Map<String, dynamic> get timerData => _timerData;

  Timer? _tickerTimer;
  String _remainingTimeString = '';
  String get remainingTimeString => _remainingTimeString;

  // Cart: Item ID -> FastFoodOrderItemModel
  final Map<String, FastFoodOrderItemModel> _cart = {};

  StreamSubscription<List<FastFoodItemModel>>? _itemsSubscription;
  StreamSubscription<List<FastFoodOrderModel>>? _customerOrdersSubscription;
  StreamSubscription<List<FastFoodOrderModel>>? _adminOrdersSubscription;

  List<FastFoodItemModel> get items => _items;
  List<FastFoodOrderModel> get customerOrders => _customerOrders;
  List<FastFoodOrderModel> get allOrders => _allOrders;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  Map<String, FastFoodOrderItemModel> get cart => _cart;
  int get cartItemCount => _cart.values.fold(0, (sum, item) => sum + item.quantity);
  String get lastDeliveryCode => _lastDeliveryCode;
  bool get isTimerRunning => _timerData['fastFoodEnabled'] == true;
  String get formattedRemainingTime => _remainingTimeString.isNotEmpty ? _remainingTimeString : '00:00';

  FastFoodProvider() {
    initItemsStream();
    initTimerStream();
  }

  void initItemsStream() {
    _isLoading = true;
    _itemsSubscription?.cancel();
    _itemsSubscription = _db.streamFastFoodItems().listen(
      (data) {
        _items = data;
        _isLoading = false;
        notifyListeners();
      },
      onError: (error) {
        _errorMessage = error.toString();
        _isLoading = false;
        notifyListeners();
      }
    );
  }

  final Set<String> _knownOrderIds = {};

  final Map<String, String> _previousCustomerStatuses = {};

  void initCustomerOrdersStream(String customerId) {
    _customerOrdersSubscription?.cancel();
    _customerOrdersSubscription = _db.streamCustomerFastFoodOrders(customerId).listen(
      (data) {
        for (var order in data) {
          final prevStatus = _previousCustomerStatuses[order.orderId];
          if (prevStatus != null && prevStatus != order.status) {
            final shortId = order.orderId.replaceAll("fford_", "");
            final cleanId = shortId.substring(0, shortId.length > 6 ? 6 : shortId.length).toUpperCase();

            NotificationService().showSimulatedNotification(
              'Order Status Updated! 🍔',
              'Your Fast Food Order #$cleanId is now ${order.status}.',
            );

            if (order.status == 'Delivered') {
              _triggerDeliveredPopup();
            }
          }
          _previousCustomerStatuses[order.orderId] = order.status;
        }

        if (_previousCustomerStatuses.isEmpty && data.isNotEmpty) {
          for (var order in data) {
            _previousCustomerStatuses[order.orderId] = order.status;
          }
        }

        _customerOrders = data;
        notifyListeners();
      }
    );
  }

  void _triggerDeliveredPopup() {
    final context = NotificationService.navigatorKey.currentContext;
    if (context == null) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.check_circle_rounded, color: Colors.green),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                '🎉 Order Delivered Successfully',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: const Text(
          'Thank you for choosing CampusKart.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('OK', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Future<bool> verifyFastFoodDeliveryCode(String orderId, String enteredCode) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      String storedOtp = '';
      String customerId = '';
      
      if (!_db.isOfflineMode) {
        try {
          final doc = await _db.client.from('fast_food_orders').select().eq('id', orderId).single();
          storedOtp = (doc['delivery_code'] ?? doc['delivery_otp'] ?? '').toString();
          customerId = (doc['customer_id'] ?? '').toString();
        } catch (e) {
          _errorMessage = 'Order not found.';
          _isLoading = false;
          notifyListeners();
          return false;
        }
      } else {
        final orderIndex = _allOrders.indexWhere((o) => o.orderId == orderId);
        if (orderIndex == -1) {
          _errorMessage = 'Order not found.';
          _isLoading = false;
          notifyListeners();
          return false;
        }
        storedOtp = _allOrders[orderIndex].deliveryCode;
        customerId = _allOrders[orderIndex].customerId;
      }

      if (storedOtp.toString().trim() != enteredCode.toString().trim()) {
        _errorMessage = 'Invalid Verification Code\nPlease verify and try again.';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      await _db.verifyAndDeliverFastFoodOrder(orderId);

      // Save direct CampusKart notification to customer history
      if (customerId.isNotEmpty) {
        try {
          await _db.sendNotification(
            title: '🎉 Order Delivered',
            message: 'Thank you for choosing CampusKart.',
            targetUserId: customerId,
          );
        } catch (e) {
          print("Failed to save customer order delivery notification: $e");
        }
      }

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

  Future<FastFoodOrderModel> checkAndGenerateFallbackOtp(FastFoodOrderModel order) async {
    if (order.deliveryCode.isEmpty) {
      final fallbackOtp = (Random().nextInt(9000) + 1000).toString();
      // Log error for debugging
      print("DEBUG ERROR: Fast Food order ${order.orderId} is missing deliveryOtp! Automatically generating fallback OTP: $fallbackOtp");
      
      try {
        if (!_db.isOfflineMode) {
          await _db.client.from('fast_food_orders').update({
            'delivery_code': fallbackOtp,
            'delivery_verified': false,
          }).eq('id', order.orderId);
        } else {
          final idx = _allOrders.indexWhere((o) => o.orderId == order.orderId);
          if (idx != -1) {
            _allOrders[idx] = _allOrders[idx].copyWith(
              deliveryCode: fallbackOtp,
              deliveryVerified: false,
            );
          }
        }
      } catch (e) {
        print("DEBUG ERROR: Failed to generate fallback OTP: $e");
      }
      return order.copyWith(deliveryCode: fallbackOtp, deliveryVerified: false);
    }
    return order;
  }

  void initAdminOrdersStream() {
    _adminOrdersSubscription?.cancel();
    _adminOrdersSubscription = _db.streamAllFastFoodOrders().listen(
      (data) {
        // Show notification to admin for new orders
        if (_knownOrderIds.isNotEmpty) {
          for (var order in data) {
            if (!_knownOrderIds.contains(order.orderId)) {
              NotificationService().showSimulatedNotification(
                'New Fast Food Order! 🍔',
                '${order.customerName} ordered ${order.items.length} items. Total: ₹${order.totalAmount.toStringAsFixed(0)}',
              );
            }
          }
        }
        _knownOrderIds.clear();
        _knownOrderIds.addAll(data.map((o) => o.orderId));

        _allOrders = data;
        notifyListeners();
      }
    );
  }

  // --- FAST FOOD TIMER REMINDER LOGIC ---

  void initTimerStream() {
    _timerSubscription?.cancel();
    _timerSubscription = _db.streamFastFoodSettings().listen((data) {
      _timerData = data;
      _checkTimerNotifications(data);

      final enabled = data['fastFoodEnabled'] ?? false;
      final endsAtVal = data['timerEndsAt'];
      if (enabled && endsAtVal != null) {
        final DateTime endsAt = endsAtVal.runtimeType.toString() == 'Timestamp'
            ? (endsAtVal as dynamic).toDate()
            : (endsAtVal is DateTime ? endsAtVal : DateTime.tryParse(endsAtVal.toString()) ?? DateTime.now());
        _startLocalTicker(endsAt);
      } else {
        _tickerTimer?.cancel();
        _tickerTimer = null;
        _remainingTimeString = '';
      }
      notifyListeners();
    });
  }

  void _startLocalTicker(DateTime endsAt) {
    _tickerTimer?.cancel();
    _updateRemainingTime(endsAt);
    _tickerTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _updateRemainingTime(endsAt);
    });
  }

  void _updateRemainingTime(DateTime endsAt) {
    final now = DateTime.now();
    if (now.isAfter(endsAt)) {
      _remainingTimeString = '00:00';
      _tickerTimer?.cancel();
      _tickerTimer = null;
      notifyListeners();
    } else {
      final diff = endsAt.difference(now);
      final minutes = diff.inMinutes;
      final seconds = diff.inSeconds % 60;
      final minStr = minutes.toString().padLeft(2, '0');
      final secStr = seconds.toString().padLeft(2, '0');
      _remainingTimeString = '$minStr:$secStr';
      notifyListeners();
    }
  }

  void _checkTimerNotifications(Map<String, dynamic> data) async {
    final enabled = data['fastFoodEnabled'] ?? false;
    final endsAtVal = data['timerEndsAt'];
    final startedAtVal = data['timerStartedAt'];
    if (!enabled || endsAtVal == null || startedAtVal == null) return;

    final DateTime now = DateTime.now();
    final DateTime startedAt = startedAtVal.runtimeType.toString() == 'Timestamp'
        ? (startedAtVal as dynamic).toDate()
        : (startedAtVal is DateTime ? startedAtVal : DateTime.parse(startedAtVal.toString()));
    final DateTime endsAt = endsAtVal.runtimeType.toString() == 'Timestamp'
        ? (endsAtVal as dynamic).toDate()
        : (endsAtVal is DateTime ? endsAtVal : DateTime.parse(endsAtVal.toString()));

    final duration = data['timerDuration'] ?? 0;

    if (now.isAfter(endsAt) || now.isAtSameMomentAs(endsAt)) {
      // Timer has expired!
      if (data['enableClosingNotification'] == true && data['closingNotificationSent'] != true) {
        await _db.sendNotification(
          title: '🍔 Fast Food Ordering Closed',
          message: 'Fast Food ordering is now closed. See you next session!',
        );
        await _db.updateFastFoodSettings({
          'fastFoodEnabled': false,
          'closingNotificationSent': true,
        });
      } else {
        await _db.updateFastFoodSettings({
          'fastFoodEnabled': false,
        });
      }
      return;
    }

    // Check Half-Time Reminder
    if (data['enableHalfTimeReminder'] == true && data['halfTimeReminderSent'] != true) {
      final double halfMin = duration / 2.0;
      final halfTime = startedAt.add(Duration(seconds: (halfMin * 60).toInt()));
      if (now.isAfter(halfTime)) {
        await _db.sendNotification(
          title: '🍔 Fast Food Half-Time Reminder',
          message: 'Half-time reminder: Fast Food ordering is closing soon.',
        );
        await _db.updateFastFoodSettings({
          'halfTimeReminderSent': true,
        });
      }
    }

    // Check 10-Minute Reminder
    if (data['enableTenMinReminder'] == true && data['tenMinReminderSent'] != true) {
      final tenMinTime = endsAt.subtract(const Duration(minutes: 10));
      if (now.isAfter(tenMinTime)) {
        await _db.sendNotification(
          title: '⏰ Fast Food 10-Minute Reminder',
          message: 'Hurry! Only 10 minutes left to order Fast Food.',
        );
        await _db.updateFastFoodSettings({
          'tenMinReminderSent': true,
        });
      }
    }
  }

  Future<void> startFastFoodTimer(int durationMinutes, bool enableHalf, bool enableTen, bool enableClose) async {
    final now = DateTime.now();
    final endsAt = now.add(Duration(minutes: durationMinutes));
    await _db.updateFastFoodSettings({
      'fastFoodEnabled': true,
      'timerDuration': durationMinutes,
      'timerStartedAt': now.toIso8601String(),
      'timerEndsAt': endsAt.toIso8601String(),
      'enableHalfTimeReminder': enableHalf,
      'enableTenMinReminder': enableTen,
      'enableClosingNotification': enableClose,
      'halfTimeReminderSent': false,
      'tenMinReminderSent': false,
      'closingNotificationSent': false,
    });
    await _db.sendNotification(
      title: '🍔 Fast Food Ordering Open',
      message: 'Fast Food ordering is now open! Order your favorites.',
    );
  }

  Future<void> stopFastFoodTimer() async {
    _tickerTimer?.cancel();
    _tickerTimer = null;
    _remainingTimeString = '';
    
    // Stop the timer and disable fast food
    await _db.updateFastFoodSettings({
      'fastFoodEnabled': false,
      'timerStartedAt': null,
      'timerEndsAt': null,
    });
  }

  // --- CART OPERATIONS ---

  void addToCart(FastFoodItemModel item) {
    if (!item.available) return;

    if (_cart.containsKey(item.id)) {
      int newQty = _cart[item.id]!.quantity + 1;
      _cart[item.id] = FastFoodOrderItemModel(
        name: item.name,
        quantity: newQty,
        price: item.price,
      );
    } else {
      _cart[item.id] = FastFoodOrderItemModel(
        name: item.name,
        quantity: 1,
        price: item.price,
      );
    }
    notifyListeners();
  }

  void removeFromCart(String itemId) {
    if (_cart.containsKey(itemId)) {
      if (_cart[itemId]!.quantity > 1) {
        _cart[itemId] = FastFoodOrderItemModel(
          name: _cart[itemId]!.name,
          quantity: _cart[itemId]!.quantity - 1,
          price: _cart[itemId]!.price,
        );
      } else {
        _cart.remove(itemId);
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

  String _paymentMethod = 'Online';
  String get paymentMethod => _paymentMethod;

  set paymentMethod(String val) {
    _paymentMethod = val;
    notifyListeners();
  }

  double get deliveryFee {
    if (_cart.isEmpty) return 0.0;
    return 10.0; // Fixed Delivery Fee of ₹10
  }

  double get codCharge {
    if (_cart.isEmpty) return 0.0;
    return _paymentMethod == 'COD' ? 10.0 : 0.0;
  }

  double get cartTotal {
    if (_cart.isEmpty) return 0.0;
    return cartSubtotal + deliveryFee + codCharge;
  }

  // --- CHECKOUT & PLACE ORDER ---

  Future<bool> checkoutAndPlaceOrder({
    required String customerId,
    required String customerName,
    required String mobile,
    required String blockName,
    required String roomNumber,
  }) async {
    if (customerName.trim().isEmpty || mobile.trim().isEmpty) {
      _errorMessage = 'Name and mobile number are required.';
      notifyListeners();
      return false;
    }

    if (blockName.trim().isEmpty || roomNumber.trim().isEmpty) {
      _errorMessage = 'Hostel block and room number are required.';
      notifyListeners();
      return false;
    }

    if (_cart.isEmpty) {
      _errorMessage = 'Cart is empty.';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final code = (Random().nextInt(9000) + 1000).toString();
      FastFoodOrderModel newOrder = FastFoodOrderModel(
        orderId: '',
        customerId: customerId,
        customerName: customerName,
        mobile: mobile,
        blockName: blockName,
        roomNumber: roomNumber,
        items: _cart.values.toList(),
        subtotal: cartSubtotal,
        deliveryFee: deliveryFee,
        totalAmount: cartTotal,
        paymentId: _paymentMethod == 'COD' ? 'COD' : 'Online',
        status: 'Pending',
        createdAt: DateTime.now(),
        foodTotal: cartSubtotal,
        deliveryCharge: deliveryFee,
        codCharge: codCharge,
        paymentMethod: _paymentMethod,
        grandTotal: cartTotal,
        deliveryCode: code,
        deliveryVerified: false,
      );

      await _db.placeFastFoodOrder(newOrder);
      _cart.clear();
      _paymentMethod = 'Online'; // Reset to default
      _lastDeliveryCode = code; // Save it to show in success dialog!
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

  /// Admin: confirm online payment and generate delivery code.
  Future<String?> confirmFastFoodPayment(String orderId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final code = await _db.confirmFastFoodPayment(orderId);
      final order = _allOrders.firstWhere((o) => o.orderId == orderId);
      await _db.sendNotification(
        title: '💳 Payment Confirmed',
        message: 'Your payment has been confirmed.',
        targetUserId: order.customerId,
      );
      _isLoading = false;
      notifyListeners();
      return code;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  /// Admin: reject online payment.
  Future<bool> rejectFastFoodPayment(String orderId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final order = _allOrders.firstWhere((o) => o.orderId == orderId);
      await _db.rejectFastFoodPayment(orderId);
      await _db.sendNotification(
        title: '❌ Order Rejected',
        message: 'Your order has been rejected.',
        targetUserId: order.customerId,
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

  // --- ADMIN OPERATIONS ---

  Future<bool> addFastFoodItem({
    required String name,
    required String description,
    required String category,
    required double price,
    required String imageUrl,
    required bool available,
    bool notifyCustomers = false,
  }) async {
    if (name.trim().isEmpty || description.trim().isEmpty || price <= 0) {
      _errorMessage = 'Invalid input details.';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    notifyListeners();

    try {
      final itemId = await _db.addFastFoodItem(name, description, category, price, imageUrl, available);
      if (notifyCustomers) {
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final docId = 'food_item_${itemId}_$timestamp';
        await _db.sendTimerNotification(
          notificationId: docId,
          title: '🍔 New Fast Food Item',
          message: '$name is now available in CampusKart Fast Food. Order now.',
          type: 'fast_food_reminder',
          imageUrl: imageUrl.isNotEmpty ? imageUrl : null,
          productId: itemId,
          productType: 'fast_food',
        );
      }
      _isLoading = false;
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateFastFoodItem(FastFoodItemModel item, {bool notifyCustomers = false}) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _db.updateFastFoodItem(item);
      if (notifyCustomers) {
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final docId = 'food_item_${item.id}_$timestamp';
        await _db.sendTimerNotification(
          notificationId: docId,
          title: '🍔 New Fast Food Item',
          message: '${item.name} is now available in CampusKart Fast Food. Order now.',
          type: 'fast_food_reminder',
          imageUrl: item.imageUrl.isNotEmpty ? item.imageUrl : null,
          productId: item.id,
          productType: 'fast_food',
        );
      }
      _isLoading = false;
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteFastFoodItem(String id) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _db.deleteFastFoodItem(id);
      _isLoading = false;
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> shipFastFoodOrder(String orderId) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _db.updateFastFoodOrderStatus(orderId, 'Out For Delivery');
      
      // Find the order to send push notification to correct customer
      FastFoodOrderModel? order;
      final idx = _allOrders.indexWhere((o) => o.orderId == orderId);
      if (idx != -1) {
        order = _allOrders[idx];
      } else {
        final custIdx = _customerOrders.indexWhere((o) => o.orderId == orderId);
        if (custIdx != -1) {
          order = _customerOrders[custIdx];
        }
      }

      if (order != null) {
        await _db.sendNotification(
          title: '🚚 Out For Delivery',
          message: 'Your Fast Food order is on the way.',
          targetUserId: order.customerId,
        );
      }
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

  Future<bool> updateOrderStatus(String orderId, String status) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _db.updateFastFoodOrderStatus(orderId, status);
      _isLoading = false;
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
    _itemsSubscription?.cancel();
    _customerOrdersSubscription?.cancel();
    _adminOrdersSubscription?.cancel();
    _timerSubscription?.cancel();
    _tickerTimer?.cancel();
    super.dispose();
  }
}
