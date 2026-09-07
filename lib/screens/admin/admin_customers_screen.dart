import 'dart:math';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../models/user_model.dart';
import '../../models/order_model.dart';
import '../../models/fast_food_order_model.dart';
import '../../models/personal_request_model.dart';
import '../../providers/admin_provider.dart';
import '../../providers/fast_food_provider.dart';
import '../../core/services/whatsapp_service.dart';
import 'send_broadcast_screen.dart';

class AdminCustomersScreen extends StatefulWidget {
  const AdminCustomersScreen({super.key});

  @override
  State<AdminCustomersScreen> createState() => _AdminCustomersScreenState();
}

class _AdminCustomersScreenState extends State<AdminCustomersScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showWhatsAppMessageDialog(BuildContext context, UserModel customer) {
    final messageController = TextEditingController(
      text: 'Hello ${customer.name}, this is CampusKart. How can we help you?',
    );

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (context, setDialogState) {
          final isPhoneValid = WhatsAppService.isValidIndianPhoneNumber(customer.mobile);
          final formattedMobile = WhatsAppService.formatDisplayMobile(customer.mobile);

          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            contentPadding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            actionsPadding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF25D366).withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.chat_rounded,
                    color: Color(0xFF25D366),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'WhatsApp ${customer.name}',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        formattedMobile,
                        style: TextStyle(
                          fontSize: 13,
                          color: isPhoneValid ? Colors.grey.shade700 : Colors.red.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!isPhoneValid)
                    Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.red.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.warning_amber_rounded, color: Colors.red.shade700, size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Warning: Customer mobile ($formattedMobile) is not a valid 10-digit Indian number.',
                              style: TextStyle(fontSize: 12, color: Colors.red.shade900),
                            ),
                          ),
                        ],
                      ),
                    ),
                  const Text(
                    'Message to pre-fill in WhatsApp:',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: messageController,
                    maxLines: 4,
                    minLines: 3,
                    decoration: InputDecoration(
                      hintText: 'Enter message to pre-fill...',
                      filled: true,
                      fillColor: Colors.grey.shade50,
                      contentPadding: const EdgeInsets.all(12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFF25D366), width: 1.5),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Quick Templates:',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      ActionChip(
                        label: const Text('Greeting', style: TextStyle(fontSize: 11)),
                        backgroundColor: Colors.grey.shade100,
                        onPressed: () {
                          setDialogState(() {
                            messageController.text = 'Hello ${customer.name}, this is CampusKart. How can we help you?';
                          });
                        },
                      ),
                      ActionChip(
                        label: const Text('Order Status', style: TextStyle(fontSize: 11)),
                        backgroundColor: Colors.grey.shade100,
                        onPressed: () {
                          setDialogState(() {
                            messageController.text = 'Hello ${customer.name}, we are checking on your CampusKart order. Please let us know if you need any assistance!';
                          });
                        },
                      ),
                      ActionChip(
                        label: const Text('Payment Update', style: TextStyle(fontSize: 11)),
                        backgroundColor: Colors.grey.shade100,
                        onPressed: () {
                          setDialogState(() {
                            messageController.text = 'Hello ${customer.name}, regarding your CampusKart transaction, please share your UPI payment reference ID.';
                          });
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogCtx),
                child: const Text('CANCEL', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF25D366),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                ),
                onPressed: () async {
                  final message = messageController.text.trim();
                  if (message.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please enter a message to send.')),
                    );
                    return;
                  }
                  Navigator.pop(dialogCtx);

                  final result = await WhatsAppService.openWhatsAppChat(
                    mobile: customer.mobile,
                    message: message,
                  );

                  if (context.mounted) {
                    WhatsAppService.showResultFeedback(
                      context,
                      result,
                      rawMobile: customer.mobile,
                    );
                  }
                },
                icon: const Icon(Icons.chat_rounded, size: 18),
                label: const Text('OPEN WHATSAPP', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showCustomerDetailsSheet(
    BuildContext context,
    UserModel customer,
    List<OrderModel> customerOrders,
    List<FastFoodOrderModel> customerFastFoodOrders,
    List<PersonalRequestModel> customerRequests,
  ) {
    double totalSpent = 0;
    for (var o in customerOrders) {
      if (o.status == 'Delivered') totalSpent += o.total;
    }
    for (var fo in customerFastFoodOrders) {
      if (fo.status == 'Delivered') totalSpent += fo.totalAmount;
    }
    for (var pr in customerRequests) {
      if (pr.status == 'Delivered') totalSpent += pr.totalAmount;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.75,
        minChildSize: 0.4,
        maxChildSize: 0.95,
        builder: (_, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.all(20),
          child: ListView(
            controller: scrollController,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.12),
                    child: Text(
                      customer.name.isNotEmpty ? customer.name[0].toUpperCase() : 'C',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          customer.name,
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          customer.mobile,
                          style: TextStyle(fontSize: 14, color: Colors.grey.shade700, fontWeight: FontWeight.w500),
                        ),
                        if (customer.email != null && customer.email!.isNotEmpty)
                          Text(
                            customer.email!,
                            style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Spend & Orders Summary
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatCol('Total Spent', '₹${totalSpent.toStringAsFixed(0)}', AppTheme.primaryColor),
                    _buildStatCol('General Orders', '${customerOrders.length}', Colors.blue.shade700),
                    _buildStatCol('Fast Food', '${customerFastFoodOrders.length}', Colors.deepOrange.shade700),
                    _buildStatCol('Requests', '${customerRequests.length}', Colors.green.shade700),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF25D366),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: () {
                        _showWhatsAppMessageDialog(context, customer);
                      },
                      icon: const Icon(Icons.chat_rounded, size: 18),
                      label: const Text('WhatsApp'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: () {
                        Navigator.pop(ctx);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => SendBroadcastScreen(
                              targetCustomerId: customer.uid,
                              targetCustomerName: customer.name,
                              targetCustomerMobile: customer.mobile,
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.send_rounded, size: 18),
                      label: const Text('Send Message'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Recent Order History
              const Text(
                'Recent Orders & Activity',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
              ),
              const SizedBox(height: 10),

              if (customerOrders.isEmpty && customerFastFoodOrders.isEmpty && customerRequests.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(
                    child: Text('No orders placed yet by this customer.', style: TextStyle(color: Colors.grey)),
                  ),
                )
              else ...[
                // List General Orders
                ...customerOrders.map((o) => _buildOrderTile(
                  title: 'General Order #${o.id.replaceAll('ord_', '').substring(0, min(6, o.id.replaceAll('ord_', '').length)).toUpperCase()}',
                  status: o.status,
                  amount: o.total,
                  date: o.orderDate,
                  icon: Icons.shopping_basket_rounded,
                  color: Colors.blue,
                  otp: o.verificationCode,
                  deleteAfter: o.deleteAfter,
                )),
                // List Fast Food Orders
                ...customerFastFoodOrders.map((fo) => _buildOrderTile(
                  title: 'Fast Food Order #${fo.orderId.replaceAll('fford_', '').substring(0, min(6, fo.orderId.replaceAll('fford_', '').length)).toUpperCase()}',
                  status: fo.status,
                  amount: fo.totalAmount,
                  date: fo.createdAt,
                  icon: Icons.fastfood_rounded,
                  color: Colors.orange,
                  otp: fo.deliveryCode,
                  deleteAfter: fo.deleteAfter,
                )),
                // List Personal Requests
                ...customerRequests.map((pr) => _buildOrderTile(
                  title: 'Custom Request: ${pr.description}',
                  status: pr.status,
                  amount: pr.totalAmount,
                  date: pr.requestDate,
                  icon: Icons.assignment_rounded,
                  color: Colors.green,
                  otp: pr.verificationCode,
                  deleteAfter: pr.deleteAfter,
                )),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCol(String label, String val, Color col) {
    return Column(
      children: [
        Text(val, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: col)),
        const SizedBox(height: 2),
        Text(label, style: TextStyle(fontSize: 11, color: Colors.grey.shade700)),
      ],
    );
  }

  Widget _buildOrderTile({
    required String title,
    required String status,
    required double amount,
    required DateTime date,
    required IconData icon,
    required MaterialColor color,
    String? otp,
    DateTime? deleteAfter,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 22, color: color),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      DateFormat('dd MMM, hh:mm a').format(date),
                      style: const TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('₹${amount.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 2),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: color.shade50,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      status,
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color.shade800),
                    ),
                  ),
                ],
              ),
            ],
          ),
          if (otp != null && otp.isNotEmpty) ...[
            const SizedBox(height: 6),
            const Divider(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'OTP: $otp',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: AppTheme.primaryColor, letterSpacing: 1.0),
                ),
                if (deleteAfter != null)
                  Text(
                    'Retained until: ${DateFormat('dd MMM, hh:mm a').format(deleteAfter)}',
                    style: TextStyle(fontSize: 10, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final admin = Provider.of<AdminProvider>(context);
    final fastFood = Provider.of<FastFoodProvider>(context);

    final customers = admin.allCustomers.where((c) {
      if (_searchQuery.isEmpty) return true;
      final q = _searchQuery.toLowerCase();
      final name = c.name.toLowerCase();
      final mobile = c.mobile.toLowerCase();
      final email = (c.email ?? '').toLowerCase();
      return name.contains(q) || mobile.contains(q) || email.contains(q);
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text('Registered Customers (${admin.allCustomers.length})'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Search Input
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: TextField(
                controller: _searchController,
                onChanged: (val) {
                  setState(() {
                    _searchQuery = val.trim();
                  });
                },
                decoration: InputDecoration(
                  hintText: 'Search by name, mobile, or email...',
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),

            Expanded(
              child: customers.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.people_outline_rounded, size: 64, color: Colors.grey.shade300),
                          const SizedBox(height: 12),
                          Text(
                            _searchQuery.isEmpty ? 'No registered customers found.' : 'No customers match "$_searchQuery"',
                            style: const TextStyle(color: Colors.grey, fontSize: 15),
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: customers.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final customer = customers[index];
                        final custOrders = admin.allOrders.where((o) => o.customerId == customer.uid).toList();
                        final custFfOrders = fastFood.allOrders.where((fo) => fo.customerId == customer.uid).toList();
                        final custRequests = admin.allRequests.where((r) => r.customerId == customer.uid).toList();

                        final totalOrders = custOrders.length + custFfOrders.length + custRequests.length;

                        return Card(
                          elevation: 1.5,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: () {
                              _showCustomerDetailsSheet(context, customer, custOrders, custFfOrders, custRequests);
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  CircleAvatar(
                                    radius: 24,
                                    backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.1),
                                    child: Text(
                                      customer.name.isNotEmpty ? customer.name[0].toUpperCase() : 'C',
                                      style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.primaryColor,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Expanded(
                                              child: Text(
                                                customer.name,
                                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                              ),
                                            ),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                              decoration: BoxDecoration(
                                                color: Colors.orange.shade50,
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: Text(
                                                '$totalOrders Orders',
                                                style: TextStyle(
                                                  color: Colors.orange.shade900,
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            const Icon(Icons.phone_android_rounded, size: 14, color: Colors.grey),
                                            const SizedBox(width: 4),
                                            Text(
                                              customer.mobile,
                                              style: TextStyle(color: Colors.grey.shade800, fontSize: 13, fontWeight: FontWeight.w500),
                                            ),
                                          ],
                                        ),
                                        if (customer.email != null && customer.email!.isNotEmpty) ...[
                                          const SizedBox(height: 2),
                                          Row(
                                            children: [
                                              const Icon(Icons.email_outlined, size: 14, color: Colors.grey),
                                              const SizedBox(width: 4),
                                              Expanded(
                                                child: Text(
                                                  customer.email!,
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                  style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                        if (customer.createdAt != null) ...[
                                          const SizedBox(height: 4),
                                          Text(
                                            'Joined: ${DateFormat('dd MMM yyyy').format(customer.createdAt!)}',
                                            style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                  const Icon(Icons.chevron_right_rounded, color: Colors.grey),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
