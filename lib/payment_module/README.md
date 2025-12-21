# Payment Module - Standalone Payment Integration

A complete, standalone payment module for Flutter apps with support for multiple payment gateways, card saving, and beautiful UI.

## Features

✅ **Multiple Payment Gateways**
- Stripe
- RazorPay
- Paystack
- CashFree
- FlutterWave
- Khalti

✅ **Save Cards**
- Save cards securely using Stripe
- Manage saved cards (add/delete)
- Quick payment with saved cards

✅ **Beautiful UI**
- Modern, clean design
- Customizable colors
- Responsive layout
- Loading states and animations

✅ **Complete Functionality**
- Amount input with validation
- Payment gateway selection
- Payment processing
- Success/Error handling
- Transaction history

✅ **Easy Integration**
- Standalone module
- Mock repository for testing
- Detailed documentation
- Minimal dependencies

## Installation

### 1. Copy the Module

Copy the entire `payment_module` folder to your Flutter project's `lib` directory.

```
lib/
  payment_module/
    models/
    repositories/
    services/
    provider/
    presentation/
```

### 2. Add Dependencies

Add these dependencies to your `pubspec.yaml`:

```yaml
dependencies:
  flutter:
    sdk: flutter
  
  # State Management
  provider: ^6.1.1
  
  # Payment Gateways
  flutter_stripe: ^11.4.0
  
  # Image Handling
  cached_network_image: ^3.3.0
```

### 3. Initialize Stripe

In your `main.dart`, initialize Stripe before running the app:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Stripe
  Stripe.publishableKey = 'YOUR_STRIPE_PUBLISHABLE_KEY';
  Stripe.merchantIdentifier = 'merchant.your.app';
  Stripe.urlScheme = 'flutterstripe';
  await Stripe.instance.applySettings();
  
  runApp(MyApp());
}
```

## Usage

### Basic Usage

Navigate to the payment screen:

```dart
import 'package:flutter/material.dart';
import 'payment_module/presentation/payment_screen.dart';

// Navigate to payment screen
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => PaymentScreen(
      userId: 'user_123',
      initialAmount: 50.0,
      title: 'Add Money to Wallet',
      onPaymentSuccess: () {
        print('Payment successful!');
      },
      onPaymentFailed: () {
        print('Payment failed!');
      },
    ),
  ),
);
```

### Customized Colors

```dart
PaymentScreen(
  userId: 'user_123',
  initialAmount: 100.0,
  title: 'Payment',
  primaryColor: Colors.blue,
  backgroundColor: Colors.grey[100],
  onPaymentSuccess: () {
    // Handle success
  },
  onPaymentFailed: () {
    // Handle failure
  },
)
```

### Using with Real API

Replace `MockPaymentRepository` with your own implementation:

```dart
// 1. Create your own repository implementation
class ApiPaymentRepository implements PaymentRepository {
  final Dio dio;
  
  ApiPaymentRepository(this.dio);
  
  @override
  Future<List<PaymentGatewayItem>> getPaymentGateways() async {
    final response = await dio.get('/api/payment-gateways');
    return (response.data as List)
        .map((json) => PaymentGatewayItem.fromJson(json))
        .toList();
  }
  
  @override
  Future<PaymentResult> processPayment({
    required String userId,
    required double amount,
    required PaymentGatewayItem gateway,
    Map<String, dynamic>? metadata,
  }) async {
    final response = await dio.post('/api/process-payment', data: {
      'user_id': userId,
      'amount': amount,
      'gateway': gateway.type.toString(),
      'metadata': metadata,
    });
    
    return PaymentResult.fromJson(response.data);
  }
  
  // Implement other methods...
}

// 2. Use your repository in the payment screen
PaymentScreen(
  userId: 'user_123',
  repository: ApiPaymentRepository(Dio()),
)
```

## Architecture

```
payment_module/
├── models/                         # Data models
│   └── payment_gateway_model.dart  # Payment models
├── repositories/                   # Data layer
│   └── payment_repository.dart     # Repository interface & mock
├── services/                       # Business logic
│   └── payment_service.dart        # Payment service (Stripe, etc.)
├── bloc/                          # State management
│   ├── payment_bloc.dart          # BLoC implementation
│   ├── payment_event.dart         # Events
│   └── payment_state.dart         # States
└── presentation/                  # UI layer
    ├── payment_screen.dart        # Main payment screen
    └── widgets/                   # UI widgets
        ├── payment_gateway_item_widget.dart
        ├── payment_amount_input_widget.dart
        ├── payment_success_dialog.dart
        └── payment_error_dialog.dart
```

## Models

### PaymentConfiguration

```dart
PaymentConfiguration(
  stripeEnabled: true,
  razorPayEnabled: true,
  stripePublishableKey: 'pk_test_...',
  environment: 'test',
  currencyCode: 'USD',
  currencySymbol: '\$',
  minimumAmount: '10',
  enableSaveCard: true,
)
```

### PaymentGatewayItem

```dart
PaymentGatewayItem(
  id: 'stripe',
  name: 'Credit/Debit Card',
  type: PaymentGatewayType.stripe,
  enabled: true,
  image: 'stripe',
  isCard: false,
)
```

### PaymentTransaction

```dart
PaymentTransaction(
  id: 'txn_123',
  userId: 'user_123',
  amount: 50.0,
  currencyCode: 'USD',
  currencySymbol: '\$',
  status: PaymentStatus.success,
  gateway: PaymentGatewayType.stripe,
  transactionId: 'pay_123',
  createdAt: DateTime.now(),
)
```

## Customization

### Change Colors

```dart
PaymentScreen(
  primaryColor: Color(0xFF6366F1), // Indigo
  backgroundColor: Colors.white,
)
```

### Custom Payment Gateways

Add your own payment gateway by implementing the repository:

```dart
@override
Future<List<PaymentGatewayItem>> getPaymentGateways() async {
  return [
    PaymentGatewayItem(
      id: 'custom',
      name: 'Custom Gateway',
      type: PaymentGatewayType.other,
      enabled: true,
      image: 'https://example.com/logo.png',
    ),
  ];
}
```

### Custom Validation

Override the minimum amount validation:

```dart
bool validateAmount({
  required double amount,
  required String minimumAmount,
}) {
  // Your custom validation logic
  return amount >= 5.0 && amount <= 1000.0;
}
```

## Testing with Mock Data

The module comes with a `MockPaymentRepository` that simulates API calls:

- Adds delay to simulate network requests
- Returns dummy payment gateways
- Simulates payment success (90% success rate)
- Manages saved cards in memory

Perfect for development and testing without a backend!

## API Integration Guide

### 1. Create Repository Implementation

```dart
class MyPaymentRepository implements PaymentRepository {
  final String baseUrl;
  final Dio dio;
  
  MyPaymentRepository({
    required this.baseUrl,
    required this.dio,
  });
  
  @override
  Future<PaymentConfiguration> getPaymentConfiguration() async {
    final response = await dio.get('$baseUrl/payment/config');
    return PaymentConfiguration.fromJson(response.data);
  }
  
  // Implement other methods...
}
```

### 2. Update Payment Screen

```dart
BlocProvider(
  create: (context) => PaymentBloc(
    repository: MyPaymentRepository(
      baseUrl: 'https://api.example.com',
      dio: Dio(),
    ),
    paymentService: PaymentService(),
  )..add(InitializePaymentEvent()),
  child: PaymentScreen(userId: userId),
)
```

## Events

- `InitializePaymentEvent` - Initialize payment module
- `LoadPaymentGatewaysEvent` - Load available payment gateways
- `SelectPaymentGatewayEvent` - Select a payment gateway
- `ProcessPaymentEvent` - Process payment
- `AddCardEvent` - Add new card
- `SaveCardEvent` - Save card after setup
- `DeleteCardEvent` - Delete saved card
- `LoadPaymentHistoryEvent` - Load payment history
- `UpdateAmountEvent` - Update payment amount
- `ValidatePaymentEvent` - Validate payment details
- `ResetPaymentEvent` - Reset payment state

## States

- `PaymentInitialState` - Initial state
- `PaymentLoadingState` - Loading data
- `PaymentGatewaysLoadedState` - Gateways loaded
- `PaymentProcessingState` - Processing payment
- `PaymentSuccessState` - Payment successful
- `PaymentFailedState` - Payment failed
- `AddingCardState` - Adding card
- `CardAddedState` - Card added
- `CardDeletedState` - Card deleted
- `PaymentHistoryLoadedState` - History loaded
- `PaymentErrorState` - Error occurred

## Stripe Integration

The module uses Stripe's Payment Sheet for secure card handling:

1. Call `getStripeSetupIntent()` to create setup intent
2. Present Stripe's Payment Sheet with the client secret
3. User enters card details securely
4. Stripe returns payment method ID
5. Save payment method to your backend

```dart
// In your repository
@override
Future<StripeSetupIntentResponse> getStripeSetupIntent() async {
  final response = await dio.post('$baseUrl/stripe/setup-intent');
  return StripeSetupIntentResponse.fromJson(response.data);
}
```

## Security Notes

⚠️ **Never store card details directly!**
- Use Stripe's tokenization
- Store only payment method IDs
- All card data handled by Stripe

⚠️ **Use HTTPS for all API calls**

⚠️ **Validate on server-side**
- Don't trust client-side validation
- Verify amounts on backend
- Check user authentication

## Screenshots

[Screenshots would go here showing:]
- Payment gateway selection
- Amount input
- Card adding flow
- Success screen
- Error handling

## Support

For issues or questions, please refer to:
- Stripe Documentation: https://stripe.com/docs
- Flutter Stripe Package: https://pub.dev/packages/flutter_stripe
- Flutter BLoC: https://bloclibrary.dev

## License

This module is part of your project and follows your project's license.

## Credits

Built with:
- Flutter
- flutter_bloc for state management
- flutter_stripe for payment processing
- cached_network_image for image handling

---

**Ready to integrate payments in your app! 🚀**
