import 'package:flutter_test/flutter_test.dart';
import 'package:campuskart/providers/auth_provider.dart';
import 'package:campuskart/models/user_model.dart';

void main() {
  group('Indian Mobile Validation Tests', () {
    test('Valid 10-digit Indian mobile numbers starting with 6, 7, 8, 9', () {
      expect(AuthProvider.isValidIndianMobile('9876543210'), isTrue);
      expect(AuthProvider.isValidIndianMobile('8123456789'), isTrue);
      expect(AuthProvider.isValidIndianMobile('7012345678'), isTrue);
      expect(AuthProvider.isValidIndianMobile('6987654321'), isTrue);
      expect(AuthProvider.isValidIndianMobile('+91 9876543210'), isTrue);
      expect(AuthProvider.isValidIndianMobile('919876543210'), isTrue);
      expect(AuthProvider.isValidIndianMobile('09876543210'), isTrue);
    });

    test('Invalid mobile numbers must be rejected', () {
      expect(AuthProvider.isValidIndianMobile(''), isFalse);
      expect(AuthProvider.isValidIndianMobile('12345'), isFalse);
      expect(AuthProvider.isValidIndianMobile('1234567890'), isFalse); // Starts with 1
      expect(AuthProvider.isValidIndianMobile('5876543210'), isFalse); // Starts with 5
      expect(AuthProvider.isValidIndianMobile('98765abcde'), isFalse);
      expect(AuthProvider.isValidIndianMobile('9876543210123'), isFalse); // Too long
    });
  });

  group('UserModel Serialization & Email Tests', () {
    test('UserModel maps email and createdAt correctly', () {
      final user = UserModel(
        uid: 'user_123',
        name: 'Rahul Sharma',
        mobile: '9876543210',
        role: 'customer',
        email: 'rahul.sharma@gmail.com',
        createdAt: DateTime(2026, 9, 1, 10, 0),
      );

      final map = user.toMap();
      expect(map['id'], equals('user_123'));
      expect(map['email'], equals('rahul.sharma@gmail.com'));
      expect(map['mobile'], equals('9876543210'));

      final fromMap = UserModel.fromMap(map, 'user_123');
      expect(fromMap.email, equals('rahul.sharma@gmail.com'));
      expect(fromMap.role, equals('customer'));
      expect(fromMap.createdAt, isNotNull);
    });
  });
}
