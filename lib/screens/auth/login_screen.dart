import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/order_provider.dart';
import '../../providers/fast_food_provider.dart';
import '../../providers/broadcast_provider.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_textfield.dart';
import '../../widgets/responsive_container.dart';
import 'register_screen.dart';
import '../customer/order_type_screen.dart';
import '../admin/admin_dashboard.dart';
import 'complete_registration_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _mobileController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _mobileController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (_formKey.currentState!.validate()) {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      
      bool success = await auth.login(
        _mobileController.text.trim(),
        _passwordController.text,
      );

      if (success && mounted) {
        if (auth.isAdmin) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const AdminDashboard()),
          );
        } else {
          // Initialize active streams for this customer
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
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(auth.errorMessage ?? 'Login failed. Please check credentials.'),
            backgroundColor: Colors.red.shade600,
          ),
        );
      }
    }
  }

  Future<void> _handleGoogleLogin() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    bool success = await auth.signInWithGoogle();

    if (mounted) {
      if (success) {
        if (auth.isAdmin) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const AdminDashboard()),
          );
        } else {
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
      } else if (auth.tempGoogleUser != null) {
        // Redirect to complete registration
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const CompleteRegistrationScreen()),
        );
      } else if (auth.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(auth.errorMessage!),
            backgroundColor: Colors.red.shade600,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);

    return Scaffold(
      body: SafeArea(
        child: ResponsiveContainer.form(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 24),
                // Heading Block
                const Text(
                  'Welcome Back!',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Sign in to order products to your hostel room.',
                  style: TextStyle(
                    fontSize: 15,
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 48),

                // Form Block
                CustomTextField(
                  label: 'Mobile Number',
                  hint: 'Enter your 10-digit mobile',
                  controller: _mobileController,
                  keyboardType: TextInputType.phone,
                  prefixIcon: Icons.phone_android_rounded,
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) return 'Mobile number is required.';
                    if (val.trim().length < 10) return 'Enter a valid 10-digit mobile number.';
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                CustomTextField(
                  label: 'Password',
                  hint: 'Enter your password',
                  controller: _passwordController,
                  isPassword: true,
                  prefixIcon: Icons.lock_outline_rounded,
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) return 'Password is required.';
                    if (val.length < 6) return 'Password must be at least 6 characters.';
                    return null;
                  },
                ),
                const SizedBox(height: 36),

                 // Login Trigger Button
                 CustomButton(
                   text: 'LOGIN',
                   isLoading: auth.isLoading,
                   onPressed: _handleLogin,
                 ),
                 const SizedBox(height: 24),

                 // OR Divider
                  const Row(
                    children: [
                      Expanded(child: Divider(color: Color(0xFFE0E0E0))),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        child: Text('OR', style: TextStyle(color: AppTheme.textSecondary, fontSize: 13, fontWeight: FontWeight.bold)),
                      ),
                      Expanded(child: Divider(color: Color(0xFFE0E0E0))),
                    ],
                  ),
                 const SizedBox(height: 24),

                 // Google Sign-In Button
                 CustomButton(
                   text: 'CONTINUE WITH GOOGLE',
                   isLoading: auth.isLoading,
                   onPressed: _handleGoogleLogin,
                 ),
                 const SizedBox(height: 24),

                // Switch To Register Link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      "Don't have an account? ",
                      style: TextStyle(color: AppTheme.textSecondary),
                    ),
                    GestureButton(
                      text: 'Register Now',
                      onTap: () {
                        auth.clearError();
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const RegisterScreen()),
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        ),
      ),
    );
  }
}

class GestureButton extends StatelessWidget {
  final String text;
  final VoidCallback onTap;

  const GestureButton({Key? key, required this.text, required this.onTap}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Text(
        text,
        style: const TextStyle(
          color: AppTheme.primaryColor,
          fontWeight: FontWeight.bold,
          decoration: TextDecoration.underline,
        ),
      ),
    );
  }
}
