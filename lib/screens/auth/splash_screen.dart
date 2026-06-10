import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/services/firebase_service.dart';
import '../../core/services/notification_service.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/order_provider.dart';
import '../../providers/fast_food_provider.dart';
import '../../providers/broadcast_provider.dart';
import 'login_screen.dart';
import '../customer/order_type_screen.dart';
import '../admin/admin_dashboard.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeIn,
    );

    _controller.forward();
    _bootstrapApp();
  }

  Future<void> _bootstrapApp() async {
    // 1. Initialize Firebase/Mock service
    await FirebaseService().initialize();
    
    if (mounted) {
      // Initialize notification service
      await NotificationService().initialize(context);

      // 2. Fetch active session if any
      final auth = Provider.of<AuthProvider>(context, listen: false);
      await auth.checkCurrentUser();

      // 3. Brief delay for visual splash transition
      await Future.delayed(const Duration(seconds: 1));

      if (mounted) {
        if (auth.isAuthenticated) {
          if (auth.isAdmin) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const AdminDashboard()),
            );
          } else {
            // Register active customer streams
            Provider.of<OrderProvider>(context, listen: false)
                .initCustomerStreams(auth.user!.uid);
            Provider.of<FastFoodProvider>(context, listen: false)
                .initCustomerOrdersStream(auth.user!.uid);
            Provider.of<BroadcastProvider>(context, listen: false)
                .initCustomerStreams(auth.user!.uid);
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const OrderTypeScreen()),
            );
          }
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const LoginScreen()),
          );
        }
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [AppTheme.primaryColor, AppTheme.primaryDark],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Beautiful app logo placeholder
              Card(
                elevation: 10,
                shadowColor: Colors.black.withOpacity(0.2),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                child: const Padding(
                  padding: EdgeInsets.all(20),
                  child: Icon(
                    Icons.shopping_cart_checkout_rounded,
                    size: 64,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'CampusKart',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 36,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Hostel delivery, simplified.',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 48),
              const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
