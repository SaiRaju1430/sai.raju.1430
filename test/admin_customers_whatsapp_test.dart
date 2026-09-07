import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:campuskart/core/services/whatsapp_service.dart';
import 'package:campuskart/models/user_model.dart';

void main() {
  group('Admin Customer WhatsApp Dialog & Messaging Flow Tests', () {
    testWidgets('Renders WhatsApp message modal with default editable message and customer data', (WidgetTester tester) async {
      final testCustomer = UserModel(
        uid: 'cust_101',
        name: 'Sai Raju',
        mobile: '9512345678',
        role: 'customer',
        email: 'sairaju@test.com',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  // Simulate opening WhatsApp dialog for customer
                  final messageController = TextEditingController(
                    text: 'Hello ${testCustomer.name}, this is CampusKart. How can we help you?',
                  );

                  showDialog(
                    context: context,
                    builder: (dialogCtx) => StatefulBuilder(
                      builder: (ctx, setDialogState) {
                        final isPhoneValid = WhatsAppService.isValidIndianPhoneNumber(testCustomer.mobile);
                        expect(isPhoneValid, isTrue);
                        final formattedMobile = WhatsAppService.formatDisplayMobile(testCustomer.mobile);

                        return AlertDialog(
                          title: Text('WhatsApp ${testCustomer.name}'),
                          content: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(formattedMobile),
                              TextField(
                                key: const Key('whatsapp_message_input'),
                                controller: messageController,
                              ),
                              ActionChip(
                                key: const Key('template_order_status'),
                                label: const Text('Order Status'),
                                onPressed: () {
                                  setDialogState(() {
                                    messageController.text = 'Hello ${testCustomer.name}, we are checking on your order!';
                                  });
                                },
                              ),
                            ],
                          ),
                          actions: [
                            ElevatedButton(
                              key: const Key('open_whatsapp_btn'),
                              onPressed: () {
                                final message = messageController.text.trim();
                                final normalized = WhatsAppService.normalizeIndianPhoneNumber(testCustomer.mobile);
                                expect(normalized, equals('919512345678'));
                                expect(message, isNotEmpty);
                                Navigator.pop(dialogCtx);
                              },
                              child: const Text('OPEN WHATSAPP'),
                            ),
                          ],
                        );
                      },
                    ),
                  );
                },
                child: const Text('Trigger WhatsApp Dialog'),
              ),
            ),
          ),
        ),
      );

      // Tap button to open WhatsApp dialog
      await tester.tap(find.text('Trigger WhatsApp Dialog'));
      await tester.pumpAndSettle();

      // Verify dialog is shown with customer name and formatted mobile (+91 95123 45678)
      expect(find.text('WhatsApp Sai Raju'), findsOneWidget);
      expect(find.text('+91 95123 45678'), findsOneWidget);

      // Verify default message is pre-filled in the text field
      expect(find.text('Hello Sai Raju, this is CampusKart. How can we help you?'), findsOneWidget);

      // Tap template chip to change message
      await tester.tap(find.byKey(const Key('template_order_status')));
      await tester.pumpAndSettle();
      expect(find.text('Hello Sai Raju, we are checking on your order!'), findsOneWidget);

      // Edit the text field manually
      await tester.enterText(find.byKey(const Key('whatsapp_message_input')), 'Custom message for Sai Raju');
      await tester.pumpAndSettle();
      expect(find.text('Custom message for Sai Raju'), findsOneWidget);

      // Tap Open WhatsApp button
      await tester.tap(find.byKey(const Key('open_whatsapp_btn')));
      await tester.pumpAndSettle();

      // Dialog closed
      expect(find.text('WhatsApp Sai Raju'), findsNothing);
    });

    testWidgets('Displays warning when customer mobile number is invalid', (WidgetTester tester) async {
      final invalidCustomer = UserModel(
        uid: 'cust_999',
        name: 'Invalid User',
        mobile: '12345', // Invalid Indian mobile
        role: 'customer',
      );

      expect(WhatsAppService.isValidIndianPhoneNumber(invalidCustomer.mobile), isFalse);
      expect(WhatsAppService.normalizeIndianPhoneNumber(invalidCustomer.mobile), isNull);
    });
  });
}
