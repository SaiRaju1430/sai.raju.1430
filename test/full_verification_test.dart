// ignore_for_file: avoid_print
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:campuskart/models/product_model.dart';

void main() {
  test(
    'Verify All Product Add & Delete Test Cases (A through J, and Deletion Cases)',
    () async {
      const url = 'https://yelczpeowtvhosvwhzxf.supabase.co';
    const anonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InllbGN6cGVvd3R2aG9zdndoenhmIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODgxNTkyNDEsImV4cCI6MjEwMzczNTI0MX0.p5BRWVDNvAk-Cy6uqTDEY6GxSM5QBV5_qOLiRWreE5E';

    final supabase = SupabaseClient(url, anonKey);

    final authRes = await supabase.auth.signInWithPassword(
      email: '9515639193@campuskart.com',
      password: 'sai@2007',
    );
    expect(authRes.user, isNotNull);

    final List<String> createdProductIds = [];

    // Helper to add and verify product
    Future<ProductModel> addAndVerify({
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
    }) async {
      // 1. Direct Add via payload formatted by ProductModel and inserted into Supabase
      final finalDescription = ProductModel.encodeDescriptionWithOffer(
        description,
        isOffer: isOffer,
        offerLabel: offerLabel,
        offerPrice: offerPrice,
      );

      final insertPayload = {
        'name': name.trim(),
        'category': category.trim(),
        'price': price,
        'quantity': quantity,
        'image_url': imageUrl.trim(),
        'description': finalDescription,
        'unit': unit.trim(),
        'available': quantity > 0,
      };

      final insertRes = await supabase.from('products').insert(insertPayload).select('id').single();
      final id = insertRes['id'].toString();
      expect(id, isNotEmpty);
      createdProductIds.add(id);

      // 2. Fetch from Supabase
      final doc = await supabase.from('products').select().eq('id', id).single();
      expect(doc['id'], equals(id));
      expect(doc['name'], equals(name));
      expect(doc['category'], equals(category));
      expect((doc['price'] as num).toDouble(), equals(price));
      expect(doc['quantity'], equals(quantity));
      expect(doc['image_url'], equals(imageUrl));
      expect(doc['unit'], equals(unit));
      expect(doc['available'], equals(quantity > 0));

      // 3. Parse via ProductModel
      final model = ProductModel.fromMap(doc, id);
      expect(model.id, equals(id));
      expect(model.name, equals(name));
      expect(model.category, equals(category));
      expect(model.price, equals(price));
      expect(model.quantity, equals(quantity));
      expect(model.imageUrl, equals(imageUrl));
      expect(model.description, equals(description));
      expect(model.unit, equals(unit));
      expect(model.available, equals(quantity > 0));
      expect(model.isOffer, equals(isOffer));
      if (isOffer) {
        expect(model.offerLabel, equals(offerLabel));
        expect(model.offerPrice, equals(offerPrice));
      }

      return model;
    }

    // ==========================================
    // SECTION 12: TEST ADD PRODUCT (A through J)
    // ==========================================

    // Case A: Product without image
    final prodA = await addAndVerify(
      name: 'Case A - No Image Product',
      category: 'Stationery',
      price: 15.0,
      quantity: 100,
      imageUrl: '',
      description: 'Standard HB pencil pack',
      unit: 'packet',
    );
    expect(prodA.imageUrl, isEmpty);

    // Case B: Product with custom image
    final customUploadBytes = utf8.encode('fake png content');
    final customPath = 'products/test_custom_${DateTime.now().millisecondsSinceEpoch}.png';
    await supabase.storage.from('product-images').uploadBinary(customPath, customUploadBytes);
    final customUrl = supabase.storage.from('product-images').getPublicUrl(customPath);
    final prodB = await addAndVerify(
      name: 'Case B - Custom Image Product',
      category: 'Dairy',
      price: 35.0,
      quantity: 40,
      imageUrl: customUrl,
      description: 'Fresh toned milk packet',
      unit: 'packet',
    );
    expect(prodB.imageUrl, equals(customUrl));

    // Case C: Product with demo image
    final prodC = await addAndVerify(
      name: 'Case C - Demo Image Product',
      category: 'Vegetables',
      price: 45.0,
      quantity: 30,
      imageUrl: 'assets/demo_products/carrot.png',
      description: 'Organic sweet farm carrots',
      unit: 'kg',
    );
    expect(prodC.imageUrl, equals('assets/demo_products/carrot.png'));

    // Case D: Normal product
    final prodD = await addAndVerify(
      name: 'Case D - Normal Fresh Apples',
      category: 'Fruits',
      price: 120.0,
      quantity: 50,
      imageUrl: 'assets/demo_products/carrot.png',
      description: 'Crisp Shimla red apples',
      unit: 'kg',
      isOffer: false,
    );
    expect(prodD.isOffer, isFalse);
    expect(prodD.effectivePrice, equals(120.0));

    // Case E: Offer product
    final prodE = await addAndVerify(
      name: 'Case E - Mega Offer Mango Pickle',
      category: 'Snacks',
      price: 80.0,
      quantity: 25,
      imageUrl: 'assets/demo_products/mango_pickle.png',
      description: 'Authentic spicy Andhra mango pickle',
      unit: 'packet',
      isOffer: true,
      offerLabel: 'HOT DEAL - 25% OFF',
      offerPrice: 60.0,
    );
    expect(prodE.isOffer, isTrue);
    expect(prodE.offerLabel, equals('HOT DEAL - 25% OFF'));
    expect(prodE.offerPrice, equals(60.0));
    expect(prodE.effectivePrice, equals(60.0));
    expect(prodE.hasDiscount, isTrue);
    expect(prodE.discountPercentage, equals(25));

    // Case F: Different categories
    final prodF1 = await addAndVerify(
      name: 'Case F1 - Vegetables Category',
      category: 'Vegetables',
      price: 20.0,
      quantity: 15,
      imageUrl: 'assets/demo_products/cucumber.png',
      description: 'Green fresh cucumber',
      unit: 'kg',
    );
    expect(prodF1.category, equals('Vegetables'));

    final prodF2 = await addAndVerify(
      name: 'Case F2 - Snacks Category',
      category: 'Snacks',
      price: 10.0,
      quantity: 80,
      imageUrl: 'assets/demo_products/salt_chips.png',
      description: 'Salted potato chips',
      unit: 'packet',
    );
    expect(prodF2.category, equals('Snacks'));

    // Case G: Different units (kg, litre, gram, piece, packet)
    final prodG1 = await addAndVerify(
      name: 'Case G1 - Litre Unit Product',
      category: 'Dairy',
      price: 60.0,
      quantity: 20,
      imageUrl: 'assets/demo_products/curd.png',
      description: 'Full cream cow milk',
      unit: 'litre',
    );
    expect(prodG1.unit, equals('litre'));

    final prodG2 = await addAndVerify(
      name: 'Case G2 - Piece Unit Product',
      category: 'Stationery',
      price: 5.0,
      quantity: 200,
      imageUrl: '',
      description: 'Blue ball pen',
      unit: 'piece',
    );
    expect(prodG2.unit, equals('piece'));

    // Case H: Different prices (low, high, fractional)
    final prodH1 = await addAndVerify(
      name: 'Case H1 - Low Price Item',
      category: 'Snacks',
      price: 2.0,
      quantity: 100,
      imageUrl: '',
      description: 'Toffee candy',
      unit: 'piece',
    );
    expect(prodH1.price, equals(2.0));

    final prodH2 = await addAndVerify(
      name: 'Case H2 - High Price Item',
      category: 'Snacks',
      price: 999.0,
      quantity: 5,
      imageUrl: '',
      description: 'Bulk dry fruits combo pack',
      unit: 'kg',
    );
    expect(prodH2.price, equals(999.0));

    // Case I: Different stock values
    final prodI1 = await addAndVerify(
      name: 'Case I1 - Single Stock Item',
      category: 'Stationery',
      price: 50.0,
      quantity: 1,
      imageUrl: '',
      description: 'Geometry box',
      unit: 'piece',
    );
    expect(prodI1.quantity, equals(1));
    expect(prodI1.available, isTrue);

    // Case J: Out-of-stock product
    final prodJ = await addAndVerify(
      name: 'Case J - Out of Stock Product',
      category: 'Fruits',
      price: 150.0,
      quantity: 0,
      imageUrl: 'assets/demo_products/grapes.png',
      description: 'Seedless black grapes',
      unit: 'kg',
    );
    expect(prodJ.quantity, equals(0));
    expect(prodJ.available, isFalse);

    // ==========================================
    // SECTION 13: TEST DELETE PRODUCT
    // ==========================================

    // Test deleting normal product
    await supabase.from('products').delete().eq('id', prodD.id);
    final verifyDelD = await supabase.from('products').select().eq('id', prodD.id).maybeSingle();
    expect(verifyDelD, isNull);

    // Test deleting offer product
    await supabase.from('products').delete().eq('id', prodE.id);
    final verifyDelE = await supabase.from('products').select().eq('id', prodE.id).maybeSingle();
    expect(verifyDelE, isNull);

    // Test deleting out-of-stock product
    await supabase.from('products').delete().eq('id', prodJ.id);
    final verifyDelJ = await supabase.from('products').select().eq('id', prodJ.id).maybeSingle();
    expect(verifyDelJ, isNull);

    // Test deleting product with an image
    await supabase.from('products').delete().eq('id', prodC.id);
    final verifyDelC = await supabase.from('products').select().eq('id', prodC.id).maybeSingle();
    expect(verifyDelC, isNull);

    // Test deleting product that has never been ordered
    await supabase.from('products').delete().eq('id', prodA.id);
    final verifyDelA = await supabase.from('products').select().eq('id', prodA.id).maybeSingle();
    expect(verifyDelA, isNull);

    // Test deleting product that has historical orders -> verify historical orders remain safe!
    final historicalProd = await addAndVerify(
      name: 'Historical Order Test Product',
      category: 'Snacks',
      price: 25.0,
      quantity: 10,
      imageUrl: 'assets/demo_products/potato.png',
      description: 'Product with past order',
      unit: 'packet',
    );

    // Create an order referencing this product
    final orderRes = await supabase.from('orders').insert({
      'customer_id': authRes.user!.id,
      'customer_name': 'Historical Customer',
      'customer_mobile': '9515639193',
      'block_name': 'Block C',
      'room_number': '302',
      'subtotal': 25.0,
      'delivery_fee': 0.0,
      'total': 25.0,
      'payment_id': 'HIST_TEST_001',
      'payment_account_name': 'Hist Acc',
      'payment_mobile_number': '9515639193',
      'verification_code': '9999',
      'status': 'Delivered',
      'delivery_verified': true,
    }).select().single();
    final testOrderId = orderRes['id'].toString();

    final orderItemRes = await supabase.from('order_items').insert({
      'order_id': testOrderId,
      'product_id': historicalProd.id,
      'product_name': historicalProd.name,
      'quantity': 1,
      'price': historicalProd.price,
      'unit': historicalProd.unit,
    }).select().single();
    expect(orderItemRes['id'], isNotNull);

    // Now delete the product
    await supabase.from('products').delete().eq('id', historicalProd.id);
    final verifyHistProdDeleted = await supabase.from('products').select().eq('id', historicalProd.id).maybeSingle();
    expect(verifyHistProdDeleted, isNull);

    // Verify order and order_items still exist with full customer historical order information intact!
    final checkOrder = await supabase.from('orders').select().eq('id', testOrderId).single();
    expect(checkOrder['id'], equals(testOrderId));
    expect(checkOrder['customer_name'], equals('Historical Customer'));
    expect(checkOrder['total'], equals(25.0));

    final checkOrderItems = await supabase.from('order_items').select().eq('order_id', testOrderId);
    expect((checkOrderItems as List).length, equals(1));
    expect(checkOrderItems.first['product_name'], equals('Historical Order Test Product'));
    expect(checkOrderItems.first['price'], equals(25.0));
    expect(checkOrderItems.first['quantity'], equals(1));

    // Clean up remaining test records
    await supabase.from('order_items').delete().eq('order_id', testOrderId);
    await supabase.from('orders').delete().eq('id', testOrderId);

    for (final id in createdProductIds) {
      try {
        await supabase.from('products').delete().eq('id', id);
      } catch (_) {}
    }

    print('ALL 10 ADD CASES (A-J) AND 6 DELETE CASES PASSED WITH 100% SUCCESS!');
  },
  timeout: const Timeout(Duration(minutes: 3)),
);
}
