import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/app_constants.dart';
import '../../models/product_model.dart';
import '../../providers/product_provider.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_textfield.dart';

class EditProductScreen extends StatefulWidget {
  final ProductModel product;

  const EditProductScreen({Key? key, required this.product}) : super(key: key);

  @override
  State<EditProductScreen> createState() => _EditProductScreenState();
}

class _EditProductScreenState extends State<EditProductScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _priceController;
  late TextEditingController _qtyController;
  late TextEditingController _imageController;
  late TextEditingController _descController;

  late String _selectedCategory;
  late String _selectedUnit;
  late bool _available;
  bool _notifyCustomers = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.product.name);
    _priceController = TextEditingController(text: widget.product.price.toStringAsFixed(0));
    _qtyController = TextEditingController(text: widget.product.quantity.toString());
    _imageController = TextEditingController(text: widget.product.imageUrl);
    _descController = TextEditingController(text: widget.product.description);
    _selectedCategory = widget.product.category;
    _selectedUnit = widget.product.unit;
    _available = widget.product.available;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _qtyController.dispose();
    _imageController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _handleUpdate() async {
    if (_formKey.currentState!.validate()) {
      final productProvider = Provider.of<ProductProvider>(context, listen: false);

      ProductModel updatedProduct = widget.product.copyWith(
        name: _nameController.text.trim(),
        category: _selectedCategory,
        price: double.parse(_priceController.text.trim()),
        quantity: int.parse(_qtyController.text.trim()),
        imageUrl: _imageController.text.trim(),
        description: _descController.text.trim(),
        unit: _selectedUnit,
        available: _available && int.parse(_qtyController.text.trim()) > 0,
      );

      bool success = await productProvider.updateProduct(updatedProduct, notifyCustomers: _notifyCustomers);

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Product updated successfully!'), backgroundColor: Colors.green),
        );
        Navigator.pop(context);
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(productProvider.errorMessage ?? 'Update failed.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final productProvider = Provider.of<ProductProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Product'),
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
                  'Update Stock Details',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Theme.of(context).textTheme.bodyLarge?.color),
                ),
                const SizedBox(height: 6),
                Text(
                  'Edit stock quantities, descriptions, pricing adjustments, or units.',
                  style: TextStyle(fontSize: 12, color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7)),
                ),
                const SizedBox(height: 32),

                // Name
                CustomTextField(
                  label: 'Product Name',
                  hint: 'e.g. Tomato Brand',
                  controller: _nameController,
                  prefixIcon: Icons.shopping_basket_rounded,
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) return 'Product name is required.';
                    return null;
                  },
                ),
                const SizedBox(height: 18),

                // Row for Category & Unit dropdowns
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

                // Price and Quantity
                Row(
                  children: [
                    Expanded(
                      child: CustomTextField(
                        label: 'Price (₹)',
                        hint: 'e.g. 50',
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
                        hint: 'e.g. 10',
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
                const SizedBox(height: 18),

                // Custom Image URL Field
                CustomTextField(
                  label: 'Product Image URL',
                  hint: 'https://images.com/my-image.jpg',
                  controller: _imageController,
                  prefixIcon: Icons.image_rounded,
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) return 'Image link is required.';
                    return null;
                  },
                ),
                const SizedBox(height: 24),

                // Product Status Toggle
                Card(
                  elevation: 1,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: SwitchListTile(
                    activeColor: AppTheme.primaryColor,
                    secondary: const Icon(Icons.check_circle_outline_rounded, color: AppTheme.primaryColor),
                    title: const Text('Store Availability Status', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    subtitle: const Text('Toggle to immediately hide/show this item in storefront.', style: TextStyle(fontSize: 11)),
                    value: _available,
                    onChanged: (val) {
                      setState(() {
                        _available = val;
                      });
                    },
                  ),
                ),
                const SizedBox(height: 20),

                // Notify Customers Checkbox
                CheckboxListTile(
                  title: const Text(
                    'Notify Customers of Edit',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                  ),
                  subtitle: const Text(
                    'Send a push notification about this product update to all registered customers.',
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
                  text: 'UPDATE PRODUCT',
                  isLoading: productProvider.isLoading,
                  onPressed: _handleUpdate,
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
