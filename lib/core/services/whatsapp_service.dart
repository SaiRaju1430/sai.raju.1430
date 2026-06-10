import 'package:url_launcher/url_launcher.dart';

class WhatsAppService {
  static Future<void> sendPaymentRequest({
    required String mobile,
    required String customerName,
    required String description,
    required double productPrice,
    required double deliveryCharge,
    required double totalAmount,
  }) async {
    final message = "Hello $customerName, your custom order request for '$description' has been approved!\n\n"
        "💰 Product Price: ₹$productPrice\n"
        "🛵 Delivery Charge: ₹$deliveryCharge\n"
        "💳 Total Amount: ₹$totalAmount\n\n"
        "Status: Payment Pending. Please open the CampusKart app to make the UPI payment and submit your transaction reference ID.";
    await _launchWhatsApp(mobile, message);
  }

  static Future<void> sendVerificationReceipt({
    required String mobile,
    required String customerName,
    required String description,
    required String verificationCode,
  }) async {
    final message = "Hello $customerName, your payment has been verified for your custom order '$description'!\n\n"
        "🔑 Doorstep Verification Code: $verificationCode\n\n"
        "Status: Confirmed. Please share this code with the delivery person when they arrive.";
    await _launchWhatsApp(mobile, message);
  }

  static Future<void> sendMessage({required String mobile, required String message}) async {
    await _launchWhatsApp(mobile, message);
  }

  static Future<void> _launchWhatsApp(String mobile, String message) async {
    String cleanMobile = mobile.replaceAll(RegExp(r'\D'), '');
    if (cleanMobile.length == 10) {
      cleanMobile = '91$cleanMobile';
    }
    final encodedMessage = Uri.encodeComponent(message);
    final url = 'https://wa.me/$cleanMobile?text=$encodedMessage';
    final uri = Uri.parse(url);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        print('Could not launch WhatsApp: $url');
      }
    } catch (e) {
      print('Error launching WhatsApp: $e');
    }
  }
}
