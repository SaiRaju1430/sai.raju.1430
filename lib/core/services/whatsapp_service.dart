import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

enum WhatsAppLaunchResult {
  success,
  invalidNumber,
  notInstalled,
  error,
}

class WhatsAppService {
  /// Official CampusKart Admin WhatsApp Number: 9515639193 (International format: 919515639193)
  static const String adminWhatsAppNumber = '9515639193';
  static const String adminWhatsAppInternational = '919515639193';

  /// Opens WhatsApp chat to contact the CampusKart Admin directly (9515639193)
  static Future<WhatsAppLaunchResult> contactAdminViaWhatsApp({
    String message = 'Hello CampusKart Admin, I need assistance with my order.',
  }) async {
    return await openWhatsAppChat(
      mobile: adminWhatsAppNumber,
      message: message,
    );
  }

  /// Safely normalizes an Indian phone number to international WhatsApp format (91XXXXXXXXXX).
  /// Returns null if the number is invalid.
  static String? normalizeIndianPhoneNumber(String? rawNumber) {
    if (rawNumber == null || rawNumber.trim().isEmpty) return null;

    // Strip all non-digit characters (+, spaces, hyphens, brackets, dots, etc.)
    String digits = rawNumber.replaceAll(RegExp(r'\D'), '');

    // Prevent accidental double country code prefix (e.g. 91919515639193)
    if (digits.length >= 14 && digits.startsWith('9191')) {
      final remainder = digits.substring(4);
      if (RegExp(r'^[6-9]\d{9}$').hasMatch(remainder)) {
        return '91$remainder';
      }
    }

    // Strip leading zeroes (e.g. 09515639193 -> 9515639193)
    digits = digits.replaceFirst(RegExp(r'^0+'), '');

    // Case: Exactly 10 digits starting with 6, 7, 8, 9
    if (digits.length == 10 && RegExp(r'^[6-9]\d{9}$').hasMatch(digits)) {
      return '91$digits';
    }

    // Case: 12 digits starting with 91 followed by valid 10-digit mobile
    if (digits.length == 12 && digits.startsWith('91')) {
      final tenDigit = digits.substring(2);
      if (RegExp(r'^[6-9]\d{9}$').hasMatch(tenDigit)) {
        return digits;
      }
    }

    // Fallback: If extra leading numbers exist, check if the last 10 digits are a valid mobile
    if (digits.length > 10) {
      final tenDigit = digits.substring(digits.length - 10);
      if (RegExp(r'^[6-9]\d{9}$').hasMatch(tenDigit)) {
        return '91$tenDigit';
      }
    }

    return null;
  }

  /// Checks if the input number is a valid Indian mobile number
  static bool isValidIndianPhoneNumber(String? rawNumber) {
    return normalizeIndianPhoneNumber(rawNumber) != null;
  }

  /// Formats the phone number for clean UI display (e.g., +91 95156 39193)
  static String formatDisplayMobile(String? rawNumber) {
    final normalized = normalizeIndianPhoneNumber(rawNumber);
    if (normalized == null || normalized.length != 12) {
      return rawNumber ?? '';
    }
    final part1 = normalized.substring(2, 7);
    final part2 = normalized.substring(7);
    return '+91 $part1 $part2';
  }

  /// Opens WhatsApp chat for the specified customer mobile number with a pre-filled message.
  /// Uses the official WhatsApp deep link format: `https://wa.me/<CUSTOMER_NUMBER>?text=<URL_ENCODED_MESSAGE>`
  static Future<WhatsAppLaunchResult> openWhatsAppChat({
    required String mobile,
    required String message,
  }) async {
    final normalizedPhone = normalizeIndianPhoneNumber(mobile);
    if (normalizedPhone == null) {
      debugPrint('WhatsAppService: Invalid Indian phone number: $mobile');
      return WhatsAppLaunchResult.invalidNumber;
    }

    final encodedMessage = Uri.encodeComponent(message);
    final urlString = 'https://wa.me/$normalizedPhone?text=$encodedMessage';
    final uri = Uri.parse(urlString);

    try {
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (launched) {
        return WhatsAppLaunchResult.success;
      }
    } catch (e) {
      debugPrint('WhatsAppService: Error launching wa.me URL: $e');
    }

    // Fallback scheme: whatsapp://send?phone=...
    try {
      final fallbackUri = Uri.parse('whatsapp://send?phone=$normalizedPhone&text=$encodedMessage');
      if (await canLaunchUrl(fallbackUri)) {
        final launched = await launchUrl(
          fallbackUri,
          mode: LaunchMode.externalApplication,
        );
        if (launched) {
          return WhatsAppLaunchResult.success;
        }
      }
    } catch (e) {
      debugPrint('WhatsAppService: Error launching fallback whatsapp scheme: $e');
    }

    return WhatsAppLaunchResult.notInstalled;
  }

  /// Sends a generic message via WhatsApp (wrapper around openWhatsAppChat)
  static Future<WhatsAppLaunchResult> sendMessage({
    required String mobile,
    required String message,
  }) async {
    return await openWhatsAppChat(mobile: mobile, message: message);
  }

  /// Helper to send custom order payment request via WhatsApp
  static Future<WhatsAppLaunchResult> sendPaymentRequest({
    required String mobile,
    required String customerName,
    required String description,
    required double productPrice,
    required double deliveryCharge,
    required double totalAmount,
  }) async {
    final message = "Hello $customerName, your custom order request for '$description' has been approved!\n\n"
        "💰 Product Price: ₹${productPrice.toStringAsFixed(0)}\n"
        "🛵 Delivery Charge: ₹${deliveryCharge.toStringAsFixed(0)}\n"
        "💳 Total Amount: ₹${totalAmount.toStringAsFixed(0)}\n\n"
        "Status: Payment Pending. Please open the CampusKart app to make the UPI payment and submit your transaction reference ID.";
    return await openWhatsAppChat(mobile: mobile, message: message);
  }

  /// Helper to send doorstep verification code receipt via WhatsApp
  static Future<WhatsAppLaunchResult> sendVerificationReceipt({
    required String mobile,
    required String customerName,
    required String description,
    required String verificationCode,
  }) async {
    final message = "Hello $customerName, your payment has been verified for your custom order '$description'!\n\n"
        "🔑 Doorstep Verification Code: $verificationCode\n\n"
        "Status: Confirmed. Please share this code with the delivery person when they arrive.";
    return await openWhatsAppChat(mobile: mobile, message: message);
  }

  /// Displays a SnackBar with appropriate user feedback based on the launch result
  static void showResultFeedback(
    BuildContext context,
    WhatsAppLaunchResult result, {
    String? rawMobile,
  }) {
    if (!context.mounted) return;

    switch (result) {
      case WhatsAppLaunchResult.success:
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Opening WhatsApp with pre-filled message...'),
            backgroundColor: Color(0xFF25D366),
            duration: Duration(seconds: 2),
          ),
        );
        break;
      case WhatsAppLaunchResult.invalidNumber:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              rawMobile != null && rawMobile.isNotEmpty
                  ? 'Customer phone number ($rawMobile) is invalid. A valid 10-digit Indian number is required.'
                  : 'Customer phone number is missing or invalid.',
            ),
            backgroundColor: Colors.red.shade700,
            duration: const Duration(seconds: 4),
          ),
        );
        break;
      case WhatsAppLaunchResult.notInstalled:
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('WhatsApp is not installed on this device.'),
            backgroundColor: Colors.redAccent,
            duration: Duration(seconds: 4),
          ),
        );
        break;
      case WhatsAppLaunchResult.error:
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not open WhatsApp. Please try again.'),
            backgroundColor: Colors.redAccent,
            duration: Duration(seconds: 3),
          ),
        );
        break;
    }
  }
}
