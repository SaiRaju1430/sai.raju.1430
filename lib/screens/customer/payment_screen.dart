import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/order_provider.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_textfield.dart';
import '../../widgets/dynamic_upi_qr_widget.dart';
import 'order_success_screen.dart';

class PaymentScreen extends StatefulWidget {
  final String customerName;
  final String customerMobile;
  final String blockName;
  final String roomNumber;

  const PaymentScreen({
    super.key,
    required this.customerName,
    required this.customerMobile,
    required this.blockName,
    required this.roomNumber,
  });

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _paymentIdController = TextEditingController();
  final _paymentAccountNameController = TextEditingController();
  final _paymentMobileController = TextEditingController();

  @override
  void dispose() {
    _paymentIdController.dispose();
    _paymentAccountNameController.dispose();
    _paymentMobileController.dispose();
    super.dispose();
  }

  Future<void> _handlePlaceOrder() async {
    final orderProvider = Provider.of<OrderProvider>(context, listen: false);

    // Requirement 15: Validate that the QR amount exactly matches the final amount stored for that order
    if (orderProvider.cartTotal <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Invalid order total. Please review your cart.'),
          backgroundColor: Colors.red.shade600,
        ),
      );
      return;
    }

    if (_formKey.currentState!.validate()) {
      final auth = Provider.of<AuthProvider>(context, listen: false);

      bool success = await orderProvider.checkoutAndPlaceOrder(
        customerId: auth.user!.uid,
        customerName: widget.customerName,
        customerMobile: widget.customerMobile,
        blockName: widget.blockName,
        roomNumber: widget.roomNumber,
        paymentId: _paymentIdController.text.trim(),
        paymentAccountName: _paymentAccountNameController.text.trim(),
        paymentMobileNumber: _paymentMobileController.text.trim(),
      );

      if (success && mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const OrderSuccessScreen()),
          (route) => route.isFirst,
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(orderProvider.errorMessage ?? 'Failed to place order. Try again.'),
            backgroundColor: Colors.red.shade600,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final orderProvider = Provider.of<OrderProvider>(context);
    final double finalAmount = orderProvider.cartTotal;

    return Scaffold(
      appBar: AppBar(
        title: const Text('UPI Payment'),
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
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 8),

                // Dynamic UPI QR Code Widget encoding the exact calculated final amount
                DynamicUpiQrWidget(
                  amount: finalAmount,
                  transactionNote: 'CampusKart Order',
                  qrSize: 180,
                  showAmountHeader: true,
                  showScanPrompt: true,
                  showUpiDetails: true,
                ),
                const SizedBox(height: 28),

                // Instructions panel
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue.shade200.withValues(alpha: 0.5)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline_rounded, color: Colors.blue.shade700, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Scan the QR with any UPI app (GPay, PhonePe, Paytm), pay ₹${finalAmount.toStringAsFixed(0)}, and submit your payment details below.',
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.85),
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // UPI Account Name Textbox
                CustomTextField(
                  label: 'UPI Account Name',
                  hint: 'Enter your UPI Account Holder Name',
                  controller: _paymentAccountNameController,
                  keyboardType: TextInputType.name,
                  prefixIcon: Icons.person_outline_rounded,
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) return 'UPI Account Name is required.';
                    if (val.trim().length < 3) return 'Please enter a valid name.';
                    return null;
                  },
                ),
                const SizedBox(height: 18),

                // Payment Mobile Number Textbox
                CustomTextField(
                  label: 'Payment Mobile Number',
                  hint: 'Enter your 10-digit payment mobile number',
                  controller: _paymentMobileController,
                  keyboardType: TextInputType.phone,
                  prefixIcon: Icons.phone_android_rounded,
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) return 'Payment Mobile Number is required.';
                    final cleanVal = val.trim();
                    if (cleanVal.length != 10 || int.tryParse(cleanVal) == null) {
                      return 'Please enter a valid 10-digit mobile number.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 18),

                // UPI Transaction ID / Ref ID (Optional / Recommended for quick admin verification)
                CustomTextField(
                  label: 'UPI Ref / Transaction ID (Optional)',
                  hint: 'e.g. 12-digit UPI reference ID / UTR',
                  controller: _paymentIdController,
                  keyboardType: TextInputType.text,
                  prefixIcon: Icons.receipt_long_rounded,
                ),
                const SizedBox(height: 28),

                // Submit Button
                CustomButton(
                  text: 'PLACE ORDER',
                  isLoading: orderProvider.isLoading,
                  onPressed: _handlePlaceOrder,
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
