import 'package:flutter_test/flutter_test.dart';
import 'package:campuskart/core/services/whatsapp_service.dart';

void main() {
  group('WhatsApp Phone Number Normalization Tests', () {
    test('Normalizes 10-digit Indian mobile numbers starting with 6, 7, 8, 9', () {
      expect(WhatsAppService.normalizeIndianPhoneNumber('9512345678'), equals('919512345678'));
      expect(WhatsAppService.normalizeIndianPhoneNumber('9515639193'), equals('919515639193')); // Admin Number
      expect(WhatsAppService.normalizeIndianPhoneNumber('8123456789'), equals('918123456789'));
      expect(WhatsAppService.normalizeIndianPhoneNumber('7012345678'), equals('917012345678'));
      expect(WhatsAppService.normalizeIndianPhoneNumber('6987654321'), equals('916987654321'));
    });

    test('Normalizes numbers with +91 country code', () {
      expect(WhatsAppService.normalizeIndianPhoneNumber('+919512345678'), equals('919512345678'));
      expect(WhatsAppService.normalizeIndianPhoneNumber('+91 95156 39193'), equals('919515639193'));
      expect(WhatsAppService.normalizeIndianPhoneNumber('+91-9512-345-678'), equals('919512345678'));
    });

    test('Normalizes numbers with 91 prefix without plus', () {
      expect(WhatsAppService.normalizeIndianPhoneNumber('919512345678'), equals('919512345678'));
      expect(WhatsAppService.normalizeIndianPhoneNumber('91 95156 39193'), equals('919515639193'));
    });

    test('Normalizes numbers with leading 0', () {
      expect(WhatsAppService.normalizeIndianPhoneNumber('09512345678'), equals('919512345678'));
      expect(WhatsAppService.normalizeIndianPhoneNumber('0 95156 39193'), equals('919515639193'));
    });

    test('Prevents accidental 9191 double prefix', () {
      expect(WhatsAppService.normalizeIndianPhoneNumber('91919512345678'), equals('919512345678'));
      expect(WhatsAppService.normalizeIndianPhoneNumber('+91919515639193'), equals('919515639193'));
    });

    test('Strips spaces, brackets, and hyphens properly', () {
      expect(WhatsAppService.normalizeIndianPhoneNumber('(951) 234-5678'), equals('919512345678'));
      expect(WhatsAppService.normalizeIndianPhoneNumber('  +91 951 563 9193  '), equals('919515639193'));
    });

    test('Rejects invalid phone numbers', () {
      expect(WhatsAppService.normalizeIndianPhoneNumber(null), isNull);
      expect(WhatsAppService.normalizeIndianPhoneNumber(''), isNull);
      expect(WhatsAppService.normalizeIndianPhoneNumber('   '), isNull);
      expect(WhatsAppService.normalizeIndianPhoneNumber('12345'), isNull);
      expect(WhatsAppService.normalizeIndianPhoneNumber('abcdefghij'), isNull);
      expect(WhatsAppService.normalizeIndianPhoneNumber('1234567890'), isNull); // Starts with 1
      expect(WhatsAppService.normalizeIndianPhoneNumber('5876543210'), isNull); // Starts with 5
      expect(WhatsAppService.normalizeIndianPhoneNumber('9876543210123456'), isNull); // Excessively long
    });

    test('isValidIndianPhoneNumber boolean check', () {
      expect(WhatsAppService.isValidIndianPhoneNumber('9515639193'), isTrue);
      expect(WhatsAppService.isValidIndianPhoneNumber('+91 9512345678'), isTrue);
      expect(WhatsAppService.isValidIndianPhoneNumber('12345'), isFalse);
      expect(WhatsAppService.isValidIndianPhoneNumber(''), isFalse);
    });

    test('Official Admin WhatsApp Number is 9515639193 and normalized is 919515639193', () {
      expect(WhatsAppService.adminWhatsAppNumber, equals('9515639193'));
      expect(WhatsAppService.adminWhatsAppInternational, equals('919515639193'));
      expect(WhatsAppService.normalizeIndianPhoneNumber(WhatsAppService.adminWhatsAppNumber), equals('919515639193'));
      expect(WhatsAppService.adminWhatsAppNumber, isNot(equals('9494278168')));
    });

    test('formatDisplayMobile returns clean formatted string', () {
      expect(WhatsAppService.formatDisplayMobile('9515639193'), equals('+91 95156 39193'));
      expect(WhatsAppService.formatDisplayMobile('+919512345678'), equals('+91 95123 45678'));
    });
  });

  group('WhatsApp URL Construction & Encoding Tests', () {
    test('Constructs valid wa.me deep-link with URL-encoded parameters', () {
      final mobile = '9512345678';
      final message = 'Hello John Doe, this is CampusKart. How can we help you?';
      final normalized = WhatsAppService.normalizeIndianPhoneNumber(mobile);
      final encoded = Uri.encodeComponent(message);
      final url = 'https://wa.me/$normalized?text=$encoded';

      expect(url, equals('https://wa.me/919512345678?text=Hello%20John%20Doe%2C%20this%20is%20CampusKart.%20How%20can%20we%20help%20you%3F'));
      expect(Uri.tryParse(url), isNotNull);
      expect(Uri.parse(url).queryParameters['text'], equals(message));
    });

    test('Handles multiline and special characters in WhatsApp message', () {
      final message = "Hello Rahul!\nYour order #ORD123 is confirmed.\nTotal: ₹500 & free delivery.";
      final encoded = Uri.encodeComponent(message);
      final url = 'https://wa.me/919876543210?text=$encoded';

      final uri = Uri.parse(url);
      expect(uri.queryParameters['text'], equals(message));
    });
  });
}
