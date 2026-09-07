import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/services/supabase_service.dart';
import '../../constants/demo_images.dart';
import '../../providers/fast_food_provider.dart';
import '../../providers/admin_provider.dart';
import '../../models/fast_food_item_model.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_textfield.dart';
import '../../widgets/app_image.dart';
import '../../widgets/demo_image_picker_sheet.dart';

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

  late String _selectedImageUrl;
  late String _selectedImageLabel;
  bool _isUploadingImage = false;

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
      _available = item.available;

      _selectedImageUrl = item.imageUrl;
      _selectedImageLabel = _selectedImageUrl.startsWith('assets/')
          ? 'Demo Asset Image'
          : (_selectedImageUrl.isNotEmpty ? 'Custom Image' : 'No Image');
      _imageController.text = item.imageUrl.startsWith('http') ? item.imageUrl : '';
    } else {
      _selectedImageUrl = 'assets/demo_fast_food/chicken_fried_rice.png';
      _selectedImageLabel = 'Demo: Chicken Fried Rice';
    }

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
    _descController.dispose();
    _categoryController.dispose();
    _priceController.dispose();
    _imageController.dispose();
    super.dispose();
  }

  Future<void> _handleChooseDemoImage() async {
    final selected = await DemoImagePickerSheet.show(
      context,
      items: DemoImages.fastFood,
      title: 'Choose Fast Food Demo Image',
      currentSelectedPath: _selectedImageUrl,
    );

    if (selected != null && mounted) {
      setState(() {
        _selectedImageUrl = selected.assetPath;
        _selectedImageLabel = 'Demo: ${selected.name}';
        _imageController.clear();

        // Convenience: Auto-populate if fields are empty
        if (_nameController.text.trim().isEmpty) {
          _nameController.text = selected.name;
        }
        if (_descController.text.trim().isEmpty) {
          _descController.text = selected.defaultDescription;
        }
        if (_categoryController.text.trim().isEmpty) {
          _categoryController.text = selected.category;
        }
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
      final path = 'fast_food/ff_${timestamp}.$fileExtension';

      final publicUrl = await SupabaseService().uploadImageBytes(
        bucketName: 'fast-food-images',
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
            content: Text('Custom fast food image uploaded successfully!'),
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

  Future<void> _handleSubmit() async {
    if (_selectedImageUrl.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select or upload a food image.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_formKey.currentState!.validate()) {
      final provider = Provider.of<FastFoodProvider>(context, listen: false);

      bool success;
      if (isEdit) {
        final updatedItem = widget.item!.copyWith(
          name: _nameController.text.trim(),
          description: _descController.text.trim(),
          category: _categoryController.text.trim(),
          price: double.parse(_priceController.text.trim()),
          imageUrl: _selectedImageUrl.trim(),
          available: _available,
        );
        success = await provider.updateFastFoodItem(updatedItem, notifyCustomers: _notifyCustomers);
      } else {
        success = await provider.addFastFoodItem(
          name: _nameController.text.trim(),
          description: _descController.text.trim(),
          category: _categoryController.text.trim(),
          price: double.parse(_priceController.text.trim()),
          imageUrl: _selectedImageUrl.trim(),
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
                  'Fill in the food details and select demo or custom photo. Customers will see these updates instantly.',
                  style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                ),
                const SizedBox(height: 28),

                // ========================================================
                // --- FOOD IMAGE SECTION (PREVIEW & DEMO/CUSTOM PICKER) ---
                // ========================================================
                const Text(
                  'Food Image',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
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
                                  fallbackIcon: Icons.fastfood_rounded,
                                ),
                              ),
                      ),

                      // Info bar below image
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withOpacity(0.06),
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
                  hint: 'https://images.com/my-food.jpg',
                  controller: _imageController,
                  prefixIcon: Icons.link_rounded,
                ),
                const SizedBox(height: 24),

                // Name
                CustomTextField(
                  label: 'Food Name',
                  hint: 'e.g. Chicken Fried Rice',
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
                  hint: 'e.g. Fried Rice, Noodles, Sides',
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
                  isLoading: provider.isLoading || _isUploadingImage,
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
