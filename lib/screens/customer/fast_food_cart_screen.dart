import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/fast_food_provider.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_textfield.dart';
import 'payment_screen.dart'; // To reuse QRPainter

class FastFoodCartScreen extends StatefulWidget {
  const FastFoodCartScreen({Key? key}) : super(key: key);

  @override
  State<FastFoodCartScreen> createState() => _FastFoodCartScreenState();
}

class _FastFoodCartScreenState extends State<FastFoodCartScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _mobileController;
  late TextEditingController _blockController;
  late TextEditingController _roomController;

  @override
  void initState() {
    super.initState();
    final auth = Provider.of<AuthProvider>(context, listen: false);
    _nameController = TextEditingController(text: auth.user?.name);
    _mobileController = TextEditingController(text: auth.user?.mobile);
    _blockController = TextEditingController();
    _roomController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _mobileController.dispose();
    _blockController.dispose();
    _roomController.dispose();
    super.dispose();
  }

  Future<void> _handlePlaceOrder(FastFoodProvider provider, String customerId) async {
    final timerData = provider.timerData;
    final bool isEnabled = timerData['fastFoodEnabled'] ?? false;
    final String remainingTime = provider.remainingTimeString;

    if (!isEnabled || remainingTime == '00:00') {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.error_outline_rounded, color: Colors.red),
              SizedBox(width: 8),
              Text('Ordering Closed'),
            ],
          ),
          content: const Text(
            'The kitchen has closed and ordering is no longer available. Your cart will be cleared.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                provider.clearCart();
                Navigator.pop(ctx);
                Navigator.popUntil(context, (route) => route.isFirst);
              },
              child: const Text('OK', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );
      return;
    }

    if (_formKey.currentState!.validate()) {
      bool success = await provider.checkoutAndPlaceOrder(
        customerId: customerId,
        customerName: _nameController.text.trim(),
        mobile: _mobileController.text.trim(),
        blockName: _blockController.text.trim(),
        roomNumber: _roomController.text.trim(),
      );

      if (success && mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (dialogCtx) => _OrderSuccessDialog(
            customerName: _nameController.text.trim(),
            blockName: _blockController.text.trim(),
            roomNumber: _roomController.text.trim(),
          ),
        ).then((_) {
          if (mounted) Navigator.popUntil(context, (route) => route.isFirst);
        });
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(provider.errorMessage ?? 'Failed to place fast food order.'),
            backgroundColor: Colors.red.shade600,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<FastFoodProvider>(context);
    final auth = Provider.of<AuthProvider>(context);
    final cartItems = provider.cart.entries.toList();
    final isOnline = provider.paymentMethod == 'Online';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Fast Food Cart'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: cartItems.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.shopping_cart_outlined, size: 64, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  const Text(
                    'Your cart is empty',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textSecondary),
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Items List
                    const Text(
                      'Items Ordered',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                    ),
                    const SizedBox(height: 12),
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: cartItems.length,
                      itemBuilder: (context, idx) {
                        final entry = cartItems[idx];
                        final itemId = entry.key;
                        final item = entry.value;

                        return Card(
                          margin: const EdgeInsets.only(bottom: 10),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item.name,
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '₹${item.price.toStringAsFixed(0)} each',
                                        style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                                      ),
                                    ],
                                  ),
                                ),
                                Row(
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.remove_circle_outline, color: AppTheme.primaryColor),
                                      onPressed: () => provider.removeFromCart(itemId),
                                    ),
                                    Text(
                                      '${item.quantity}',
                                      style: const TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.add_circle_outline, color: AppTheme.primaryColor),
                                      onPressed: () {
                                        final fullItem = provider.items.firstWhere((i) => i.id == itemId);
                                        provider.addToCart(fullItem);
                                      },
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 20),

                    // Pricing Details
                    const Text(
                      'Payment Details',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                    ),
                    const SizedBox(height: 12),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Food Total'),
                                Text('₹${provider.cartSubtotal.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Delivery Charge'),
                                Text('₹${provider.deliveryFee.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                              ],
                            ),
                            if (provider.paymentMethod == 'COD') ...[
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('COD Charge'),
                                  Text('₹${provider.codCharge.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ],
                            const Divider(height: 24),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Grand Total', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryColor)),
                                Text('₹${provider.cartTotal.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppTheme.primaryColor)),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Select Payment Method
                    const Text(
                      'Select Payment Method',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                    ),
                    const SizedBox(height: 12),
                    Card(
                      elevation: 1,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: Column(
                        children: [
                          RadioListTile<String>(
                            title: const Text('Online Payment', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                            subtitle: const Text('Scan QR and pay via UPI', style: TextStyle(fontSize: 11)),
                            value: 'Online',
                            groupValue: provider.paymentMethod,
                            activeColor: AppTheme.primaryColor,
                            onChanged: (val) {
                              if (val != null) provider.paymentMethod = val;
                            },
                          ),
                          const Divider(height: 1),
                          RadioListTile<String>(
                            title: const Text('Cash On Delivery (COD)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                            subtitle: const Text('Pay with cash or UPI at delivery', style: TextStyle(fontSize: 11)),
                            value: 'COD',
                            groupValue: provider.paymentMethod,
                            activeColor: AppTheme.primaryColor,
                            onChanged: (val) {
                              if (val != null) provider.paymentMethod = val;
                            },
                          ),
                        ],
                      ),
                    ),
                    if (provider.paymentMethod == 'COD') ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade50,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.orange.shade200),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.info_outline_rounded, color: Colors.orange.shade800, size: 20),
                            const SizedBox(width: 8),
                            const Expanded(
                              child: Text(
                                'Cash On Delivery orders include an additional ₹10 COD handling fee.',
                                style: TextStyle(fontSize: 12, color: AppTheme.textPrimary, fontWeight: FontWeight.w500),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),

                    // QR Code UPI Scan (Online only)
                    if (isOnline) ...[
                      Center(
                        child: Column(
                          children: [
                            const Text(
                              'Scan QR to Pay via UPI',
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              width: 160,
                              height: 160,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.grey.shade300),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.06),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              padding: const EdgeInsets.all(8),
                              child: CustomPaint(
                                painter: QRPainter(),
                                child: Center(
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: const Icon(Icons.qr_code_scanner_rounded, color: AppTheme.primaryColor, size: 24),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'UPI ID: campuskart@upi',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Amount: ₹${provider.cartTotal.toStringAsFixed(0)}',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color: AppTheme.primaryColor,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade50,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: Colors.blue.shade200),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.touch_app_rounded, color: Colors.blue.shade700, size: 20),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'After completing payment, tap "I Have Paid" below. No transaction ID required.',
                                      style: TextStyle(fontSize: 12, color: Colors.blue.shade800, fontWeight: FontWeight.w500),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],

                    // Delivery Information Form
                    const Text(
                      'Delivery Information',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                    ),
                    const SizedBox(height: 12),
                    CustomTextField(
                      label: 'Customer Name',
                      hint: 'Enter your name',
                      controller: _nameController,
                      prefixIcon: Icons.person_outline_rounded,
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) return 'Customer Name is required.';
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    CustomTextField(
                      label: 'Mobile Number',
                      hint: 'Enter your 10-digit mobile number',
                      controller: _mobileController,
                      keyboardType: TextInputType.phone,
                      prefixIcon: Icons.phone_android_outlined,
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) return 'Mobile Number is required.';
                        if (val.trim().length < 10) return 'Enter a valid 10-digit number.';
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    CustomTextField(
                      label: 'Hostel Block',
                      hint: 'e.g. Block A, Block B',
                      controller: _blockController,
                      prefixIcon: Icons.apartment_rounded,
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) return 'Hostel block is required.';
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    CustomTextField(
                      label: 'Room Number',
                      hint: 'e.g. 204, G-12',
                      controller: _roomController,
                      prefixIcon: Icons.door_front_door_outlined,
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) return 'Room number is required.';
                        return null;
                      },
                    ),
                    const SizedBox(height: 32),

                    CustomButton(
                      text: isOnline ? 'I HAVE PAID' : 'PLACE ORDER',
                      isLoading: provider.isLoading,
                      onPressed: () => _handlePlaceOrder(provider, auth.user!.uid),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
    );
  }
}

/// Success dialog for COD orders — shows delivery code immediately
/// Success dialog for all orders — shows delivery code immediately
class _OrderSuccessDialog extends StatelessWidget {
  final String customerName;
  final String blockName;
  final String roomNumber;

  const _OrderSuccessDialog({
    required this.customerName,
    required this.blockName,
    required this.roomNumber,
  });

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<FastFoodProvider>(context, listen: false);
    // The most recently placed order should be the first in customerOrders
    final latestOrder = provider.customerOrders.isNotEmpty ? provider.customerOrders.first : null;
    final deliveryCode = provider.lastDeliveryCode.isNotEmpty
        ? provider.lastDeliveryCode
        : (latestOrder?.deliveryCode ?? '----');

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Row(
        children: [
          Icon(Icons.check_circle, color: Colors.green),
          SizedBox(width: 8),
          Text('Order Confirmed'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Your Delivery Verification Code:',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 12),
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.primaryColor.withOpacity(0.2)),
              ),
              child: Text(
                deliveryCode,
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 4.0,
                  color: AppTheme.primaryColor,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Delivering to: $blockName, Room $roomNumber',
            style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 8),
          const Text(
            'Please provide this code to the CampusKart delivery person when receiving your order.',
            style: TextStyle(fontSize: 13, height: 1.4),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('OK', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}
