import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/order_provider.dart';
import '../../widgets/custom_button.dart';

class OrderSuccessScreen extends StatelessWidget {
  final bool isPersonal;
  const OrderSuccessScreen({Key? key, this.isPersonal = false}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final orderProvider = Provider.of<OrderProvider>(context);
    final orders = orderProvider.customerOrders;
    
    // Grab the latest order verification details
    String deliveryCode = '4821'; // Standard default fallback
    if (orders.isNotEmpty) {
      deliveryCode = orders.first.verificationCode;
    }

    return Scaffold(
      body: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Celebratory visual icon
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.check_circle_rounded,
                size: 80,
                color: Colors.green.shade600,
              ),
            ),
            const SizedBox(height: 32),

            Text(
              isPersonal ? 'Request Submitted!' : 'Order Confirmed!',
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w900,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 12),

            Text(
              isPersonal
                  ? 'Your custom request has been sent to the owner. Once reviewed, you will be notified to make payment.'
                  : 'Your order has been sent to the owner. Please share the following verification code at the time of delivery.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: AppTheme.textSecondary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 36),

            // Verification Code Display Panel / Status Panel
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200, width: 1.5),
              ),
              child: Column(
                children: [
                  Text(
                    isPersonal ? 'REQUEST STATUS' : 'DELIVERY CODE',
                    style: const TextStyle(
                      fontSize: 12,
                      letterSpacing: 1.5,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isPersonal ? 'Pending Review' : deliveryCode,
                    style: TextStyle(
                      fontSize: isPersonal ? 24 : 40,
                      fontWeight: FontWeight.w900,
                      color: isPersonal ? Colors.amber.shade700 : AppTheme.primaryColor,
                      letterSpacing: isPersonal ? 0.0 : 4.0,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 48),

            const Text(
              'Thank you for choosing CampusKart',
              style: TextStyle(
                fontSize: 14,
                fontStyle: FontStyle.italic,
                fontWeight: FontWeight.bold,
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 48),

            CustomButton(
              text: 'BACK TO PORTAL',
              onPressed: () {
                // Clear state redirects cleanly
                Navigator.popUntil(context, (route) => route.isFirst);
              },
            ),
          ],
        ),
      ),
    );
  }
}
