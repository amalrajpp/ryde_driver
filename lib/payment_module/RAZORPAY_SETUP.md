# 🎯 RAZORPAY INTEGRATION - QUICK START

## ✅ What Changed

Your payment module now uses **RazorPay** instead of Stripe:

- ✅ RazorPay Flutter SDK installed
- ✅ Payment service updated to use RazorPay
- ✅ Currency changed to INR (₹)
- ✅ Mock repository updated with RazorPay gateways
- ✅ Configuration prioritizes RazorPay
- ✅ All other features remain intact

---

## ⚡ Quick Start (3 Steps)

### 1️⃣ Get RazorPay API Key (5 min)

**Create Account:**
```
https://dashboard.razorpay.com/signup
```

**Get Keys:**
1. Go to: https://dashboard.razorpay.com/app/keys
2. Copy your **Key ID** (starts with `rzp_test_`)
3. Copy your **Key Secret** (keep this safe on backend!)

**Example:** `rzp_test_AbC123XyZ456789`

---

### 2️⃣ Add Your Key (2 min)

Open: `/lib/payment_module/config/payment_config.dart`

**Line 32 - Replace:**
```dart
static const String razorPayKeyTest = 
    'rzp_test_YOUR_RAZORPAY_KEY_HERE'; // ← Add your key
```

**With your actual key:**
```dart
static const String razorPayKeyTest = 
    'rzp_test_AbC123XyZ456789'; // ✅ Your real key
```

---

### 3️⃣ Test (2 min)

1. **Run:** `flutter run`
2. **Navigate to:** Earnings Screen
3. **Tap:** "Available Earnings" button
4. **Enter amount:** Any amount (e.g., 500)
5. **Select:** "RazorPay"
6. **Payment opens:** RazorPay payment page
7. **Use test card:** See below
8. **Success!** 🎉

---

## 🧪 RazorPay Test Cards

### Success Cards:

| Card Number | CVV | Expiry | Result |
|-------------|-----|--------|--------|
| 4111 1111 1111 1111 | Any 3 digits | Any future | ✅ Success |
| 5555 5555 5555 4444 | Any 3 digits | Any future | ✅ Success |

### Failed Cards:

| Card Number | CVV | Expiry | Result |
|-------------|-----|--------|--------|
| 4000 0000 0000 0002 | Any 3 digits | Any future | ❌ Declined |

### Test UPI:
- **UPI ID:** `success@razorpay`
- **Result:** ✅ Success

### Test Net Banking:
- **Bank:** Select any bank
- **Credentials:** Use test credentials provided

---

## 💰 Currency Support

**Changed from USD ($) to INR (₹):**

```dart
// Before (Stripe - USD)
currencyCode: 'USD'
currencySymbol: '$'

// After (RazorPay - INR)
currencyCode: 'INR'
currencySymbol: '₹'
```

**All amounts now display in Rupees:**
- ₹500 instead of $500
- ₹1000 instead of $1000

---

## 🎨 Payment Methods Available

### With RazorPay, users can pay via:

1. **💳 Cards** - Debit/Credit cards (Visa, Mastercard, RuPay, etc.)
2. **📱 UPI** - Google Pay, PhonePe, Paytm, BHIM
3. **🏦 Net Banking** - All major Indian banks
4. **💰 Wallets** - Paytm, PhonePe, Mobikwik, etc.
5. **📲 EMI** - Card/Cardless EMI options

All these methods work through the same RazorPay integration!

---

## 📱 What's Different

### Removed:
- ❌ Stripe SDK
- ❌ Card saving feature (not needed with RazorPay)
- ❌ Stripe-specific setup intents

### Added:
- ✅ RazorPay SDK
- ✅ Support for UPI payments
- ✅ Support for Net Banking
- ✅ Support for Indian payment methods
- ✅ INR currency

### Unchanged:
- ✅ Beautiful payment UI
- ✅ State management (BLoC)
- ✅ Mock repository for testing
- ✅ Integration in Earnings screen
- ✅ Payment success/error handling
- ✅ All helper methods
- ✅ Documentation structure

---

## 🔧 Configuration

### Test Mode (Current):
```dart
// config/payment_config.dart
static const bool isProduction = false; // Test mode
static const String razorPayKeyTest = 'rzp_test_YOUR_KEY';
```

### Production Mode (When Ready):
```dart
// config/payment_config.dart
static const bool isProduction = true; // Live mode
static const String razorPayKeyLive = 'rzp_live_YOUR_KEY';
```

---

## 🏗️ Backend Requirements

For production, you'll need backend endpoints:

### 1. Create RazorPay Order
```
POST /payment/razorpay/create-order
Body: { user_id, amount }
Response: { order_id, amount, currency }
```

### 2. Verify Payment
```
POST /payment/razorpay/verify
Body: { razorpay_order_id, razorpay_payment_id, razorpay_signature }
Response: { success: true/false }
```

### 3. Get Payment History
```
GET /payment/history?user_id={userId}
Response: { transactions: [...] }
```

**See:** `/lib/payment_module/API_SPECIFICATION.md` for complete specs

---

## 💻 Code Example

### Open RazorPay Payment:

```dart
import 'package:ryde/payment_module/helpers/payment_integration.dart';

// Show payment screen
await PaymentIntegration.showPaymentScreenWithMock(
  context: context,
  amount: 500.00, // Amount in INR
  title: 'Withdraw Earnings',
);
```

### Payment Button (Already in Earnings Screen):

```dart
PaymentIntegration.buildEarningsPaymentButton(
  context: context,
  earningsAmount: 2340.50, // INR
  onPressed: () {
    // Open payment screen
  },
)
```

---

## 🔐 Security

### RazorPay Security Features:
- ✅ PCI DSS Level 1 compliant
- ✅ 2FA for all payments
- ✅ Encrypted payment data
- ✅ Webhook verification
- ✅ IP whitelisting
- ✅ Fraud detection

### Best Practices:
1. **Never expose Key Secret** in app code
2. **Use webhook signature** verification
3. **Validate on backend** before confirming
4. **Use HTTPS only** for API calls
5. **Store transaction IDs** for reconciliation

---

## 📋 Testing Checklist

- [ ] Add RazorPay test key
- [ ] Run the app
- [ ] Navigate to Earnings screen
- [ ] Tap payment button
- [ ] Select RazorPay
- [ ] Test with card: 4111 1111 1111 1111
- [ ] Test with UPI: success@razorpay
- [ ] Test failed payment with card: 4000 0000 0000 0002
- [ ] Verify success message
- [ ] Verify error handling

---

## 📱 Platform Setup

### Android (Required):

**Add to `android/app/src/main/AndroidManifest.xml`:**

```xml
<application>
    <!-- Add this -->
    <activity android:name="com.razorpay.CheckoutActivity"
        android:theme="@style/Theme.AppCompat.NoActionBar"
        android:exported="true">
    </activity>
</application>
```

### iOS (Optional):

No additional setup needed for basic integration!

---

## 💰 RazorPay Pricing

### Transaction Fees:
- **Domestic Cards:** 2% (₹ no setup fee)
- **International Cards:** 3%
- **UPI:** FREE
- **Net Banking:** ₹ varies by bank
- **Wallets:** 2%

### No Hidden Fees:
- ✅ No setup fee
- ✅ No annual fee
- ✅ No monthly fee
- ✅ Pay only for successful transactions

---

## 🆘 Troubleshooting

### "RazorPay not configured"
**Solution:** Add your RazorPay key in `config/payment_config.dart`

### Payment doesn't open
**Solution:** 
1. Restart app after adding key
2. Check key starts with `rzp_test_`
3. Verify internet connection

### "Invalid Key ID"
**Solution:** 
1. Copy key ID correctly from dashboard
2. Don't use Key Secret (that's for backend only)
3. Use test key (rzp_test_) in test mode

### Android build fails
**Solution:** Add RazorPay activity to AndroidManifest.xml (see above)

---

## 📚 Resources

- **RazorPay Dashboard:** https://dashboard.razorpay.com
- **RazorPay Docs:** https://razorpay.com/docs/payments/
- **Flutter Plugin:** https://pub.dev/packages/razorpay_flutter
- **Test Cards:** https://razorpay.com/docs/payments/payments/test-card-details/
- **API Docs:** https://razorpay.com/docs/api/

---

## 🎉 Ready to Go!

Your payment module now uses **RazorPay** - perfect for Indian market!

**Next Steps:**
1. ✅ Add RazorPay test key (2 min)
2. ✅ Test payment flow (2 min)
3. 🔜 Set up backend for production
4. 🔜 Switch to live keys when ready
5. 🔜 Launch! 🚀

---

**All features work exactly the same, just with RazorPay instead of Stripe! 💙**
