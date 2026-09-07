import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../models/order_model.dart';
import '../../providers/admin_provider.dart';
import '../../widgets/custom_button.dart';
import 'verify_delivery_screen.dart';
import 'send_broadcast_screen.dart';

class OrderDetailsScreen extends StatelessWidget {
  final OrderModel order;

  const OrderDetailsScreen({Key? key, required this.order}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final adminProvider = Provider.of<AdminProvider>(context);

    // Refresh state using newest data from admin provider list
    OrderModel activeOrder = order;
    try {
      activeOrder = adminProvider.allOrders.firstWhere((o) => o.id == order.id);
    } catch (_) {}

    return Scaffold(
      appBar: AppBar(
        title: const Text('Order Details'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Order Overview & OTP Card
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'ORDER #${activeOrder.id.replaceAll('ord_', '').toUpperCase()}',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: activeOrder.status == 'Delivered'
                                ? Colors.green.shade50
                                : (activeOrder.status == 'Rejected' ? Colors.red.shade50 : Colors.orange.shade50),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: activeOrder.status == 'Delivered'
                                  ? Colors.green.shade200
                                  : (activeOrder.status == 'Rejected' ? Colors.red.shade200 : Colors.orange.shade200),
                            ),
                          ),
                          child: Text(
                            activeOrder.status,
                            style: TextStyle(
                              color: activeOrder.status == 'Delivered'
                                  ? Colors.green.shade800
                                  : (activeOrder.status == 'Rejected' ? Colors.red.shade800 : Colors.orange.shade900),
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Divider(),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Delivery OTP (Code):', style: TextStyle(fontSize: 13, color: Colors.grey, fontWeight: FontWeight.w600)),
                        Text(
                          activeOrder.verificationCode.isNotEmpty ? activeOrder.verificationCode : 'N/A',
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AppTheme.primaryColor, letterSpacing: 2),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Created At:', style: TextStyle(fontSize: 12, color: Colors.grey)),
                        Text(
                          DateFormat('dd MMM yyyy, hh:mm a').format(activeOrder.orderDate),
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                    if (activeOrder.deliveredAt != null) ...[
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Delivered At:', style: TextStyle(fontSize: 12, color: Colors.green)),
                          Text(
                            DateFormat('dd MMM yyyy, hh:mm a').format(activeOrder.deliveredAt!),
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.green),
                          ),
                        ],
                      ),
                    ],
                    if (activeOrder.rejectedAt != null) ...[
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Rejected At:', style: TextStyle(fontSize: 12, color: Colors.red)),
                          Text(
                            DateFormat('dd MMM yyyy, hh:mm a').format(activeOrder.rejectedAt!),
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.red),
                          ),
                        ],
                      ),
                    ],
                    if (activeOrder.deleteAfter != null) ...[
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.auto_delete_outlined, size: 14, color: Colors.grey),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                '3-Day Retention: auto-deleted on ${DateFormat('dd MMM yyyy, hh:mm a').format(activeOrder.deleteAfter!)}',
                                style: TextStyle(fontSize: 11, color: Colors.grey.shade700, fontWeight: FontWeight.w500),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Customer Contact Panel
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('CUSTOMER INFO', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.6), letterSpacing: 0.5)),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Icon(Icons.person_outline_rounded, color: AppTheme.primaryColor),
                        const SizedBox(width: 12),
                        Text(activeOrder.customerName, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Theme.of(context).textTheme.bodyLarge?.color)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.phone_android_rounded, color: AppTheme.primaryColor),
                        const SizedBox(width: 12),
                        Text(activeOrder.customerMobile, style: TextStyle(fontSize: 14, color: Theme.of(context).textTheme.bodyLarge?.color)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.room_rounded, color: AppTheme.primaryColor),
                        const SizedBox(width: 12),
                        Text('${activeOrder.blockName}, Room ${activeOrder.roomNumber}', style: TextStyle(fontSize: 14, color: Theme.of(context).textTheme.bodyLarge?.color)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    OutlinedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => SendBroadcastScreen(
                              targetCustomerId: activeOrder.customerId,
                              targetCustomerName: activeOrder.customerName,
                              targetCustomerMobile: activeOrder.customerMobile,
                            ),
                          ),
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.primaryColor,
                        side: const BorderSide(color: AppTheme.primaryColor),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        minimumSize: const Size(double.infinity, 40),
                      ),
                      icon: const Icon(Icons.message_outlined, size: 18),
                      label: const Text(
                        'Send Message To This Customer',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Order Items Panel
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('ORDER ITEMS', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.6), letterSpacing: 0.5)),
                    const SizedBox(height: 12),
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: activeOrder.items.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, idx) {
                        final item = activeOrder.items[idx];
                        return Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${item.quantity}x  ${item.productName}', 
                              style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).textTheme.bodyLarge?.color),
                            ),
                            Text(
                              '₹${(item.price * item.quantity).toStringAsFixed(0)}',
                              style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
                            ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                    const Divider(),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Subtotal', style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.6))),
                        Text('₹${activeOrder.subtotal.toStringAsFixed(0)}', style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Delivery Charges (Income)', style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.6))),
                        Text('₹${activeOrder.deliveryFee.toStringAsFixed(0)}', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Grand Total', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Theme.of(context).textTheme.bodyLarge?.color)),
                        Text('₹${activeOrder.total.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: AppTheme.primaryColor)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Payment Details Card (UPI Account Name & UPI Ref Transaction ID)
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'PAYMENT DETAILS',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.6),
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'UPI Account Name:',
                          style: TextStyle(fontSize: 13, color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.8)),
                        ),
                        Text(
                          activeOrder.paymentAccountName.isEmpty ? 'N/A' : activeOrder.paymentAccountName,
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Theme.of(context).textTheme.bodyLarge?.color),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Payment Mobile Number:',
                          style: TextStyle(fontSize: 13, color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.8)),
                        ),
                        Text(
                          activeOrder.paymentMobileNumber.isEmpty ? 'N/A' : activeOrder.paymentMobileNumber,
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Theme.of(context).textTheme.bodyLarge?.color),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 36),

            // Actions Block based on Status
            _buildActionButtons(context, activeOrder, adminProvider),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, OrderModel order, AdminProvider provider) {
    switch (order.status) {
      case 'Pending':
        return Row(
          children: [
            Expanded(
              child: CustomButton(
                text: 'REJECT',
                color: Colors.red.shade600,
                onPressed: () async {
                  bool success = await provider.rejectOrder(order.id);
                  if (success && context.mounted) Navigator.pop(context);
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: CustomButton(
                text: 'ACCEPT',
                color: Colors.green.shade600,
                onPressed: () async {
                  bool success = await provider.acceptOrder(order.id);
                  if (success && context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Order accepted successfully!')));
                  }
                },
              ),
            ),
          ],
        );
      case 'Accepted':
        return CustomButton(
          text: 'SHIP ORDER (OUT FOR DELIVERY)',
          color: AppTheme.primaryColor,
          onPressed: () async {
            bool success = await provider.shipOrder(order.id);
            if (success && context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Order is out for delivery!')));
            }
          },
        );
      case 'Out For Delivery':
        return CustomButton(
          text: 'VERIFY DOORSTEP DELIVERY CODE',
          color: Colors.green.shade600,
          onPressed: () {
            // Trigger door code check popup overlay
            showDialog(
              context: context,
              barrierDismissible: true,
              builder: (_) => VerifyDeliveryScreen(orderId: order.id),
            );
          },
        );
      case 'Delivered':
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.green.shade200)),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.check_circle_rounded, color: Colors.green.shade700),
              const SizedBox(width: 8),
              Text('Order Delivered Successfully!', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green.shade800)),
            ],
          ),
        );
      case 'Rejected':
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.red.shade200)),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.cancel_rounded, color: Colors.red.shade700),
              const SizedBox(width: 8),
              Text('Order Rejected', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red.shade800)),
            ],
          ),
        );
      default:
        return const SizedBox();
    }
  }
}
