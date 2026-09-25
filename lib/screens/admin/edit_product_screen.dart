import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/app_constants.dart';
import '../../core/services/supabase_service.dart';
import '../../constants/demo_images.dart';
import '../../models/product_model.dart';
import '../../providers/product_provider.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_textfield.dart';
import '../../widgets/app_image.dart';
import '../../widgets/demo_image_picker_sheet.dart';

class EditProductScreen extends StatefulWidget {
  final ProductModel product;

  const EditProductScreen({super.key, required this.product});

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
  late bool _isOffer;
  bool _notifyCustomers = false;

  late String _selectedImageUrl;
  late String _selectedImageLabel;
  bool _isUploadingImage = false;

  late TextEditingController _offerLabelController;
  late TextEditingController _offerPriceController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.product.name);
    _priceController = TextEditingController(text: widget.product.price.toStringAsFixed(0));
    _qtyController = TextEditingController(text: widget.product.quantity.toString());
    _descController = TextEditingController(text: widget.product.description);
    _selectedCategory = widget.product.category;
    _selectedUnit = widget.product.unit;
    _available = widget.product.available;
    _isOffer = widget.product.isOffer;

    _offerLabelController = TextEditingController(
      text: widget.product.offerLabel.isNotEmpty ? widget.product.offerLabel : 'OFFER',
    );
    _offerPriceController = TextEditingController(
      text: widget.product.offerPrice != null ? widget.product.offerPrice!.toStringAsFixed(0) : '',
    );

    _selectedImageUrl = widget.product.imageUrl;
    _selectedImageLabel = _selectedImageUrl.startsWith('assets/')
        ? 'Demo Asset Image'
        : (_selectedImageUrl.isNotEmpty ? 'Custom Image' : 'No Image');
    _imageController = TextEditingController(text: widget.product.imageUrl.startsWith('http') ? widget.product.imageUrl : '');
    _imageController.addListener(_onImageUrlChanged);
  }

  void _onImageUrlChanged() {
    final text = _imageController.text.trim();
    if (text.isNotEmpty && text != _selectedImageUrl) {
      setState(() {
        _selectedImageUrl = text;
        _selectedImageLabel = 'Custom URL';
      });
    }
  }

  @override
  void dispose() {
    _imageController.removeListener(_onImageUrlChanged);
    _nameController.dispose();
    _priceController.dispose();
    _qtyController.dispose();
    _imageController.dispose();
    _descController.dispose();
    _offerLabelController.dispose();
    _offerPriceController.dispose();
    super.dispose();
  }

  Future<void> _handleChooseDemoImage() async {
    final selected = await DemoImagePickerSheet.show(
      context,
      items: DemoImages.generalProducts,
      title: 'Choose General Product Demo Image',
      currentSelectedPath: _selectedImageUrl,
    );

    if (selected != null && mounted) {
      setState(() {
        _selectedImageUrl = selected.assetPath;
        _selectedImageLabel = 'Demo: ${selected.name}';
        _imageController.clear();
      });
    }
  }

  Future<void> _handleUploadCustomImage() async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 1024,
      );

      if (pickedFile == null) return;

      setState(() => _isUploadingImage = true);

      final Uint8List bytes = await pickedFile.readAsBytes();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileExtension = pickedFile.name.split('.').last.toLowerCase();
      final path = 'products/prod_$timestamp.$fileExtension';

      final publicUrl = await SupabaseService().uploadImageBytes(
        bucketName: 'product-images',
        path: path,
        bytes: bytes,
        contentType: 'image/$fileExtension',
      );

      if (mounted) {
        setState(() {
          _selectedImageUrl = publicUrl;
          _selectedImageLabel = 'Custom Uploaded Image';
          _imageController.text = publicUrl;
          _isUploadingImage = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Custom image uploaded successfully!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isUploadingImage = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Image upload failed: $e'),
            backgroundColor: Colors.red.shade600,
          ),
        );
      }
    }
  }

  Future<void> _handleDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Product'),
        content: Text('Are you sure you want to permanently delete "${widget.product.name}" from the store inventory?'),
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

    if (confirmed == true && mounted) {
      final productProvider = Provider.of<ProductProvider>(context, listen: false);
      final success = await productProvider.deleteProduct(widget.product.id);
      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Product "${widget.product.name}" deleted successfully.'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(productProvider.errorMessage ?? 'Unable to delete product. Please check your connection or admin permissions.'),
              backgroundColor: Colors.red.shade600,
            ),
          );
        }
      }
    }
  }

  Future<void> _handleUpdate() async {
    if (_formKey.currentState!.validate()) {
      final productProvider = Provider.of<ProductProvider>(context, listen: false);

      double? offerPrice;
      if (_isOffer && _offerPriceController.text.trim().isNotEmpty) {
        offerPrice = double.tryParse(_offerPriceController.text.trim());
      }

      ProductModel updatedProduct = widget.product.copyWith(
        name: _nameController.text.trim(),
        category: _selectedCategory,
        price: double.parse(_priceController.text.trim()),
        quantity: int.parse(_qtyController.text.trim()),
        imageUrl: _selectedImageUrl.trim(),
        description: _descController.text.trim(),
        unit: _selectedUnit,
        available: _available && int.parse(_qtyController.text.trim()) > 0,
        isOffer: _isOffer,
        offerLabel: _offerLabelController.text.trim().isEmpty ? 'OFFER' : _offerLabelController.text.trim(),
        offerPrice: offerPrice,
        clearOfferPrice: !_isOffer || (_offerPriceController.text.trim().isEmpty),
      );

      bool success = await productProvider.updateProduct(updatedProduct, notifyCustomers: _notifyCustomers);

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Product updated successfully!'), backgroundColor: Colors.green),
        );
        Navigator.pop(context);
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(productProvider.errorMessage ?? 'Unable to update product. Please check your connection or admin permissions.'),
            backgroundColor: Colors.red.shade600,
          ),
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
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, color: Colors.red),
            tooltip: 'Delete Product',
            onPressed: productProvider.isLoading ? null : _handleDelete,
          ),
          const SizedBox(width: 8),
        ],
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
                  'Edit stock quantities, descriptions, pricing adjustments, units, or images.',
                  style: TextStyle(fontSize: 12, color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.7)),
                ),
                const SizedBox(height: 28),

                // ========================================================
                // --- PRODUCT IMAGE SECTION (PREVIEW & DEMO/CUSTOM PICKER) ---
                // ========================================================
                Text(
                  'Product Image',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                ),
                const SizedBox(height: 10),

                // Live Image Preview Card
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Column(
                    children: [
                      // Preview Area
                      Container(
                        height: 180,
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
                        ),
                        child: _isUploadingImage
                            ? const Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    CircularProgressIndicator(),
                                    SizedBox(height: 12),
                                    Text('Uploading custom image to Supabase...', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                                  ],
                                ),
                              )
                            : Center(
                                child: AppImage(
                                  imageUrl: _selectedImageUrl,
                                  height: 156,
                                  fit: BoxFit.contain,
                                  fallbackIcon: Icons.add_photo_alternate_outlined,
                                ),
                              ),
                      ),

                      // Info bar below image
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withValues(alpha: 0.06),
                          borderRadius: const BorderRadius.vertical(bottom: Radius.circular(15)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.check_circle_rounded, color: AppTheme.primaryColor, size: 16),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Selected: $_selectedImageLabel',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.primaryColor,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // Action Buttons: [ Choose Demo Image ] OR [ Upload Custom Image ]
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _handleChooseDemoImage,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        icon: const Icon(Icons.collections_rounded, size: 18),
                        label: const Text(
                          'Choose Demo Image',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _isUploadingImage ? null : _handleUploadCustomImage,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.primaryColor,
                          side: const BorderSide(color: AppTheme.primaryColor, width: 1.5),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        icon: const Icon(Icons.cloud_upload_rounded, size: 18),
                        label: const Text(
                          'Upload Custom Image',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Optional Direct URL input
                CustomTextField(
                  label: 'Or Custom Image URL (Optional)',
                  hint: 'https://images.com/my-photo.jpg',
                  controller: _imageController,
                  prefixIcon: Icons.link_rounded,
                ),
                const SizedBox(height: 24),

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
                            initialValue: _selectedCategory,
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
                            initialValue: _selectedUnit,
                            decoration: const InputDecoration(
                              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            ),
                            items: ['kg', 'gram', 'litre', 'ml', 'packet', 'piece', 'portion'].map((u) {
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
                const SizedBox(height: 20),

                // ========================================================
                // --- SPECIAL OFFER & HIGHLIGHT SETTINGS ---
                // ========================================================
                Container(
                  decoration: BoxDecoration(
                    color: _isOffer ? Colors.orange.shade50.withValues(alpha: 0.5) : Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: _isOffer ? Colors.orange.shade300 : Colors.grey.shade300,
                      width: _isOffer ? 1.5 : 1.0,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SwitchListTile(
                        activeThumbColor: Colors.orange.shade700,
                        activeTrackColor: Colors.orange.shade200,
                        secondary: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: _isOffer ? Colors.orange.shade100 : Colors.grey.shade200,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.local_fire_department_rounded,
                            color: _isOffer ? Colors.orange.shade700 : Colors.grey.shade600,
                            size: 22,
                          ),
                        ),
                        title: const Text(
                          'Offer Item',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                        subtitle: Text(
                          _isOffer
                              ? 'Highlighted with an eye-catching OFFER badge on customer screens.'
                              : 'Toggle ON to mark and highlight this product as a special offer.',
                          style: TextStyle(fontSize: 12, color: _isOffer ? Colors.orange.shade900 : AppTheme.textSecondary),
                        ),
                        value: _isOffer,
                        onChanged: (val) {
                          setState(() {
                            _isOffer = val;
                          });
                        },
                      ),
                      if (_isOffer) ...[
                        const Divider(height: 1),
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Live Badge Preview
                              Row(
                                children: [
                                  const Text(
                                    'Badge Preview:',
                                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textSecondary),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [Colors.orange.shade700, Colors.deepOrange.shade600],
                                      ),
                                      borderRadius: BorderRadius.circular(20),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.deepOrange.withValues(alpha: 0.3),
                                          blurRadius: 4,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Text('🔥 ', style: TextStyle(fontSize: 11)),
                                        Text(
                                          (_offerLabelController.text.trim().isEmpty ? 'OFFER' : _offerLabelController.text.trim()).toUpperCase(),
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 11,
                                            fontWeight: FontWeight.w900,
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 14),

                              // Offer badge text input
                              CustomTextField(
                                label: 'Offer Title / Badge Text (Optional)',
                                hint: 'e.g. OFFER, HOT DEAL, 20% OFF',
                                controller: _offerLabelController,
                                prefixIcon: Icons.discount_rounded,
                                onChanged: (val) => setState(() {}),
                              ),
                              const SizedBox(height: 14),

                              // Optional Offer Price input
                              CustomTextField(
                                label: 'Offer Price (₹) (Optional)',
                                hint: 'e.g. Discounted price (leave empty to keep regular price)',
                                controller: _offerPriceController,
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                prefixIcon: Icons.sell_rounded,
                                validator: (val) {
                                  if (val != null && val.trim().isNotEmpty) {
                                    final parsed = double.tryParse(val.trim());
                                    if (parsed == null) return 'Invalid number.';
                                    if (parsed <= 0) return 'Offer price must be > 0.';
                                  }
                                  return null;
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Product Status Toggle
                Card(
                  elevation: 1,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: SwitchListTile(
                    activeThumbColor: AppTheme.primaryColor,
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
                  isLoading: productProvider.isLoading || _isUploadingImage,
                  onPressed: _handleUpdate,
                ),
                const SizedBox(height: 12),

                // Delete Product Button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: OutlinedButton.icon(
                    onPressed: (productProvider.isLoading || _isUploadingImage) ? null : _handleDelete,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: BorderSide(color: Colors.red.shade300, width: 1.5),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: const Icon(Icons.delete_forever_rounded, size: 20),
                    label: const Text(
                      'DELETE PRODUCT',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 0.5),
                    ),
                  ),
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
