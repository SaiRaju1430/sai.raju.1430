import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../models/personal_request_model.dart';
import '../../providers/admin_provider.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_textfield.dart';
import 'verify_delivery_screen.dart';


class PersonalRequestsScreen extends StatelessWidget {
  const PersonalRequestsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Personal Requests'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: const PersonalRequestsListView(),
    );
  }
}

class PersonalRequestsListView extends StatefulWidget {
  const PersonalRequestsListView({Key? key}) : super(key: key);

  @override
  State<PersonalRequestsListView> createState() => _PersonalRequestsListViewState();
}

class _PersonalRequestsListViewState extends State<PersonalRequestsListView> {
  Color _getStatusColor(String status) {
    switch (status) {
      case 'Pending Review':
        return Colors.amber.shade700;
      case 'Payment Pending':
        return Colors.purple.shade600;
      case 'Payment Verification Pending':
        return Colors.blue.shade600;
      case 'Confirmed':
        return Colors.green.shade600;
      case 'Out For Delivery':
        return Colors.orange.shade700;
      case 'Delivered':
        return Colors.green.shade800;
      case 'Rejected':
        return Colors.red.shade600;
      default:
        return Colors.grey;
    }
  }

  void _showPricingDialog(BuildContext context, AdminProvider provider, PersonalRequestModel req) {
    final productPriceController = TextEditingController();
    final deliveryChargeController = TextEditingController(text: '20'); // Default ₹20 delivery fee
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            'Approve & Set Prices',
            style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).textTheme.bodyLarge?.color),
          ),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CustomTextField(
                  label: 'Product Price (₹)',
                  hint: 'e.g. 180',
                  controller: productPriceController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  prefixIcon: Icons.currency_rupee_rounded,
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) return 'Product price is required.';
                    if (double.tryParse(val) == null) return 'Enter a valid number.';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  label: 'Delivery Charge (₹)',
                  hint: 'e.g. 20',
                  controller: deliveryChargeController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  prefixIcon: Icons.delivery_dining_rounded,
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) return 'Delivery charge is required.';
                    if (double.tryParse(val) == null) return 'Enter a valid number.';
                    return null;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('CANCEL', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  final price = double.parse(productPriceController.text.trim());
                  final delivery = double.parse(deliveryChargeController.text.trim());
                  Navigator.pop(context); // Close Dialog
                  
                  bool success = await provider.sendPaymentRequest(
                    requestId: req.id,
                    productPrice: price,
                    deliveryCharge: delivery,
                  );

                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(success 
                            ? 'Payment request sent via WhatsApp successfully!' 
                            : provider.errorMessage ?? 'Failed to send payment request.'),
                        backgroundColor: success ? Colors.green : Colors.red,
                      ),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
              ),
              child: const Text('SEND PAYMENT REQUEST', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final adminProvider = Provider.of<AdminProvider>(context);
    final reqs = adminProvider.allRequests;

    return adminProvider.isLoading
        ? const Center(child: CircularProgressIndicator())
          : reqs.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.assignment_turned_in_rounded, size: 48, color: Colors.grey.shade400),
                      const SizedBox(height: 12),
                      Text(
                        'No custom requests submitted yet.', 
                        style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.5)),
                      ),
                    ],
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: reqs.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    final req = reqs[index];
                    final statusColor = _getStatusColor(req.status);

                    return Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Header Customer Detail Row
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        req.customerName,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Theme.of(context).textTheme.bodyLarge?.color),
                                      ),
                                      Text(
                                        'Mob: ${req.customerMobile} • Block: ${req.blockName} • Rm: ${req.roomNumber}',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(fontSize: 12, color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.6)),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: statusColor.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: statusColor.withOpacity(0.3)),
                                  ),
                                  child: Text(
                                    req.status,
                                    style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 11),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            const Divider(),
                            const SizedBox(height: 12),

                            // Description and Graphic Image Block
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'REQUESTED ITEMS',
                                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.6), letterSpacing: 0.5),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        req.description,
                                        style: TextStyle(fontSize: 13, color: Theme.of(context).textTheme.bodyLarge?.color, height: 1.4),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Submitted: ${DateFormat('dd MMM yyyy, hh:mm a').format(req.requestDate)}',
                              style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
                            ),
                            // Action buttons based on status
                            if (req.status == 'Pending Review') ...[
                              const SizedBox(height: 18),
                              Row(
                                children: [
                                  Expanded(
                                    child: SizedBox(
                                      height: 44,
                                      child: OutlinedButton(
                                        style: OutlinedButton.styleFrom(
                                          padding: EdgeInsets.zero,
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                          side: const BorderSide(color: Colors.red, width: 1.5),
                                        ),
                                        onPressed: () {
                                          adminProvider.rejectPersonalRequest(req.id);
                                        },
                                        child: const Text('REJECT', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 14)),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: CustomButton(
                                      text: 'APPROVE',
                                      height: 44,
                                      fontSize: 14,
                                      color: Colors.green.shade600,
                                      onPressed: () => _showPricingDialog(context, adminProvider, req),
                                    ),
                                  ),
                                ],
                              ),
                            ] else if (req.status == 'Payment Pending') ...[
                              const SizedBox(height: 16),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.purple.shade50.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: Colors.purple.shade300.withOpacity(0.4)),
                                ),
                                child: Text(
                                  'Price request sent: ₹${req.productPrice.toStringAsFixed(0)} + ₹${req.deliveryCharge.toStringAsFixed(0)} delivery. Total = ₹${req.totalAmount.toStringAsFixed(0)}. Waiting for customer checkout.',
                                  style: const TextStyle(fontSize: 11, color: Colors.purple, fontWeight: FontWeight.w500),
                                ),
                              ),
                            ] else if (req.status == 'Payment Verification Pending') ...[
                              const SizedBox(height: 16),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.blue.shade50.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: Colors.blue.shade300.withOpacity(0.4)),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'UPI Account Name: ${req.paymentAccountName.isEmpty ? "N/A" : req.paymentAccountName}',
                                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Theme.of(context).textTheme.bodyLarge?.color),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Payment Mobile Number: ${req.paymentMobileNumber.isEmpty ? "N/A" : req.paymentMobileNumber}',
                                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Theme.of(context).textTheme.bodyLarge?.color),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Please verify this transaction in your bank account for amount ₹${req.totalAmount.toStringAsFixed(0)}.',
                                      style: const TextStyle(fontSize: 11, color: Colors.grey),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 14),
                              Row(
                                children: [
                                  Expanded(
                                    child: SizedBox(
                                      height: 44,
                                      child: OutlinedButton(
                                        style: OutlinedButton.styleFrom(
                                          padding: EdgeInsets.zero,
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                          side: const BorderSide(color: Colors.red, width: 1.5),
                                        ),
                                        onPressed: () {
                                          adminProvider.rejectPersonalRequest(req.id);
                                        },
                                        child: const FittedBox(
                                          fit: BoxFit.scaleDown,
                                          child: Padding(
                                            padding: EdgeInsets.symmetric(horizontal: 8.0),
                                            child: Text('REJECT PAYMENT', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 13)),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: CustomButton(
                                      text: 'CONFIRM PAYMENT',
                                      height: 44,
                                      fontSize: 13,
                                      color: Colors.green.shade600,
                                      onPressed: () async {
                                        bool success = await adminProvider.confirmPersonalRequestPayment(req.id);
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: Text(success 
                                                  ? 'Payment confirmed and WhatsApp receipt sent!' 
                                                  : adminProvider.errorMessage ?? 'Verification failed.'),
                                              backgroundColor: success ? Colors.green : Colors.red,
                                            ),
                                          );
                                        }
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ] else if (req.status == 'Confirmed') ...[
                              const SizedBox(height: 14),
                              CustomButton(
                                text: 'SHIP REQUEST (OUT FOR DELIVERY)',
                                height: 44,
                                fontSize: 14,
                                color: Colors.orange.shade700,
                                onPressed: () async {
                                  bool success = await adminProvider.shipPersonalRequest(req.id);
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(success 
                                            ? 'Request is out for delivery!' 
                                            : adminProvider.errorMessage ?? 'Failed to ship request.'),
                                        backgroundColor: success ? Colors.green : Colors.red,
                                      ),
                                    );
                                  }
                                },
                              ),
                            ] else if (req.status == 'Out For Delivery') ...[
                              const SizedBox(height: 16),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.green.shade50.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: Colors.green.shade300.withOpacity(0.4)),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'Doorstep Delivery Code',
                                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.green),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            'Deliver to Block ${req.blockName}, Room ${req.roomNumber}',
                                            style: const TextStyle(fontSize: 10, color: Colors.grey),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Text(
                                      req.verificationCode,
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w900,
                                        color: Colors.green,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 14),
                              CustomButton(
                                text: 'MARK AS DELIVERED',
                                height: 44,
                                fontSize: 14,
                                color: Colors.green.shade700,
                                onPressed: () {
                                  showDialog(
                                    context: context,
                                    builder: (_) => VerifyDeliveryScreen(orderId: req.id),
                                  );
                                },
                              ),
                            ] else if (req.status == 'Delivered') ...[
                              const SizedBox(height: 16),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.green.shade50.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: Colors.green.shade300.withOpacity(0.4)),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Row(
                                      children: [
                                        Icon(Icons.check_circle_outline_rounded, color: Colors.green, size: 20),
                                        SizedBox(width: 8),
                                        Text(
                                          'Request Delivered Successfully!',
                                          style: TextStyle(fontSize: 12, color: Colors.green, fontWeight: FontWeight.bold),
                                        ),
                                      ],
                                    ),
                                    if (req.verificationCode.isNotEmpty) ...[
                                      const SizedBox(height: 8),
                                      Text(
                                        'Delivery OTP: ${req.verificationCode} (Verified)',
                                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Colors.green, letterSpacing: 1.0),
                                      ),
                                    ],
                                    if (req.deliveredAt != null) ...[
                                      const SizedBox(height: 4),
                                      Text(
                                        'Delivered at: ${DateFormat('dd MMM yyyy, hh:mm a').format(req.deliveredAt!)}',
                                        style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
                                      ),
                                    ],
                                    if (req.deleteAfter != null) ...[
                                      const SizedBox(height: 4),
                                      Text(
                                        '3-Day Retention: auto-deleted on ${DateFormat('dd MMM yyyy, hh:mm a').format(req.deleteAfter!)}',
                                        style: TextStyle(fontSize: 10, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ] else if (req.status == 'Rejected') ...[
                              const SizedBox(height: 16),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.red.shade50.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: Colors.red.shade300.withOpacity(0.4)),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Row(
                                      children: [
                                        Icon(Icons.cancel_outlined, color: Colors.red, size: 20),
                                        SizedBox(width: 8),
                                        Text(
                                          'This request was rejected.',
                                          style: TextStyle(fontSize: 12, color: Colors.red, fontWeight: FontWeight.bold),
                                        ),
                                      ],
                                    ),
                                    if (req.verificationCode.isNotEmpty) ...[
                                      const SizedBox(height: 8),
                                      Text(
                                        'OTP: ${req.verificationCode}',
                                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Colors.red, letterSpacing: 1.0),
                                      ),
                                    ],
                                    if (req.rejectedAt != null) ...[
                                      const SizedBox(height: 4),
                                      Text(
                                        'Rejected at: ${DateFormat('dd MMM yyyy, hh:mm a').format(req.rejectedAt!)}',
                                        style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
                                      ),
                                    ],
                                    if (req.deleteAfter != null) ...[
                                      const SizedBox(height: 4),
                                      Text(
                                        '3-Day Retention: auto-deleted on ${DateFormat('dd MMM yyyy, hh:mm a').format(req.deleteAfter!)}',
                                        style: TextStyle(fontSize: 10, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                );
  }
}
