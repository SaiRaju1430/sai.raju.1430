import 'dart:math';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../models/fast_food_order_model.dart';
import '../../providers/fast_food_provider.dart';
import '../../core/services/firebase_service.dart';
import 'admin_dashboard.dart'; // To reuse VerifyFastFoodDeliveryCodeDialog

class AdminFastFoodOrdersPage extends StatelessWidget {
  const AdminFastFoodOrdersPage({Key? key}) : super(key: key);

  Widget _buildStatusControl(BuildContext context, FastFoodOrderModel order, FastFoodProvider provider) {
    Color bgColor;
    Color borderColor;
    Color textColor;
    String label = order.status;

    switch (order.status) {
      case 'Delivered':
        bgColor = Colors.green.shade50;
        borderColor = Colors.green.shade200;
        textColor = Colors.green.shade800;
        label = 'Delivered';
        break;
      case 'Pending':
        bgColor = Colors.orange.shade50;
        borderColor = Colors.orange.shade200;
        textColor = Colors.orange.shade800;
        label = 'Pending';
        break;
      case 'Payment Verification Pending':
        bgColor = Colors.amber.shade50;
        borderColor = Colors.amber.shade200;
        textColor = Colors.amber.shade800;
        label = 'Verify Payment';
        break;
      case 'Confirmed':
        bgColor = Colors.blue.shade50;
        borderColor = Colors.blue.shade200;
        textColor = Colors.blue.shade800;
        label = 'Confirmed';
        break;
      case 'Rejected':
        bgColor = Colors.red.shade50;
        borderColor = Colors.red.shade200;
        textColor = Colors.red.shade800;
        label = 'Rejected';
        break;
      case 'Out For Delivery':
        bgColor = Colors.deepOrange.shade50;
        borderColor = Colors.deepOrange.shade200;
        textColor = Colors.deepOrange.shade800;
        label = 'Out For Delivery';
        break;
      default:
        bgColor = Colors.grey.shade50;
        borderColor = Colors.grey.shade200;
        textColor = Colors.grey.shade800;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor),
      ),
      child: Text(
        label,
        style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 12),
      ),
    );
  }

  Widget _buildStatTile(String label, String value, Color color) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.06),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.15)),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: color),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFastFoodOrderCard(BuildContext context, FastFoodOrderModel order, FastFoodProvider provider) {
    final cleanId = order.orderId.replaceAll('fford_', '').toUpperCase();
    final shortId = cleanId.substring(0, min(6, cleanId.length));

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
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
                  'Order #$shortId',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                _buildStatusControl(context, order, provider),
              ],
            ),
            const SizedBox(height: 8),

            // Customer Details
            Row(
              children: [
                const Icon(Icons.person_outline_rounded, size: 14, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  '${order.customerName} (${order.mobile})',
                  style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w500),
                ),
              ],
            ),
            if (order.blockName.isNotEmpty || order.roomNumber.isNotEmpty) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.location_on_outlined, size: 14, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    '${order.blockName}, Room ${order.roomNumber}',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 4),

            // Order Time
            Row(
              children: [
                const Icon(Icons.access_time_rounded, size: 14, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  DateFormat('dd MMM yyyy, hh:mm a').format(order.createdAt),
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ],
            ),
            
            const Divider(height: 20),

            // Items Ordered list
            ...order.items.map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${item.quantity}x ${item.name}',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                      ),
                      Text(
                        '₹${(item.price * item.quantity).toStringAsFixed(0)}',
                        style: const TextStyle(fontSize: 13, color: Colors.grey),
                      ),
                    ],
                  ),
                )),

            const SizedBox(height: 8),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Payment Method', style: TextStyle(fontSize: 12, color: Colors.grey)),
                Text(order.paymentMethod, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              ],
            ),

            const SizedBox(height: 4),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Food Total', style: TextStyle(fontSize: 12, color: Colors.grey)),
                Text('₹${order.foodTotal.toStringAsFixed(0)}', style: const TextStyle(fontSize: 12)),
              ],
            ),

            const SizedBox(height: 4),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Delivery Charge', style: TextStyle(fontSize: 12, color: Colors.grey)),
                Text('₹${order.deliveryCharge.toStringAsFixed(0)}', style: const TextStyle(fontSize: 12)),
              ],
            ),

            if (order.paymentMethod == 'COD') ...[
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('COD Charge', style: TextStyle(fontSize: 12, color: Colors.grey)),
                  Text('₹${order.codCharge.toStringAsFixed(0)}', style: const TextStyle(fontSize: 12)),
                ],
              ),
            ],

            const Divider(height: 12),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Grand Total',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                Text(
                  '₹${order.grandTotal.toStringAsFixed(0)}',
                  style: const TextStyle(fontWeight: FontWeight.w900, color: AppTheme.primaryColor, fontSize: 15),
                ),
              ],
            ),

            // --- PENDING STATUS ACTIONS: ACCEPT OR REJECT ---
            if (order.status == 'Pending') ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                      icon: const Icon(Icons.close_rounded, size: 18),
                      label: const Text('REJECT', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                      onPressed: () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            title: const Text('Reject Order?'),
                            content: const Text('This will cancel the order and notify the customer.'),
                            actions: [
                              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                              TextButton(
                                onPressed: () => Navigator.pop(ctx, true),
                                child: const Text('Reject', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                              ),
                            ],
                          ),
                        );
                        if (confirm == true && context.mounted) {
                          await provider.rejectFastFoodPayment(order.orderId);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Order rejected successfully.')));
                          }
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                      icon: const Icon(Icons.check_rounded, size: 18),
                      label: const Text('ACCEPT', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                      onPressed: () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            title: const Text('Accept Order?'),
                            content: const Text('This will accept the order and notify the customer.'),
                            actions: [
                              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                              TextButton(
                                onPressed: () => Navigator.pop(ctx, true),
                                child: const Text('Accept', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                              ),
                            ],
                          ),
                        );
                        if (confirm == true && context.mounted) {
                          await provider.confirmFastFoodPayment(order.orderId);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Order accepted successfully.')));
                          }
                        }
                      },
                    ),
                  ),
                ],
              ),
            ],

            // --- CONFIRMED STATUS ACTIONS: REJECT OR MARK OUT FOR DELIVERY ---
            if (order.status == 'Confirmed') ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                      icon: const Icon(Icons.close_rounded, size: 18),
                      label: const Text('REJECT ORDER', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                      onPressed: () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            title: const Text('Reject Order?'),
                            content: const Text('This will cancel the order and notify the customer.'),
                            actions: [
                              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                              TextButton(
                                onPressed: () => Navigator.pop(ctx, true),
                                child: const Text('Reject', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                              ),
                            ],
                          ),
                        );
                        if (confirm == true && context.mounted) {
                          await provider.rejectFastFoodPayment(order.orderId);
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange.shade800,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                      icon: const Icon(Icons.delivery_dining_rounded, size: 18),
                      label: const Text('OUT FOR DELIVERY', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                      onPressed: () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            title: const Text('Mark Out For Delivery?'),
                            content: const Text('This will set the order status to "Out For Delivery" and notify the customer.'),
                            actions: [
                              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                              TextButton(
                                onPressed: () => Navigator.pop(ctx, true),
                                child: const Text('Confirm', style: TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.bold)),
                              ),
                            ],
                          ),
                        );
                        if (confirm == true && context.mounted) {
                          await provider.shipFastFoodOrder(order.orderId);
                        }
                      },
                    ),
                  ),
                ],
              ),
            ],

            // --- OUT FOR DELIVERY / FOOD READY STATUS ACTIONS: VERIFY DELIVERY CODE ---
            if (order.status == 'Out For Delivery' || order.status == 'Food Ready') ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  icon: const Icon(Icons.verified_user_rounded),
                  label: const Text(
                    'Verify Code',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  onPressed: () async {
                    var currentOrder = order;
                    if (order.deliveryCode.isEmpty) {
                      currentOrder = await provider.checkAndGenerateFallbackOtp(order);
                    }
                    if (context.mounted) {
                      showDialog(
                        context: context,
                        barrierDismissible: false,
                        builder: (_) => VerifyFastFoodDeliveryCodeDialog(
                          order: currentOrder,
                          provider: provider,
                        ),
                      );
                    }
                  },
                ),
              ),
            ],
            // --- DELIVERED ORDER TIMESTAMP ---
            if (order.status == 'Delivered' && order.deliveredAt != null) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.check_circle_outline_rounded, size: 14, color: Colors.green),
                  const SizedBox(width: 4),
                  Text(
                    'Delivered at: ${DateFormat('dd MMM yyyy, hh:mm a').format(order.deliveredAt!)}',
                    style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<FastFoodProvider>(context);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Fast Food Orders'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded),
            onPressed: () => Navigator.pop(context),
          ),
          bottom: const TabBar(
            indicatorColor: Colors.white,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            tabs: [
              Tab(text: 'Pending Orders'),
              Tab(text: 'Delivery History'),
            ],
          ),
        ),
        body: StreamBuilder<List<FastFoodOrderModel>>(
          stream: FirebaseService().streamAllFastFoodOrders(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final orders = snapshot.data ?? [];
            final pendingList = orders.where((o) => o.status != 'Delivered' && o.status != 'Rejected').toList();
            final deliveredList = orders.where((o) => o.status == 'Delivered').toList();

            final totalCount = orders.length;
            final pendingCount = pendingList.length;
            final outForDeliveryCount = orders.where((o) => o.status == 'Out For Delivery').length;
            final deliveredCount = deliveredList.length;

            return Column(
              children: [
                // Stats counters header
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildStatTile("Total Orders", "$totalCount", AppTheme.primaryColor),
                      _buildStatTile("Pending", "$pendingCount", Colors.amber.shade800),
                      _buildStatTile("Out Delivery", "$outForDeliveryCount", Colors.orange.shade800),
                      _buildStatTile("Delivered", "$deliveredCount", Colors.green.shade700),
                    ],
                  ),
                ),

                const Divider(height: 1),

                // TabBarView for list of orders
                Expanded(
                  child: TabBarView(
                    children: [
                      // Tab 1: Pending Orders
                      pendingList.isEmpty
                          ? const Center(child: Text('No pending Fast Food orders.'))
                          : ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: pendingList.length,
                              itemBuilder: (context, index) {
                                return _buildFastFoodOrderCard(context, pendingList[index], provider);
                              },
                            ),
                      // Tab 2: Delivery History
                      deliveredList.isEmpty
                          ? const Center(child: Text('No delivered Fast Food orders.'))
                          : ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: deliveredList.length,
                              itemBuilder: (context, index) {
                                return _buildFastFoodOrderCard(context, deliveredList[index], provider);
                              },
                            ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
