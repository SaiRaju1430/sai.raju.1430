import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/services/supabase_service.dart';
import '../core/services/notification_service.dart';
import 'auth_provider.dart';

class BroadcastProvider extends ChangeNotifier {
  final SupabaseService _db = SupabaseService();
  String? _customerId;
  List<Map<String, dynamic>> _allBroadcasts = [];
  List<Map<String, dynamic>> _rawNotifications = [];

  final Set<String> _notifiedBroadcastIds = {};
  DateTime _streamStartTime = DateTime.now();
  StreamSubscription<List<Map<String, dynamic>>>? _notificationsSubscription;

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
    _streamStartTime = DateTime.now().subtract(const Duration(seconds: 5));

    // Subscribe to global notifications collection (per-user filtered)
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
    _rawNotifications = [];
    _notificationsSubscription?.cancel();
    notifyListeners();
  }

  DateTime _parseDateTime(dynamic value) {
    if (value is DateTime) return value;
    if (value.runtimeType.toString() == 'Timestamp') return (value as dynamic).toDate();
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
          debugPrint("CampusKart BroadcastProvider: Error checking notificationsEnabled: $e");
        }
      }
      NotificationService().showSimulatedNotification(title, content);
    }
  }

  /// Mark a single notification as read — persisted to Supabase.
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
    
    // Persist to Supabase
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
    
    // Persist each to Supabase
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
    _notificationsSubscription?.cancel();
    super.dispose();
  }
}
