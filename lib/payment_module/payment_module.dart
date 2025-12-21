/// Payment Module - Standalone Payment Integration
///
/// This module provides a complete payment solution with:
/// - Multiple payment gateway support (Stripe, RazorPay, Paystack, etc.)
/// - Save card functionality
/// - Payment history
/// - Beautiful UI with customization options
/// - Easy integration with any Flutter app

library payment_module;

// Models
export 'models/payment_gateway_model.dart';

// Repositories
export 'repositories/payment_repository.dart';

// Services
export 'services/payment_service.dart';

// Provider (State Management)
export 'provider/payment_provider.dart';

// Presentation
export 'presentation/payment_screen.dart';
export 'presentation/widgets/payment_gateway_item_widget.dart';
export 'presentation/widgets/payment_amount_input_widget.dart';
export 'presentation/widgets/payment_success_dialog.dart';
export 'presentation/widgets/payment_error_dialog.dart';
