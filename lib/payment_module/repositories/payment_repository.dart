import '../models/payment_gateway_model.dart';

/// Payment repository interface
abstract class PaymentRepository {
  /// Get available payment gateways
  Future<List<PaymentGatewayItem>> getPaymentGateways();

  /// Get payment configuration
  Future<PaymentConfiguration> getPaymentConfiguration();

  /// Process payment with selected gateway
  Future<PaymentResult> processPayment({
    required String userId,
    required double amount,
    required PaymentGatewayItem gateway,
    Map<String, dynamic>? metadata,
  });

  /// Get Stripe setup intent for adding card
  Future<StripeSetupIntentResponse> getStripeSetupIntent();

  /// Save card details to stripe
  Future<PaymentResult> saveCardDetails({
    required String paymentMethodId,
    required String userId,
  });

  /// Process payment with saved card
  Future<PaymentResult> processPaymentWithCard({
    required String userId,
    required double amount,
    required String cardToken,
    Map<String, dynamic>? metadata,
  });

  /// Get payment history
  Future<List<PaymentTransaction>> getPaymentHistory({
    required String userId,
    int page = 1,
    int perPage = 20,
  });

  /// Get payment transaction by ID
  Future<PaymentTransaction?> getPaymentTransaction(String transactionId);

  /// Delete saved card
  Future<bool> deleteSavedCard({
    required String userId,
    required String cardToken,
  });
}

/// Mock payment repository implementation
class MockPaymentRepository implements PaymentRepository {
  // Simulated saved cards
  final List<PaymentGatewayItem> _savedCards = [
    PaymentGatewayItem(
      id: 'card_1',
      name: 'Visa',
      type: PaymentGatewayType.stripe,
      enabled: true,
      image: 'visa',
      cardToken: 'pm_1234567890',
      lastFourDigits: '4242',
      cardBrand: 'visa',
      isCard: true,
    ),
    PaymentGatewayItem(
      id: 'card_2',
      name: 'Mastercard',
      type: PaymentGatewayType.stripe,
      enabled: true,
      image: 'mastercard',
      cardToken: 'pm_0987654321',
      lastFourDigits: '5555',
      cardBrand: 'mastercard',
      isCard: true,
    ),
  ];

  final List<PaymentTransaction> _transactions = [];

  @override
  Future<List<PaymentGatewayItem>> getPaymentGateways() async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 500));

    return [
      PaymentGatewayItem(
        id: 'razorpay',
        name: 'RazorPay',
        type: PaymentGatewayType.razorPay,
        enabled: true,
        image: 'razorpay',
        isCard: false,
      ),
    ];
  }

  @override
  Future<PaymentConfiguration> getPaymentConfiguration() async {
    await Future.delayed(const Duration(milliseconds: 300));

    return PaymentConfiguration(
      stripeEnabled: false,
      razorPayEnabled: true,
      paystackEnabled: false,
      cashFreeEnabled: false,
      flutterWaveEnabled: false,
      khaltiPayEnabled: false,
      stripePublishableKey: '',
      razorPayKey: 'rzp_test_mLjOYPDdtvn3SX',
      environment: 'test',
      currencyCode: 'INR',
      currencySymbol: '₹',
      minimumAmount: '10',
      enableSaveCard: false,
    );
  }

  @override
  Future<PaymentResult> processPayment({
    required String userId,
    required double amount,
    required PaymentGatewayItem gateway,
    Map<String, dynamic>? metadata,
  }) async {
    // Simulate payment processing
    await Future.delayed(const Duration(seconds: 2));

    // Simulate 90% success rate
    final isSuccess = DateTime.now().millisecond % 10 != 0;

    if (isSuccess) {
      final transaction = PaymentTransaction(
        id: 'txn_${DateTime.now().millisecondsSinceEpoch}',
        userId: userId,
        amount: amount,
        currencyCode: 'USD',
        currencySymbol: '\$',
        status: PaymentStatus.success,
        gateway: gateway.type,
        transactionId: 'pay_${DateTime.now().millisecondsSinceEpoch}',
        paymentIntentId: 'pi_${DateTime.now().millisecondsSinceEpoch}',
        createdAt: DateTime.now(),
        completedAt: DateTime.now(),
        metadata: metadata,
      );

      _transactions.insert(0, transaction);

      return PaymentResult.success(
        message: 'Payment processed successfully',
        transactionId: transaction.transactionId,
        transaction: transaction,
      );
    } else {
      return PaymentResult.failure(
        message: 'Payment failed. Please try again.',
      );
    }
  }

  @override
  Future<StripeSetupIntentResponse> getStripeSetupIntent() async {
    await Future.delayed(const Duration(milliseconds: 800));

    return StripeSetupIntentResponse(
      success: true,
      message: 'Setup intent created',
      clientSecret: 'seti_${DateTime.now().millisecondsSinceEpoch}_secret',
      customerId: 'cus_${DateTime.now().millisecondsSinceEpoch}',
      testEnvironment: true,
    );
  }

  @override
  Future<PaymentResult> saveCardDetails({
    required String paymentMethodId,
    required String userId,
  }) async {
    await Future.delayed(const Duration(seconds: 1));

    // Simulate card save
    final cardBrands = ['visa', 'mastercard', 'amex', 'discover'];
    final randomBrand =
        cardBrands[DateTime.now().millisecond % cardBrands.length];
    final lastFour = (1000 + DateTime.now().millisecond % 9000)
        .toString()
        .substring(0, 4);

    final newCard = PaymentGatewayItem(
      id: 'card_${_savedCards.length + 1}',
      name: randomBrand.toUpperCase(),
      type: PaymentGatewayType.stripe,
      enabled: true,
      image: randomBrand,
      cardToken: paymentMethodId,
      lastFourDigits: lastFour,
      cardBrand: randomBrand,
      isCard: true,
    );

    _savedCards.add(newCard);

    return PaymentResult.success(
      message: 'Card saved successfully',
      data: newCard.toJson(),
    );
  }

  @override
  Future<PaymentResult> processPaymentWithCard({
    required String userId,
    required double amount,
    required String cardToken,
    Map<String, dynamic>? metadata,
  }) async {
    await Future.delayed(const Duration(seconds: 2));

    // Find card
    final card = _savedCards.firstWhere(
      (c) => c.cardToken == cardToken,
      orElse: () => PaymentGatewayItem(
        id: 'unknown',
        name: 'Unknown Card',
        type: PaymentGatewayType.stripe,
      ),
    );

    return processPayment(
      userId: userId,
      amount: amount,
      gateway: card,
      metadata: metadata,
    );
  }

  @override
  Future<List<PaymentTransaction>> getPaymentHistory({
    required String userId,
    int page = 1,
    int perPage = 20,
  }) async {
    await Future.delayed(const Duration(milliseconds: 500));
    return List.from(_transactions);
  }

  @override
  Future<PaymentTransaction?> getPaymentTransaction(
    String transactionId,
  ) async {
    await Future.delayed(const Duration(milliseconds: 300));
    try {
      return _transactions.firstWhere(
        (t) => t.transactionId == transactionId || t.id == transactionId,
      );
    } catch (e) {
      return null;
    }
  }

  @override
  Future<bool> deleteSavedCard({
    required String userId,
    required String cardToken,
  }) async {
    await Future.delayed(const Duration(milliseconds: 500));
    _savedCards.removeWhere((card) => card.cardToken == cardToken);
    return true;
  }
}
