import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/payment_gateway_model.dart';
import '../config/payment_config.dart';

/// Real payment repository implementation with backend API integration
class RealPaymentRepository {
  final String baseUrl;
  final String Function() getAuthToken;

  RealPaymentRepository({String? baseUrl, required this.getAuthToken})
    : baseUrl = baseUrl ?? PaymentConfig.apiBaseUrl;

  /// Get headers with authentication
  Map<String, String> _getHeaders() {
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer ${getAuthToken()}',
    };
  }

  /// Get payment configuration from backend
  Future<PaymentConfiguration> getPaymentConfiguration() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/payment/config'),
        headers: _getHeaders(),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return PaymentConfiguration.fromJson(data['data']);
      } else {
        throw Exception('Failed to load payment configuration');
      }
    } catch (e) {
      // Fallback to local configuration
      return _getLocalConfiguration();
    }
  }

  /// Get available payment gateways from backend
  Future<List<PaymentGatewayItem>> getPaymentGateways(String userId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/payment/gateways?user_id=$userId'),
        headers: _getHeaders(),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> gatewaysList = data['data'];
        return gatewaysList
            .map((json) => PaymentGatewayItem.fromJson(json))
            .toList();
      } else {
        throw Exception('Failed to load payment gateways');
      }
    } catch (e) {
      // Fallback to local gateways
      return _getLocalGateways();
    }
  }

  /// Process payment through backend
  Future<PaymentResult> processPayment({
    required String userId,
    required double amount,
    required PaymentGatewayItem gateway,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final body = {
        'user_id': userId,
        'amount': amount,
        'gateway_id': gateway.id,
        'gateway_type': gateway.type.toString().split('.').last,
        'metadata': metadata,
      };

      final response = await http.post(
        Uri.parse('$baseUrl/payment/process'),
        headers: _getHeaders(),
        body: json.encode(body),
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        return PaymentResult(
          success: true,
          message: data['message'] ?? 'Payment successful',
          transactionId: data['data']['transaction_id'],
          data: {
            'payment_intent_id': data['data']['payment_intent_id'],
            'client_secret': data['data']['client_secret'],
          },
        );
      } else {
        return PaymentResult.failure(
          message: data['message'] ?? 'Payment failed',
        );
      }
    } catch (e) {
      return PaymentResult.failure(message: 'Network error: ${e.toString()}');
    }
  }

  /// Get Stripe setup intent for adding card
  Future<StripeSetupIntentResponse> getStripeSetupIntent(String userId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/payment/stripe/setup-intent'),
        headers: _getHeaders(),
        body: json.encode({'user_id': userId}),
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        return StripeSetupIntentResponse.fromJson(data);
      } else {
        throw Exception(data['message'] ?? 'Failed to create setup intent');
      }
    } catch (e) {
      throw Exception('Failed to get setup intent: ${e.toString()}');
    }
  }

  /// Save card details to backend after Stripe confirmation
  Future<PaymentResult> saveCardDetails({
    required String paymentMethodId,
    required String userId,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/payment/card/save'),
        headers: _getHeaders(),
        body: json.encode({
          'user_id': userId,
          'payment_method_id': paymentMethodId,
        }),
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        return PaymentResult.success(
          message: data['message'] ?? 'Card saved successfully',
        );
      } else {
        return PaymentResult.failure(
          message: data['message'] ?? 'Failed to save card',
        );
      }
    } catch (e) {
      return PaymentResult.failure(
        message: 'Failed to save card: ${e.toString()}',
      );
    }
  }

  /// Process payment with saved card
  Future<PaymentResult> processPaymentWithCard({
    required String userId,
    required double amount,
    required String cardToken,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/payment/card/charge'),
        headers: _getHeaders(),
        body: json.encode({
          'user_id': userId,
          'amount': amount,
          'card_token': cardToken,
          'metadata': metadata,
        }),
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        return PaymentResult(
          success: true,
          message: data['message'] ?? 'Payment successful',
          transactionId: data['data']['transaction_id'],
          data: {'client_secret': data['data']['client_secret']},
        );
      } else {
        return PaymentResult.failure(
          message: data['message'] ?? 'Payment failed',
        );
      }
    } catch (e) {
      return PaymentResult.failure(message: 'Payment failed: ${e.toString()}');
    }
  }

  /// Get payment history
  Future<List<PaymentTransaction>> getPaymentHistory({
    required String userId,
    int page = 1,
    int perPage = 20,
  }) async {
    try {
      final response = await http.get(
        Uri.parse(
          '$baseUrl/payment/history?user_id=$userId&page=$page&per_page=$perPage',
        ),
        headers: _getHeaders(),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> transactions = data['data'];
        return transactions
            .map((json) => PaymentTransaction.fromJson(json))
            .toList();
      } else {
        return [];
      }
    } catch (e) {
      return [];
    }
  }

  /// Delete saved card
  Future<bool> deleteSavedCard({
    required String userId,
    required String cardToken,
  }) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/payment/card/delete'),
        headers: _getHeaders(),
        body: json.encode({'user_id': userId, 'card_token': cardToken}),
      );

      final data = json.decode(response.body);
      return response.statusCode == 200 && data['success'] == true;
    } catch (e) {
      return false;
    }
  }

  // ==========================================
  // FALLBACK LOCAL CONFIGURATIONS
  // ==========================================

  /// Local configuration fallback
  PaymentConfiguration _getLocalConfiguration() {
    return PaymentConfiguration(
      stripeEnabled: false,
      razorPayEnabled: PaymentConfig.isRazorPayConfigured,
      paystackEnabled: false,
      cashFreeEnabled: false,
      flutterWaveEnabled: false,
      khaltiPayEnabled: false,
      stripePublishableKey: '',
      razorPayKey: PaymentConfig.razorPayKey,
      environment: PaymentConfig.isProduction ? 'live' : 'test',
      currencyCode: PaymentConfig.defaultCurrencyCode,
      currencySymbol: PaymentConfig.defaultCurrencySymbol,
      minimumAmount: PaymentConfig.minimumAmount,
      enableSaveCard: false,
    );
  }

  /// Local gateways fallback
  List<PaymentGatewayItem> _getLocalGateways() {
    final List<PaymentGatewayItem> gateways = [];

    if (PaymentConfig.isRazorPayConfigured) {
      gateways.add(
        PaymentGatewayItem(
          id: 'razorpay',
          name: 'RazorPay',
          type: PaymentGatewayType.razorPay,
          enabled: true,
          image: 'razorpay',
          isCard: false,
        ),
      );

      gateways.add(
        PaymentGatewayItem(
          id: 'upi',
          name: 'UPI',
          type: PaymentGatewayType.razorPay,
          enabled: true,
          image: 'upi',
          isCard: false,
        ),
      );

      gateways.add(
        PaymentGatewayItem(
          id: 'netbanking',
          name: 'Net Banking',
          type: PaymentGatewayType.razorPay,
          enabled: true,
          image: 'netbanking',
          isCard: false,
        ),
      );
    }

    return gateways;
  }
}
