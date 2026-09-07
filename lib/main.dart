import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'providers/auth_provider.dart';
import 'providers/product_provider.dart';
import 'providers/order_provider.dart';
import 'providers/admin_provider.dart';
import 'providers/fast_food_provider.dart';
import 'providers/broadcast_provider.dart';
import 'core/services/notification_service.dart';
import 'screens/auth/splash_screen.dart';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Supabase.initialize(
      url: SupabaseOptions.url,
      anonKey: SupabaseOptions.anonKey,
    );
  } catch (e) {
    debugPrint("Supabase initialization error: $e");
  }
  runApp(const CampusKartApp());
}


class CampusKartApp extends StatelessWidget {
  const CampusKartApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ProductProvider()),
        ChangeNotifierProvider(create: (_) => OrderProvider()),
        ChangeNotifierProvider(create: (_) => AdminProvider()),
        ChangeNotifierProvider(create: (_) => FastFoodProvider()),
        ChangeNotifierProvider(create: (_) => BroadcastProvider()),
      ],
      child: MaterialApp(
        title: 'CampusKart',
        scaffoldMessengerKey: NotificationService.messengerKey,
        navigatorKey: NotificationService.navigatorKey,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        themeMode: ThemeMode.light,
        home: const SplashScreen(),
      ),
    );
  }
}
