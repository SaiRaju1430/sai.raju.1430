import 'package:flutter_test/flutter_test.dart';
import 'package:campuskart/providers/auth_provider.dart';
import 'package:campuskart/models/user_model.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Customer Registration & Validation Flow Tests', () {
    test('1. Registration without completing Google Authentication must fail', () async {
      final authProvider = AuthProvider();

      // Attempt registration directly without Google Auth
      final result = await authProvider.completeRegistration('Alice Doe', '9876543210');
      
      expect(result, isFalse);
      expect(authProvider.user, isNull);
      expect(authProvider.tempGoogleUser, isNull);
      expect(authProvider.errorMessage, contains('sign in with Google first'));
    });

    test('2. Indian Mobile Number Validation handles varied formats', () {
      expect(AuthProvider.isValidIndianMobile('9876543210'), isTrue);
      expect(AuthProvider.isValidIndianMobile('+91 9876543210'), isTrue);
      expect(AuthProvider.isValidIndianMobile('09876543210'), isTrue);
      expect(AuthProvider.isValidIndianMobile('8123456789'), isTrue);
      expect(AuthProvider.isValidIndianMobile('7000000000'), isTrue);
      expect(AuthProvider.isValidIndianMobile('6999999999'), isTrue);

      // Rejections
      expect(AuthProvider.isValidIndianMobile('5876543210'), isFalse);
      expect(AuthProvider.isValidIndianMobile('1234567890'), isFalse);
      expect(AuthProvider.isValidIndianMobile('98765'), isFalse);
      expect(AuthProvider.isValidIndianMobile('9876543210999'), isFalse);
    });

    test('3. UserModel correctly serializes and deserializes email & profile fields', () {
      final user = UserModel(
        uid: 'sb_auth_uid_456',
        name: 'Test Student',
        mobile: '9876543210',
        role: 'customer',
        email: 'student@college.edu',
        createdAt: DateTime(2026, 9, 1, 12, 0),
      );

      final map = user.toMap();
      expect(map['id'], equals('sb_auth_uid_456'));
      expect(map['email'], equals('student@college.edu'));
      expect(map['mobile'], equals('9876543210'));
      expect(map['role'], equals('customer'));

      final restored = UserModel.fromMap(map, 'sb_auth_uid_456');
      expect(restored.uid, equals('sb_auth_uid_456'));
      expect(restored.email, equals('student@college.edu'));
      expect(restored.name, equals('Test Student'));
      expect(restored.createdAt, isNotNull);
    });
  });
}
