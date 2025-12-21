import '../models/payment_gateway_model.dart';

/// Base payment state
abstract class PaymentState {}

/// Initial state
class PaymentInitialState extends PaymentState {}

/// Loading state
class PaymentLoadingState extends PaymentState {
  final String? message;

  PaymentLoadingState({this.message});
}

/// Payment gateways loaded
class PaymentGatewaysLoadedState extends PaymentState {
  final List<PaymentGatewayItem> gateways;
  final PaymentConfiguration configuration;
  final int? selectedIndex;
  final String amount;

  PaymentGatewaysLoadedState({
    required this.gateways,
    required this.configuration,
    this.selectedIndex,
    this.amount = '0',
  });

  PaymentGatewaysLoadedState copyWith({
    List<PaymentGatewayItem>? gateways,
    PaymentConfiguration? configuration,
    int? selectedIndex,
    String? amount,
  }) {
    return PaymentGatewaysLoadedState(
      gateways: gateways ?? this.gateways,
      configuration: configuration ?? this.configuration,
      selectedIndex: selectedIndex ?? this.selectedIndex,
      amount: amount ?? this.amount,
    );
  }
}

/// Payment gateway selected
class PaymentGatewaySelectedState extends PaymentState {
  final int selectedIndex;
  final PaymentGatewayItem gateway;

  PaymentGatewaySelectedState({
    required this.selectedIndex,
    required this.gateway,
  });
}

/// Payment processing
class PaymentProcessingState extends PaymentState {
  final String message;

  PaymentProcessingState({this.message = 'Processing payment...'});
}

/// Payment success
class PaymentSuccessState extends PaymentState {
  final PaymentResult result;
  final String message;

  PaymentSuccessState({
    required this.result,
    this.message = 'Payment successful!',
  });
}

/// Payment failed
class PaymentFailedState extends PaymentState {
  final String message;
  final dynamic error;

  PaymentFailedState({
    required this.message,
    this.error,
  });
}

/// Card adding state
class AddingCardState extends PaymentState {
  final String clientSecret;

  AddingCardState({required this.clientSecret});
}

/// Card added successfully
class CardAddedState extends PaymentState {
  final String message;
  final PaymentGatewayItem card;

  CardAddedState({
    required this.message,
    required this.card,
  });
}

/// Card deleted
class CardDeletedState extends PaymentState {
  final String message;

  CardDeletedState({required this.message});
}

/// Payment history loaded
class PaymentHistoryLoadedState extends PaymentState {
  final List<PaymentTransaction> transactions;
  final int currentPage;
  final bool hasMore;

  PaymentHistoryLoadedState({
    required this.transactions,
    this.currentPage = 1,
    this.hasMore = false,
  });
}

/// Amount validation state
class AmountValidationState extends PaymentState {
  final bool isValid;
  final String? errorMessage;
  final double amount;

  AmountValidationState({
    required this.isValid,
    this.errorMessage,
    required this.amount,
  });
}

/// Show add card bottom sheet
class ShowAddCardSheetState extends PaymentState {}

/// Error state
class PaymentErrorState extends PaymentState {
  final String message;
  final dynamic error;

  PaymentErrorState({
    required this.message,
    this.error,
  });
}
