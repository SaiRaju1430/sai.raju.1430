import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'firebase_service.dart';
import '../../screens/customer/notifications_screen.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    await Firebase.initializeApp();
  } catch (e) {
    print('CampusKart: Background Firebase initialization exception: $e');
  }
  print('CampusKart: Handling background message: ${message.messageId}');
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  static final GlobalKey<ScaffoldMessengerState> messengerKey = GlobalKey<ScaffoldMessengerState>();
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  bool _initialized = false;

  Future<void> initialize(BuildContext context) async {
    if (_initialized) return;
    
    try {
      FirebaseMessaging messaging = FirebaseMessaging.instance;

      // Register background message handler
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

      // Request permission
      NotificationSettings settings = await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        print('CampusKart: FCM permissions granted.');

        // Token fetch
        String? token = await messaging.getToken();
        print('CampusKart: FCM Device Token: $token');

        // Handle foreground notifications
        FirebaseMessaging.onMessage.listen((RemoteMessage message) {
          _showLocalNotification(message.notification?.title ?? 'Notification', message.notification?.body ?? '');
        });

        // Handle notification clicks when app is in background
        FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
          _handleNotificationClick(message);
        });

        // Handle notification clicks when app is closed
        messaging.getInitialMessage().then((RemoteMessage? message) {
          if (message != null) {
            _handleNotificationClick(message);
          }
        });
      }
      _initialized = true;
    } catch (e) {
      print('CampusKart: Notification service running in local simulated mode.');
      _initialized = true;
    }
  }

  void _handleNotificationClick(RemoteMessage message) {
    print('CampusKart: Notification clicked: ${message.messageId}');
    final context = navigatorKey.currentContext;
    if (context != null) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const NotificationsScreen()),
      );
    }
  }

  Future<void> requestFCMPermissions() async {
    try {
      FirebaseMessaging messaging = FirebaseMessaging.instance;
      await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
    } catch (e) {
      print('CampusKart: Request FCM permissions failed/offline: $e');
    }
  }

  Future<void> setupUserFCMToken(String userId) async {
    try {
      FirebaseMessaging messaging = FirebaseMessaging.instance;
      String? token = await messaging.getToken();
      if (token != null) {
        print('CampusKart: FCM setup for user $userId. Token: $token');
        await FirebaseService().updateUserFCMToken(userId, token);
        
        // Listen to token refresh
        messaging.onTokenRefresh.listen((newToken) {
          FirebaseService().updateUserFCMToken(userId, newToken);
        });
        return;
      }
    } catch (e) {
      print('CampusKart: FCM setup failed / offline mode: $e');
    }
    // Mock fallback
    final mockToken = 'mock_fcm_token_$userId';
    await FirebaseService().updateUserFCMToken(userId, mockToken);
  }

  /// Trigger simulated push notifications locally inside the app.
  /// This is used both as a local fallback and to immediately show notifications.
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
