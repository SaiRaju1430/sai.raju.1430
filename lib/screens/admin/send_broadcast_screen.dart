import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/admin_provider.dart';
import '../../providers/fast_food_provider.dart';
import '../../core/services/whatsapp_service.dart';
import '../../core/services/firebase_service.dart';
import '../../models/user_model.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_textfield.dart';

class SendBroadcastScreen extends StatefulWidget {
  final String? targetCustomerId;
  final String? targetCustomerName;
  final String? targetCustomerMobile;

  const SendBroadcastScreen({
    Key? key,
    this.targetCustomerId,
    this.targetCustomerName,
    this.targetCustomerMobile,
  }) : super(key: key);

  @override
  State<SendBroadcastScreen> createState() => _SendBroadcastScreenState();
}

class _SendBroadcastScreenState extends State<SendBroadcastScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  bool _isLoading = false;
  String? _selectedTemplateLabel = 'Custom';

  String _targetType = 'all'; // 'all' or 'specific'
  List<UserModel> _users = [];
  UserModel? _selectedUser;
  bool _loadingUsers = false;

  final List<Map<String, String>> _templates = [
    {
      'label': 'Delivery Delay',
      'title': 'Delivery Delay Alert ⏳',
      'content': 'Due to heavy rain or high demand, deliveries may be delayed by 30 minutes. We apologize for the delay.',
    },
    {
      'label': 'Out Of Stock',
      'title': 'Item Unavailable 📦',
      'content': 'Some products in your order are currently unavailable. We will contact you shortly to coordinate replacements.',
    },
    {
      'label': 'Order Processing',
      'title': 'Preparing Your Order 🍔',
      'content': 'We have confirmed your order and are currently preparing it. It will be out for delivery soon.',
    },
    {
      'label': 'Temporary Issue',
      'title': 'CampusKart Status 🚫',
      'content': 'CampusKart is temporarily unable to deliver orders tonight. Active orders will be resolved or rescheduled tomorrow.',
    },
    {
      'label': 'Custom',
      'title': '',
      'content': '',
    },
  ];

  @override
  void initState() {
    super.initState();
    if (widget.targetCustomerId != null) {
      _targetType = 'specific';
    } else {
      _loadUsers();
    }
  }

  Future<void> _loadUsers() async {
    setState(() => _loadingUsers = true);
    try {
      final list = await FirebaseService().getAllUsers();
      setState(() {
        _users = list.where((u) => u.role == 'customer').toList();
        if (_users.isNotEmpty) {
          _selectedUser = _users.first;
        }
      });
    } catch (e) {
      print('Failed to load users: $e');
    } finally {
      setState(() => _loadingUsers = false);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  void _applyTemplate(Map<String, String> template) {
    setState(() {
      _selectedTemplateLabel = template['label'];
      _titleController.text = template['title'] ?? '';
      _contentController.text = template['content'] ?? '';
    });
  }

  bool _isOrderActive(String status) {
    final s = status.trim().toLowerCase();
    return s != 'delivered' && s != 'rejected' && s != 'cancelled';
  }

  List<Map<String, String>> _getActiveCustomers() {
    final adminProvider = Provider.of<AdminProvider>(context, listen: false);
    final fastFoodProvider = Provider.of<FastFoodProvider>(context, listen: false);
    
    final Map<String, String> customers = {}; // mobile -> name

    // General Orders
    for (var order in adminProvider.allOrders) {
      if (_isOrderActive(order.status)) {
        customers[order.customerMobile] = order.customerName;
      }
    }

    // Fast Food Orders
    for (var order in fastFoodProvider.allOrders) {
      if (_isOrderActive(order.status)) {
        customers[order.mobile] = order.customerName;
      }
    }

    // Personal Requests
    for (var req in adminProvider.allRequests) {
      if (_isOrderActive(req.status)) {
        customers[req.customerMobile] = req.customerName;
      }
    }

    return customers.entries.map((e) => {'mobile': e.key, 'name': e.value}).toList();
  }

  Future<void> _handleSendMessage() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final title = _titleController.text.trim();
    final content = _contentController.text.trim();

    try {
      if (widget.targetCustomerId != null) {
        // Individual customer message (target locked by route)
        await FirebaseService().sendNotification(
          title: title,
          message: content,
          targetUserId: widget.targetCustomerId!,
        );

        if (widget.targetCustomerMobile != null) {
          // Open WhatsApp immediately
          await WhatsAppService.sendMessage(
            mobile: widget.targetCustomerMobile!,
            message: content,
          );
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Message sent in-app & WhatsApp redirect opened!'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context);
        }
      } else {
        // Broadcast message to All Users or Specific User
        if (_targetType == 'all') {
          await FirebaseService().sendNotification(
            title: title,
            message: content,
            targetUserId: null,
          );
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Broadcast sent to all users!'),
                backgroundColor: Colors.green,
              ),
            );
            Navigator.pop(context);
          }
        } else {
          if (_selectedUser == null) {
            throw Exception('Please select a recipient customer.');
          }
          await FirebaseService().sendNotification(
            title: title,
            message: content,
            targetUserId: _selectedUser!.uid,
          );
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Message sent to ${_selectedUser!.name}!'),
                backgroundColor: Colors.green,
              ),
            );
            Navigator.pop(context);
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }


  @override
  Widget build(BuildContext context) {
    final isIndividual = widget.targetCustomerId != null;
    final activeCustomers = isIndividual ? [] : _getActiveCustomers();

    return Scaffold(
      appBar: AppBar(
        title: Text(isIndividual ? 'Send Direct Message' : 'Send Broadcast Message'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Info Banner
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isIndividual ? Colors.blue.shade50 : Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: isIndividual ? Colors.blue.shade100 : Colors.orange.shade100),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isIndividual ? Icons.person_outline_rounded : Icons.campaign_rounded,
                        color: isIndividual ? Colors.blue.shade800 : Colors.orange.shade800,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isIndividual ? 'Recipient Customer:' : 'Targeting Active Customers:',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: isIndividual ? Colors.blue.shade900 : Colors.orange.shade900,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              isIndividual
                                  ? '${widget.targetCustomerName} (${widget.targetCustomerMobile})'
                                  : '${activeCustomers.length} active orders pending delivery right now.',
                              style: TextStyle(
                                fontSize: 12,
                                color: isIndividual ? Colors.blue.shade800 : Colors.orange.shade800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                if (!isIndividual) ...[
                  const Text(
                    'Target Audience',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: RadioListTile<String>(
                          title: const Text('All Users', style: TextStyle(fontSize: 14)),
                          value: 'all',
                          groupValue: _targetType,
                          activeColor: AppTheme.primaryColor,
                          contentPadding: EdgeInsets.zero,
                          onChanged: (val) {
                            setState(() => _targetType = val!);
                          },
                        ),
                      ),
                      Expanded(
                        child: RadioListTile<String>(
                          title: const Text('Specific User', style: TextStyle(fontSize: 14)),
                          value: 'specific',
                          groupValue: _targetType,
                          activeColor: AppTheme.primaryColor,
                          contentPadding: EdgeInsets.zero,
                          onChanged: (val) {
                            setState(() => _targetType = val!);
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (_targetType == 'specific') ...[
                    const Text(
                      'Select Recipient Customer',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _loadingUsers
                        ? const Center(child: CircularProgressIndicator())
                        : Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<UserModel>(
                                value: _selectedUser,
                                isExpanded: true,
                                icon: const Icon(Icons.arrow_drop_down, color: AppTheme.primaryColor),
                                items: _users.map((user) {
                                  return DropdownMenuItem<UserModel>(
                                    value: user,
                                    child: Text('${user.name} (${user.mobile})'),
                                  );
                                }).toList(),
                                onChanged: (user) {
                                  setState(() => _selectedUser = user);
                                },
                              ),
                            ),
                          ),
                    const SizedBox(height: 24),
                  ],
                ],

                // Quick Templates
                const Text(
                  'Quick Message Templates',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _templates.map((temp) {
                    final isSelected = _selectedTemplateLabel == temp['label'];
                    return ChoiceChip(
                      label: Text(temp['label']!),
                      selected: isSelected,
                      selectedColor: AppTheme.primaryColor.withOpacity(0.15),
                      labelStyle: TextStyle(
                        color: isSelected ? AppTheme.primaryColor : AppTheme.textSecondary,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                      onSelected: (_) => _applyTemplate(temp),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),

                // Form Fields
                CustomTextField(
                  label: 'Message Title',
                  hint: 'Enter alert title (e.g. Delivery Delay)',
                  controller: _titleController,
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) return 'Message title is required.';
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                CustomTextField(
                  label: 'Message Content',
                  hint: 'Enter message description details here...',
                  controller: _contentController,
                  maxLines: 4,
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) return 'Message description is required.';
                    return null;
                  },
                ),
                const SizedBox(height: 36),

                // Send Trigger
                CustomButton(
                  text: isIndividual 
                      ? 'SEND DIRECT MESSAGE' 
                      : (_targetType == 'all' ? 'SEND TO ALL USERS' : 'SEND TO CUSTOMER'),
                  isLoading: _isLoading,
                  onPressed: _handleSendMessage,
                ),
                const SizedBox(height: 16),
                Center(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
                      'CANCEL',
                      style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
