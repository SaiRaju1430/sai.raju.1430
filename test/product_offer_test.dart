import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:campuskart/models/product_model.dart';
import 'package:campuskart/providers/order_provider.dart';
import 'package:campuskart/widgets/product_card.dart';
import 'package:campuskart/screens/customer/product_detail_screen.dart';

void main() {
  group('ProductModel Offer & Highlight Tests', () {
    test('Default product has isOffer=false and default offerLabel="OFFER"', () {
      final product = ProductModel(
        id: 'prod_1',
        name: 'Fresh Tomatoes',
        category: 'Vegetables',
        price: 40.0,
        quantity: 20,
        imageUrl: 'assets/demo_products/tomato.png',
        description: 'Fresh local tomatoes',
        unit: 'kg',
        available: true,
        createdDate: DateTime(2026, 1, 1),
      );

      expect(product.isOffer, isFalse);
      expect(product.offerLabel, equals('OFFER'));
      expect(product.offerPrice, isNull);
      expect(product.effectivePrice, equals(40.0));
      expect(product.hasDiscount, isFalse);
      expect(product.discountPercentage, isNull);
    });

    test('Offer product with custom label and discounted offer price', () {
      final product = ProductModel(
        id: 'prod_2',
        name: 'Organic Apples',
        category: 'Fruits',
        price: 100.0,
        quantity: 15,
        imageUrl: 'assets/demo_products/apple.png',
        description: 'Crisp apples',
        unit: 'kg',
        available: true,
        createdDate: DateTime(2026, 1, 1),
        isOffer: true,
        offerLabel: 'HOT DEAL',
        offerPrice: 75.0,
      );

      expect(product.isOffer, isTrue);
      expect(product.offerLabel, equals('HOT DEAL'));
      expect(product.offerPrice, equals(75.0));
      expect(product.effectivePrice, equals(75.0));
      expect(product.hasDiscount, isTrue);
      expect(product.discountPercentage, equals(25));
    });

    test('Serialization and Deserialization (fromMap & toMap)', () {
      final data = {
        'name': 'Crunchy Biscuits',
        'category': 'Snacks',
        'price': 30.0,
        'quantity': 50,
        'imageUrl': 'assets/demo_products/biscuit.png',
        'description': 'Tea time snack',
        'unit': 'packet',
        'available': true,
        'created_at': '2026-02-01T10:00:00.000',
        'is_offer': true,
        'offer_label': 'SPECIAL 20% OFF',
        'offer_price': 24.0,
      };

      final product = ProductModel.fromMap(data, 'prod_3');
      expect(product.id, equals('prod_3'));
      expect(product.name, equals('Crunchy Biscuits'));
      expect(product.isOffer, isTrue);
      expect(product.offerLabel, equals('SPECIAL 20% OFF'));
      expect(product.offerPrice, equals(24.0));
      expect(product.effectivePrice, equals(24.0));

      final map = product.toMap();
      expect(map['is_offer'], isTrue);
      expect(map['offer_label'], equals('SPECIAL 20% OFF'));
      expect(map['offer_price'], equals(24.0));
    });

    test('copyWith updates offer fields or resets them properly', () {
      final initial = ProductModel(
        id: 'prod_4',
        name: 'Milk',
        category: 'Dairy',
        price: 35.0,
        quantity: 10,
        imageUrl: 'assets/demo_products/milk.png',
        description: 'Fresh milk',
        unit: 'litre',
        available: true,
        createdDate: DateTime(2026, 1, 1),
        isOffer: true,
        offerLabel: 'MORNING OFFER',
        offerPrice: 30.0,
      );

      // Turn offer OFF
      final turnedOff = initial.copyWith(isOffer: false, clearOfferPrice: true);
      expect(turnedOff.isOffer, isFalse);
      expect(turnedOff.offerPrice, isNull);
      expect(turnedOff.effectivePrice, equals(35.0));

      // Turn offer back ON with different label
      final turnedOn = turnedOff.copyWith(isOffer: true, offerLabel: 'FLASH SALE', offerPrice: 28.0);
      expect(turnedOn.isOffer, isTrue);
      expect(turnedOn.offerLabel, equals('FLASH SALE'));
      expect(turnedOn.offerPrice, equals(28.0));
      expect(turnedOn.effectivePrice, equals(28.0));
    });
  });

  group('OrderProvider Cart Pricing with Offers', () {
    test('Adding offer product to cart uses effectivePrice', () {
      final orderProvider = OrderProvider();

      final offerProduct = ProductModel(
        id: 'prod_offer_1',
        name: 'Discounted Rice',
        category: 'Grocery',
        price: 60.0,
        quantity: 10,
        imageUrl: 'assets/demo_products/rice.png',
        description: 'Premium rice',
        unit: 'kg',
        available: true,
        createdDate: DateTime.now(),
        isOffer: true,
        offerLabel: 'OFFER',
        offerPrice: 48.0,
      );

      orderProvider.addToCart(offerProduct);

      expect(orderProvider.cart.containsKey('prod_offer_1'), isTrue);
      expect(orderProvider.cart['prod_offer_1']!.price, equals(48.0));
      expect(orderProvider.cartSubtotal, equals(48.0));

      // Normal product without offer
      final normalProduct = ProductModel(
        id: 'prod_norm_1',
        name: 'Sugar',
        category: 'Grocery',
        price: 45.0,
        quantity: 10,
        imageUrl: 'assets/demo_products/sugar.png',
        description: 'Refined sugar',
        unit: 'kg',
        available: true,
        createdDate: DateTime.now(),
        isOffer: false,
      );

      orderProvider.addToCart(normalProduct);
      expect(orderProvider.cart['prod_norm_1']!.price, equals(45.0));
      expect(orderProvider.cartSubtotal, equals(48.0 + 45.0));
    });
  });

  group('Widget Tests: ProductCard and ProductDetailScreen', () {
    testWidgets('Normal product card does NOT show offer badge or highlight border', (tester) async {
      final normalProduct = ProductModel(
        id: 'prod_normal',
        name: 'Fresh Carrots',
        category: 'Vegetables',
        price: 30.0,
        quantity: 10,
        imageUrl: 'assets/demo_products/carrot.png',
        description: 'Crunchy carrots',
        unit: 'kg',
        available: true,
        createdDate: DateTime.now(),
        isOffer: false,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider(
            create: (_) => OrderProvider(),
            child: Scaffold(
              body: SizedBox(
                height: 300,
                width: 200,
                child: ProductCard(product: normalProduct),
              ),
            ),
          ),
        ),
      );

      expect(find.text('Fresh Carrots'), findsOneWidget);
      expect(find.text('₹30 / kg'), findsOneWidget);
      // No 🔥 OFFER badge
      expect(find.textContaining('🔥'), findsNothing);
      expect(find.text('OFFER'), findsNothing);
    });

    testWidgets('Offer product card displays 🔥 OFFER badge, highlight and dual pricing', (tester) async {
      final offerProduct = ProductModel(
        id: 'prod_offer',
        name: 'Juicy Mangoes',
        category: 'Fruits',
        price: 120.0,
        quantity: 10,
        imageUrl: 'assets/demo_products/mango.png',
        description: 'Sweet mangoes',
        unit: 'kg',
        available: true,
        createdDate: DateTime.now(),
        isOffer: true,
        offerLabel: 'HOT DEAL',
        offerPrice: 90.0,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider(
            create: (_) => OrderProvider(),
            child: Scaffold(
              body: SizedBox(
                height: 300,
                width: 200,
                child: ProductCard(product: offerProduct),
              ),
            ),
          ),
        ),
      );

      expect(find.text('Juicy Mangoes'), findsOneWidget);
      // Offer badge
      expect(find.text('HOT DEAL'), findsOneWidget);
      expect(find.textContaining('🔥'), findsOneWidget);
      // Dual pricing
      expect(find.text('₹90'), findsOneWidget);
      expect(find.text('₹120'), findsOneWidget);
    });

    testWidgets('ProductDetailScreen displays offer badge, discount % and strike-through pricing', (tester) async {
      final offerProduct = ProductModel(
        id: 'prod_detail_offer',
        name: 'Green Tea',
        category: 'Snacks',
        price: 200.0,
        quantity: 15,
        imageUrl: 'assets/demo_products/tea.png',
        description: 'Healthy green tea leaves',
        unit: 'packet',
        available: true,
        createdDate: DateTime.now(),
        isOffer: true,
        offerLabel: 'MEGA DEAL',
        offerPrice: 150.0,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider(
            create: (_) => OrderProvider(),
            child: ProductDetailScreen(product: offerProduct),
          ),
        ),
      );

      expect(find.text('Green Tea'), findsWidgets);
      expect(find.text('MEGA DEAL'), findsWidgets);
      expect(find.text('25% OFF'), findsOneWidget);
      expect(find.text('₹150'), findsOneWidget);
      expect(find.text('₹200'), findsOneWidget);
      expect(find.text('/ packet'), findsOneWidget);
    });
  });
}
