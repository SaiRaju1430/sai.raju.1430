import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:campuskart/core/theme/app_theme.dart';

void main() {
  testWidgets('CampusKart App Theme and Branding Smoke Test', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: const Scaffold(
          body: Center(
            child: Text(
              'CampusKart',
              style: TextStyle(
                color: AppTheme.primaryColor,
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );

    expect(find.text('CampusKart'), findsOneWidget);
  });
}
