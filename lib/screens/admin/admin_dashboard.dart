import 'dart:math';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/admin_provider.dart';
import '../../providers/product_provider.dart';
import '../../widgets/dashboard_card.dart';
import '../../widgets/product_card.dart';
import '../auth/login_screen.dart';
import 'add_product_screen.dart';
import 'edit_product_screen.dart';
import 'order_details_screen.dart';
import 'personal_requests_screen.dart';
import 'settings_screen.dart';
import '../../providers/fast_food_provider.dart';
import '../../models/fast_food_order_model.dart';
import 'add_edit_fast_food_screen.dart';
import 'send_broadcast_screen.dart';
import '../../core/services/firebase_service.dart';
import 'admin_fast_food_orders_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../widgets/custom_textfield.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({Key? key}) : super(key: key);

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int _currentIndex = 0;
  int _selectedDuration = 30;
  final TextEditingController _customDurationController = TextEditingController(text: '30');
  bool _enableHalfTime = true;
  bool _enableTenMin = true;
  bool _enableClosing = true;

  @override
  void dispose() {
    _customDurationController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AdminProvider>(context, listen: false).initAdminStreams();
      Provider.of<ProductProvider>(context, listen: false).initProductStream();
      Provider.of<FastFoodProvider>(context, listen: false).initAdminOrdersStream();
      Provider.of<FastFoodProvider>(context, listen: false).initItemsStream();
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final adminProvider = Provider.of<AdminProvider>(context);
    final productProvider = Provider.of<ProductProvider>(context);

    final stats = adminProvider.earningsDetails;
    final products = productProvider.products;
    
    // Grab pending orders
    final pendingOrders = adminProvider.allOrders.where((o) => o.status != 'Delivered' && o.status != 'Rejected').toList();
    final fastFoodProvider = Provider.of<FastFoodProvider>(context);
    final pendingFastFoodCount = fastFoodProvider.allOrders.where((o) => o.status == 'Pending').length;
    final totalPending = pendingOrders.length + stats.pendingRequestsCount + pendingFastFoodCount;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _currentIndex == 0
              ? 'Owner Dashboard'
              : (_currentIndex == 1
                  ? (totalPending == 0
                      ? 'Orders & Requests'
                      : 'Orders & Requests ($totalPending)')
                  : (_currentIndex == 2 ? 'Stock Inventory' : 'Fast Food Hub')),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_rounded, color: AppTheme.textSecondary),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Colors.red),
            onPressed: () async {
              await auth.logout();
              if (context.mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (route) => false,
                );
              }
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: [
          // --- TAB 1: ANALYTICS DASHBOARD ---
          RefreshIndicator(
            onRefresh: () async {
              // Automatically triggers stream refresh
              await Future.delayed(const Duration(milliseconds: 500));
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Welcome Header Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Welcome back, Owner!',
                            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Here are your campus analytics for today.',
                            style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                          ),
                        ],
                      ),
                      // Availability Indicator
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: adminProvider.isOwnerAvailable ? Colors.green.shade50 : Colors.red.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: adminProvider.isOwnerAvailable ? Colors.green.shade200 : Colors.red.shade200),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: adminProvider.isOwnerAvailable ? Colors.green : Colors.red,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              adminProvider.isOwnerAvailable ? 'OPEN' : 'CLOSED',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: adminProvider.isOwnerAvailable ? Colors.green.shade800 : Colors.red.shade800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),

                  // Analytics Grid
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 14,
                    mainAxisSpacing: 14,
                    childAspectRatio: 1.0,
                    children: [
                      DashboardCard(
                        title: "Today's Orders",
                        value: "${stats.todayOrdersCount}",
                        icon: Icons.shopping_basket_rounded,
                        color: AppTheme.primaryColor,
                        onTap: () {
                          setState(() {
                            _currentIndex = 1;
                          });
                        },
                      ),
                      DashboardCard(
                        title: "Pending Orders",
                        value: "${stats.pendingOrdersCount}",
                        icon: Icons.hourglass_empty_rounded,
                        color: Colors.blue.shade600,
                        onTap: () {
                          setState(() {
                            _currentIndex = 1;
                          });
                        },
                      ),
                      DashboardCard(
                        title: "Personal Requests",
                        value: "${stats.pendingRequestsCount}",
                        icon: Icons.assignment_rounded,
                        color: AppTheme.secondaryColor,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const PersonalRequestsScreen()),
                          );
                        },
                      ),
                      StreamBuilder<List<FastFoodOrderModel>>(
                        stream: FirebaseService().streamAllFastFoodOrders(),
                        builder: (context, snapshot) {
                          final count = (snapshot.data ?? [])
                              .where((o) => o.status == 'Pending')
                              .length;
                          return DashboardCard(
                            title: "Pending Fast Food",
                            value: "$count",
                            icon: Icons.fastfood_rounded,
                            color: Colors.orange.shade700,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const AdminFastFoodOrdersPage()),
                              );
                            },
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  DashboardCard(
                    title: "Availability Status",
                    value: adminProvider.isOwnerAvailable ? "Open" : "Closed",
                    icon: Icons.storefront_rounded,
                    color: adminProvider.isOwnerAvailable ? Colors.green.shade600 : Colors.red.shade600,
                    onTap: () {
                      adminProvider.toggleAvailability(!adminProvider.isOwnerAvailable);
                    },
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const SendBroadcastScreen()),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                      minimumSize: const Size(double.infinity, 50),
                    ),
                    icon: const Icon(Icons.campaign_rounded),
                    label: const Text(
                      'Send Message To Pending Orders',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // --- TAB 2: UNIFIED ORDERS & REQUESTS ---
          DefaultTabController(
            length: 2,
            child: Column(
              children: [
                TabBar(
                  indicatorColor: AppTheme.primaryColor,
                  labelColor: AppTheme.primaryColor,
                  unselectedLabelColor: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.6),
                  tabs: const [
                    Tab(text: 'General Orders'),
                    Tab(text: 'Personal Requests'),
                  ],
                ),
                Expanded(
                  child: TabBarView(
                    children: [
                      // Sub-tab 1: General Orders
                      pendingOrders.isEmpty
                          ? const Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.done_all_rounded, size: 48, color: Colors.green),
                                  SizedBox(height: 12),
                                  Text('All orders fulfilled!', style: TextStyle(color: AppTheme.textSecondary, fontWeight: FontWeight.bold)),
                                ],
                              ),
                            )
                          : ListView.separated(
                              padding: const EdgeInsets.all(16),
                              itemCount: pendingOrders.length,
                              separatorBuilder: (_, __) => const SizedBox(height: 16),
                              itemBuilder: (context, index) {
                                final order = pendingOrders[index];
                                return Card(
                                  elevation: 2,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(16),
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(builder: (_) => OrderDetailsScreen(order: order)),
                                      );
                                    },
                                    child: Padding(
                                      padding: const EdgeInsets.all(16),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          // Top Row: ID and Status
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                'Order #${order.id.replaceAll('ord_', '').substring(0, min(6, order.id.replaceAll('ord_', '').length)).toUpperCase()}',
                                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                              ),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                                decoration: BoxDecoration(
                                                  color: Colors.orange.shade50,
                                                  borderRadius: BorderRadius.circular(8),
                                                  border: Border.all(color: Colors.orange.shade200),
                                                ),
                                                child: Text(
                                                  order.status,
                                                  style: TextStyle(color: Colors.orange.shade900, fontWeight: FontWeight.bold, fontSize: 11),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          
                                          // Order Time Row
                                          Row(
                                            children: [
                                              const Icon(Icons.access_time_rounded, size: 13, color: Colors.grey),
                                              const SizedBox(width: 4),
                                              Text(
                                                'Placed: ${DateFormat('dd MMM yyyy, hh:mm a').format(order.orderDate)}',
                                                style: const TextStyle(fontSize: 11, color: Colors.grey),
                                              ),
                                            ],
                                          ),
                                          const Divider(height: 20),
                                          
                                          // Customer Name & Room Details Row
                                          Row(
                                            children: [
                                              const Icon(Icons.person_outline_rounded, size: 16, color: AppTheme.primaryColor),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                child: Text(
                                                  '${order.customerName} (${order.blockName}, Rm ${order.roomNumber})',
                                                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 12),
                                          
                                          // Financial & Items count overview
                                          Container(
                                            padding: const EdgeInsets.all(12),
                                            decoration: BoxDecoration(
                                              color: Colors.grey.shade50,
                                              borderRadius: BorderRadius.circular(10),
                                              border: Border.all(color: Colors.grey.shade100),
                                            ),
                                            child: Column(
                                              children: [
                                                Row(
                                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                  children: [
                                                    Text(
                                                      'Items Count (${order.items.length} types):',
                                                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                                                    ),
                                                    Text(
                                                      '${order.items.fold<int>(0, (sum, i) => sum + i.quantity)} items',
                                                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(height: 6),
                                                Row(
                                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                  children: [
                                                    const Text(
                                                      'Subtotal:',
                                                      style: TextStyle(fontSize: 12, color: Colors.grey),
                                                    ),
                                                    Text(
                                                      '₹${order.subtotal.toStringAsFixed(0)}',
                                                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(height: 6),
                                                Row(
                                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                  children: [
                                                    const Text(
                                                      'Delivery Fee:',
                                                      style: TextStyle(fontSize: 12, color: Colors.grey),
                                                    ),
                                                    Text(
                                                      '₹${order.deliveryFee.toStringAsFixed(0)}',
                                                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                                    ),
                                                  ],
                                                ),
                                                const Divider(height: 12),
                                                Row(
                                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                  children: [
                                                    const Text(
                                                      'Total Amount:',
                                                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                                                    ),
                                                    Text(
                                                      '₹${order.total.toStringAsFixed(0)}',
                                                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: AppTheme.primaryColor),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),

                      // Sub-tab 2: Personal Requests
                      const PersonalRequestsListView(),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // --- TAB 3: STOCK INVENTORY LIST ---
          productProvider.isLoading
              ? const Center(child: CircularProgressIndicator())
              : products.isEmpty
                  ? const Center(child: Text('No products in catalog yet.'))
                  : GridView.builder(
                      padding: const EdgeInsets.all(16),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 0.70,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                      ),
                      itemCount: products.length,
                      itemBuilder: (context, index) {
                        final prod = products[index];
                        return ProductCard(
                          product: prod,
                          isAdmin: true,
                          onEdit: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => EditProductScreen(product: prod)),
                            );
                          },
                          onDelete: () async {
                            bool success = await productProvider.deleteProduct(prod.id);
                            if (success && context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Product deleted successfully.')));
                            }
                          },
                        );
                      },
                    ),
          // --- TAB 4: FAST FOOD MANAGEMENT & ORDERS ---
          const AdminFastFoodDashboard(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (idx) {
          setState(() {
            _currentIndex = idx;
          });
        },
        destinations: [
          const NavigationDestination(icon: Icon(Icons.analytics_outlined), selectedIcon: Icon(Icons.analytics), label: 'Overview'),
          NavigationDestination(
            icon: Badge(
              label: Text('$totalPending'),
              isLabelVisible: totalPending > 0,
              backgroundColor: AppTheme.primaryColor,
              textColor: Colors.white,
              child: const Icon(Icons.receipt_long_outlined),
            ),
            selectedIcon: Badge(
              label: Text('$totalPending'),
              isLabelVisible: totalPending > 0,
              backgroundColor: AppTheme.primaryColor,
              textColor: Colors.white,
              child: const Icon(Icons.receipt_long),
            ),
            label: 'Orders',
          ),
          const NavigationDestination(icon: Icon(Icons.inventory_2_outlined), selectedIcon: Icon(Icons.inventory_2), label: 'Inventory'),
          const NavigationDestination(icon: Icon(Icons.fastfood_outlined), selectedIcon: Icon(Icons.fastfood), label: 'Fast Food'),
        ],
      ),
      floatingActionButton: _currentIndex == 2
          ? FloatingActionButton(
              backgroundColor: AppTheme.primaryColor,
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AddProductScreen()),
                );
              },
              child: const Icon(Icons.add, color: Colors.white),
            )
          : (_currentIndex == 3
              ? FloatingActionButton(
                  backgroundColor: AppTheme.primaryColor,
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const AddEditFastFoodScreen()),
                    );
                  },
                  child: const Icon(Icons.add, color: Colors.white),
                )
              : null),
    );
  }
}

class AdminFastFoodDashboard extends StatefulWidget {
  const AdminFastFoodDashboard({Key? key}) : super(key: key);

  @override
  State<AdminFastFoodDashboard> createState() => _AdminFastFoodDashboardState();
}

class _AdminFastFoodDashboardState extends State<AdminFastFoodDashboard> {
  int _selectedDuration = 30;
  final TextEditingController _customDurationController = TextEditingController(text: '30');
  bool _enableHalfTime = true;
  bool _enableTenMin = true;
  bool _enableClosing = true;

  @override
  void initState() {
    super.initState();
    _customDurationController.addListener(() {
      final parsed = int.tryParse(_customDurationController.text) ?? 0;
      if (parsed != _selectedDuration) {
        setState(() {
          _selectedDuration = parsed;
        });
      }
    });
  }

  @override
  void dispose() {
    _customDurationController.dispose();
    super.dispose();
  }

  Widget _buildFastFoodStatusWidget(BuildContext context, FastFoodOrderModel order, FastFoodProvider provider) {
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
  Widget _buildFastFoodOrderCard(BuildContext context, FastFoodOrderModel order, FastFoodProvider provider) {
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
                  'Order #${order.orderId.replaceAll('fford_', '').substring(0, min(6, order.orderId.replaceAll('fford_', '').length)).toUpperCase()}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                _buildFastFoodStatusWidget(context, order, provider),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.person_outline_rounded, size: 14, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  '${order.customerName} (${order.mobile})',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
            if (order.blockName.isNotEmpty || order.roomNumber.isNotEmpty) ...[
              const SizedBox(height: 2),
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
            const Divider(height: 20),
            ...order.items.map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('${item.quantity}x ${item.name}', style: const TextStyle(fontSize: 13)),
                      Text('₹${(item.price * item.quantity).toStringAsFixed(0)}', style: const TextStyle(fontSize: 13, color: Colors.grey)),
                    ],
                  ),
                )),
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
                const Text('Grand Total', style: TextStyle(fontWeight: FontWeight.bold)),
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
    return DefaultTabController(
      length: 3,
      child: Column(
        children: [
          const TabBar(
            indicatorColor: AppTheme.primaryColor,
            labelColor: AppTheme.primaryColor,
            tabs: [
              Tab(text: 'Fast Food Menu'),
              Tab(text: 'Fast Food Orders'),
              Tab(text: 'Timer Controls'),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                // Sub-tab 1: Fast Food Menu Management
                Consumer<FastFoodProvider>(
                  builder: (context, provider, child) {
                    if (provider.isLoading) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (provider.items.isEmpty) {
                      return const Center(child: Text('No fast food items. Click + to add one.'));
                    }
                    return GridView.builder(
                      padding: const EdgeInsets.all(16),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 0.72,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                      ),
                      itemCount: provider.items.length,
                      itemBuilder: (context, index) {
                        final item = provider.items[index];
                        return Card(
                          elevation: 2,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Stack(
                                  children: [
                                    ClipRRect(
                                      borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                                      child: Image.network(
                                        item.imageUrl,
                                        width: double.infinity,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) => Container(
                                          color: Colors.grey.shade100,
                                          child: const Center(
                                            child: Icon(Icons.fastfood, color: Colors.grey, size: 40),
                                          ),
                                        ),
                                      ),
                                    ),
                                    if (!item.available)
                                      Positioned.fill(
                                        child: Container(
                                          color: Colors.black.withOpacity(0.5),
                                          alignment: Alignment.center,
                                          child: const Text(
                                            'UNAVAILABLE',
                                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.name,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                    ),
                                    const SizedBox(height: 2),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          '₹${item.price.toStringAsFixed(0)}',
                                          style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryColor),
                                        ),
                                        Row(
                                          children: [
                                            IconButton(
                                              icon: const Icon(Icons.edit, size: 16, color: Colors.blue),
                                              padding: EdgeInsets.zero,
                                              constraints: const BoxConstraints(),
                                              onPressed: () {
                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (_) => AddEditFastFoodScreen(item: item),
                                                  ),
                                                );
                                              },
                                            ),
                                            const SizedBox(width: 8),
                                            IconButton(
                                              icon: const Icon(Icons.delete, size: 16, color: Colors.red),
                                              padding: EdgeInsets.zero,
                                              constraints: const BoxConstraints(),
                                              onPressed: () async {
                                                bool success = await provider.deleteFastFoodItem(item.id);
                                                if (success && context.mounted) {
                                                  ScaffoldMessenger.of(context).showSnackBar(
                                                    const SnackBar(content: Text('Item deleted successfully.')),
                                                  );
                                                }
                                              },
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),

                 // Sub-tab 2: Fast Food Orders Management
                Consumer<FastFoodProvider>(
                  builder: (context, provider, child) {
                    final orders = provider.allOrders;
                    final pendingList = orders.where((o) => o.status != 'Delivered' && o.status != 'Rejected').toList();
                    final deliveredList = orders.where((o) => o.status == 'Delivered').toList();

                    if (orders.isEmpty) {
                      return const Center(child: Text('No fast food orders yet.'));
                    }

                    return ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        if (pendingList.isNotEmpty) ...[
                          const Padding(
                            padding: EdgeInsets.only(bottom: 12.0, top: 4.0),
                            child: Text(
                              'Pending Orders',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.primaryColor),
                            ),
                          ),
                          ...pendingList.map((order) => _buildFastFoodOrderCard(context, order, provider)),
                        ],
                        if (deliveredList.isNotEmpty) ...[
                          Padding(
                            padding: EdgeInsets.only(top: pendingList.isNotEmpty ? 24.0 : 4.0, bottom: 12.0),
                            child: const Text(
                              'Delivery History',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green),
                            ),
                          ),
                          ...deliveredList.map((order) => _buildFastFoodOrderCard(context, order, provider)),
                        ],
                      ],
                    );
                  },
                ),
                _buildTimerControlsTab(context),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimerControlsTab(BuildContext context) {
    return Consumer<FastFoodProvider>(
      builder: (context, provider, child) {
        final timerData = provider.timerData;
        final bool isEnabled = timerData['fastFoodEnabled'] ?? false;
        final String remainingTime = provider.remainingTimeString;

        final DateTime now = DateTime.now();
        
        String formatDateTime(dynamic val) {
          if (val == null) return 'N/A';
          DateTime dt;
          if (val is Timestamp) {
            dt = val.toDate();
          } else if (val is DateTime) {
            dt = val;
          } else {
            dt = DateTime.tryParse(val.toString()) ?? now;
          }
          return DateFormat('hh:mm:ss a').format(dt);
        }

        final startTimeStr = formatDateTime(timerData['timerStartedAt']);
        final endTimeStr = formatDateTime(timerData['timerEndsAt']);

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (isEnabled) ...[
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  color: Colors.amber.shade50,
                  shadowColor: Colors.amber.withOpacity(0.2),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.timer_rounded, color: Colors.amber, size: 28),
                            SizedBox(width: 8),
                            Text(
                              'Active Ordering Session',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        Text(
                          remainingTime.isNotEmpty ? remainingTime : '00:00',
                          style: TextStyle(
                            fontSize: 64,
                            fontWeight: FontWeight.w900,
                            fontFamily: 'monospace',
                            color: Colors.amber.shade900,
                            letterSpacing: 2,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildTimerMetaInfo('Started At', startTimeStr),
                            _buildTimerMetaInfo('Ends At', endTimeStr),
                          ],
                        ),
                        const Divider(height: 32, thickness: 1),
                        const Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Sent Notification Status Logs:',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.textPrimary),
                          ),
                        ),
                        const SizedBox(height: 12),
                        _buildReminderLogItem(
                          'Half-Time (at 50% duration)',
                          timerData['enableHalfTimeReminder'] ?? false,
                          timerData['halfTimeReminderSent'] ?? false,
                        ),
                        _buildReminderLogItem(
                          '10-Minute Warning',
                          timerData['enableTenMinReminder'] ?? false,
                          timerData['tenMinReminderSent'] ?? false,
                        ),
                        _buildReminderLogItem(
                          'Session Closed Alert',
                          timerData['enableClosingNotification'] ?? false,
                          timerData['closingNotificationSent'] ?? false,
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () async {
                              await provider.stopFastFoodTimer();
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Fast Food ordering timer stopped successfully!'), backgroundColor: Colors.red),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            icon: const Icon(Icons.stop_circle_rounded),
                            label: const Text('STOP TIMER INSTANTLY', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ] else ...[
                const Text(
                  'Start Fast Food Session',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Set session length and configure automatic customer reminder notifications.',
                  style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                ),
                const SizedBox(height: 24),

                const Text(
                  'Session Duration',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [15, 30, 45, 60].map((mins) {
                    final isSelected = _selectedDuration == mins;
                    return Expanded(
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedDuration = mins;
                            _customDurationController.text = mins.toString();
                          });
                        },
                        child: Container(
                          margin: const EdgeInsets.only(right: 6),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: isSelected ? AppTheme.primaryColor : Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isSelected ? AppTheme.primaryColor : Colors.grey.shade300,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              '$mins min',
                              style: TextStyle(
                                color: isSelected ? Colors.white : AppTheme.textPrimary,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  label: 'Or Custom Duration (minutes)',
                  hint: 'Enter minutes, e.g. 120',
                  controller: _customDurationController,
                  keyboardType: TextInputType.number,
                  prefixIcon: Icons.av_timer_rounded,
                ),
                const SizedBox(height: 28),

                const Text(
                  'Reminder Settings',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                ),
                const SizedBox(height: 12),
                Card(
                  elevation: 1,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Column(
                      children: [
                        SwitchListTile(
                          title: const Text('Half-Time Reminder Notification', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                          subtitle: const Text('Notify customers when half of the timer has passed.', style: TextStyle(fontSize: 10)),
                          value: _enableHalfTime,
                          activeColor: AppTheme.primaryColor,
                          onChanged: (val) {
                            setState(() {
                              _enableHalfTime = val;
                            });
                          },
                        ),
                        const Divider(height: 8),
                        SwitchListTile(
                          title: const Text('10-Minute Warning Notification', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                          subtitle: const Text('Notify customers when 10 minutes remain.', style: TextStyle(fontSize: 10)),
                          value: _enableTenMin,
                          activeColor: AppTheme.primaryColor,
                          onChanged: (val) {
                            setState(() {
                              _enableTenMin = val;
                            });
                          },
                        ),
                        const Divider(height: 8),
                        SwitchListTile(
                          title: const Text('Session Closure Notification', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                          subtitle: const Text('Turn off fastFoodEnabled and notify customers on timer end.', style: TextStyle(fontSize: 10)),
                          value: _enableClosing,
                          activeColor: AppTheme.primaryColor,
                          onChanged: (val) {
                            setState(() {
                              _enableClosing = val;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 36),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      if (_selectedDuration <= 0) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Please select or enter a valid duration greater than 0 minutes.')),
                        );
                        return;
                      }
                      await provider.startFastFoodTimer(
                        _selectedDuration,
                        _enableHalfTime,
                        _enableTenMin,
                        _enableClosing,
                      );
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Fast Food ordering timer started for $_selectedDuration minutes!'), backgroundColor: Colors.green),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: const Icon(Icons.play_circle_fill_rounded),
                    label: const Text('START TIMER NOW', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildTimerMetaInfo(String label, String timeStr) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(timeStr, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
      ],
    );
  }

  Widget _buildReminderLogItem(String title, bool isEnabled, bool isSent) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(
            !isEnabled
                ? Icons.disabled_by_default_rounded
                : (isSent ? Icons.check_circle_rounded : Icons.pending_actions_rounded),
            color: !isEnabled
                ? Colors.grey
                : (isSent ? Colors.green : Colors.orange),
            size: 18,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 12,
                color: !isEnabled ? Colors.grey : AppTheme.textPrimary,
                decoration: !isEnabled ? TextDecoration.lineThrough : null,
              ),
            ),
          ),
          Text(
            !isEnabled ? 'Disabled' : (isSent ? 'Sent' : 'Pending'),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: !isEnabled
                  ? Colors.grey
                  : (isSent ? Colors.green : Colors.orange),
            ),
          ),
        ],
      ),
    );
  }
}

class VerifyFastFoodDeliveryCodeDialog extends StatefulWidget {
  final FastFoodOrderModel order;
  final FastFoodProvider provider;

  const VerifyFastFoodDeliveryCodeDialog({
    Key? key,
    required this.order,
    required this.provider,
  }) : super(key: key);

  @override
  State<VerifyFastFoodDeliveryCodeDialog> createState() => _VerifyFastFoodDeliveryCodeDialogState();
}

class _VerifyFastFoodDeliveryCodeDialogState extends State<VerifyFastFoodDeliveryCodeDialog> {
  final TextEditingController _codeController = TextEditingController();
  String? _localError;
  bool _isVerifying = false;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cleanId = widget.order.orderId.replaceAll('fford_', '').toUpperCase();
    final displayId = cleanId.substring(0, min(6, cleanId.length));

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text(
        'Verify Delivery Code',
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Customer Name: ${widget.order.customerName}',
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
            const SizedBox(height: 4),
            Text(
              'Order ID: #$displayId',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _codeController,
              keyboardType: TextInputType.number,
              maxLength: 4,
              decoration: InputDecoration(
                labelText: 'Enter Delivery Code',
                hintText: '4-digit code',
                errorText: _localError,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                prefixIcon: const Icon(Icons.lock_outline_rounded),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isVerifying ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryColor,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          onPressed: _isVerifying ? null : _handleVerify,
          child: _isVerifying
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Text('Verify'),
        ),
      ],
    );
  }

  Future<void> _handleVerify() async {
    final code = _codeController.text.trim();
    if (code.length != 4) {
      setState(() {
        _localError = 'Please enter a 4-digit delivery code.';
      });
      return;
    }

    setState(() {
      _isVerifying = true;
      _localError = null;
    });

    final success = await widget.provider.verifyFastFoodDeliveryCode(widget.order.orderId, code);

    if (!mounted) return;

    setState(() {
      _isVerifying = false;
    });

    if (success) {
      Navigator.pop(context); // Close verification dialog
      _showSuccessPopup();
    } else {
      setState(() {
        _localError = widget.provider.errorMessage ?? 'Invalid OTP. Please try again.';
      });
    }
  }

  void _showSuccessPopup() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.check_circle_rounded, color: Colors.green),
            SizedBox(width: 8),
            Text('Delivery Successful'),
          ],
        ),
        content: const Text(
          'Order delivered successfully.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('OK', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
