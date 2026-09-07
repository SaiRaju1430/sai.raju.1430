import 'dart:async';
import 'package:flutter/material.dart';
import '../models/product_model.dart';
import '../core/services/supabase_service.dart';

class ProductProvider extends ChangeNotifier {
  final SupabaseService _db = SupabaseService();
  
  List<ProductModel> _products = [];
  bool _isLoading = false;
  String? _errorMessage;
  StreamSubscription<List<ProductModel>>? _productsSubscription;

  List<ProductModel> get products => _products;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  ProductProvider() {
    initProductStream();
  }

  void initProductStream() {
    _isLoading = true;
    _productsSubscription?.cancel();
    _productsSubscription = _db.streamProducts().listen(
      (items) {
        _products = items;
        _isLoading = false;
        notifyListeners();
      },
      onError: (error) {
        _errorMessage = error.toString();
        _isLoading = false;
        notifyListeners();
      }
    );
  }

  List<ProductModel> getProductsByCategory(String category) {
    return _products.where((p) => p.category.toLowerCase() == category.toLowerCase()).toList();
  }

  Future<bool> addProduct({
    required String name,
    required String category,
    required double price,
    required int quantity,
    required String imageUrl,
    required String description,
    required String unit,
    bool notifyCustomers = false,
  }) async {
    if (name.trim().isEmpty || category.trim().isEmpty || price <= 0 || quantity < 0) {
      _errorMessage = 'Please provide valid product details.';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    notifyListeners();

    try {
      final productId = await _db.addProduct(name, category, price, quantity, imageUrl, description, unit);
      if (notifyCustomers) {
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final docId = 'general_prod_${productId}_$timestamp';
        await _db.sendTimerNotification(
          notificationId: docId,
          title: '🛒 New Product Added',
          message: '$name is now available in CampusKart. Order now before stock runs out.',
          type: 'new_item',
          imageUrl: imageUrl.isNotEmpty ? imageUrl : null,
          productId: productId,
          productType: 'general',
        );
      }
      _isLoading = false;
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateProduct(ProductModel product, {bool notifyCustomers = false}) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _db.updateProduct(product);
      if (notifyCustomers) {
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final docId = 'general_prod_${product.id}_$timestamp';
        await _db.sendTimerNotification(
          notificationId: docId,
          title: '🛒 New Product Added',
          message: '${product.name} is now available in CampusKart. Order now before stock runs out.',
          type: 'new_item',
          imageUrl: product.imageUrl.isNotEmpty ? product.imageUrl : null,
          productId: product.id,
          productType: 'general',
        );
      }
      _isLoading = false;
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteProduct(String productId) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _db.deleteProduct(productId);
      _isLoading = false;
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  @override
  void dispose() {
    _productsSubscription?.cancel();
    super.dispose();
  }
}
