# 🎯 PAYMENT MODULE - VISUAL INTEGRATION GUIDE

## 🎨 HOW IT LOOKS

### Main Payment Screen
```
┌─────────────────────────────────────┐
│  ← Payment                          │
├─────────────────────────────────────┤
│                                     │
│  Enter Amount                       │
│  ┌───────────────────────────────┐ │
│  │ $    [  50.00  ]              │ │
│  └───────────────────────────────┘ │
│  ℹ️ Minimum amount: $ 10.00        │
│                                     │
│  Select Payment Method  [+ Add Card]│
│                                     │
│  ┌───────────────────────────────┐ │
│  │ 💳  Visa              ⚪       │ │
│  │     Ends in **** 4242          │ │
│  └───────────────────────────────┘ │
│                                     │
│  ┌───────────────────────────────┐ │
│  │ 💳  Mastercard        🗑️ ⚪   │ │
│  │     Ends in **** 5555          │ │
│  └───────────────────────────────┘ │
│                                     │
│  ┌───────────────────────────────┐ │
│  │ 💳  Credit/Debit Card ⚫       │ │
│  │     Add new card               │ │
│  └───────────────────────────────┘ │
│                                     │
├─────────────────────────────────────┤
│  [ Continue to Payment ]            │
└─────────────────────────────────────┘
```

### Success Dialog
```
┌───────────────────────────┐
│                           │
│      ✅                   │
│   (Success Icon)          │
│                           │
│  Payment Successful!      │
│                           │
│  Your payment has been    │
│  processed successfully   │
│                           │
│  ┌─────────────────────┐ │
│  │ Transaction ID      │ │
│  │ pay_1234567890      │ │
│  └─────────────────────┘ │
│                           │
│  [        Done        ]   │
│                           │
└───────────────────────────┘
```

---

## 🎯 INTEGRATION LOCATIONS

### 1. Profile/Account Screen

**Current Location**: `lib/features/account/presentation/pages/accountpage.dart`

**Add After**: Existing menu items (e.g., after "Wallet" or "Subscription")

```dart
// Add this menu item
ListTile(
  leading: Icon(Icons.payment),
  title: Text('Payment Methods'),
  trailing: Icon(Icons.arrow_forward_ios),
  onTap: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PaymentScreen(
          userId: userData!.userId.toString(),
          title: 'Payment Methods',
        ),
      ),
    );
  },
)
```

**Visual Position**:
```
Profile Screen
├── My Profile
├── Documents
├── Wallet
├── Subscription
├── 🆕 Payment Methods  ← ADD HERE
├── Bank Details
└── Settings
```

---

### 2. Wallet Screen

**Current Location**: `lib/features/account/presentation/pages/wallet/page/wallet_page.dart`

**Add**: Floating action button or top button

```dart
FloatingActionButton.extended(
  onPressed: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PaymentScreen(
          userId: userData!.userId.toString(),
          title: 'Add Money',
          onPaymentSuccess: () {
            // Reload wallet
            context.read<AccBloc>().add(WalletPageEvent());
          },
        ),
      ),
    );
  },
  icon: Icon(Icons.add),
  label: Text('Add Money'),
)
```

**Visual Position**:
```
Wallet Screen
┌────────────────────────┐
│ Wallet Balance         │
│ $ 150.50               │
│                        │
│ [🆕 Add Money]        │ ← ADD HERE
│                        │
│ Recent Transactions    │
│ • Transaction 1        │
│ • Transaction 2        │
└────────────────────────┘
```

---

### 3. Subscription Screen

**Current Location**: `lib/features/account/presentation/pages/subscription/page/subscription_page.dart`

**Replace**: Existing payment gateway selection

```dart
// In subscribe button
onPressed: () {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => PaymentScreen(
        userId: userData!.userId.toString(),
        initialAmount: selectedPlan.price,
        title: 'Subscribe - ${selectedPlan.name}',
        onPaymentSuccess: () {
          // Activate subscription
          showSuccessDialog();
        },
      ),
    ),
  );
}
```

**Visual Flow**:
```
Subscription Plans
      ↓
Select Plan
      ↓
[Subscribe Now] → 🆕 Payment Screen → Success
```

---

## 📱 SCREEN FLOW

### Complete User Journey

```
┌─────────────────┐
│   Profile       │
│   • Payment     │ ← User clicks
└────────┬────────┘
         ↓
┌─────────────────┐
│  Payment Screen │
│  • Enter amount │
│  • Select card  │ ← Choose payment
└────────┬────────┘
         ↓
┌─────────────────┐
│   Processing    │
│   Loading...    │ ← Show loader
└────────┬────────┘
         ↓
┌─────────────────┐
│  Success Dialog │
│  ✅ Done!       │ ← Show success
└────────┬────────┘
         ↓
┌─────────────────┐
│  Back to Profile│
│  (Updated)      │ ← Return
└─────────────────┘
```

---

## 🎨 CUSTOMIZATION EXAMPLES

### Example 1: Match Your App Colors

```dart
PaymentScreen(
  userId: userData.userId.toString(),
  primaryColor: AppColors.primaryColor,      // Your theme
  backgroundColor: AppColors.backgroundColor, // Your theme
)
```

### Example 2: Profile Integration

```dart
// In your profile menu
_buildMenuItem(
  icon: Icons.payment,
  title: AppLocalizations.of(context)!.paymentMethods,
  subtitle: 'Manage cards and payments',
  onTap: () => _navigateToPayment(),
)

void _navigateToPayment() {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => PaymentScreen(
        userId: userData!.userId.toString(),
        title: AppLocalizations.of(context)!.paymentMethods,
        primaryColor: Theme.of(context).primaryColor,
        onPaymentSuccess: () {
          _showSuccessSnackBar();
        },
      ),
    ),
  );
}
```

### Example 3: Wallet Integration

```dart
// In wallet page
Widget _buildAddMoneyButton() {
  return Container(
    margin: EdgeInsets.all(16),
    child: ElevatedButton.icon(
      icon: Icon(Icons.add_card),
      label: Text('Add Money to Wallet'),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primaryColor,
        padding: EdgeInsets.symmetric(vertical: 16),
      ),
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PaymentScreen(
              userId: userData!.userId.toString(),
              title: 'Add Money',
              primaryColor: AppColors.primaryColor,
              onPaymentSuccess: () {
                // Reload wallet
                context.read<AccBloc>().add(
                  WalletPageEvent(),
                );
                // Show success
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Money added successfully!'),
                    backgroundColor: Colors.green,
                  ),
                );
              },
            ),
          ),
        );
      },
    ),
  );
}
```

---

## 📂 FILE LOCATIONS QUICK REFERENCE

```
YOUR PROJECT
├── lib/
│   ├── features/
│   │   ├── account/
│   │   │   └── presentation/
│   │   │       └── pages/
│   │   │           ├── accountpage.dart        ← Add here (Option 1)
│   │   │           ├── wallet/
│   │   │           │   └── page/
│   │   │           │       └── wallet_page.dart ← Add here (Option 2)
│   │   │           └── subscription/
│   │   │               └── page/
│   │   │                   └── subscription_page.dart ← Add here (Option 3)
│   │   └── ...
│   │
│   └── 🆕 payment_module/           ← NEW MODULE
│       ├── payment_screen.dart      ← Import this
│       └── ...
│
└── ...
```

---

## 🔧 IMPLEMENTATION CHECKLIST

### Step 1: Import (1 line)
```dart
import 'package:restart_tagxi/payment_module/presentation/payment_screen.dart';
```

### Step 2: Navigate (5 lines)
```dart
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => PaymentScreen(
      userId: userData.userId.toString(),
    ),
  ),
);
```

### Step 3: Test (1 minute)
- Run app
- Navigate to screen
- Click button
- See payment screen
- Done! ✅

---

## 🎯 QUICK START CODE SNIPPETS

### Snippet 1: Basic Navigation
```dart
// Copy-paste ready!
import 'package:restart_tagxi/payment_module/presentation/payment_screen.dart';

// Use anywhere:
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => PaymentScreen(
      userId: userData!.userId.toString(),
    ),
  ),
);
```

### Snippet 2: With Success Handler
```dart
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => PaymentScreen(
      userId: userData!.userId.toString(),
      onPaymentSuccess: () {
        // Your success logic here
        print('Payment successful!');
      },
    ),
  ),
);
```

### Snippet 3: Full Featured
```dart
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => PaymentScreen(
      userId: userData!.userId.toString(),
      initialAmount: 50.0,
      title: 'Add Money to Wallet',
      primaryColor: Theme.of(context).primaryColor,
      onPaymentSuccess: () {
        // Reload data
        context.read<AccBloc>().add(AccGetUserDetailsEvent());
        // Show message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Payment successful!')),
        );
      },
      onPaymentFailed: () {
        // Handle failure
        print('Payment failed');
      },
    ),
  ),
);
```

---

## 🎨 UI CUSTOMIZATION

### Colors
```dart
PaymentScreen(
  primaryColor: Color(0xFF6366F1),  // Indigo
  backgroundColor: Colors.white,
)
```

### Text
```dart
PaymentScreen(
  title: 'Your Custom Title',
)
```

### Amount
```dart
PaymentScreen(
  initialAmount: 100.0,  // Pre-filled
)
```

---

## 🚀 LAUNCH CHECKLIST

### Before Launch
- [ ] Import payment screen
- [ ] Add navigation code
- [ ] Test basic flow
- [ ] Customize colors
- [ ] Add success handler

### During Testing
- [ ] Test with mock data
- [ ] Try different amounts
- [ ] Test card adding
- [ ] Test card deletion
- [ ] Test success flow
- [ ] Test error handling

### After Launch
- [ ] Connect real backend
- [ ] Test with real payments
- [ ] Monitor transactions
- [ ] Collect user feedback
- [ ] Optimize as needed

---

## 📱 RESPONSIVE DESIGN

The payment screen automatically adapts to:
- ✅ Different screen sizes
- ✅ Portrait/landscape
- ✅ iOS/Android
- ✅ Light/dark theme
- ✅ Different languages (ready)

---

## 🎉 YOU'RE READY!

Choose your integration location:

1. **Profile** → Best for: Managing payment methods
2. **Wallet** → Best for: Adding money
3. **Subscription** → Best for: Payment during signup

Copy the code snippet above and paste it in your chosen location!

---

**Total time to integrate: 2 minutes! ⏱️**

**Questions? Check**: `QUICKSTART.md`, `INTEGRATION_GUIDE.md`, or `README.md`
