import 'package:flutter/material.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import '../models/payment_gateway_model.dart';

/// Payment service for handling payment gateway integrations
class PaymentService {
  static final PaymentService _instance = PaymentService._internal();
  factory PaymentService() => _instance;
  PaymentService._internal();

  PaymentConfiguration? _configuration;
  Razorpay? _razorpay;

  /// Initialize payment service with configuration
  Future<void> initialize(PaymentConfiguration configuration) async {
    _configuration = configuration;

    // Initialize RazorPay if enabled
    if (configuration.razorPayEnabled && configuration.razorPayKey.isNotEmpty) {
      try {
        _razorpay = Razorpay();

        // Set up external wallet listener (for UPI apps, Paytm, etc.)
        _razorpay!.on(Razorpay.EVENT_EXTERNAL_WALLET, (response) {
          debugPrint('🔔 External Wallet Selected: ${response.toString()}');
        });

        debugPrint(
          '✅ RazorPay initialized with key: ${configuration.razorPayKey.substring(0, 15)}...',
        );
      } catch (e) {
        debugPrint('❌ Error initializing RazorPay: $e');
      }
    }
  }

  /// Process RazorPay payment
  Future<PaymentResult> processRazorPayPayment({
    required double amount,
    required String orderId,
    required String userName,
    required String userEmail,
    required String userPhone,
    required Function(PaymentSuccessResponse) onSuccess,
    required Function(PaymentFailureResponse) onFailure,
  }) async {
    try {
      if (_razorpay == null) {
        return PaymentResult.failure(message: 'RazorPay not initialized');
      }

      _razorpay!.on(Razorpay.EVENT_PAYMENT_SUCCESS, (response) {
        onSuccess(response as PaymentSuccessResponse);
      });

      _razorpay!.on(Razorpay.EVENT_PAYMENT_ERROR, (response) {
        onFailure(response as PaymentFailureResponse);
      });

      var options = {
        'key': _configuration?.razorPayKey ?? '',
        'amount': (amount * 100).toInt(), // Amount in paise (1 INR = 100 paise)
        'currency': 'INR', // REQUIRED field
        'name': 'Ryde Driver',
        'description': 'Earnings Withdrawal',
        'prefill': {'contact': userPhone, 'email': userEmail, 'name': userName},
        'method': {
          'netbanking': true,
          'card': true,
          'upi': true,
          'wallet': false,
        },
        'theme': {'color': '#01221D'},
        'send_sms_hash': true,
        'retry': {'enabled': true, 'max_count': 4},
      };

      // Only add order_id if it's a valid one from backend
      // For test mode without backend, we skip order_id
      if (orderId.isNotEmpty && !orderId.startsWith('order_')) {
        options['order_id'] = orderId;
      }

      debugPrint(
        '🔑 RazorPay Opening with Key: ${_configuration?.razorPayKey}',
      );
      debugPrint('💰 Amount: ₹$amount (${options['amount']} paise)');

      _razorpay!.open(options);

      return PaymentResult.success(message: 'Payment initiated');
    } catch (e) {
      return PaymentResult.failure(
        message: 'An error occurred: ${e.toString()}',
      );
    }
  }

  /// Dispose RazorPay instance
  void dispose() {
    _razorpay?.clear();
  }

  /// Get card brand image asset path
  static String getCardBrandImage(String? brand) {
    if (brand == null) return 'assets/images/credit_card.png';

    switch (brand.toLowerCase()) {
      case 'visa':
        return 'assets/images/visa.png';
      case 'mastercard':
        return 'assets/images/master.png';
      case 'amex':
      case 'american express':
        return 'assets/images/american_express.png';
      case 'discover':
        return 'assets/images/discover.png';
      case 'jcb':
        return 'assets/images/jcb.png';
      case 'eftpos':
        return 'assets/images/eftpos.png';
      default:
        return 'assets/images/credit_card.png';
    }
  }

  /// Get payment gateway logo
  static String getPaymentGatewayLogo(PaymentGatewayType type) {
    switch (type) {
      case PaymentGatewayType.stripe:
        return 'assets/images/stripe.png';
      case PaymentGatewayType.razorPay:
        return 'assets/images/razorpay.png';
      case PaymentGatewayType.paystack:
        return 'assets/images/paystack.png';
      case PaymentGatewayType.cashFree:
        return 'assets/images/cashfree.png';
      case PaymentGatewayType.flutterWave:
        return 'assets/images/flutterwave.png';
      case PaymentGatewayType.khalti:
        return 'assets/images/khalti.png';
      default:
        return 'assets/images/payment.png';
    }
  }

  /// Format amount with currency
  static String formatAmount({
    required double amount,
    required String currencySymbol,
  }) {
    return '$currencySymbol${amount.toStringAsFixed(2)}';
  }

  /// Validate amount
  static bool validateAmount({
    required double amount,
    required String minimumAmount,
  }) {
    final minAmount = double.tryParse(minimumAmount) ?? 0.0;
    return amount >= minAmount;
  }

  /// Get configuration
  PaymentConfiguration? get configuration => _configuration;
}
