import 'dart:math';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../models/order_model.dart';
import '../../models/personal_request_model.dart';
import '../../models/fast_food_order_model.dart';
import '../../providers/order_provider.dart';
import '../../providers/fast_food_provider.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_textfield.dart';
import 'payment_screen.dart'; // To use QRPainter

class MyOrdersScreen extends StatelessWidget {
  const MyOrdersScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final orderProvider = Provider.of<OrderProvider>(context);
    final orders = orderProvider.customerOrders;
    final requests = orderProvider.customerRequests;

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('My History & Status'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded),
            onPressed: () => Navigator.pop(context),
          ),
          bottom: TabBar(
            indicatorColor: AppTheme.primaryColor,
            labelColor: AppTheme.primaryColor,
            unselectedLabelColor: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.6),
            tabs: const [
              Tab(text: 'General Orders'),
              Tab(text: 'Personal Requests'),
              Tab(text: 'Fast Food'),
            ],
          ),
        ),
        body: orderProvider.isLoading
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(
                children: [
                  // --- TAB 1: GENERAL ORDERS ---
                  orders.isEmpty
                      ? const EmptyListPlaceholder(message: 'No general orders placed yet.')
                      : ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: orders.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 16),
                          itemBuilder: (context, index) {
                            final order = orders[index];
                            return OrderHistoryCard(order: order);
                          },
                        ),

                  // --- TAB 2: PERSONAL REQUESTS ---
                  requests.isEmpty
                      ? const EmptyListPlaceholder(message: 'No personal requests submitted yet.')
                      : ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: requests.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 16),
                          itemBuilder: (context, index) {
                            final req = requests[index];
                            return RequestHistoryCard(request: req);
                          },
                        ),

                  // --- TAB 3: FAST FOOD ORDERS ---
                  const FastFoodOrdersList(),
                ],
              ),
      ),
    );
  }
}

class EmptyListPlaceholder extends StatelessWidget {
  final String message;

  const EmptyListPlaceholder({Key? key, required this.message}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history_toggle_off_rounded, size: 48, color: Colors.grey.shade400),
          const SizedBox(height: 12),
          Text(
            message,
            style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.5)),
          ),
        ],
      ),
    );
  }
}

class OrderHistoryCard extends StatelessWidget {
  final OrderModel order;
  const OrderHistoryCard({Key? key, required this.order}) : super(key: key);

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Pending':
        return Colors.amber.shade700;
      case 'Accepted':
        return Colors.blue.shade600;
      case 'Out For Delivery':
        return Colors.orange.shade800;
      case 'Delivered':
        return Colors.green.shade600;
      case 'Rejected':
        return Colors.red.shade600;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isFinalized = order.status == 'Delivered' || order.status == 'Rejected';
    
    // Requirement: Map active orders to "Arriving"
    final displayStatus = isFinalized ? order.status : 'Arriving';
    final statusColor = _getStatusColor(order.status);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status and ID row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Order #${order.id.replaceAll('ord_', '').substring(0, 6).toUpperCase()}',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Theme.of(context).textTheme.bodyLarge?.color),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      DateFormat('dd MMM yyyy, hh:mm a').format(order.orderDate),
                      style: TextStyle(fontSize: 11, color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.6)),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: statusColor.withOpacity(0.3)),
                  ),
                  child: Text(
                    displayStatus,
                    style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 12),

            // Items list summary
            ...order.items.map<Widget>((item) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${item.quantity}x ${item.productName}',
                        style: TextStyle(fontSize: 13, color: Theme.of(context).textTheme.bodyLarge?.color),
                      ),
                      Text(
                        '₹${(item.price * item.quantity).toStringAsFixed(0)}',
                        style: TextStyle(fontSize: 13, color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7)),
                      ),
                    ],
                  ),
                )),
            
            const SizedBox(height: 8),
            const Divider(),
            const SizedBox(height: 8),

            // Pricing totals
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Delivery Charge', style: TextStyle(fontSize: 12, color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7))),
                Text('₹${order.deliveryFee.toStringAsFixed(0)}', style: TextStyle(fontSize: 12, color: Theme.of(context).textTheme.bodyLarge?.color)),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Total Amount', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Theme.of(context).textTheme.bodyLarge?.color)),
                Text('₹${order.total.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: AppTheme.primaryColor)),
              ],
            ),
            
            // Verification Code Display Panel if active (arriving)
            if (!isFinalized) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppTheme.primaryColor.withOpacity(0.12)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Delivery Verification Code',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7)),
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            'Share at the door to receive package',
                            style: TextStyle(fontSize: 10, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      order.verificationCode,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: AppTheme.primaryColor,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class RequestHistoryCard extends StatefulWidget {
  final PersonalRequestModel request;
  const RequestHistoryCard({Key? key, required this.request}) : super(key: key);

  @override
  State<RequestHistoryCard> createState() => _RequestHistoryCardState();
}

class _RequestHistoryCardState extends State<RequestHistoryCard> {
  final _paymentAccountNameController = TextEditingController(); // NEW
  final _paymentMobileController = TextEditingController(); // NEW
  final _formKey = GlobalKey<FormState>();
  bool _isSubmitting = false;
  bool _shownDeliveredPopup = false;

  @override
  void initState() {
    super.initState();
    // If card loads already in Delivered state, mark flag so we don't show on first build
    if (widget.request.status == 'Delivered') {
      _shownDeliveredPopup = true;
    }
  }

  @override
  void didUpdateWidget(covariant RequestHistoryCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Real-time trigger: show delivery success popup when status transitions to Delivered
    if (oldWidget.request.status != 'Delivered' &&
        widget.request.status == 'Delivered' &&
        !_shownDeliveredPopup) {
      _shownDeliveredPopup = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (ctx) => AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: const Row(
                children: [
                  Text('🎉', style: TextStyle(fontSize: 28)),
                  SizedBox(width: 10),
                  Text('Delivery Successful', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.green.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.check_circle_rounded, color: Colors.green.shade700, size: 24),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Text(
                            'Your Personal Request has been delivered successfully.',
                            style: TextStyle(fontSize: 13, height: 1.4, fontWeight: FontWeight.w500),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'Thank you for choosing CampusKart.',
                    style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('OK', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryColor)),
                ),
              ],
            ),
          );
        }
      });
    }
  }

  @override
  void dispose() {
    _paymentAccountNameController.dispose(); // NEW
    _paymentMobileController.dispose(); // NEW
    super.dispose();
  }

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

  Future<void> _handlePaymentSubmit(OrderProvider provider) async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isSubmitting = true;
      });

      bool success = await provider.submitPersonalRequestPayment(
        requestId: widget.request.id,
        paymentId: '',
        paymentAccountName: _paymentAccountNameController.text.trim(), // NEW
        paymentMobileNumber: _paymentMobileController.text.trim(), // NEW
      );

      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Payment Transaction ID submitted successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(provider.errorMessage ?? 'Submission failed.'),
              backgroundColor: Colors.red.shade600,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<OrderProvider>(context, listen: false);
    final statusColor = _getStatusColor(widget.request.status);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top overview row
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.receipt_long_rounded, color: AppTheme.primaryColor, size: 32),
                ),
                const SizedBox(width: 14),
                
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            () {
                              final rawId = widget.request.id.replaceAll('req_', '');
                              final displayId = rawId.substring(0, rawId.length < 6 ? rawId.length : 6).toUpperCase();
                              return 'Req #$displayId';
                            }(),
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Theme.of(context).textTheme.bodyLarge?.color),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: statusColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: statusColor.withOpacity(0.3)),
                            ),
                            child: Text(
                              widget.request.status,
                              style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 10),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        DateFormat('dd MMM yyyy, hh:mm a').format(widget.request.requestDate),
                        style: TextStyle(fontSize: 10, color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.6)),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        widget.request.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 12, color: Theme.of(context).textTheme.bodyLarge?.color, height: 1.3),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Divider(height: 1),
            ),

            // Dynamic flow rendering based on status
            if (widget.request.status == 'Pending Review') ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.amber.shade300.withOpacity(0.4)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.hourglass_empty_rounded, color: Colors.amber.shade800, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Request sent successfully. Please wait for admin review.',
                        style: TextStyle(fontSize: 12, color: Colors.amber.shade900, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
              ),
            ] else if (widget.request.status == 'Payment Pending') ...[
              Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Pricing Breakdown
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.purple.shade50.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.purple.shade200.withOpacity(0.4)),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Product Price', style: TextStyle(fontSize: 12, color: Colors.grey)),
                              Text('₹${widget.request.productPrice.toStringAsFixed(0)}', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Theme.of(context).textTheme.bodyLarge?.color)),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Delivery Charge', style: TextStyle(fontSize: 12, color: Colors.grey)),
                              Text('₹${widget.request.deliveryCharge.toStringAsFixed(0)}', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Theme.of(context).textTheme.bodyLarge?.color)),
                            ],
                          ),
                          const Divider(),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Total Amount', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.purple)),
                              Text('₹${widget.request.totalAmount.toStringAsFixed(0)}', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Colors.purple)),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // QR Code Visual
                    Center(
                      child: Column(
                        children: [
                          const Text(
                            'Scan QR to Pay via UPI',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            width: 140,
                            height: 140,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey.shade300),
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
                                  child: const Icon(Icons.qr_code_scanner_rounded, color: AppTheme.primaryColor, size: 20),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'UPI ID: campuskart@upi',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

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
                    const SizedBox(height: 12),

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
                    const SizedBox(height: 12),

                    // Submit Button
                    CustomButton(
                      text: 'PAY & SUBMIT',
                      isLoading: _isSubmitting,
                      onPressed: () => _handlePaymentSubmit(provider),
                    ),
                  ],
                ),
              ),
            ] else if (widget.request.status == 'Payment Verification Pending') ...[
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
                    Row(
                      children: [
                        Icon(Icons.verified_user_outlined, color: Colors.blue.shade800, size: 20),
                        const SizedBox(width: 8),
                        const Text(
                          'Payment Verification Pending',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.blue),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Admin is currently verifying your transaction. Reference ID: ${widget.request.paymentId}. Once verified, your delivery code will appear here.',
                      style: TextStyle(fontSize: 11, color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.8), height: 1.4),
                    ),
                  ],
                ),
              ),
            ] else if (widget.request.status == 'Confirmed' || widget.request.status == 'Out For Delivery') ...[
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
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.check_circle_outline_rounded, color: Colors.green.shade800, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              widget.request.status == 'Out For Delivery' 
                                  ? 'Out For Delivery - Code' 
                                  : 'Doorstep Delivery Code',
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.green),
                            ),
                          ],
                        ),
                        Text(
                          widget.request.verificationCode,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: Colors.green,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      widget.request.status == 'Out For Delivery'
                          ? 'Your request is out for delivery! Share this code with the delivery person. Delivering to ${widget.request.blockName}, Room ${widget.request.roomNumber}.'
                          : 'Payment verified successfully. Share this code with the delivery person. Delivering to ${widget.request.blockName}, Room ${widget.request.roomNumber}.',
                      style: TextStyle(fontSize: 11, color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.8), height: 1.4),
                    ),
                  ],
                ),
              ),
            ] else if (widget.request.status == 'Delivered') ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.shade50.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.green.shade300.withOpacity(0.4)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.check_circle_rounded, color: Colors.green.shade800, size: 20),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'This order has been delivered successfully. Thank you!',
                        style: TextStyle(fontSize: 12, color: Colors.green, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
            ] else if (widget.request.status == 'Rejected') ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.red.shade300.withOpacity(0.4)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.cancel_outlined, color: Colors.red.shade800, size: 20),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'This request has been rejected by the admin.',
                        style: TextStyle(fontSize: 12, color: Colors.red, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class FastFoodOrdersList extends StatelessWidget {
  const FastFoodOrdersList({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<FastFoodProvider>(context);
    final orders = provider.customerOrders;

    if (orders.isEmpty) {
      return const EmptyListPlaceholder(message: 'No fast food orders placed yet.');
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: orders.length,
      separatorBuilder: (_, __) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        return FastFoodOrderHistoryCard(order: orders[index]);
      },
    );
  }
}

class FastFoodOrderHistoryCard extends StatelessWidget {
  final FastFoodOrderModel order;
  const FastFoodOrderHistoryCard({Key? key, required this.order}) : super(key: key);

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Pending':
        return Colors.amber.shade700;
      case 'Accepted':
        return Colors.blue.shade600;
      case 'Restaurant Ordered':
        return Colors.purple.shade600;
      case 'Preparing':
        return Colors.purple.shade600;
      case 'Food Ready':
        return Colors.teal.shade600;
      case 'Out For Delivery':
        return Colors.orange.shade800;
      case 'Delivered':
        return Colors.green.shade600;
      case 'Rejected':
        return Colors.red.shade600;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor(order.status);

    return Card(
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
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Order #${order.orderId.replaceAll('fford_', '').substring(0, min(6, order.orderId.replaceAll('fford_', '').length)).toUpperCase()}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      DateFormat('dd MMM yyyy, hh:mm a').format(order.createdAt),
                      style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: statusColor.withOpacity(0.3)),
                  ),
                  child: Text(
                    order.status,
                    style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 12),

            ...order.items.map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${item.quantity}x ${item.name}',
                        style: const TextStyle(fontSize: 13),
                      ),
                      Text(
                        '₹${(item.price * item.quantity).toStringAsFixed(0)}',
                        style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                      ),
                    ],
                  ),
                )),
            
            const SizedBox(height: 8),
            const Divider(),
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
                const Text('Grand Total', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                Text('₹${order.grandTotal.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: AppTheme.primaryColor)),
              ],
            ),
            if (order.status != 'Delivered' && order.status != 'Rejected' && order.deliveryCode.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.primaryColor.withOpacity(0.2)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.check_circle, color: AppTheme.primaryColor, size: 18),
                        SizedBox(width: 6),
                        Text(
                          'Delivery OTP Code',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Your Delivery Verification Code:',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      order.deliveryCode,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2.0,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Please provide this code to the CampusKart delivery person when receiving your order.',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade700,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
