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
    bool isOffer = false,
    String offerLabel = 'OFFER',
    double? offerPrice,
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
      final productId = await _db.addProduct(
        name,
        category,
        price,
        quantity,
        imageUrl,
        description,
        unit,
        isOffer: isOffer,
        offerLabel: offerLabel,
        offerPrice: offerPrice,
      );
      if (notifyCustomers) {
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final docId = 'general_prod_${productId}_$timestamp';
        final notifTitle = isOffer ? '🔥 Special Offer: $name' : '🛒 New Product Added';
        final notifMsg = isOffer && offerPrice != null && offerPrice < price
            ? '$name is now on special offer for just ₹${offerPrice.toStringAsFixed(0)} (Original ₹${price.toStringAsFixed(0)}). Grab it before stock ends!'
            : '$name is now available in CampusKart. Order now before stock runs out.';
        await _db.sendTimerNotification(
          notificationId: docId,
          title: notifTitle,
          message: notifMsg,
          type: isOffer ? 'deal' : 'new_item',
          imageUrl: imageUrl.isNotEmpty ? imageUrl : null,
          productId: productId,
          productType: 'general',
        );
      }
      _isLoading = false;
      return true;
    } catch (e, stack) {
      debugPrint("CampusKart [ProductProvider] addProduct error: $e\n$stack");
      _errorMessage = "Unable to add product. Please check your connection or admin permissions.";
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
        final notifTitle = product.isOffer ? '🔥 Special Offer: ${product.name}' : '🛒 Product Updated';
        final notifMsg = product.isOffer && product.offerPrice != null && product.offerPrice! < product.price
            ? '${product.name} is now on special offer for just ₹${product.offerPrice!.toStringAsFixed(0)} (Original ₹${product.price.toStringAsFixed(0)}). Order now!'
            : '${product.name} details have been updated in CampusKart. Check it out now.';
        await _db.sendTimerNotification(
          notificationId: docId,
          title: notifTitle,
          message: notifMsg,
          type: product.isOffer ? 'deal' : 'new_item',
          imageUrl: product.imageUrl.isNotEmpty ? product.imageUrl : null,
          productId: product.id,
          productType: 'general',
        );
      }
      _isLoading = false;
      return true;
    } catch (e, stack) {
      debugPrint("CampusKart [ProductProvider] updateProduct error: $e\n$stack");
      _errorMessage = "Unable to update product. Please check your connection or admin permissions.";
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
    } catch (e, stack) {
      debugPrint("CampusKart [ProductProvider] deleteProduct error: $e\n$stack");
      _errorMessage = "Unable to delete product. Please check your connection or admin permissions.";
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
