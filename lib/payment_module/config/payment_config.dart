/// Payment Module Configuration
/// Store your API keys and configuration here
class PaymentConfig {
  // ==========================================
  // STRIPE CONFIGURATION
  // ==========================================

  /// Stripe Publishable Key (Test)
  /// Get this from: https://dashboard.stripe.com/test/apikeys
  static const String stripePublishableKeyTest =
      'pk_test_YOUR_STRIPE_PUBLISHABLE_KEY_HERE';

  /// Stripe Publishable Key (Production)
  /// Get this from: https://dashboard.stripe.com/apikeys
  static const String stripePublishableKeyLive =
      'pk_live_YOUR_STRIPE_PUBLISHABLE_KEY_HERE';

  /// Stripe Merchant Identifier
  /// Use your app's bundle ID or package name
  static const String stripeMerchantIdentifier = 'merchant.com.ryde.driver';

  /// Stripe URL Scheme (for redirects)
  static const String stripeUrlScheme = 'rydestripe';

  // ==========================================
  // RAZORPAY CONFIGURATION
  // ==========================================

  /// RazorPay Key ID (Test)
  /// Get this from: https://dashboard.razorpay.com/app/keys
  static const String razorPayKeyTest = 'rzp_test_mLjOYPDdtvn3SX';

  /// RazorPay Key Secret (Test)
  /// ⚠️ IMPORTANT: Never expose this in production! Use backend API instead
  /// This is only for testing/development purposes
  static const String razorPaySecretTest = 'zLargP4Ig6wUCfO1UVZRJSfw';

  /// RazorPay Key ID (Production)
  static const String razorPayKeyLive = 'rzp_live_YOUR_RAZORPAY_KEY_HERE';

  /// RazorPay Key Secret (Production)
  /// ⚠️ CRITICAL: Store this ONLY on your backend server, never in the app
  static const String razorPaySecretLive = 'YOUR_RAZORPAY_SECRET_HERE';

  // ==========================================
  // OTHER PAYMENT GATEWAYS
  // ==========================================

  /// Paystack Public Key
  static const String paystackPublicKey = 'pk_test_YOUR_PAYSTACK_KEY_HERE';

  /// CashFree App ID
  static const String cashFreeAppId = 'YOUR_CASHFREE_APP_ID_HERE';

  /// FlutterWave Public Key
  static const String flutterWavePublicKey = 'FLWPUBK_TEST_YOUR_KEY_HERE';

  /// Khalti Public Key
  static const String khaltiPublicKey = 'YOUR_KHALTI_PUBLIC_KEY_HERE';

  // ==========================================
  // BACKEND API CONFIGURATION
  // ==========================================

  /// Your backend API base URL
  static const String apiBaseUrl = 'https://api.yourapp.com/api/v1';

  /// Alternative: Use your Firebase Functions URL
  static const String firebaseFunctionsUrl =
      'https://us-central1-your-project.cloudfunctions.net';

  // ==========================================
  // ENVIRONMENT SETTINGS
  // ==========================================

  /// Current environment (test/production)
  static const bool isProduction = false;

  /// Get appropriate Stripe key based on environment
  static String get stripePublishableKey =>
      isProduction ? stripePublishableKeyLive : stripePublishableKeyTest;

  /// Get appropriate RazorPay key based on environment
  static String get razorPayKey =>
      isProduction ? razorPayKeyLive : razorPayKeyTest;

  // ==========================================
  // CURRENCY SETTINGS
  // ==========================================

  /// Default currency code (INR for India - RazorPay)
  static const String defaultCurrencyCode = 'INR';

  /// Default currency symbol (₹ for Indian Rupee)
  static const String defaultCurrencySymbol = '₹';

  /// Minimum payment amount
  static const String minimumAmount = '10';

  // ==========================================
  // FEATURE FLAGS
  // ==========================================

  /// Enable card saving feature
  /// Note: RazorPay doesn't support card saving like Stripe does
  /// Set to false when using RazorPay as the primary gateway
  static const bool enableSaveCard = false;

  /// Enable payment history
  static const bool enablePaymentHistory = true;

  /// Enable multiple payment gateways
  static const bool enableMultipleGateways = true;

  // ==========================================
  // HELPER METHODS
  // ==========================================

  /// Validate if Stripe is properly configured
  static bool get isStripeConfigured {
    final key = stripePublishableKey;
    return key.isNotEmpty && !key.contains('YOUR_');
  }

  /// Validate if RazorPay is properly configured
  static bool get isRazorPayConfigured {
    final key = razorPayKey;
    return key.isNotEmpty && !key.contains('YOUR_');
  }

  /// Get configuration summary
  static Map<String, dynamic> getConfigSummary() {
    return {
      'environment': isProduction ? 'production' : 'test',
      'stripe_configured': isStripeConfigured,
      'razorpay_configured': isRazorPayConfigured,
      'save_card_enabled': enableSaveCard,
      'currency': defaultCurrencyCode,
    };
  }
}
