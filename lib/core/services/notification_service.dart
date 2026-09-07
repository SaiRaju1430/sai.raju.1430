import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import '../../supabase_options.dart';
import 'supabase_service.dart';
import '../../screens/customer/notifications_screen.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  static final GlobalKey<ScaffoldMessengerState> messengerKey = GlobalKey<ScaffoldMessengerState>();
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  bool _initialized = false;
  String? _currentUserId;

  String _getDeviceType() {
    if (kIsWeb) return 'web';
    try {
      if (defaultTargetPlatform == TargetPlatform.android) return 'android';
      if (defaultTargetPlatform == TargetPlatform.iOS) return 'ios';
      if (defaultTargetPlatform == TargetPlatform.macOS) return 'macos';
      if (defaultTargetPlatform == TargetPlatform.windows) return 'windows';
      if (defaultTargetPlatform == TargetPlatform.linux) return 'linux';
      return 'other';
    } catch (_) {
      return 'web';
    }
  }

  Future<void> initialize(BuildContext context) async {
    if (_initialized) return;

    if (kIsWeb) {
      // Web notification support via in-app alert banners and Supabase notification streams
      _initialized = true;
      return;
    }

    try {
      if (SupabaseOptions.oneSignalAppId != 'YOUR_ONESIGNAL_APP_ID' && SupabaseOptions.oneSignalAppId.isNotEmpty) {
        // Initialize OneSignal
        OneSignal.Debug.setLogLevel(OSLogLevel.verbose);
        OneSignal.initialize(SupabaseOptions.oneSignalAppId);
        
        // Request permissions
        OneSignal.Notifications.requestPermission(true);

        // Handle dynamic push subscription updates
        OneSignal.User.pushSubscription.addObserver((state) {
          final newSubId = state.current.id;
          if (newSubId != null && newSubId.isNotEmpty && _currentUserId != null) {
            SupabaseService().registerPushSubscription(
              uid: _currentUserId!,
              subscriptionId: newSubId,
              deviceType: _getDeviceType(),
            );
          }
        });

        // Handle foreground notifications
        OneSignal.Notifications.addForegroundWillDisplayListener((event) {
          final title = event.notification.title ?? 'Notification';
          final body = event.notification.body ?? '';
          _showLocalNotification(title, body);
        });

        // Handle notification clicks
        OneSignal.Notifications.addClickListener((event) {
          _handleNotificationClick();
        });
      } else {
        print('CampusKart: OneSignal running in simulated mode (no App ID).');
      }
      _initialized = true;
    } catch (e) {
      print('CampusKart: Notification service running in local simulated mode: $e');
      _initialized = true;
    }
  }

  void _handleNotificationClick() {
    final context = navigatorKey.currentContext;
    if (context != null) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const NotificationsScreen()),
      );
    }
  }

  Future<void> requestFCMPermissions() async {
    if (kIsWeb) return;
    try {
      OneSignal.Notifications.requestPermission(true);
    } catch (e) {
      print('CampusKart: Request OneSignal permissions failed: $e');
    }
  }

  Future<void> setupUserFCMToken(String userId) async {
    _currentUserId = userId;
    final deviceType = _getDeviceType();

    if (!kIsWeb) {
      try {
        // Set external ID for targeting in OneSignal
        OneSignal.login(userId);

        final String? subscriptionId = OneSignal.User.pushSubscription.id;
        if (subscriptionId != null && subscriptionId.isNotEmpty) {
          print('CampusKart: OneSignal setup for user $userId. ID: $subscriptionId ($deviceType)');
          await SupabaseService().registerPushSubscription(
            uid: userId,
            subscriptionId: subscriptionId,
            deviceType: deviceType,
          );
          
          // Tag admin users specifically in OneSignal
          final bool isAdmin = userId == "admin123" || userId == "admin456";
          OneSignal.User.addTagWithKey("role", isAdmin ? "admin" : "customer");
          return;
        }
      } catch (e) {
        print('CampusKart: OneSignal setup failed / offline mode: $e');
      }
    }

    // Web & Mock fallback for notification stream tracking
    final mockToken = '${deviceType}_token_$userId';
    await SupabaseService().registerPushSubscription(
      uid: userId,
      subscriptionId: mockToken,
      deviceType: deviceType,
    );
  }

  /// Trigger simulated push notifications locally inside the app.
  void showSimulatedNotification(String title, String body) {
    _showLocalNotification(title, body);
  }

  void _showLocalNotification(String title, String body) {
    messengerKey.currentState?.showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        backgroundColor: const Color(0xFF212121),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        content: Row(
          children: [
            const Icon(Icons.notifications_active, color: Color(0xFFFF6D00)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  Text(
                    body,
                    style: const TextStyle(fontSize: 12, color: Color(0xFFE0E0E0)),
                  ),
                ],
              ),
            ),
          ],
        ),
        duration: const Duration(seconds: 4),
      ),
    );
  }
}
