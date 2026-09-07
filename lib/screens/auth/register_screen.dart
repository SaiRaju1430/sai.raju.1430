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
import '../customer/order_type_screen.dart';
import '../admin/admin_dashboard.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({Key? key}) : super(key: key);

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _mobileController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _mobileController.dispose();
    super.dispose();
  }

  Future<void> _handleGoogleAuth() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    
    // Call registration-specific Google Auth method
    bool authSuccess = await auth.authenticateGoogleForRegistration();

    if (mounted) {
      if (auth.isExistingAccountLoaded && auth.isAuthenticated) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Existing account found! Logging in...'),
            backgroundColor: Colors.green,
          ),
        );
        if (auth.isAdmin) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const AdminDashboard()),
            (route) => false,
          );
        } else {
          Provider.of<OrderProvider>(context, listen: false)
              .initCustomerStreams(auth.user!.uid);
          Provider.of<FastFoodProvider>(context, listen: false)
              .initCustomerOrdersStream(auth.user!.uid);
          Provider.of<BroadcastProvider>(context, listen: false)
              .initCustomerStreams(auth.user!.uid);
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const OrderTypeScreen()),
            (route) => false,
          );
        }
      } else if (authSuccess) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Google authentication successful! Press Registration to finish.'),
            backgroundColor: Colors.green,
          ),
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

  Future<void> _handleRegister() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);

    // 1. Validate Form Fields
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // 2. Validate Google Auth completed
    if (auth.tempGoogleUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please sign in with your Google account first.'),
          backgroundColor: Colors.amber.shade800,
        ),
      );
      return;
    }

    // 3. Complete Registration
    bool success = await auth.completeRegistration(
      _nameController.text.trim(),
      _mobileController.text.trim(),
    );

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Registration successful!'),
          backgroundColor: Colors.green,
        ),
      );
      if (auth.isAdmin) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const AdminDashboard()),
          (route) => false,
        );
      } else {
        Provider.of<OrderProvider>(context, listen: false)
            .initCustomerStreams(auth.user!.uid);
        Provider.of<FastFoodProvider>(context, listen: false)
            .initCustomerOrdersStream(auth.user!.uid);
        Provider.of<BroadcastProvider>(context, listen: false)
            .initCustomerStreams(auth.user!.uid);
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const OrderTypeScreen()),
          (route) => false,
        );
      }
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(auth.errorMessage ?? 'Registration failed.'),
          backgroundColor: Colors.red.shade600,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final bool isGoogleAuthed = auth.tempGoogleUser != null;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () {
            // Clear temporary registration Google sessions on back
            auth.clearTempGoogleUser();
            Navigator.pop(context);
          },
        ),
        title: const Text('Register'),
      ),
      body: SafeArea(
        child: ResponsiveContainer.form(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Create Account',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Get snacks, dairy, groceries & stationery delivered straight to your room.',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppTheme.textSecondary,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Name input
                  CustomTextField(
                    label: 'Full Name',
                    hint: 'Enter your full name',
                    controller: _nameController,
                    prefixIcon: Icons.person_outline_rounded,
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return 'Full name is required.';
                      }
                      if (val.trim().length < 2) {
                        return 'Please enter a valid full name.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),

                  // Mobile input
                  CustomTextField(
                    label: 'Mobile Number',
                    hint: 'Enter 10-digit Indian mobile number',
                    controller: _mobileController,
                    keyboardType: TextInputType.phone,
                    prefixIcon: Icons.phone_android_rounded,
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return 'Mobile number is required.';
                      }
                      if (!AuthProvider.isValidIndianMobile(val.trim())) {
                        return 'Enter a valid 10-digit Indian mobile (e.g. 9876543210).';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 28),

                  // Google Authentication Section
                  if (!isGoogleAuthed) ...[
                    // Not authenticated yet
                    CustomButton(
                      text: 'SIGN IN WITH GOOGLE',
                      isLoading: auth.isLoading && auth.tempGoogleUser == null,
                      icon: Icons.g_mobiledata_rounded,
                      color: Colors.white,
                      textColor: Colors.black87,
                      onPressed: _handleGoogleAuth,
                    ),
                  ] else ...[
                    // Google verified successfully
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.green.shade200, width: 1.5),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.check_circle_rounded, color: Colors.green.shade700, size: 24),
                              const SizedBox(width: 8),
                              Text(
                                'Google Account Verified',
                                style: TextStyle(
                                  color: Colors.green.shade900,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            auth.tempGoogleUser!.email ?? '',
                            style: TextStyle(
                              color: Colors.green.shade800,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 12),
                          GestureDetector(
                            onTap: () {
                              auth.clearTempGoogleUser();
                            },
                            child: const Text(
                              'Change Google Account',
                              style: TextStyle(
                                color: AppTheme.primaryColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 40),

                  // Final Registration Button: ONLY enabled when Google Authentication succeeds
                  CustomButton(
                    text: 'REGISTRATION',
                    isLoading: auth.isLoading && isGoogleAuthed,
                    onPressed: isGoogleAuthed ? _handleRegister : null,
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
