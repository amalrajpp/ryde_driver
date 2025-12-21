import '../models/payment_gateway_model.dart';

/// Base payment event
abstract class PaymentEvent {}

/// Initialize payment module
class InitializePaymentEvent extends PaymentEvent {}

/// Load payment gateways
class LoadPaymentGatewaysEvent extends PaymentEvent {}

/// Select payment gateway
class SelectPaymentGatewayEvent extends PaymentEvent {
  final int index;
  final PaymentGatewayItem gateway;

  SelectPaymentGatewayEvent({
    required this.index,
    required this.gateway,
  });
}

/// Process payment
class ProcessPaymentEvent extends PaymentEvent {
  final String userId;
  final double amount;
  final PaymentGatewayItem gateway;
  final Map<String, dynamic>? metadata;

  ProcessPaymentEvent({
    required this.userId,
    required this.amount,
    required this.gateway,
    this.metadata,
  });
}

/// Add new card
class AddCardEvent extends PaymentEvent {
  final String userId;

  AddCardEvent({required this.userId});
}

/// Save card after setup intent
class SaveCardEvent extends PaymentEvent {
  final String userId;
  final String paymentMethodId;

  SaveCardEvent({
    required this.userId,
    required this.paymentMethodId,
  });
}

/// Delete saved card
class DeleteCardEvent extends PaymentEvent {
  final String userId;
  final String cardToken;
  final int index;

  DeleteCardEvent({
    required this.userId,
    required this.cardToken,
    required this.index,
  });
}

/// Load payment history
class LoadPaymentHistoryEvent extends PaymentEvent {
  final String userId;
  final int page;

  LoadPaymentHistoryEvent({
    required this.userId,
    this.page = 1,
  });
}

/// Update amount
class UpdateAmountEvent extends PaymentEvent {
  final String amount;

  UpdateAmountEvent({required this.amount});
}

/// Validate payment
class ValidatePaymentEvent extends PaymentEvent {
  final double amount;

  ValidatePaymentEvent({required this.amount});
}

/// Reset payment state
class ResetPaymentEvent extends PaymentEvent {}

/// Show add card sheet
class ShowAddCardSheetEvent extends PaymentEvent {}

/// Hide add card sheet
class HideAddCardSheetEvent extends PaymentEvent {}
