import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/admin_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/fast_food_provider.dart';
import '../../providers/product_provider.dart';
import '../../widgets/app_image.dart';
import '../../widgets/dashboard_card.dart';
import '../../widgets/responsive_container.dart';
import '../auth/login_screen.dart';
import 'add_edit_fast_food_screen.dart';
import 'add_product_screen.dart';
import 'admin_customers_screen.dart';
import 'admin_fast_food_orders_page.dart';
import 'edit_product_screen.dart';
import 'order_details_screen.dart';
import 'personal_requests_screen.dart';
import 'send_broadcast_screen.dart';
import 'settings_screen.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> with SingleTickerProviderStateMixin {
  int _currentIndex = 0;
  int _selectedDuration = 30;
  bool _isCustomDuration = false;
  final TextEditingController _customDurationController = TextEditingController(text: '30');
  bool _enableHalfTime = true;
  bool _enableTenMin = true;
  bool _enableClosing = true;

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
  void dispose() {
    _customDurationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final adminProvider = Provider.of<AdminProvider>(context);
    final productProvider = Provider.of<ProductProvider>(context);
    final fastFoodProvider = Provider.of<FastFoodProvider>(context);

    final stats = adminProvider.earningsDetails;
    final pendingOrders = adminProvider.allOrders.where((o) => o.status != 'Delivered' && o.status != 'Rejected').toList();
    final pendingFastFoodCount = fastFoodProvider.allOrders.where((o) => o.status == 'Pending').length;
    final totalPending = pendingOrders.length + stats.pendingRequestsCount + pendingFastFoodCount;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _currentIndex == 0
              ? 'Admin Dashboard'
              : (_currentIndex == 1
                  ? (totalPending == 0 ? 'Orders & Requests' : 'Orders & Requests ($totalPending)')
                  : (_currentIndex == 2 ? 'Store Inventory' : 'Fast Food Hub')),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.people_alt_rounded, color: AppTheme.primaryColor),
            tooltip: 'Customer Directory & WhatsApp',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AdminCustomersScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.campaign_rounded, color: AppTheme.primaryColor),
            tooltip: 'Send Broadcast Alert',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SendBroadcastScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings_rounded, color: AppTheme.textSecondary),
            tooltip: 'Settings',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Colors.red),
            tooltip: 'Logout',
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
      body: ResponsiveContainer.wide(
        child: IndexedStack(
          index: _currentIndex,
          children: [
            _buildAnalyticsTab(adminProvider, stats),
            _buildOrdersTab(adminProvider, fastFoodProvider),
            _buildInventoryTab(productProvider),
            _buildFastFoodTab(fastFoodProvider),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppTheme.primaryColor,
        unselectedItemColor: Colors.grey,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
        unselectedLabelStyle: const TextStyle(fontSize: 11),
        items: [
          const BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_rounded),
            label: 'Overview',
          ),
          BottomNavigationBarItem(
            icon: Badge(
              isLabelVisible: totalPending > 0,
              label: Text('$totalPending'),
              child: const Icon(Icons.receipt_long_rounded),
            ),
            label: 'Orders',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.inventory_2_rounded),
            label: 'Inventory',
          ),
          BottomNavigationBarItem(
            icon: Badge(
              isLabelVisible: pendingFastFoodCount > 0,
              label: Text('$pendingFastFoodCount'),
              child: const Icon(Icons.fastfood_rounded),
            ),
            label: 'Fast Food',
          ),
        ],
      ),
    );
  }

  // --- TAB 1: OVERVIEW & ANALYTICS ---
  Widget _buildAnalyticsTab(AdminProvider adminProvider, dynamic stats) {
    return RefreshIndicator(
      onRefresh: () async => Future.delayed(const Duration(milliseconds: 500)),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Store Status Switch Card
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: (adminProvider.isOwnerAvailable ? Colors.green : Colors.red).withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        adminProvider.isOwnerAvailable ? Icons.storefront_rounded : Icons.storefront_outlined,
                        color: adminProvider.isOwnerAvailable ? Colors.green : Colors.red,
                        size: 26,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            adminProvider.isOwnerAvailable ? 'Campus Store is OPEN' : 'Campus Store is CLOSED',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.textPrimary),
                          ),
                          Text(
                            adminProvider.isOwnerAvailable ? 'Accepting student orders' : 'Ordering temporarily paused',
                            style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: adminProvider.isOwnerAvailable,
                      activeThumbColor: Colors.green,
                      onChanged: (val) => adminProvider.toggleOwnerAvailability(val),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            const Text(
              'Business Overview',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
            ),
            const SizedBox(height: 12),

            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.15,
              children: [
                DashboardCard(
                  title: "Today's Orders",
                  value: "${stats.todayOrdersCount}",
                  icon: Icons.shopping_bag_rounded,
                  color: AppTheme.primaryColor,
                  onTap: () => setState(() => _currentIndex = 1),
                ),
                DashboardCard(
                  title: "Pending Orders",
                  value: "${stats.pendingOrdersCount}",
                  icon: Icons.hourglass_top_rounded,
                  color: Colors.orange,
                  onTap: () => setState(() => _currentIndex = 1),
                ),
                DashboardCard(
                  title: "Personal Requests",
                  value: "${stats.pendingRequestsCount}",
                  icon: Icons.assignment_late_rounded,
                  color: Colors.purple,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const PersonalRequestsScreen()),
                    );
                  },
                ),
                DashboardCard(
                  title: "Total Revenue",
                  value: "₹${stats.totalEarnings.toStringAsFixed(0)}",
                  icon: Icons.account_balance_wallet_rounded,
                  color: Colors.green,
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Quick Management Actions
            const Text(
              'Quick Actions',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
            ),
            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const AddProductScreen()),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: const Icon(Icons.add_photo_alternate_rounded, size: 20),
                    label: const Text('Add Product', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const AddEditFastFoodScreen()),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.primaryColor,
                      side: const BorderSide(color: AppTheme.primaryColor, width: 1.5),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: const Icon(Icons.fastfood_rounded, size: 20),
                    label: const Text('Add Fast Food', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // --- TAB 2: ORDERS & REQUESTS ---
  Widget _buildOrdersTab(AdminProvider adminProvider, FastFoodProvider fastFoodProvider) {
    return DefaultTabController(
      length: 3,
      child: Column(
        children: [
          Container(
            color: Colors.white,
            child: const TabBar(
              indicatorColor: AppTheme.primaryColor,
              labelColor: AppTheme.primaryColor,
              unselectedLabelColor: Colors.grey,
              labelStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              tabs: [
                Tab(text: 'General Orders'),
                Tab(text: 'Personal Requests'),
                Tab(text: 'Fast Food Orders'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              children: [
                // 1. General Orders
                _buildGeneralOrdersList(adminProvider),
                // 2. Personal Requests
                _buildPersonalRequestsList(adminProvider),
                // 3. Fast Food Orders
                const AdminFastFoodOrdersPage(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGeneralOrdersList(AdminProvider adminProvider) {
    final orders = adminProvider.allOrders;
    if (orders.isEmpty) {
      return const Center(
        child: Text('No general orders yet', style: TextStyle(color: AppTheme.textSecondary)),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: orders.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, idx) {
        final order = orders[idx];
        return Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          child: ListTile(
            contentPadding: const EdgeInsets.all(14),
            title: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Order #${order.orderId.substring(0, min(8, order.orderId.length))}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
                _buildStatusChip(order.status),
              ],
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 6),
                Text('Customer: ${order.customerName} (${order.customerMobile})'),
                Text('Location: ${order.blockName}, Room ${order.roomNumber}'),
                Text(
                  'Total: ₹${order.totalAmount.toStringAsFixed(0)} • ${order.items.length} items',
                  style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryColor),
                ),
              ],
            ),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => OrderDetailsScreen(order: order)),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildPersonalRequestsList(AdminProvider adminProvider) {
    final requests = adminProvider.allRequests;
    if (requests.isEmpty) {
      return const Center(
        child: Text('No personal requests yet', style: TextStyle(color: AppTheme.textSecondary)),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: requests.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, idx) {
        final req = requests[idx];
        return Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          child: ListTile(
            contentPadding: const EdgeInsets.all(14),
            title: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    req.itemName,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                _buildStatusChip(req.status),
              ],
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text('Customer: ${req.customerName} (${req.customerMobile})'),
                Text('Location: ${req.blockName}, Room ${req.roomNumber}'),
                if (req.quotedPrice != null)
                  Text(
                    'Quoted: ₹${req.quotedPrice!.toStringAsFixed(0)}',
                    style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryColor),
                  ),
              ],
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PersonalRequestsScreen()),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildStatusChip(String status) {
    Color bg;
    Color fg;
    switch (status.toLowerCase()) {
      case 'delivered':
        bg = Colors.green.shade50;
        fg = Colors.green.shade800;
        break;
      case 'pending':
        bg = Colors.orange.shade50;
        fg = Colors.orange.shade800;
        break;
      case 'rejected':
      case 'cancelled':
        bg = Colors.red.shade50;
        fg = Colors.red.shade800;
        break;
      default:
        bg = Colors.blue.shade50;
        fg = Colors.blue.shade800;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        status,
        style: TextStyle(color: fg, fontWeight: FontWeight.bold, fontSize: 11),
      ),
    );
  }

  Future<void> _confirmDeleteProduct(BuildContext context, ProductProvider provider, dynamic product) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Product'),
        content: Text('Are you sure you want to permanently delete "${product.name}" from your store?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      final success = await provider.deleteProduct(product.id);
      if (context.mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Product "${product.name}" deleted successfully.'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(provider.errorMessage ?? 'Unable to delete product. Please check your connection or admin permissions.'),
              backgroundColor: Colors.red.shade600,
            ),
          );
        }
      }
    }
  }

  // --- TAB 3: INVENTORY ---
  Widget _buildInventoryTab(ProductProvider productProvider) {
    final products = productProvider.products;
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddProductScreen()),
          );
        },
        backgroundColor: AppTheme.primaryColor,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Add Product', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: products.isEmpty
          ? const Center(
              child: Text('No products in inventory yet', style: TextStyle(color: AppTheme.textSecondary)),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: products.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, idx) {
                final product = products[idx];
                return Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(12),
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        width: 54,
                        height: 54,
                        color: Colors.grey.shade100,
                        child: AppImage(
                          imageUrl: product.imageUrl,
                          width: 54,
                          height: 54,
                          fit: BoxFit.cover,
                          fallbackIcon: Icons.shopping_basket_outlined,
                        ),
                      ),
                    ),
                    title: Row(
                      children: [
                        Expanded(
                          child: Text(
                            product.name,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (product.isOffer) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.orange.shade100,
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: Colors.orange.shade700, width: 0.8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text('🔥 ', style: TextStyle(fontSize: 9)),
                                Text(
                                  (product.offerLabel.isNotEmpty ? product.offerLabel : 'OFFER').toUpperCase(),
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.orange.shade900,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 2),
                        Text(
                          product.hasDiscount
                              ? '₹${product.offerPrice!.toStringAsFixed(0)} (Orig: ₹${product.price.toStringAsFixed(0)}) / ${product.unit} • Stock: ${product.quantity}'
                              : '₹${product.price.toStringAsFixed(0)} / ${product.unit} • Stock: ${product.quantity}',
                        ),
                        Text(
                          product.available ? 'Available' : 'Hidden / Out of Stock',
                          style: TextStyle(
                            fontSize: 11,
                            color: product.available ? Colors.green : Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit_rounded, color: AppTheme.primaryColor),
                          tooltip: 'Edit Product',
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => EditProductScreen(product: product)),
                            );
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline_rounded, color: Colors.red),
                          tooltip: 'Delete Product',
                          onPressed: () => _confirmDeleteProduct(context, productProvider, product),
                        ),
                      ],
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => EditProductScreen(product: product)),
                      );
                    },
                  ),
                );
              },
            ),
    );
  }

  // --- TAB 4: FAST FOOD HUB ---
  Widget _buildFastFoodTab(FastFoodProvider fastFoodProvider) {
    final items = fastFoodProvider.items;
    final isTimerRunning = fastFoodProvider.isTimerRunning;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timer Control Card
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
                      const Text(
                        'Fast Food Order Window',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: isTimerRunning ? Colors.green.shade50 : Colors.red.shade50,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          isTimerRunning ? 'ACTIVE' : 'INACTIVE',
                          style: TextStyle(
                            color: isTimerRunning ? Colors.green.shade800 : Colors.red.shade800,
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (isTimerRunning) ...[
                    Text(
                      'Time Remaining: ${fastFoodProvider.formattedRemainingTime}',
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppTheme.primaryColor),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Quick Extend Window:',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textSecondary),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        ActionChip(
                          avatar: const Icon(Icons.add_circle_outline_rounded, size: 16, color: AppTheme.primaryColor),
                          label: const Text('+15 min'),
                          onPressed: () => fastFoodProvider.extendFastFoodTimer(15),
                        ),
                        ActionChip(
                          avatar: const Icon(Icons.add_circle_outline_rounded, size: 16, color: AppTheme.primaryColor),
                          label: const Text('+30 min'),
                          onPressed: () => fastFoodProvider.extendFastFoodTimer(30),
                        ),
                        ActionChip(
                          avatar: const Icon(Icons.add_circle_outline_rounded, size: 16, color: AppTheme.primaryColor),
                          label: const Text('+60 min'),
                          onPressed: () => fastFoodProvider.extendFastFoodTimer(60),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    ElevatedButton.icon(
                      onPressed: () => fastFoodProvider.stopFastFoodTimer(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      icon: const Icon(Icons.stop_rounded),
                      label: const Text('Close Window Now', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ] else ...[
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          ...[15, 30, 45, 60, 90, 120].map((mins) {
                            final isSel = !_isCustomDuration && _selectedDuration == mins;
                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: ChoiceChip(
                                label: Text('$mins m'),
                                selected: isSel,
                                onSelected: (val) {
                                  setState(() {
                                    _isCustomDuration = false;
                                    _selectedDuration = mins;
                                    _customDurationController.text = mins.toString();
                                  });
                                },
                                selectedColor: AppTheme.primaryColor,
                                labelStyle: TextStyle(
                                  color: isSel ? Colors.white : AppTheme.textPrimary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            );
                          }),
                          ChoiceChip(
                            avatar: Icon(
                              Icons.edit_calendar_rounded,
                              size: 16,
                              color: _isCustomDuration ? Colors.white : AppTheme.primaryColor,
                            ),
                            label: const Text('Custom Time'),
                            selected: _isCustomDuration,
                            onSelected: (val) {
                              setState(() {
                                _isCustomDuration = true;
                              });
                            },
                            selectedColor: AppTheme.primaryColor,
                            labelStyle: TextStyle(
                              color: _isCustomDuration ? Colors.white : AppTheme.textPrimary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (_isCustomDuration) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Set Custom Window Duration',
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.remove_circle_outline, color: AppTheme.primaryColor),
                                  onPressed: () {
                                    final cur = int.tryParse(_customDurationController.text) ?? 30;
                                    if (cur > 5) {
                                      final next = cur - 5;
                                      setState(() {
                                        _selectedDuration = next;
                                        _customDurationController.text = next.toString();
                                      });
                                    }
                                  },
                                ),
                                Expanded(
                                  child: TextField(
                                    controller: _customDurationController,
                                    keyboardType: TextInputType.number,
                                    textAlign: TextAlign.center,
                                    decoration: InputDecoration(
                                      suffixText: 'mins',
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                      isDense: true,
                                    ),
                                    onChanged: (val) {
                                      final parsed = int.tryParse(val);
                                      if (parsed != null && parsed > 0) {
                                        setState(() {
                                          _selectedDuration = parsed;
                                        });
                                      }
                                    },
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.add_circle_outline, color: AppTheme.primaryColor),
                                  onPressed: () {
                                    final cur = int.tryParse(_customDurationController.text) ?? 30;
                                    final next = cur + 5;
                                    setState(() {
                                      _selectedDuration = next;
                                      _customDurationController.text = next.toString();
                                    });
                                  },
                                ),
                                const SizedBox(width: 8),
                                OutlinedButton.icon(
                                  onPressed: () async {
                                    final now = TimeOfDay.now();
                                    final picked = await showTimePicker(
                                      context: context,
                                      initialTime: TimeOfDay(
                                        hour: (now.hour + 1) % 24,
                                        minute: now.minute,
                                      ),
                                    );
                                    if (picked != null) {
                                      final currentDt = DateTime.now();
                                      var targetDt = DateTime(
                                        currentDt.year,
                                        currentDt.month,
                                        currentDt.day,
                                        picked.hour,
                                        picked.minute,
                                      );
                                      if (targetDt.isBefore(currentDt)) {
                                        targetDt = targetDt.add(const Duration(days: 1));
                                      }
                                      final diffMins = targetDt.difference(currentDt).inMinutes;
                                      if (diffMins > 0) {
                                        setState(() {
                                          _selectedDuration = diffMins;
                                          _customDurationController.text = diffMins.toString();
                                        });
                                      }
                                    }
                                  },
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: AppTheme.primaryColor,
                                    side: const BorderSide(color: AppTheme.primaryColor),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                                  ),
                                  icon: const Icon(Icons.access_time_rounded, size: 18),
                                  label: const Text('Pick Closing Time', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    Theme(
                      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                      child: ExpansionTile(
                        tilePadding: EdgeInsets.zero,
                        title: const Text(
                          'Reminder & Notification Preferences',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textSecondary),
                        ),
                        children: [
                          SwitchListTile(
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                            activeThumbColor: AppTheme.primaryColor,
                            title: const Text('Half-Time Reminder Notification', style: TextStyle(fontSize: 13)),
                            value: _enableHalfTime,
                            onChanged: (v) => setState(() => _enableHalfTime = v),
                          ),
                          SwitchListTile(
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                            activeThumbColor: AppTheme.primaryColor,
                            title: const Text('10-Minute Warning Notification', style: TextStyle(fontSize: 13)),
                            value: _enableTenMin,
                            onChanged: (v) => setState(() => _enableTenMin = v),
                          ),
                          SwitchListTile(
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                            activeThumbColor: AppTheme.primaryColor,
                            title: const Text('Ordering Closed Notification', style: TextStyle(fontSize: 13)),
                            value: _enableClosing,
                            onChanged: (v) => setState(() => _enableClosing = v),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: () {
                        final mins = _isCustomDuration
                            ? (int.tryParse(_customDurationController.text) ?? _selectedDuration)
                            : _selectedDuration;
                        if (mins <= 0) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Please specify a valid window duration in minutes.')),
                          );
                          return;
                        }
                        fastFoodProvider.startFastFoodTimer(
                          mins,
                          _enableHalfTime,
                          _enableTenMin,
                          _enableClosing,
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                      ),
                      icon: const Icon(Icons.play_circle_fill_rounded),
                      label: Text(
                        'Open Window For ${_isCustomDuration ? (_customDurationController.text.isNotEmpty ? _customDurationController.text : '$_selectedDuration') : '$_selectedDuration'} Mins',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Menu Items Header & Add Button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Menu Catalog',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
              ),
              TextButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AddEditFastFoodScreen()),
                  );
                },
                icon: const Icon(Icons.add_rounded, color: AppTheme.primaryColor),
                label: const Text('Add Food Item', style: TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Food items list
          if (items.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text('No fast food items configured', style: TextStyle(color: AppTheme.textSecondary)),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, idx) {
                final item = items[idx];
                return Card(
                  elevation: 1.5,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(12),
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        width: 50,
                        height: 50,
                        color: Colors.grey.shade100,
                        child: AppImage(
                          imageUrl: item.imageUrl,
                          width: 50,
                          height: 50,
                          fit: BoxFit.cover,
                          fallbackIcon: Icons.fastfood_rounded,
                        ),
                      ),
                    ),
                    title: Text(item.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    subtitle: Text('₹${item.price.toStringAsFixed(0)} • ${item.category} • ${item.available ? "Available" : "Out of Stock"}'),
                    trailing: IconButton(
                      icon: const Icon(Icons.edit_rounded, color: AppTheme.primaryColor),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => AddEditFastFoodScreen(item: item)),
                        );
                      },
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}
