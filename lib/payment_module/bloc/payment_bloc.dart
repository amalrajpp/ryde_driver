import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../models/payment_gateway_model.dart';
import '../repositories/payment_repository.dart';
import '../services/payment_service.dart';
import 'payment_event.dart';
import 'payment_state.dart';

/// Payment BLoC for managing payment state
class PaymentBloc extends Bloc<PaymentEvent, PaymentState> {
  final PaymentRepository repository;
  final PaymentService paymentService;

  // Current state data
  List<PaymentGatewayItem> _gateways = [];
  PaymentConfiguration? _configuration;
  int? _selectedIndex;
  String _amount = '0';
  List<PaymentTransaction> _transactions = [];

  PaymentBloc({
    required this.repository,
    required this.paymentService,
  }) : super(PaymentInitialState()) {
    on<InitializePaymentEvent>(_onInitialize);
    on<LoadPaymentGatewaysEvent>(_onLoadGateways);
    on<SelectPaymentGatewayEvent>(_onSelectGateway);
    on<ProcessPaymentEvent>(_onProcessPayment);
    on<AddCardEvent>(_onAddCard);
    on<SaveCardEvent>(_onSaveCard);
    on<DeleteCardEvent>(_onDeleteCard);
    on<LoadPaymentHistoryEvent>(_onLoadHistory);
    on<UpdateAmountEvent>(_onUpdateAmount);
    on<ValidatePaymentEvent>(_onValidatePayment);
    on<ResetPaymentEvent>(_onReset);
    on<ShowAddCardSheetEvent>(_onShowAddCardSheet);
  }

  // Getters
  List<PaymentGatewayItem> get gateways => _gateways;
  PaymentConfiguration? get configuration => _configuration;
  int? get selectedIndex => _selectedIndex;
  String get amount => _amount;
  List<PaymentTransaction> get transactions => _transactions;

  /// Initialize payment module
  Future<void> _onInitialize(
    InitializePaymentEvent event,
    Emitter<PaymentState> emit,
  ) async {
    try {
      emit(PaymentLoadingState(message: 'Initializing payment module...'));

      // Load configuration
      _configuration = await repository.getPaymentConfiguration();

      // Initialize payment service
      await paymentService.initialize(_configuration!);

      // Load payment gateways
      add(LoadPaymentGatewaysEvent());
    } catch (e) {
      emit(PaymentErrorState(
        message: 'Failed to initialize payment module',
        error: e,
      ));
    }
  }

  /// Load payment gateways
  Future<void> _onLoadGateways(
    LoadPaymentGatewaysEvent event,
    Emitter<PaymentState> emit,
  ) async {
    try {
      emit(PaymentLoadingState(message: 'Loading payment methods...'));

      // Load configuration if not loaded
      if (_configuration == null) {
        _configuration = await repository.getPaymentConfiguration();
        await paymentService.initialize(_configuration!);
      }

      // Load gateways
      _gateways = await repository.getPaymentGateways();

      emit(PaymentGatewaysLoadedState(
        gateways: _gateways,
        configuration: _configuration!,
        selectedIndex: _selectedIndex,
        amount: _amount,
      ));
    } catch (e) {
      emit(PaymentErrorState(
        message: 'Failed to load payment methods',
        error: e,
      ));
    }
  }

  /// Select payment gateway
  Future<void> _onSelectGateway(
    SelectPaymentGatewayEvent event,
    Emitter<PaymentState> emit,
  ) async {
    _selectedIndex = event.index;

    emit(PaymentGatewaysLoadedState(
      gateways: _gateways,
      configuration: _configuration!,
      selectedIndex: _selectedIndex,
      amount: _amount,
    ));

    emit(PaymentGatewaySelectedState(
      selectedIndex: event.index,
      gateway: event.gateway,
    ));
  }

  /// Process payment
  Future<void> _onProcessPayment(
    ProcessPaymentEvent event,
    Emitter<PaymentState> emit,
  ) async {
    try {
      emit(PaymentProcessingState(message: 'Processing payment...'));

      PaymentResult result;

      if (event.gateway.isCard) {
        // Process with saved card
        result = await repository.processPaymentWithCard(
          userId: event.userId,
          amount: event.amount,
          cardToken: event.gateway.cardToken!,
          metadata: event.metadata,
        );
      } else {
        // Process with payment gateway
        result = await repository.processPayment(
          userId: event.userId,
          amount: event.amount,
          gateway: event.gateway,
          metadata: event.metadata,
        );
      }

      if (result.success) {
        emit(PaymentSuccessState(
          result: result,
          message: result.message,
        ));

        // Reload gateways after successful payment
        await Future.delayed(const Duration(seconds: 2));
        add(LoadPaymentGatewaysEvent());
      } else {
        emit(PaymentFailedState(
          message: result.message,
        ));

        // Return to gateway selection after 2 seconds
        await Future.delayed(const Duration(seconds: 2));
        emit(PaymentGatewaysLoadedState(
          gateways: _gateways,
          configuration: _configuration!,
          selectedIndex: _selectedIndex,
          amount: _amount,
        ));
      }
    } catch (e) {
      emit(PaymentFailedState(
        message: 'Payment failed: ${e.toString()}',
        error: e,
      ));

      // Return to gateway selection after 2 seconds
      await Future.delayed(const Duration(seconds: 2));
      emit(PaymentGatewaysLoadedState(
        gateways: _gateways,
        configuration: _configuration!,
        selectedIndex: _selectedIndex,
        amount: _amount,
      ));
    }
  }

  /// Add new card
  Future<void> _onAddCard(
    AddCardEvent event,
    Emitter<PaymentState> emit,
  ) async {
    try {
      emit(PaymentLoadingState(message: 'Setting up card...'));

      // Get setup intent
      final response = await repository.getStripeSetupIntent();

      if (response.success) {
        emit(AddingCardState(clientSecret: response.clientSecret));
      } else {
        emit(PaymentErrorState(
          message: response.message,
        ));
      }
    } catch (e) {
      emit(PaymentErrorState(
        message: 'Failed to setup card: ${e.toString()}',
        error: e,
      ));
    }
  }

  /// Save card after setup intent
  Future<void> _onSaveCard(
    SaveCardEvent event,
    Emitter<PaymentState> emit,
  ) async {
    try {
      emit(PaymentLoadingState(message: 'Saving card...'));

      final result = await repository.saveCardDetails(
        paymentMethodId: event.paymentMethodId,
        userId: event.userId,
      );

      if (result.success) {
        // Reload gateways
        _gateways = await repository.getPaymentGateways();

        emit(CardAddedState(
          message: result.message,
          card: PaymentGatewayItem.fromJson(result.data),
        ));

        // Return to gateway list
        await Future.delayed(const Duration(seconds: 1));
        emit(PaymentGatewaysLoadedState(
          gateways: _gateways,
          configuration: _configuration!,
          selectedIndex: _selectedIndex,
          amount: _amount,
        ));
      } else {
        emit(PaymentErrorState(message: result.message));
      }
    } catch (e) {
      emit(PaymentErrorState(
        message: 'Failed to save card: ${e.toString()}',
        error: e,
      ));
    }
  }

  /// Delete saved card
  Future<void> _onDeleteCard(
    DeleteCardEvent event,
    Emitter<PaymentState> emit,
  ) async {
    try {
      emit(PaymentLoadingState(message: 'Removing card...'));

      final success = await repository.deleteSavedCard(
        userId: event.userId,
        cardToken: event.cardToken,
      );

      if (success) {
        // Remove from local list
        _gateways.removeAt(event.index);

        emit(CardDeletedState(message: 'Card removed successfully'));

        // Return to gateway list
        await Future.delayed(const Duration(seconds: 1));
        emit(PaymentGatewaysLoadedState(
          gateways: _gateways,
          configuration: _configuration!,
          selectedIndex: _selectedIndex,
          amount: _amount,
        ));
      } else {
        emit(PaymentErrorState(message: 'Failed to remove card'));
      }
    } catch (e) {
      emit(PaymentErrorState(
        message: 'Failed to remove card: ${e.toString()}',
        error: e,
      ));
    }
  }

  /// Load payment history
  Future<void> _onLoadHistory(
    LoadPaymentHistoryEvent event,
    Emitter<PaymentState> emit,
  ) async {
    try {
      emit(PaymentLoadingState(message: 'Loading transactions...'));

      _transactions = await repository.getPaymentHistory(
        userId: event.userId,
        page: event.page,
      );

      emit(PaymentHistoryLoadedState(
        transactions: _transactions,
        currentPage: event.page,
        hasMore: _transactions.length >= 20,
      ));
    } catch (e) {
      emit(PaymentErrorState(
        message: 'Failed to load payment history',
        error: e,
      ));
    }
  }

  /// Update amount
  Future<void> _onUpdateAmount(
    UpdateAmountEvent event,
    Emitter<PaymentState> emit,
  ) async {
    _amount = event.amount;

    emit(PaymentGatewaysLoadedState(
      gateways: _gateways,
      configuration: _configuration!,
      selectedIndex: _selectedIndex,
      amount: _amount,
    ));
  }

  /// Validate payment
  Future<void> _onValidatePayment(
    ValidatePaymentEvent event,
    Emitter<PaymentState> emit,
  ) async {
    if (_configuration == null) return;

    final isValid = PaymentService.validateAmount(
      amount: event.amount,
      minimumAmount: _configuration!.minimumAmount,
    );

    emit(AmountValidationState(
      isValid: isValid,
      errorMessage: isValid
          ? null
          : 'Minimum amount is ${_configuration!.currencySymbol}${_configuration!.minimumAmount}',
      amount: event.amount,
    ));

    // Return to gateway list
    await Future.delayed(const Duration(milliseconds: 100));
    emit(PaymentGatewaysLoadedState(
      gateways: _gateways,
      configuration: _configuration!,
      selectedIndex: _selectedIndex,
      amount: _amount,
    ));
  }

  /// Reset payment state
  Future<void> _onReset(
    ResetPaymentEvent event,
    Emitter<PaymentState> emit,
  ) async {
    _selectedIndex = null;
    _amount = '0';

    emit(PaymentInitialState());
  }

  /// Show add card sheet
  Future<void> _onShowAddCardSheet(
    ShowAddCardSheetEvent event,
    Emitter<PaymentState> emit,
  ) async {
    emit(ShowAddCardSheetState());
  }
}
