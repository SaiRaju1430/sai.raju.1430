import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:campuskart/constants/demo_images.dart';
import 'package:campuskart/widgets/app_image.dart';
import 'package:campuskart/widgets/demo_image_picker_sheet.dart';

void main() {
  group('Demo Images Constants & Catalog Verification', () {
    test('General products catalog contains exactly 17 items with valid properties', () {
      expect(DemoImages.generalProducts.length, 17);

      final expectedNames = [
        'Carrot',
        'Cucumber',
        'Banana',
        'Pomegranate',
        'Orange',
        'Grapes',
        'Curd',
        'Potato',
        'Salt Chips',
        'Banana Chips',
        'Potato Chilli Chips',
        'Cassava Tuber Chips',
        'Cauliflower Pakoda',
        'Mango Pickle',
        'Chicken Pickle',
        'Prawn Pickle',
        'Groundnut Chikki',
      ];

      for (var name in expectedNames) {
        final item = DemoImages.generalProducts.firstWhere(
          (e) => e.name == name,
          orElse: () => throw Exception('Missing expected general demo item: $name'),
        );
        expect(item.assetPath.startsWith('assets/demo_products/'), isTrue);
        expect(item.category.isNotEmpty, isTrue);
        expect(item.defaultUnit.isNotEmpty, isTrue);
        expect(item.defaultDescription.isNotEmpty, isTrue);
      }
    });

    test('Fast food catalog contains exactly 7 items with valid properties', () {
      expect(DemoImages.fastFood.length, 7);

      final expectedFastFood = [
        'Chicken Fried Rice',
        'Egg Fried Rice',
        'Veg Fried Rice',
        'Chicken Noodles',
        'Egg Noodles',
        'Veg Noodles',
        'Chicken Joint',
      ];

      for (var name in expectedFastFood) {
        final item = DemoImages.fastFood.firstWhere(
          (e) => e.name == name,
          orElse: () => throw Exception('Missing expected fast food demo item: $name'),
        );
        expect(item.assetPath.startsWith('assets/demo_fast_food/'), isTrue);
        expect(item.category.isNotEmpty, isTrue);
        expect(item.defaultDescription.isNotEmpty, isTrue);
      }
    });
  });

  group('AppImage Widget Unit & Fallback Tests', () {
    testWidgets('Renders fallback icon when image URL is null or empty', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AppImage(
              imageUrl: '',
              fallbackIcon: Icons.fastfood_rounded,
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.fastfood_rounded), findsOneWidget);
    });

    testWidgets('Renders ClipRRect with specified border radius', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AppImage(
              imageUrl: '',
              borderRadius: BorderRadius.all(Radius.circular(12)),
            ),
          ),
        ),
      );

      expect(find.byType(ClipRRect), findsOneWidget);
    });
  });

  group('DemoImagePickerSheet Search & Selection Tests', () {
    testWidgets('Displays all demo items and filters by search query', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DemoImagePickerSheet(
              items: DemoImages.generalProducts,
              title: 'Choose General Product Demo Image',
            ),
          ),
        ),
      );

      // Verify title is rendered
      expect(find.text('Choose General Product Demo Image'), findsOneWidget);

      // Verify initial items exist in the GridView
      expect(find.descendant(of: find.byType(GridView), matching: find.text('Carrot')), findsOneWidget);
      expect(find.descendant(of: find.byType(GridView), matching: find.text('Banana')), findsOneWidget);

      // Search for "Carrot"
      await tester.enterText(find.byType(TextField), 'Carrot');
      await tester.pump();

      expect(find.descendant(of: find.byType(GridView), matching: find.text('Carrot')), findsOneWidget);
      expect(find.descendant(of: find.byType(GridView), matching: find.text('Banana')), findsNothing);
    });
  });
}
