import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/fast_food_provider.dart';
import '../../providers/admin_provider.dart';
import '../../models/fast_food_item_model.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_textfield.dart';

class AddEditFastFoodScreen extends StatefulWidget {
  final FastFoodItemModel? item;
  const AddEditFastFoodScreen({Key? key, this.item}) : super(key: key);

  @override
  State<AddEditFastFoodScreen> createState() => _AddEditFastFoodScreenState();
}

class _AddEditFastFoodScreenState extends State<AddEditFastFoodScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  final _categoryController = TextEditingController();
  final _priceController = TextEditingController();
  final _imageController = TextEditingController();
  bool _available = true;
  bool _notifyCustomers = true;
  bool _notifyCustomersInitialized = false;

  final List<String> _demoImages = [
    'https://images.unsplash.com/photo-1568901346375-23c9450c58cd?w=400', // Burger
    'https://images.unsplash.com/photo-1513104890138-7c749659a591?w=400', // Pizza
    'https://images.unsplash.com/photo-1576107232684-1279f390859f?w=400', // Fries
    'https://images.unsplash.com/photo-1585032226651-759b368d7246?w=400', // Noodles
  ];
  int _selectedDemoIndex = 0;

  bool get isEdit => widget.item != null;

  @override
  void initState() {
    super.initState();
    if (isEdit) {
      final item = widget.item!;
      _nameController.text = item.name;
      _descController.text = item.description;
      _categoryController.text = item.category;
      _priceController.text = item.price.toStringAsFixed(0);
      _imageController.text = item.imageUrl;
      _available = item.available;

      // Match demo index if matched
      int idx = _demoImages.indexOf(item.imageUrl);
      if (idx != -1) {
        _selectedDemoIndex = idx;
      } else {
        _selectedDemoIndex = -1;
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _categoryController.dispose();
    _priceController.dispose();
    _imageController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (_formKey.currentState!.validate()) {
      final provider = Provider.of<FastFoodProvider>(context, listen: false);

      final imgUrl = _imageController.text.isNotEmpty
          ? _imageController.text.trim()
          : (_selectedDemoIndex != -1 ? _demoImages[_selectedDemoIndex] : '');

      bool success;
      if (isEdit) {
        final updatedItem = widget.item!.copyWith(
          name: _nameController.text.trim(),
          description: _descController.text.trim(),
          category: _categoryController.text.trim(),
          price: double.parse(_priceController.text.trim()),
          imageUrl: imgUrl,
          available: _available,
        );
        success = await provider.updateFastFoodItem(updatedItem, notifyCustomers: _notifyCustomers);
      } else {
        success = await provider.addFastFoodItem(
          name: _nameController.text.trim(),
          description: _descController.text.trim(),
          category: _categoryController.text.trim(),
          price: double.parse(_priceController.text.trim()),
          imageUrl: imgUrl,
          available: _available,
          notifyCustomers: _notifyCustomers,
        );
      }

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isEdit ? 'Food item updated successfully!' : 'Food item added successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(provider.errorMessage ?? 'Operation failed.'),
            backgroundColor: Colors.red.shade600,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<FastFoodProvider>(context);
    final adminProvider = Provider.of<AdminProvider>(context);
    if (!_notifyCustomersInitialized) {
      if (isEdit) {
        _notifyCustomers = false;
      } else {
        _notifyCustomers = adminProvider.sendNotificationOnNewItem;
      }
      _notifyCustomersInitialized = true;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'Edit Food Item' : 'Add Food Item'),
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
                  isEdit ? 'Modify Fast Food Item' : 'New Fast Food Item',
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Fill in the food details. Customers will see these updates instantly.',
                  style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                ),
                const SizedBox(height: 28),

                // Name
                CustomTextField(
                  label: 'Food Name',
                  hint: 'e.g. Double Cheese Burger',
                  controller: _nameController,
                  prefixIcon: Icons.fastfood_rounded,
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) return 'Food name is required.';
                    return null;
                  },
                ),
                const SizedBox(height: 18),

                // Description
                CustomTextField(
                  label: 'Description',
                  hint: 'Enter description (ingredients, spicy level, etc.)',
                  controller: _descController,
                  maxLines: 3,
                  prefixIcon: Icons.description_outlined,
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) return 'Description is required.';
                    return null;
                  },
                ),
                const SizedBox(height: 18),

                // Category
                CustomTextField(
                  label: 'Category',
                  hint: 'e.g. Burgers, Pizzas, Sides',
                  controller: _categoryController,
                  prefixIcon: Icons.category_outlined,
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) return 'Category is required.';
                    return null;
                  },
                ),
                const SizedBox(height: 18),

                // Price
                CustomTextField(
                  label: 'Price (₹)',
                  hint: 'e.g. 120',
                  controller: _priceController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  prefixIcon: Icons.currency_rupee_rounded,
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) return 'Price is required.';
                    if (double.tryParse(val.trim()) == null || double.parse(val.trim()) <= 0) {
                      return 'Enter a valid positive price.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 18),

                // Availability Switch
                Card(
                  elevation: 1,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: SwitchListTile(
                    activeColor: AppTheme.primaryColor,
                    title: const Text('Available for Ordering', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    subtitle: const Text('If disabled, customers will see "Out of Stock".', style: TextStyle(fontSize: 11)),
                    value: _available,
                    onChanged: (val) {
                      setState(() {
                        _available = val;
                      });
                    },
                  ),
                ),
                const SizedBox(height: 24),

                // Demo Images shortcuts
                const Text(
                  'Select Food Image Mockup',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 64,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _demoImages.length,
                    itemBuilder: (context, idx) {
                      final isSelected = _selectedDemoIndex == idx;
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedDemoIndex = idx;
                            _imageController.clear();
                          });
                        },
                        child: Container(
                          width: 64,
                          height: 64,
                          margin: const EdgeInsets.only(right: 10),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isSelected ? AppTheme.primaryColor : Colors.grey.withOpacity(0.3),
                              width: isSelected ? 2.5 : 1,
                            ),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: Image.network(_demoImages[idx], fit: BoxFit.cover),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 18),

                // Custom Image URL
                CustomTextField(
                  label: 'Or Custom Image URL',
                  hint: 'https://example.com/food.jpg',
                  controller: _imageController,
                  prefixIcon: Icons.link,
                ),
                const SizedBox(height: 20),

                // Notify Customers Checkbox
                CheckboxListTile(
                  title: const Text(
                    'Notify Customers',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                  ),
                  subtitle: Text(
                    isEdit
                        ? 'Send a push notification about this food item update to all registered customers.'
                        : 'Send a push notification about this new food item to all registered customers.',
                    style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                  ),
                  value: _notifyCustomers,
                  activeColor: AppTheme.primaryColor,
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                  onChanged: (val) {
                    setState(() {
                      _notifyCustomers = val ?? false;
                    });
                  },
                ),
                const SizedBox(height: 24),

                CustomButton(
                  text: isEdit ? 'SAVE CHANGES' : 'ADD FOOD ITEM',
                  isLoading: provider.isLoading,
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
