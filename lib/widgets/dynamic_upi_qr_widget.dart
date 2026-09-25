import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../core/theme/app_theme.dart';
import '../core/utils/upi_payment_helper.dart';

/// Reusable widget to display a dynamically generated UPI Payment QR code
/// with exact payable amount, scan prompt, and interactive UPI details.
class DynamicUpiQrWidget extends StatelessWidget {
  /// The exact calculated final order amount (e.g. 150, 200, 350)
  final double amount;

  /// Optional transaction note (e.g. 'CampusKart Order #1234')
  final String? transactionNote;

  /// Size of the QR Code itself
  final double qrSize;

  /// Whether to show the "Pay ₹XXX" badge above the QR
  final bool showAmountHeader;

  /// Whether to show the scan instructions prompt
  final bool showScanPrompt;

  /// Whether to show the copyable UPI ID / Number card
  final bool showUpiDetails;

  const DynamicUpiQrWidget({
    super.key,
    required this.amount,
    this.transactionNote,
    this.qrSize = 180,
    this.showAmountHeader = true,
    this.showScanPrompt = true,
    this.showUpiDetails = true,
  });

  @override
  Widget build(BuildContext context) {
    // Generate standard dynamic UPI URI: upi://pay?pa=...&pn=CampusKart&am=...&cu=INR
    final upiUri = UpiPaymentHelper.buildUpiUri(
      amount: amount,
      transactionNote: transactionNote,
    );

    final displayAmount = UpiPaymentHelper.formatDisplayAmount(amount);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // 1. Amount Header: "Pay ₹XXX"
        if (showAmountHeader) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.25)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.account_balance_wallet_rounded,
                  color: AppTheme.primaryColor,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Pay $displayAmount',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.primaryColor,
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
        ],

        // 2. Subtitle: "Scan this QR to pay the exact order amount."
        if (showScanPrompt) ...[
          Text(
            'Scan this QR to pay the exact order amount.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.75),
            ),
          ),
          const SizedBox(height: 14),
        ],

        // 3. Dynamic QR Code Container
        Container(
          width: qrSize + 32,
          height: qrSize + 32,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.grey.shade300, width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 14,
                spreadRadius: 1,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Center(
            child: QrImageView(
              data: upiUri,
              version: QrVersions.auto,
              size: qrSize,
              backgroundColor: Colors.white,
              eyeStyle: const QrEyeStyle(
                eyeShape: QrEyeShape.square,
                color: Colors.black87,
              ),
              dataModuleStyle: const QrDataModuleStyle(
                dataModuleShape: QrDataModuleShape.square,
                color: Colors.black87,
              ),
              errorCorrectionLevel: QrErrorCorrectLevel.M,
            ),
          ),
        ),
        const SizedBox(height: 12),

        // 4. UPI Identifier details with Copy action
        if (showUpiDetails) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.qr_code_2_rounded, size: 16, color: Colors.grey),
                const SizedBox(width: 6),
                Text(
                  'UPI ID: ${UpiPaymentHelper.adminUpiId}',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: Colors.grey.shade800,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(width: 8),
                InkWell(
                  onTap: () {
                    Clipboard.setData(const ClipboardData(text: UpiPaymentHelper.adminUpiId));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('UPI ID ${UpiPaymentHelper.adminUpiId} copied!'),
                        duration: const Duration(seconds: 2),
                        backgroundColor: AppTheme.primaryColor,
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(4),
                  child: Padding(
                    padding: const EdgeInsets.all(2),
                    child: Icon(Icons.copy_rounded, size: 15, color: Colors.grey.shade700),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
