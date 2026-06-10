import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/order_provider.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_textfield.dart';
import 'order_success_screen.dart';

class PersonalOrderScreen extends StatefulWidget {
  const PersonalOrderScreen({Key? key}) : super(key: key);

  @override
  State<PersonalOrderScreen> createState() => _PersonalOrderScreenState();
}

class _PersonalOrderScreenState extends State<PersonalOrderScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descController = TextEditingController();
  final _blockController = TextEditingController();
  final _roomController = TextEditingController();

  @override
  void dispose() {
    _descController.dispose();
    _blockController.dispose();
    _roomController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (_formKey.currentState!.validate()) {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final orderProvider = Provider.of<OrderProvider>(context, listen: false);

      bool success = await orderProvider.submitPersonalRequest(
        customerId: auth.user!.uid,
        customerName: auth.user!.name,
        customerMobile: auth.user!.mobile,
        blockName: _blockController.text.trim(),
        roomNumber: _roomController.text.trim(),
        description: _descController.text.trim(),
      );

      if (success && mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const OrderSuccessScreen(isPersonal: true)),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(orderProvider.errorMessage ?? 'Submission failed.'),
            backgroundColor: Colors.red.shade600,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final orderProvider = Provider.of<OrderProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Custom Request'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Custom Hostel Delivery',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Need something specific? Describe the items you need and our delivery person will bring it directly to your room.',
                  style: TextStyle(fontSize: 13, color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7), height: 1.4),
                ),
                const SizedBox(height: 32),

                // Hostel details
                Row(
                  children: [
                    Expanded(
                      child: CustomTextField(
                        label: 'Hostel Block',
                        hint: 'e.g. Block A',
                        controller: _blockController,
                        prefixIcon: Icons.apartment_rounded,
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) return 'Block is required.';
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: CustomTextField(
                        label: 'Room Number',
                        hint: 'e.g. 302',
                        controller: _roomController,
                        prefixIcon: Icons.room_rounded,
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) return 'Room number is required.';
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Description Box
                CustomTextField(
                  label: 'Describe your Request',
                  hint: 'e.g. 1x Colgate Total Paste (150g), 2x Nataraj Blue Pens. Please get it from the corner pharmacy.',
                  controller: _descController,
                  maxLines: 4,
                  prefixIcon: Icons.edit_note_rounded,
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) return 'Please describe the delivery request.';
                    return null;
                  },
                ),
                const SizedBox(height: 40),

                // Submit Button
                CustomButton(
                  text: 'SUBMIT REQUEST',
                  isLoading: orderProvider.isLoading,
                  onPressed: _handleSubmit,
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
