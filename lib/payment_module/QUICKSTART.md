# Payment Module - Quick Start Guide

## 🚀 Quick Start (5 Minutes)

### Step 1: Verify Dependencies

Make sure these are in your `pubspec.yaml`:

```yaml
dependencies:
  provider: ^6.1.1
  flutter_stripe: ^11.4.0
  cached_network_image: ^3.3.0
```

Run: `flutter pub get`

### Step 2: Initialize Stripe

In your `main.dart`:

```dart
import 'package:flutter_stripe/flutter_stripe.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  Stripe.publishableKey = 'YOUR_STRIPE_KEY'; // Replace with your key
  await Stripe.instance.applySettings();
  
  runApp(MyApp());
}
```

### Step 3: Use the Payment Screen

```dart
import 'package:flutter/material.dart';
import 'payment_module/presentation/payment_screen.dart';

// Open payment screen
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => PaymentScreen(
      userId: 'user_123',
      initialAmount: 50.0,
    ),
  ),
);
```

**That's it! 🎉 You're ready to accept payments!**

---

## 📋 Integration Checklist

### Required Setup

- [ ] Copy `payment_module` folder to your project
- [ ] Add dependencies to `pubspec.yaml`
- [ ] Run `flutter pub get`
- [ ] Initialize Stripe in `main.dart`
- [ ] Get Stripe publishable key from dashboard

### Optional Setup

- [ ] Configure custom colors
- [ ] Implement real API repository
- [ ] Add transaction history
- [ ] Set up webhooks for server-side verification
- [ ] Add analytics tracking
- [ ] Implement error logging

---

## 🔑 Getting Stripe Keys

### Test Mode (Development)

1. Go to https://dashboard.stripe.com
2. Toggle to "Test mode" (top right)
3. Go to Developers → API keys
4. Copy "Publishable key" (starts with `pk_test_`)

### Live Mode (Production)

1. Complete Stripe account verification
2. Toggle to "Live mode"
3. Copy "Publishable key" (starts with `pk_live_`)

⚠️ **Never commit API keys to version control!**

Use environment variables:
```dart
Stripe.publishableKey = const String.fromEnvironment(
  'STRIPE_KEY',
  defaultValue: 'pk_test_...',
);
```

---

## 🎨 Customization Options

### Colors

```dart
PaymentScreen(
  primaryColor: Color(0xFF6366F1),  // Your brand color
  backgroundColor: Colors.white,
)
```

### Initial Amount

```dart
PaymentScreen(
  initialAmount: 100.0,  // Pre-fill amount
)
```

### Callbacks

```dart
PaymentScreen(
  onPaymentSuccess: () {
    // Update UI
    // Refresh wallet balance
    // Show success message
  },
  onPaymentFailed: () {
    // Show error
    // Log analytics
  },
)
```

---

## 🔄 Connecting to Your Backend

### 1. Create Repository Implementation

```dart
class ApiPaymentRepository implements PaymentRepository {
  final Dio dio;
  final String baseUrl;
  
  @override
  Future<PaymentConfiguration> getPaymentConfiguration() async {
    final response = await dio.get('$baseUrl/payment/config');
    return PaymentConfiguration.fromJson(response.data);
  }
  
  @override
  Future<List<PaymentGatewayItem>> getPaymentGateways() async {
    final response = await dio.get('$baseUrl/payment/gateways');
    return (response.data as List)
        .map((e) => PaymentGatewayItem.fromJson(e))
        .toList();
  }
  
  @override
  Future<PaymentResult> processPayment({
    required String userId,
    required double amount,
    required PaymentGatewayItem gateway,
    Map<String, dynamic>? metadata,
  }) async {
    final response = await dio.post('$baseUrl/payment/process', data: {
      'user_id': userId,
      'amount': amount,
      'gateway': gateway.id,
      'metadata': metadata,
    });
    return PaymentResult.fromJson(response.data);
  }
}
```

### 2. Use Your Repository

```dart
// In payment screen creation
BlocProvider(
  create: (context) => PaymentBloc(
    repository: ApiPaymentRepository(
      dio: Dio(),
      baseUrl: 'https://api.yourapp.com',
    ),
    paymentService: PaymentService(),
  )..add(InitializePaymentEvent()),
  child: PaymentScreen(userId: userId),
)
```

---

## 🧪 Testing

### With Mock Data (Default)

The module comes with `MockPaymentRepository` that works without a backend:
- Simulates network delays
- Returns dummy payment gateways
- 90% payment success rate
- Perfect for development!

### Manual Testing Checklist

- [ ] Open payment screen
- [ ] Enter amount
- [ ] Select payment method
- [ ] Process payment (should succeed most times)
- [ ] Add a new card
- [ ] Delete a saved card
- [ ] Try with invalid amount
- [ ] Test success callback
- [ ] Test failure callback

### Stripe Test Cards

Use these for testing:

| Card Number | Result |
|-------------|--------|
| 4242 4242 4242 4242 | Success |
| 4000 0000 0000 9995 | Declined |
| 4000 0000 0000 3220 | 3D Secure required |

Use any:
- Future expiry date (e.g., 12/34)
- Any 3-digit CVC
- Any postal code

---

## 🐛 Troubleshooting

### Issue: "Target of URI doesn't exist"

**Solution:** Make sure you copied the entire `payment_module` folder

### Issue: Stripe not working

**Solution:** 
1. Check Stripe key is set in `main.dart`
2. Verify key starts with `pk_test_` or `pk_live_`
3. Check internet connection

### Issue: Payment always fails

**Solution:**
1. If using mock: This is random simulation (90% success)
2. If using real API: Check backend logs
3. Verify Stripe webhooks are configured

### Issue: App crashes on payment

**Solution:**
1. Check all dependencies are installed
2. Verify Stripe initialization
3. Check console for error messages

---

## 📱 Platform-Specific Setup

### Android

No additional setup required! 🎉

### iOS

Add to `Info.plist`:

```xml
<key>CFBundleURLTypes</key>
<array>
  <dict>
    <key>CFBundleTypeRole</key>
    <string>Editor</string>
    <key>CFBundleURLName</key>
    <string>com.yourapp.payment</string>
    <key>CFBundleURLSchemes</key>
    <array>
      <string>flutterstripe</string>
    </array>
  </dict>
</array>
```

---

## 🔒 Security Best Practices

### ✅ DO

- Use HTTPS for all API calls
- Store only payment method IDs
- Validate amounts on server
- Use Stripe's tokenization
- Implement webhook verification
- Log all transactions
- Use test keys in development

### ❌ DON'T

- Store card numbers
- Trust client-side validation only
- Commit API keys to git
- Use test keys in production
- Process payments without authentication
- Skip error handling

---

## 📊 Next Steps

### Basic Implementation (You're here! ✓)
- [x] Copy module
- [x] Add dependencies
- [x] Initialize Stripe
- [x] Use payment screen

### Intermediate
- [ ] Connect to your backend API
- [ ] Implement payment history
- [ ] Add transaction receipts
- [ ] Custom error messages
- [ ] Analytics tracking

### Advanced
- [ ] Multiple currency support
- [ ] Subscription payments
- [ ] Refund functionality
- [ ] Payment disputes
- [ ] Custom payment flows
- [ ] Webhook handling

---

## 📚 Resources

- [Stripe Documentation](https://stripe.com/docs)
- [flutter_stripe Package](https://pub.dev/packages/flutter_stripe)
- [BLoC Documentation](https://bloclibrary.dev)
- [Flutter Documentation](https://flutter.dev/docs)

---

## 💡 Tips

1. **Start with mock data** - Perfect the UI before connecting backend
2. **Test with test keys** - Always use test mode during development
3. **Handle errors gracefully** - Show user-friendly error messages
4. **Log everything** - Keep track of all payment attempts
5. **Mobile-first** - Design for small screens first

---

## 🆘 Need Help?

Common questions:

**Q: Can I use this without Stripe?**
A: Yes! Implement your own repository with your payment provider.

**Q: Does this work offline?**
A: No, payments require internet connection.

**Q: Can I customize the UI?**
A: Yes! Edit the widgets in `presentation/widgets/` folder.

**Q: Is this production-ready?**
A: With your backend integration, yes! The mock is for testing only.

---

**Happy coding! 🚀**
