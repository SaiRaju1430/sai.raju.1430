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

class CompleteRegistrationScreen extends StatefulWidget {
  const CompleteRegistrationScreen({Key? key}) : super(key: key);

  @override
  State<CompleteRegistrationScreen> createState() => _CompleteRegistrationScreenState();
}

class _CompleteRegistrationScreenState extends State<CompleteRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _mobileController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Pre-fill name from Google Metadata if available
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      if (auth.tempGoogleUser != null) {
        final googleName = auth.tempGoogleUser!.userMetadata?['name'] ?? 
                           auth.tempGoogleUser!.userMetadata?['full_name'] ?? '';
        _nameController.text = googleName.toString();
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _mobileController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (_formKey.currentState!.validate()) {
      final auth = Provider.of<AuthProvider>(context, listen: false);

      bool success = await auth.completeRegistration(
        _nameController.text.trim(),
        _mobileController.text.trim(),
      );

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Registration complete!'),
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
            content: Text(auth.errorMessage ?? 'Failed to complete registration.'),
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
      appBar: AppBar(
        title: const Text('Complete Profile'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: AppTheme.textPrimary,
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
                    'Almost Done!',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Please confirm your name and provide your mobile number to start ordering products to your hostel room.',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 36),

                  // Name Input
                  CustomTextField(
                    label: 'Full Name',
                    hint: 'Enter your name',
                    controller: _nameController,
                    prefixIcon: Icons.person_outline_rounded,
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) return 'Full name is required.';
                      return null;
                    },
                  ),
                  const SizedBox(height: 18),

                  // Mobile Input
                  CustomTextField(
                    label: 'Mobile Number',
                    hint: 'Enter 10-digit Indian mobile number',
                    controller: _mobileController,
                    keyboardType: TextInputType.phone,
                    prefixIcon: Icons.phone_android_rounded,
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) return 'Mobile number is required.';
                      if (!AuthProvider.isValidIndianMobile(val.trim())) {
                        return 'Enter a valid 10-digit Indian mobile (e.g. 9876543210).';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 36),

                  // Register Button
                  CustomButton(
                    text: 'COMPLETE REGISTRATION',
                    isLoading: auth.isLoading,
                    onPressed: _handleRegister,
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
