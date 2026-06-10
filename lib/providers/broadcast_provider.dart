import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/services/firebase_service.dart';
import '../core/services/notification_service.dart';
import '../models/order_model.dart';
import '../models/personal_request_model.dart';
import '../models/fast_food_order_model.dart';
import 'auth_provider.dart';

class BroadcastProvider extends ChangeNotifier {
  final FirebaseService _db = FirebaseService();
  String? _customerId;
  List<Map<String, dynamic>> _allBroadcasts = [];
  List<OrderModel> _customerOrders = [];
  List<FastFoodOrderModel> _customerFastFoodOrders = [];
  List<PersonalRequestModel> _customerRequests = [];

  List<Map<String, dynamic>> _rawNotifications = [];

  final Set<String> _notifiedBroadcastIds = {};
  final Set<String> _readBroadcastIds = {};
  StreamSubscription<QuerySnapshot>? _broadcastsSubscription;
  StreamSubscription<DocumentSnapshot>? _readIdsSubscription;
  DateTime _streamStartTime = DateTime.now();
  StreamSubscription<List<Map<String, dynamic>>>? _notificationsSubscription;
  StreamSubscription<List<OrderModel>>? _ordersSubscription;
  StreamSubscription<List<FastFoodOrderModel>>? _fastFoodOrdersSubscription;
  StreamSubscription<List<PersonalRequestModel>>? _requestsSubscription;

  List<Map<String, dynamic>> get allBroadcasts => _allBroadcasts;

  // All notifications visible to this customer
  List<Map<String, dynamic>> get customerNotifications {
    return _allBroadcasts;
  }

  // Only unread notifications
  List<Map<String, dynamic>> get unreadNotifications {
    return _allBroadcasts
        .where((bc) => !(bc['isRead'] as bool? ?? false))
        .toList();
  }

  int get unreadCount => unreadNotifications.length;

  bool isRead(String notifId) {
    final index = _allBroadcasts.indexWhere((bc) => bc['id'] == notifId);
    if (index != -1) {
      return _allBroadcasts[index]['isRead'] as bool? ?? false;
    }
    return false;
  }

  void initCustomerStreams(String customerId) {
    _customerId = customerId;
    _notifiedBroadcastIds.clear();
    _readBroadcastIds.clear();
    _streamStartTime = DateTime.now().subtract(const Duration(seconds: 5));

    // 1. Subscribe to General Orders
    _ordersSubscription?.cancel();
    _ordersSubscription = _db.streamCustomerOrders(customerId).listen((orders) {
      _customerOrders = orders;
      _checkAndTriggerNotifications();
      notifyListeners();
    });

    // 2. Subscribe to Fast Food Orders
    _fastFoodOrdersSubscription?.cancel();
    _fastFoodOrdersSubscription = _db.streamCustomerFastFoodOrders(customerId).listen((orders) {
      _customerFastFoodOrders = orders;
      _checkAndTriggerNotifications();
      notifyListeners();
    });

    // 3. Subscribe to Personal Requests
    _requestsSubscription?.cancel();
    _requestsSubscription = _db.streamCustomerRequests(customerId).listen((reqs) {
      _customerRequests = reqs;
      _checkAndTriggerNotifications();
      notifyListeners();
    });

    // 4. Subscribe to global notifications collection (per-user filtered)
    _notificationsSubscription?.cancel();
    _notificationsSubscription = _db.streamNotificationsForUser(customerId).listen((notifications) {
      _rawNotifications = notifications;
      _updateCombinedBroadcasts();
    });
  }

  void _updateCombinedBroadcasts() {
    List<Map<String, dynamic>> combined = [];
    final Set<String> seenIds = {};

    for (var note in _rawNotifications) {
      final id = note['notificationId'] ?? note['id'] ?? '';
      if (id.isNotEmpty) {
        if (seenIds.contains(id)) continue;
        seenIds.add(id);
      }
      combined.add({
        'id': id,
        'title': note['title'] ?? '',
        'content': note['message'] ?? '',
        'targetType': 'individual',
        'createdAt': note['createdAt'] ?? DateTime.now(),
        'isRead': note['isRead'] ?? false,
      });
    }

    combined.sort((a, b) {
      DateTime ta = _parseDateTime(a['createdAt']);
      DateTime tb = _parseDateTime(b['createdAt']);
      return tb.compareTo(ta);
    });

    _allBroadcasts = combined;
    _checkAndTriggerNotifications();
    notifyListeners();
  }

  void clearCustomerStreams() {
    _customerId = null;
    _allBroadcasts = [];
    _customerOrders = [];
    _customerFastFoodOrders = [];
    _customerRequests = [];
    _rawNotifications = [];
    _ordersSubscription?.cancel();
    _fastFoodOrdersSubscription?.cancel();
    _requestsSubscription?.cancel();
    _notificationsSubscription?.cancel();
    notifyListeners();
  }

  bool _isOrderActive(String status) {
    final s = status.trim().toLowerCase();
    return s != 'delivered' && s != 'rejected' && s != 'cancelled';
  }

  DateTime _parseDateTime(dynamic value) {
    if (value is DateTime) return value;
    if (value is Timestamp) return value.toDate();
    if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
    return DateTime.now();
  }

  void _checkAndTriggerNotifications() {
    if (_customerId == null || _allBroadcasts.isEmpty) return;

    for (var bc in _allBroadcasts) {
      final id = bc['id'] ?? '';
      if (id.isEmpty) continue;

      // 1. Skip if already read or notified
      final isRead = bc['isRead'] as bool? ?? false;
      if (isRead) {
        _notifiedBroadcastIds.add(id);
        continue;
      }
      if (_notifiedBroadcastIds.contains(id)) continue;

      // 2. Skip if the notification was sent before the streams were started (historical alerts)
      final bcTime = _parseDateTime(bc['createdAt']);
      if (bcTime.isBefore(_streamStartTime)) {
        _notifiedBroadcastIds.add(id);
        continue;
      }

      final title = bc['title'] ?? 'Broadcast Alert';
      final content = bc['content'] ?? '';

      _notifiedBroadcastIds.add(id);

      final context = NotificationService.navigatorKey.currentContext;
      if (context != null) {
        try {
          final auth = Provider.of<AuthProvider>(context, listen: false);
          if (auth.user != null && !auth.user!.notificationsEnabled) {
            continue;
          }
        } catch (e) {
          print("CampusKart BroadcastProvider: Error checking notificationsEnabled: $e");
        }
      }
      NotificationService().showSimulatedNotification(title, content);
    }
  }

  /// Mark a single notification as read — persisted to Firestore.
  Future<void> markAsRead(String notifId) async {
    if (_customerId == null || notifId.isEmpty) return;
    
    // Optimistic local update
    final index = _allBroadcasts.indexWhere((bc) => bc['id'] == notifId);
    if (index != -1) {
      // Create a mutable copy of the map and set isRead
      final updatedMap = Map<String, dynamic>.from(_allBroadcasts[index]);
      updatedMap['isRead'] = true;
      _allBroadcasts[index] = updatedMap;
    }
    notifyListeners();
    
    // Persist to Firestore / mock
    await _db.markNotificationRead(notifId);
  }

  /// Mark all currently visible notifications as read.
  Future<void> markAllAsRead() async {
    if (_customerId == null) return;
    
    final ids = customerNotifications
        .where((bc) => !(bc['isRead'] as bool? ?? false))
        .map((bc) => bc['id'] as String? ?? '')
        .where((id) => id.isNotEmpty)
        .toList();
    if (ids.isEmpty) return;
    
    // Optimistic local update
    for (final id in ids) {
      final index = _allBroadcasts.indexWhere((bc) => bc['id'] == id);
      if (index != -1) {
        final updatedMap = Map<String, dynamic>.from(_allBroadcasts[index]);
        updatedMap['isRead'] = true;
        _allBroadcasts[index] = updatedMap;
      }
    }
    notifyListeners();
    
    // Persist each to Firestore
    for (final id in ids) {
      await _db.markNotificationRead(id);
    }
  }

  Future<void> sendBroadcastToPendingOrders({
    required String title,
    required String content,
  }) async {
    await _db.sendNotification(
      title: title,
      message: content,
      targetUserId: null,
    );
  }

  Future<void> sendIndividualMessage({
    required String customerId,
    required String title,
    required String content,
  }) async {
    await _db.sendNotification(
      title: title,
      message: content,
      targetUserId: customerId,
    );
  }

  @override
  void dispose() {
    _ordersSubscription?.cancel();
    _fastFoodOrdersSubscription?.cancel();
    _requestsSubscription?.cancel();
    _broadcastsSubscription?.cancel();
    _notificationsSubscription?.cancel();
    _readIdsSubscription?.cancel();
    super.dispose();
  }
}
