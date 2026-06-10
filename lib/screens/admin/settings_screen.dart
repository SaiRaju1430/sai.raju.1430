import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/admin_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final admin = Provider.of<AdminProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Store Settings'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Global Adjustments',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
            ),
            const SizedBox(height: 6),
            const Text(
              'Manage store availability rules and live hostel delivery limits.',
              style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 32),

            // Availability Switch Card
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
                          'Store Delivery Status',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        Switch(
                          value: admin.isOwnerAvailable,
                          activeColor: AppTheme.primaryColor,
                          onChanged: (val) {
                            admin.toggleAvailability(val);
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      admin.isOwnerAvailable
                          ? 'Customers are currently allowed to place general orders, search standard catalogs, and submit custom requests.'
                          : 'Orders are currently suspended. The customer application is greyed-out with a notification banner.',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600, height: 1.4),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // New Item Notification Toggle Card
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
                        const Expanded(
                          child: Text(
                            'Send Notification When New Item Added',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                          ),
                        ),
                        Switch(
                          value: admin.sendNotificationOnNewItem,
                          activeColor: AppTheme.primaryColor,
                          onChanged: (val) {
                            admin.toggleSendNotificationOnNewItem(val);
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'When enabled, adding a new general or fast food product will automatically trigger push notifications to all customers.',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600, height: 1.4),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Timings Information Card
            Card(
              elevation: 1,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.schedule_rounded, color: AppTheme.primaryColor),
                        SizedBox(width: 10),
                        Text(
                          'Campus Timings Guidelines',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Monday - Saturday Service Hours:',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: AppTheme.textPrimary),
                    ),
                    const Text('• Standard Rate Shift: 6 PM - 11 PM \n• Urgent Rate Shift: 11 PM - 2 AM', style: TextStyle(fontSize: 11, color: AppTheme.textSecondary, height: 1.5)),
                    const SizedBox(height: 10),
                    const Text(
                      'Sunday Service Shifts (Auto-Blocked Outside):',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: AppTheme.textPrimary),
                    ),
                    const Text('• Morning Shift: 10 AM - 12 PM \n• Evening Shift: 4 PM - 1:30 AM', style: TextStyle(fontSize: 11, color: AppTheme.textSecondary, height: 1.5)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
