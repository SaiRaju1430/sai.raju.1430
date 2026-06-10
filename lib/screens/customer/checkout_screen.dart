import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_textfield.dart';
import 'payment_screen.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({Key? key}) : super(key: key);

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _formKey = GlobalKey<FormState>();
  
  late TextEditingController _nameController;
  late TextEditingController _mobileController;
  final _blockController = TextEditingController();
  final _roomController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Prefill name & mobile from logged-in user
    final auth = Provider.of<AuthProvider>(context, listen: false);
    _nameController = TextEditingController(text: auth.user?.name);
    _mobileController = TextEditingController(text: auth.user?.mobile);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _mobileController.dispose();
    _blockController.dispose();
    _roomController.dispose();
    super.dispose();
  }

  void _proceedToPayment() {
    if (_formKey.currentState!.validate()) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PaymentScreen(
            customerName: _nameController.text.trim(),
            customerMobile: _mobileController.text.trim(),
            blockName: _blockController.text.trim(),
            roomNumber: _roomController.text.trim(),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Delivery Details'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Where to deliver?',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Please fill in your hostel details for delivery.',
                  style: TextStyle(fontSize: 14, color: AppTheme.textSecondary),
                ),
                const SizedBox(height: 32),

                // Customer Name
                CustomTextField(
                  label: 'Customer Name',
                  hint: 'Enter your name',
                  controller: _nameController,
                  prefixIcon: Icons.person_outline_rounded,
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) return 'Name is required.';
                    return null;
                  },
                ),
                const SizedBox(height: 18),

                // Mobile
                CustomTextField(
                  label: 'Mobile Number',
                  hint: 'Enter 10-digit number',
                  controller: _mobileController,
                  keyboardType: TextInputType.phone,
                  prefixIcon: Icons.phone_android_outlined,
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) return 'Mobile is required.';
                    if (val.trim().length < 10) return 'Enter a valid mobile number.';
                    return null;
                  },
                ),
                const SizedBox(height: 18),

                // Block Name
                CustomTextField(
                  label: 'Hostel Block Name / Number',
                  hint: 'e.g. Block A, Ramanujan Hall',
                  controller: _blockController,
                  prefixIcon: Icons.domain_rounded,
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) return 'Block name is required.';
                    return null;
                  },
                ),
                const SizedBox(height: 18),

                // Room Number
                CustomTextField(
                  label: 'Room Number',
                  hint: 'e.g. 102, F-45',
                  controller: _roomController,
                  prefixIcon: Icons.meeting_room_rounded,
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) return 'Room number is required.';
                    return null;
                  },
                ),
                const SizedBox(height: 48),

                CustomButton(
                  text: 'CONTINUE TO PAYMENT',
                  onPressed: _proceedToPayment,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
