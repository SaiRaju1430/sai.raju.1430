import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/app_constants.dart';
import '../../providers/product_provider.dart';
import '../../providers/admin_provider.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_textfield.dart';

class AddProductScreen extends StatefulWidget {
  const AddProductScreen({Key? key}) : super(key: key);

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final _formKey = GlobalKey<FormState>();
  
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _qtyController = TextEditingController();
  final _imageController = TextEditingController();
  final _descController = TextEditingController();

  String _selectedCategory = AppConstants.categories.first;
  String _selectedUnit = 'kg';
  bool _notifyCustomers = true;
  bool _notifyCustomersInitialized = false;

  // Curated premium images matching our catalog for quick demo populating
  final List<String> _demoImages = [
    'https://images.unsplash.com/photo-1595855759920-86582396756a?w=400', // Veg
    'https://images.unsplash.com/photo-1560806887-1e4cd0b6cbd6?w=400', // Fruit
    'https://images.unsplash.com/photo-1586201375761-83865001e31c?w=400', // Grocery
    'https://images.unsplash.com/photo-1566478989037-eec170784d0b?w=400', // Snack
    'https://images.unsplash.com/photo-1531346878377-a5be20888e57?w=400', // Stationery
    'https://images.unsplash.com/photo-1589985270826-4b7bb135bc9d?w=400', // Dairy
  ];
  int _selectedDemoIndex = 2;

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _qtyController.dispose();
    _imageController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (_formKey.currentState!.validate()) {
      final productProvider = Provider.of<ProductProvider>(context, listen: false);

      final imgUrl = _imageController.text.isNotEmpty 
          ? _imageController.text.trim()
          : _demoImages[_selectedDemoIndex];

      bool success = await productProvider.addProduct(
        name: _nameController.text.trim(),
        category: _selectedCategory,
        price: double.parse(_priceController.text.trim()),
        quantity: int.parse(_qtyController.text.trim()),
        imageUrl: imgUrl,
        description: _descController.text.trim(),
        unit: _selectedUnit,
        notifyCustomers: _notifyCustomers,
      );

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Product added successfully!'), backgroundColor: Colors.green),
        );
        Navigator.pop(context);
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(productProvider.errorMessage ?? 'Failed to add product.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final productProvider = Provider.of<ProductProvider>(context);
    final adminProvider = Provider.of<AdminProvider>(context);
    if (!_notifyCustomersInitialized) {
      _notifyCustomers = adminProvider.sendNotificationOnNewItem;
      _notifyCustomersInitialized = true;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Product'),
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
                  'Catalog Creation Form',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Theme.of(context).textTheme.bodyLarge?.color),
                ),
                const SizedBox(height: 6),
                Text(
                  'Add a new product item with descriptions and custom e-commerce units.',
                  style: TextStyle(fontSize: 12, color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7)),
                ),
                const SizedBox(height: 32),

                // Product Name
                CustomTextField(
                  label: 'Product Name',
                  hint: 'e.g. Fresh Red Tomatoes',
                  controller: _nameController,
                  prefixIcon: Icons.shopping_basket_rounded,
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) return 'Product name is required.';
                    return null;
                  },
                ),
                const SizedBox(height: 18),

                // Row for Category & Unit Dropdown Selection
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Category',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Theme.of(context).textTheme.bodyLarge?.color),
                          ),
                          const SizedBox(height: 6),
                          DropdownButtonFormField<String>(
                            value: _selectedCategory,
                            decoration: const InputDecoration(
                              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            ),
                            items: AppConstants.categories.map((cat) {
                              return DropdownMenuItem<String>(
                                value: cat,
                                child: Text(cat, style: const TextStyle(fontSize: 13)),
                              );
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) {
                                setState(() {
                                  _selectedCategory = val;
                                  // Auto-adjust default unit based on selected category
                                  if (val == 'Vegetables' || val == 'Fruits') {
                                    _selectedUnit = 'kg';
                                  } else if (val == 'Dairy') {
                                    _selectedUnit = 'litre';
                                  } else if (val == 'Snacks') {
                                    _selectedUnit = 'packet';
                                  } else if (val == 'Stationery') {
                                    _selectedUnit = 'piece';
                                  }
                                });
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Unit',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Theme.of(context).textTheme.bodyLarge?.color),
                          ),
                          const SizedBox(height: 6),
                          DropdownButtonFormField<String>(
                            value: _selectedUnit,
                            decoration: const InputDecoration(
                              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            ),
                            items: ['kg', 'gram', 'litre', 'ml', 'packet', 'piece'].map((u) {
                              return DropdownMenuItem<String>(
                                value: u,
                                child: Text(u, style: const TextStyle(fontSize: 13)),
                              );
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) {
                                setState(() {
                                  _selectedUnit = val;
                                });
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),

                // Description field
                CustomTextField(
                  label: 'Product Description',
                  hint: 'Enter detailed information about the product...',
                  controller: _descController,
                  maxLines: 3,
                  prefixIcon: Icons.description_rounded,
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) return 'Product description is required.';
                    return null;
                  },
                ),
                const SizedBox(height: 18),

                // Row for Price & Qty
                Row(
                  children: [
                    Expanded(
                      child: CustomTextField(
                        label: 'Price (₹)',
                        hint: 'e.g. 30',
                        controller: _priceController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        prefixIcon: Icons.currency_rupee_rounded,
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) return 'Required.';
                          if (double.tryParse(val.trim()) == null) return 'Invalid number.';
                          if (double.parse(val.trim()) <= 0) return 'Must be > 0.';
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: CustomTextField(
                        label: 'Stock Quantity',
                        hint: 'e.g. 50',
                        controller: _qtyController,
                        keyboardType: TextInputType.number,
                        prefixIcon: Icons.inventory_2_rounded,
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) return 'Required.';
                          if (int.tryParse(val.trim()) == null) return 'Invalid integer.';
                          if (int.parse(val.trim()) < 0) return 'Must be >= 0.';
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Demo Images shortcuts
                Text(
                  'Choose Simulated Demo Image',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Theme.of(context).textTheme.bodyLarge?.color),
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

                // Custom Image URL Field
                CustomTextField(
                  label: 'Or Custom Image URL',
                  hint: 'https://images.com/my-image.jpg',
                  controller: _imageController,
                  prefixIcon: Icons.image_rounded,
                ),
                const SizedBox(height: 20),

                // Notify Customers Checkbox
                CheckboxListTile(
                  title: const Text(
                    'Notify Customers',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                  ),
                  subtitle: const Text(
                    'Send a push notification about this new product to all registered customers.',
                    style: TextStyle(fontSize: 11, color: AppTheme.textSecondary),
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

                // Submit Button
                CustomButton(
                  text: 'ADD TO STORE',
                  isLoading: productProvider.isLoading,
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
