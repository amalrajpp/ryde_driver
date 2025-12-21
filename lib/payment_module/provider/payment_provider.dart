import 'package:flutter/material.dart';
import '../models/payment_gateway_model.dart';
import '../repositories/payment_repository.dart';
import '../services/payment_service.dart';

/// Payment provider for state management without BLoC
class PaymentProvider extends ChangeNotifier {
  final PaymentRepository repository;
  final PaymentService paymentService;

  PaymentProvider({
    required this.repository,
    required this.paymentService,
  });

  // State
  bool _isLoading = false;
  bool _isProcessing = false;
  String? _errorMessage;
  List<PaymentGatewayItem> _gateways = [];
  PaymentConfiguration? _configuration;
  int? _selectedIndex;
  String _amount = '0';
  PaymentResult? _lastResult;
  bool _showSuccessDialog = false;
  bool _showErrorDialog = false;
  String? _clientSecret;

  // Getters
  bool get isLoading => _isLoading;
  bool get isProcessing => _isProcessing;
  String? get errorMessage => _errorMessage;
  List<PaymentGatewayItem> get gateways => _gateways;
  PaymentConfiguration? get configuration => _configuration;
  int? get selectedIndex => _selectedIndex;
  String get amount => _amount;
  PaymentResult? get lastResult => _lastResult;
  bool get showSuccessDialog => _showSuccessDialog;
  bool get showErrorDialog => _showErrorDialog;
  String? get clientSecret => _clientSecret;

  /// Initialize payment module
  Future<void> initialize() async {
    try {
      _setLoading(true);
      _errorMessage = null;

      // Load configuration
      _configuration = await repository.getPaymentConfiguration();

      // Initialize payment service
      await paymentService.initialize(_configuration!);

      // Load payment gateways
      await loadGateways();

      _setLoading(false);
    } catch (e) {
      _errorMessage = 'Failed to initialize: ${e.toString()}';
      _setLoading(false);
    }
  }

  /// Load payment gateways
  Future<void> loadGateways() async {
    try {
      _setLoading(true);
      _errorMessage = null;

      if (_configuration == null) {
        _configuration = await repository.getPaymentConfiguration();
        await paymentService.initialize(_configuration!);
      }

      _gateways = await repository.getPaymentGateways();
      _setLoading(false);
    } catch (e) {
      _errorMessage = 'Failed to load payment methods: ${e.toString()}';
      _setLoading(false);
    }
  }

  /// Select payment gateway
  void selectGateway(int index) {
    _selectedIndex = index;
    notifyListeners();
  }

  /// Update amount
  void updateAmount(String amount) {
    _amount = amount;
    notifyListeners();
  }

  /// Process payment
  Future<void> processPayment({
    required String userId,
    required double amount,
    Map<String, dynamic>? metadata,
  }) async {
    if (_selectedIndex == null || _selectedIndex! >= _gateways.length) {
      _errorMessage = 'Please select a payment method';
      notifyListeners();
      return;
    }

    try {
      _setProcessing(true);
      _errorMessage = null;
      _showSuccessDialog = false;
      _showErrorDialog = false;

      final gateway = _gateways[_selectedIndex!];

      PaymentResult result;
      if (gateway.isCard) {
        result = await repository.processPaymentWithCard(
          userId: userId,
          amount: amount,
          cardToken: gateway.cardToken!,
          metadata: metadata,
        );
      } else {
        result = await repository.processPayment(
          userId: userId,
          amount: amount,
          gateway: gateway,
          metadata: metadata,
        );
      }

      _lastResult = result;
      _setProcessing(false);

      if (result.success) {
        _showSuccessDialog = true;
        notifyListeners();
        // Reload gateways after successful payment
        await Future.delayed(const Duration(seconds: 2));
        await loadGateways();
      } else {
        _errorMessage = result.message;
        _showErrorDialog = true;
        notifyListeners();
        await Future.delayed(const Duration(seconds: 2));
        _showErrorDialog = false;
        notifyListeners();
      }
    } catch (e) {
      _errorMessage = 'Payment failed: ${e.toString()}';
      _setProcessing(false);
      _showErrorDialog = true;
      notifyListeners();
      await Future.delayed(const Duration(seconds: 2));
      _showErrorDialog = false;
      notifyListeners();
    }
  }

  /// Add new card
  Future<void> addCard(String userId) async {
    try {
      _setLoading(true);
      _errorMessage = null;

      final response = await repository.getStripeSetupIntent();

      if (response.success) {
        _clientSecret = response.clientSecret;
        _setLoading(false);
      } else {
        _errorMessage = response.message;
        _setLoading(false);
      }
    } catch (e) {
      _errorMessage = 'Failed to setup card: ${e.toString()}';
      _setLoading(false);
    }
  }

  /// Save card after setup intent
  Future<void> saveCard({
    required String userId,
    required String paymentMethodId,
  }) async {
    try {
      _setLoading(true);
      _errorMessage = null;
      _clientSecret = null;

      final result = await repository.saveCardDetails(
        paymentMethodId: paymentMethodId,
        userId: userId,
      );

      if (result.success) {
        await loadGateways();
        _setLoading(false);
        // Show success message
        _showSuccessDialog = true;
        notifyListeners();
        await Future.delayed(const Duration(seconds: 1));
        _showSuccessDialog = false;
        notifyListeners();
      } else {
        _errorMessage = result.message;
        _setLoading(false);
      }
    } catch (e) {
      _errorMessage = 'Failed to save card: ${e.toString()}';
      _setLoading(false);
    }
  }

  /// Delete saved card
  Future<void> deleteCard({
    required String userId,
    required String cardToken,
    required int index,
  }) async {
    try {
      _setLoading(true);
      _errorMessage = null;

      final success = await repository.deleteSavedCard(
        userId: userId,
        cardToken: cardToken,
      );

      if (success) {
        _gateways.removeAt(index);
        if (_selectedIndex == index) {
          _selectedIndex = null;
        }
        _setLoading(false);
      } else {
        _errorMessage = 'Failed to remove card';
        _setLoading(false);
      }
    } catch (e) {
      _errorMessage = 'Failed to remove card: ${e.toString()}';
      _setLoading(false);
    }
  }

  /// Validate amount
  bool validateAmount(double amount) {
    if (_configuration == null) return false;

    return PaymentService.validateAmount(
      amount: amount,
      minimumAmount: _configuration!.minimumAmount,
    );
  }

  /// Reset state
  void reset() {
    _selectedIndex = null;
    _amount = '0';
    _errorMessage = null;
    _lastResult = null;
    _showSuccessDialog = false;
    _showErrorDialog = false;
    _clientSecret = null;
    notifyListeners();
  }

  /// Clear error
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Hide success dialog
  void hideSuccessDialog() {
    _showSuccessDialog = false;
    notifyListeners();
  }

  /// Hide error dialog
  void hideErrorDialog() {
    _showErrorDialog = false;
    notifyListeners();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setProcessing(bool value) {
    _isProcessing = value;
    notifyListeners();
  }
}
