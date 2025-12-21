/// Main payment configuration model
class PaymentConfiguration {
  final bool stripeEnabled;
  final bool razorPayEnabled;
  final bool paystackEnabled;
  final bool cashFreeEnabled;
  final bool flutterWaveEnabled;
  final bool khaltiPayEnabled;
  final String stripePublishableKey;
  final String razorPayKey;
  final String paystackPublicKey;
  final String cashFreeAppId;
  final String flutterWavePublicKey;
  final String khaltiPublicKey;
  final String environment; // 'test' or 'live'
  final String currencyCode;
  final String currencySymbol;
  final String minimumAmount;
  final bool enableSaveCard;

  PaymentConfiguration({
    this.stripeEnabled = false,
    this.razorPayEnabled = false,
    this.paystackEnabled = false,
    this.cashFreeEnabled = false,
    this.flutterWaveEnabled = false,
    this.khaltiPayEnabled = false,
    this.stripePublishableKey = '',
    this.razorPayKey = '',
    this.paystackPublicKey = '',
    this.cashFreeAppId = '',
    this.flutterWavePublicKey = '',
    this.khaltiPublicKey = '',
    this.environment = 'test',
    this.currencyCode = 'USD',
    this.currencySymbol = '\$',
    this.minimumAmount = '10',
    this.enableSaveCard = true,
  });

  factory PaymentConfiguration.fromJson(Map<String, dynamic> json) =>
      PaymentConfiguration(
        stripeEnabled: json['stripe'] ?? false,
        razorPayEnabled: json['razor_pay'] ?? false,
        paystackEnabled: json['paystack'] ?? false,
        cashFreeEnabled: json['cash_free'] ?? false,
        flutterWaveEnabled: json['flutter_wave'] ?? false,
        khaltiPayEnabled: json['khalti_pay'] ?? false,
        stripePublishableKey: json['stripe_publishable_key'] ?? '',
        razorPayKey: json['razorpay_api_key'] ?? '',
        paystackPublicKey: json['paystack_public_key'] ?? '',
        cashFreeAppId: json['cashfree_app_id'] ?? '',
        flutterWavePublicKey: json['flutterwave_public_key'] ?? '',
        khaltiPublicKey: json['khalti_public_key'] ?? '',
        environment: json['environment'] ?? 'test',
        currencyCode: json['currency_code'] ?? 'USD',
        currencySymbol: json['currency_symbol'] ?? '\$',
        minimumAmount: json['minimum_amount'] ?? '10',
        enableSaveCard: json['enable_save_card'] ?? true,
      );

  Map<String, dynamic> toJson() => {
        'stripe': stripeEnabled,
        'razor_pay': razorPayEnabled,
        'paystack': paystackEnabled,
        'cash_free': cashFreeEnabled,
        'flutter_wave': flutterWaveEnabled,
        'khalti_pay': khaltiPayEnabled,
        'stripe_publishable_key': stripePublishableKey,
        'razorpay_api_key': razorPayKey,
        'paystack_public_key': paystackPublicKey,
        'cashfree_app_id': cashFreeAppId,
        'flutterwave_public_key': flutterWavePublicKey,
        'khalti_public_key': khaltiPublicKey,
        'environment': environment,
        'currency_code': currencyCode,
        'currency_symbol': currencySymbol,
        'minimum_amount': minimumAmount,
        'enable_save_card': enableSaveCard,
      };
}

/// Payment gateway item model
class PaymentGatewayItem {
  final String id;
  final String name;
  final PaymentGatewayType type;
  final bool enabled;
  final String image;
  final String? cardToken; // For saved cards
  final String? lastFourDigits; // For saved cards
  final String? cardBrand; // visa, mastercard, etc.
  final bool isCard;
  final Map<String, dynamic>? metadata;

  PaymentGatewayItem({
    required this.id,
    required this.name,
    required this.type,
    this.enabled = true,
    this.image = '',
    this.cardToken,
    this.lastFourDigits,
    this.cardBrand,
    this.isCard = false,
    this.metadata,
  });

  factory PaymentGatewayItem.fromJson(Map<String, dynamic> json) =>
      PaymentGatewayItem(
        id: json['id']?.toString() ?? '',
        name: json['gateway'] ?? json['name'] ?? '',
        type: _parsePaymentType(json['gateway'] ?? json['type'] ?? ''),
        enabled: json['enabled'] ?? true,
        image: json['image'] ?? '',
        cardToken: json['url'] ?? json['card_token'],
        lastFourDigits: json['last_four_digits'],
        cardBrand: json['card_brand'],
        isCard: json['is_card'] ?? false,
        metadata: json['metadata'],
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'type': type.toString(),
        'enabled': enabled,
        'image': image,
        'card_token': cardToken,
        'last_four_digits': lastFourDigits,
        'card_brand': cardBrand,
        'is_card': isCard,
        'metadata': metadata,
      };

  static PaymentGatewayType _parsePaymentType(String type) {
    final lowerType = type.toLowerCase();
    if (lowerType.contains('stripe') || lowerType.contains('card')) {
      return PaymentGatewayType.stripe;
    } else if (lowerType.contains('razorpay') || lowerType.contains('razor')) {
      return PaymentGatewayType.razorPay;
    } else if (lowerType.contains('paystack')) {
      return PaymentGatewayType.paystack;
    } else if (lowerType.contains('cashfree') || lowerType.contains('cash')) {
      return PaymentGatewayType.cashFree;
    } else if (lowerType.contains('flutterwave') ||
        lowerType.contains('flutter')) {
      return PaymentGatewayType.flutterWave;
    } else if (lowerType.contains('khalti')) {
      return PaymentGatewayType.khalti;
    }
    return PaymentGatewayType.other;
  }

  PaymentGatewayItem copyWith({
    String? id,
    String? name,
    PaymentGatewayType? type,
    bool? enabled,
    String? image,
    String? cardToken,
    String? lastFourDigits,
    String? cardBrand,
    bool? isCard,
    Map<String, dynamic>? metadata,
  }) {
    return PaymentGatewayItem(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      enabled: enabled ?? this.enabled,
      image: image ?? this.image,
      cardToken: cardToken ?? this.cardToken,
      lastFourDigits: lastFourDigits ?? this.lastFourDigits,
      cardBrand: cardBrand ?? this.cardBrand,
      isCard: isCard ?? this.isCard,
      metadata: metadata ?? this.metadata,
    );
  }
}

/// Payment gateway types
enum PaymentGatewayType {
  stripe,
  razorPay,
  paystack,
  cashFree,
  flutterWave,
  khalti,
  other,
}

/// Payment transaction model
class PaymentTransaction {
  final String id;
  final String userId;
  final double amount;
  final String currencyCode;
  final String currencySymbol;
  final PaymentStatus status;
  final PaymentGatewayType gateway;
  final String? transactionId;
  final String? paymentIntentId;
  final String? errorMessage;
  final DateTime createdAt;
  final DateTime? completedAt;
  final Map<String, dynamic>? metadata;

  PaymentTransaction({
    required this.id,
    required this.userId,
    required this.amount,
    required this.currencyCode,
    required this.currencySymbol,
    required this.status,
    required this.gateway,
    this.transactionId,
    this.paymentIntentId,
    this.errorMessage,
    required this.createdAt,
    this.completedAt,
    this.metadata,
  });

  factory PaymentTransaction.fromJson(Map<String, dynamic> json) =>
      PaymentTransaction(
        id: json['id']?.toString() ?? '',
        userId: json['user_id']?.toString() ?? '',
        amount: double.tryParse(json['amount']?.toString() ?? '0') ?? 0.0,
        currencyCode: json['currency_code'] ?? 'USD',
        currencySymbol: json['currency_symbol'] ?? '\$',
        status: _parseStatus(json['status']),
        gateway: PaymentGatewayItem._parsePaymentType(json['gateway'] ?? ''),
        transactionId: json['transaction_id'],
        paymentIntentId: json['payment_intent_id'],
        errorMessage: json['error_message'],
        createdAt: json['created_at'] != null
            ? DateTime.parse(json['created_at'])
            : DateTime.now(),
        completedAt: json['completed_at'] != null
            ? DateTime.parse(json['completed_at'])
            : null,
        metadata: json['metadata'],
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'amount': amount,
        'currency_code': currencyCode,
        'currency_symbol': currencySymbol,
        'status': status.toString(),
        'gateway': gateway.toString(),
        'transaction_id': transactionId,
        'payment_intent_id': paymentIntentId,
        'error_message': errorMessage,
        'created_at': createdAt.toIso8601String(),
        'completed_at': completedAt?.toIso8601String(),
        'metadata': metadata,
      };

  static PaymentStatus _parseStatus(String? status) {
    switch (status?.toLowerCase()) {
      case 'pending':
        return PaymentStatus.pending;
      case 'processing':
        return PaymentStatus.processing;
      case 'success':
      case 'completed':
        return PaymentStatus.success;
      case 'failed':
      case 'error':
        return PaymentStatus.failed;
      case 'cancelled':
        return PaymentStatus.cancelled;
      default:
        return PaymentStatus.pending;
    }
  }
}

/// Payment status enum
enum PaymentStatus {
  pending,
  processing,
  success,
  failed,
  cancelled,
}

/// Stripe specific models
class StripeSetupIntentResponse {
  final bool success;
  final String message;
  final String clientSecret;
  final String? customerId;
  final bool testEnvironment;

  StripeSetupIntentResponse({
    required this.success,
    required this.message,
    required this.clientSecret,
    this.customerId,
    this.testEnvironment = true,
  });

  factory StripeSetupIntentResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] ?? {};
    return StripeSetupIntentResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      clientSecret: data['client_secret'] ?? '',
      customerId: data['customer_id'],
      testEnvironment: data['test_environment'] ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
        'success': success,
        'message': message,
        'data': {
          'client_secret': clientSecret,
          'customer_id': customerId,
          'test_environment': testEnvironment,
        },
      };
}

/// Payment result model
class PaymentResult {
  final bool success;
  final String message;
  final String? transactionId;
  final PaymentTransaction? transaction;
  final dynamic data;

  PaymentResult({
    required this.success,
    required this.message,
    this.transactionId,
    this.transaction,
    this.data,
  });

  factory PaymentResult.success({
    String message = 'Payment successful',
    String? transactionId,
    PaymentTransaction? transaction,
    dynamic data,
  }) {
    return PaymentResult(
      success: true,
      message: message,
      transactionId: transactionId,
      transaction: transaction,
      data: data,
    );
  }

  factory PaymentResult.failure({
    String message = 'Payment failed',
    dynamic data,
  }) {
    return PaymentResult(
      success: false,
      message: message,
      data: data,
    );
  }

  factory PaymentResult.fromJson(Map<String, dynamic> json) => PaymentResult(
        success: json['success'] ?? false,
        message: json['message'] ?? '',
        transactionId: json['transaction_id'],
        transaction: json['transaction'] != null
            ? PaymentTransaction.fromJson(json['transaction'])
            : null,
        data: json['data'],
      );

  Map<String, dynamic> toJson() => {
        'success': success,
        'message': message,
        'transaction_id': transactionId,
        'transaction': transaction?.toJson(),
        'data': data,
      };
}
