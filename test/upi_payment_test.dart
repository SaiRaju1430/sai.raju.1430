import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:campuskart/core/constants/app_constants.dart';
import 'package:campuskart/core/utils/upi_payment_helper.dart';
import 'package:campuskart/widgets/dynamic_upi_qr_widget.dart';

void main() {
  group('CampusKart UPI Payment System - Unit Tests', () {
    test('Admin UPI configuration is exactly 9787684437', () {
      expect(AppConstants.adminUpiNumber, '9787684437');
      expect(AppConstants.adminUpiId, '9787684437@upi');
      expect(AppConstants.adminUpiMerchantName, 'CampusKart');
      expect(UpiPaymentHelper.adminUpiNumber, '9787684437');
      expect(UpiPaymentHelper.adminUpiId, '9787684437@upi');
      expect(UpiPaymentHelper.merchantName, 'CampusKart');
    });

    test('Test ₹150 Order - Generates exact UPI Payment URI', () {
      final uri = UpiPaymentHelper.buildUpiUri(amount: 150.0);
      final parsed = Uri.parse(uri);

      expect(parsed.scheme, 'upi');
      expect(parsed.host, 'pay');
      expect(parsed.queryParameters['pa'], '9787684437@upi');
      expect(parsed.queryParameters['pn'], 'CampusKart');
      expect(parsed.queryParameters['am'], '150');
      expect(parsed.queryParameters['cu'], 'INR');
    });

    test('Test ₹200 Order - Generates exact UPI Payment URI', () {
      final uri = UpiPaymentHelper.buildUpiUri(amount: 200.0);
      final parsed = Uri.parse(uri);

      expect(parsed.scheme, 'upi');
      expect(parsed.host, 'pay');
      expect(parsed.queryParameters['pa'], '9787684437@upi');
      expect(parsed.queryParameters['pn'], 'CampusKart');
      expect(parsed.queryParameters['am'], '200');
      expect(parsed.queryParameters['cu'], 'INR');
    });

    test('Test ₹350 Order - Generates exact UPI Payment URI', () {
      final uri = UpiPaymentHelper.buildUpiUri(amount: 350.0);
      final parsed = Uri.parse(uri);

      expect(parsed.scheme, 'upi');
      expect(parsed.host, 'pay');
      expect(parsed.queryParameters['pa'], '9787684437@upi');
      expect(parsed.queryParameters['pn'], 'CampusKart');
      expect(parsed.queryParameters['am'], '350');
      expect(parsed.queryParameters['cu'], 'INR');
    });

    test('Test Display Amount Formatting', () {
      expect(UpiPaymentHelper.formatDisplayAmount(150.0), '₹150');
      expect(UpiPaymentHelper.formatDisplayAmount(200.0), '₹200');
      expect(UpiPaymentHelper.formatDisplayAmount(350.0), '₹350');
      expect(UpiPaymentHelper.formatDisplayAmount(149.50), '₹149.50');
    });

    test('Test Order Payment Validation', () {
      // Matching amounts
      expect(
        UpiPaymentHelper.validateOrderPaymentAmount(expectedAmount: 150.0, actualAmount: 150.0),
        isTrue,
      );
      expect(
        UpiPaymentHelper.validateOrderPaymentAmount(expectedAmount: 200.0, actualAmount: 200.0),
        isTrue,
      );
      // Mismatched amounts
      expect(
        UpiPaymentHelper.validateOrderPaymentAmount(expectedAmount: 150.0, actualAmount: 200.0),
        isFalse,
      );
      // Zero / Negative
      expect(
        UpiPaymentHelper.validateOrderPaymentAmount(expectedAmount: 0.0, actualAmount: 0.0),
        isFalse,
      );
    });
  });

  group('CampusKart Dynamic UPI QR Widget - UI Tests', () {
    testWidgets('Renders dynamic QR for ₹150 order', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: DynamicUpiQrWidget(amount: 150.0),
          ),
        ),
      );

      // Verify "Pay ₹150" is displayed
      expect(find.text('Pay ₹150'), findsOneWidget);

      // Verify instruction text is displayed
      expect(find.text('Scan this QR to pay the exact order amount.'), findsOneWidget);

      // Verify DynamicUpiQrWidget amount
      final dynamicQrWidget = tester.widget<DynamicUpiQrWidget>(find.byType(DynamicUpiQrWidget));
      expect(dynamicQrWidget.amount, 150.0);

      // Verify QrImageView is present in the widget tree
      expect(find.byType(QrImageView), findsOneWidget);

      // Verify UPI ID identifier is shown
      expect(find.text('UPI ID: 9787684437@upi'), findsOneWidget);
    });

    testWidgets('Renders dynamic QR for ₹200 order', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: DynamicUpiQrWidget(amount: 200.0),
          ),
        ),
      );

      expect(find.text('Pay ₹200'), findsOneWidget);
      expect(find.text('Scan this QR to pay the exact order amount.'), findsOneWidget);

      final dynamicQrWidget = tester.widget<DynamicUpiQrWidget>(find.byType(DynamicUpiQrWidget));
      expect(dynamicQrWidget.amount, 200.0);
    });

    testWidgets('Renders dynamic QR for ₹350 order', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: DynamicUpiQrWidget(amount: 350.0),
          ),
        ),
      );

      expect(find.text('Pay ₹350'), findsOneWidget);
      expect(find.text('Scan this QR to pay the exact order amount.'), findsOneWidget);

      final dynamicQrWidget = tester.widget<DynamicUpiQrWidget>(find.byType(DynamicUpiQrWidget));
      expect(dynamicQrWidget.amount, 350.0);
    });

    testWidgets('Regenerates QR dynamically when Personal Order price updates from ₹150 to ₹250', (WidgetTester tester) async {
      double orderPrice = 150.0;

      await tester.pumpWidget(
        StatefulBuilder(
          builder: (context, setState) {
            return MaterialApp(
              home: Scaffold(
                body: Column(
                  children: [
                    DynamicUpiQrWidget(amount: orderPrice),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          orderPrice = 250.0; // Admin updated price
                        });
                      },
                      child: const Text('Update Price'),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      );

      // Initial state: ₹150
      expect(find.text('Pay ₹150'), findsOneWidget);
      var dynamicQr = tester.widget<DynamicUpiQrWidget>(find.byType(DynamicUpiQrWidget));
      expect(dynamicQr.amount, 150.0);

      // Admin modifies price to ₹250
      await tester.tap(find.text('Update Price'));
      await tester.pump();

      // Updated state: ₹250
      expect(find.text('Pay ₹250'), findsOneWidget);
      dynamicQr = tester.widget<DynamicUpiQrWidget>(find.byType(DynamicUpiQrWidget));
      expect(dynamicQr.amount, 250.0);
    });
  });
}
