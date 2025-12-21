import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../presentation/payment_screen.dart';

/// Payment Integration Helper
/// Use this class to easily integrate payment functionality into your app
class PaymentIntegration {
  /// Navigate to payment screen with mock repository (for testing)
  static Future<bool?> showPaymentScreenWithMock({
    required BuildContext context,
    double? amount,
    String? title,
    Color? primaryColor,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please login first')));
      return null;
    }

    return await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => PaymentScreen(
          userId: user.uid,
          initialAmount: amount,
          title: title ?? 'Payment',
          primaryColor: primaryColor,
          onPaymentSuccess: (amount, paymentId) {
            Navigator.pop(context, true);
          },
          onPaymentFailed: () {
            // Handle failure
          },
        ),
      ),
    );
  }

  /// Navigate to payment screen with real backend (for production)
  static Future<bool?> showPaymentScreenWithBackend({
    required BuildContext context,
    required String Function() getAuthToken,
    double? amount,
    String? title,
    String? apiBaseUrl,
    Color? primaryColor,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please login first')));
      return null;
    }

    // Note: You'll need to create a version of PaymentScreen that accepts
    // RealPaymentRepository. For now, this shows the concept.

    return await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => PaymentScreen(
          userId: user.uid,
          initialAmount: amount,
          title: title ?? 'Payment',
          primaryColor: primaryColor,
          onPaymentSuccess: (amount, paymentId) {
            Navigator.pop(context, true);
          },
          onPaymentFailed: () {
            // Handle failure
          },
        ),
      ),
    );
  }

  /// Show payment bottom sheet
  static Future<bool?> showPaymentBottomSheet({
    required BuildContext context,
    required double amount,
    String? title,
    Color? primaryColor,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please login first')));
      return null;
    }

    return await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (_, controller) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: PaymentScreen(
            userId: user.uid,
            initialAmount: amount,
            title: title ?? 'Payment',
            primaryColor: primaryColor,
            backgroundColor: Colors.white,
            onPaymentSuccess: (amount, paymentId) {
              Navigator.pop(context, true);
            },
            onPaymentFailed: () {
              // Handle failure
            },
          ),
        ),
      ),
    );
  }

  /// Simple payment button widget
  static Widget buildPaymentButton({
    required BuildContext context,
    required double amount,
    required VoidCallback onPressed,
    String? text,
    Color? backgroundColor,
    Color? textColor,
  }) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: backgroundColor ?? Theme.of(context).primaryColor,
        foregroundColor: textColor ?? Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.payment),
          const SizedBox(width: 8),
          Text(
            text ?? 'Pay \$${amount.toStringAsFixed(2)}',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  /// Earnings payment button specifically for drivers
  static Widget buildEarningsPaymentButton({
    required BuildContext context,
    required double earningsAmount,
    required VoidCallback onPressed,
  }) {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).primaryColor,
            Theme.of(context).primaryColor.withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).primaryColor.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.account_balance_wallet,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Available Earnings',
                        style: TextStyle(color: Colors.white70, fontSize: 14),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '\$${earningsAmount.toStringAsFixed(2)}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward, color: Colors.white),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
