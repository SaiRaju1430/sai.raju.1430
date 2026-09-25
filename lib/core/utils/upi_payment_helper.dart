import '../constants/app_constants.dart';

/// Helper utility for generating and validating dynamic UPI payment URIs and amounts
class UpiPaymentHelper {
  /// Admin UPI / Merchant Receiver Phone Number: 9787684437
  static const String adminUpiNumber = AppConstants.adminUpiNumber;

  /// Admin UPI ID / VPA: 9787684437@upi
  static const String adminUpiId = AppConstants.adminUpiId;

  /// Payee Name: CampusKart
  static const String merchantName = AppConstants.adminUpiMerchantName;

  /// Currency: INR
  static const String currency = 'INR';

  /// Generates a standard dynamic UPI payment URI based on the exact final order bill amount.
  /// 
  /// Format:
  /// `upi://pay?pa=9787684437@upi&pn=CampusKart&am=<EXACT_AMOUNT>&cu=INR`
  /// 
  /// Examples:
  /// - ₹150 -> upi://pay?pa=9787684437@upi&pn=CampusKart&am=150&cu=INR
  /// - ₹200 -> upi://pay?pa=9787684437@upi&pn=CampusKart&am=200&cu=INR
  /// - ₹350 -> upi://pay?pa=9787684437@upi&pn=CampusKart&am=350&cu=INR
  static String buildUpiUri({
    required double amount,
    String? transactionNote,
    String? transactionRef,
  }) {
    // Format amount cleanly without unnecessary trailing zeroes for integers
    final String formattedAmount = formatAmountValue(amount);

    final Map<String, String> queryParams = {
      'pa': adminUpiId,
      'pn': merchantName,
      'am': formattedAmount,
      'cu': currency,
    };

    if (transactionNote != null && transactionNote.trim().isNotEmpty) {
      queryParams['tn'] = transactionNote.trim();
    }

    if (transactionRef != null && transactionRef.trim().isNotEmpty) {
      queryParams['tr'] = transactionRef.trim();
    }

    // Construct standard UPI URI
    final uri = Uri(
      scheme: 'upi',
      host: 'pay',
      queryParameters: queryParams,
    );

    return uri.toString();
  }

  /// Formats raw numeric amount into string for UPI URI query param
  static String formatAmountValue(double amount) {
    if (amount % 1 == 0) {
      return amount.toInt().toString();
    }
    return amount.toStringAsFixed(2);
  }

  /// Formats amount for user-facing UI displays (e.g. ₹150, ₹200, ₹350)
  static String formatDisplayAmount(double amount) {
    if (amount % 1 == 0) {
      return '₹${amount.toInt()}';
    }
    return '₹${amount.toStringAsFixed(2)}';
  }

  /// Validates that the QR amount exactly matches the final order amount stored for that order.
  static bool validateOrderPaymentAmount({
    required double expectedAmount,
    required double actualAmount,
  }) {
    if (expectedAmount <= 0 || actualAmount <= 0) return false;
    return (expectedAmount - actualAmount).abs() < 0.01;
  }
}
