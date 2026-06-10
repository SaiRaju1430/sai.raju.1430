import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/order_provider.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_textfield.dart';
import 'order_success_screen.dart';

class PaymentScreen extends StatefulWidget {
  final String customerName;
  final String customerMobile;
  final String blockName;
  final String roomNumber;

  const PaymentScreen({
    Key? key,
    required this.customerName,
    required this.customerMobile,
    required this.blockName,
    required this.roomNumber,
  }) : super(key: key);

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _paymentAccountNameController = TextEditingController();
  final _paymentMobileController = TextEditingController(); // NEW

  @override
  void dispose() {
    _paymentAccountNameController.dispose();
    _paymentMobileController.dispose(); // NEW
    super.dispose();
  }

  Future<void> _handlePlaceOrder() async {
    if (_formKey.currentState!.validate()) {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final orderProvider = Provider.of<OrderProvider>(context, listen: false);

      bool success = await orderProvider.checkoutAndPlaceOrder(
        customerId: auth.user!.uid,
        customerName: widget.customerName,
        customerMobile: widget.customerMobile,
        blockName: widget.blockName,
        roomNumber: widget.roomNumber,
        paymentId: '',
        paymentAccountName: _paymentAccountNameController.text.trim(),
        paymentMobileNumber: _paymentMobileController.text.trim(), // NEW
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
                Text(
                  'Scan QR Code to Pay',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Pay exactly the Grand Total and input the details below.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.6)),
                ),
                const SizedBox(height: 28),

                // Grand Total Box
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppTheme.primaryColor.withOpacity(0.2)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Amount to Pay: ',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Theme.of(context).textTheme.bodyLarge?.color),
                      ),
                      Text(
                        '₹${orderProvider.cartTotal.toStringAsFixed(0)}',
                        style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 22, color: AppTheme.primaryColor),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),

                // Mock Premium QR Visual Panel
                Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade300, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      )
                    ],
                  ),
                  padding: const EdgeInsets.all(12),
                  child: CustomPaint(
                    painter: QRPainter(),
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.shopping_cart_rounded, color: AppTheme.primaryColor, size: 28),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'UPI ID: campuskart@upi',
                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey.shade700, fontSize: 13),
                ),
                const SizedBox(height: 30),

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
                const SizedBox(height: 20),

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
                const SizedBox(height: 20),

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

/// Custom Painter to draw a simulated high-fidelity QR Code
class QRPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black
      ..strokeWidth = 2
      ..style = PaintingStyle.fill;

    // Draw Corner Finders
    // Top-Left
    canvas.drawRect(Rect.fromLTWH(0, 0, 40, 40), paint);
    canvas.drawRect(Rect.fromLTWH(5, 5, 30, 30), Paint()..color = Colors.white);
    canvas.drawRect(Rect.fromLTWH(10, 10, 20, 20), paint);

    // Top-Right
    canvas.drawRect(Rect.fromLTWH(size.width - 40, 0, 40, 40), paint);
    canvas.drawRect(Rect.fromLTWH(size.width - 35, 5, 30, 30), Paint()..color = Colors.white);
    canvas.drawRect(Rect.fromLTWH(size.width - 30, 10, 20, 20), paint);

    // Bottom-Left
    canvas.drawRect(Rect.fromLTWH(0, size.height - 40, 40, 40), paint);
    canvas.drawRect(Rect.fromLTWH(5, size.height - 35, 30, 30), Paint()..color = Colors.white);
    canvas.drawRect(Rect.fromLTWH(10, size.height - 30, 20, 20), paint);

    // Draw random simulated data pixels
    final pixelPaint = Paint()..color = Colors.grey.shade900;
    
    // Simple mock grid pattern
    for (double x = 10; x < size.width - 10; x += 15) {
      for (double y = 10; y < size.height - 10; y += 15) {
        // Exclude corners
        bool isCorner = (x < 50 && y < 50) || 
                       (x > size.width - 50 && y < 50) || 
                       (x < 50 && y > size.height - 50);
        if (!isCorner && (x * y).toInt() % 3 == 0) {
          canvas.drawRect(Rect.fromLTWH(x, y, 6, 6), pixelPaint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
