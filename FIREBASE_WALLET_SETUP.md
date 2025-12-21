# Firebase Setup Guide for Wallet Feature

## Database Structure

### Initialize Wallet for a Driver

When a new driver signs up, initialize their wallet:

```javascript
// In Firebase Console or Cloud Function
db.collection('drivers').doc(userId).set({
  walletBalance: 0.0,
  lastUpdated: firebase.firestore.FieldValue.serverTimestamp(),
  // ... other driver fields
}, { merge: true });
```

### Sample Wallet Document

```json
{
  "walletBalance": 1500.50,
  "lastUpdated": "2024-01-15T10:30:00Z",
  "name": "John Doe",
  "email": "john@example.com"
}
```

### Sample Transaction Document

**Path**: `drivers/{userId}/transactions/{transactionId}`

**Credit Transaction (Add Money)**:
```json
{
  "type": "credit",
  "amount": 500.00,
  "description": "Money added to wallet",
  "paymentId": "pay_1234567890",
  "status": "completed",
  "timestamp": "2024-01-15T10:30:00Z",
  "balanceAfter": 1500.50
}
```

**Debit Transaction (Withdraw Money)**:
```json
{
  "type": "debit",
  "amount": 200.00,
  "description": "Money withdrawn from wallet",
  "paymentId": "pay_0987654321",
  "status": "pending",
  "timestamp": "2024-01-15T11:00:00Z",
  "balanceAfter": 1300.50
}
```

## Firestore Rules

Add these security rules to protect wallet data:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    // Drivers collection
    match /drivers/{userId} {
      // Allow read if authenticated and it's their own document
      allow read: if request.auth != null && request.auth.uid == userId;
      
      // Don't allow direct wallet balance updates from client
      // (only through WalletService which uses transactions)
      allow write: if false;
      
      // Transactions subcollection
      match /transactions/{transactionId} {
        // Allow read if it's their own transactions
        allow read: if request.auth != null && request.auth.uid == userId;
        
        // Don't allow direct writes (only through WalletService)
        allow write: if false;
      }
    }
  }
}
```

## Firestore Indexes

Create these indexes in Firebase Console for better query performance:

1. **Transaction History Query**:
   - Collection: `drivers/{userId}/transactions`
   - Fields: `timestamp` (Descending)
   - Query scope: Collection

To create indexes:
1. Go to Firebase Console
2. Select your project
3. Go to Firestore Database
4. Click "Indexes" tab
5. Click "Create Index"
6. Add the index details above

## Initial Test Data

To test the wallet feature, add sample data in Firebase Console:

### Step 1: Create Driver Document
```
Collection: drivers
Document ID: [your-test-user-id]
Fields:
  - walletBalance: 500.00 (number)
  - lastUpdated: [current timestamp]
  - name: "Test Driver" (string)
  - email: "test@example.com" (string)
```

### Step 2: Add Sample Transactions
```
Collection: drivers/[your-test-user-id]/transactions
Auto ID

Transaction 1:
  - type: "credit" (string)
  - amount: 500.00 (number)
  - description: "Initial wallet credit" (string)
  - paymentId: "pay_test_123" (string)
  - status: "completed" (string)
  - timestamp: [current timestamp]
  - balanceAfter: 500.00 (number)

Transaction 2:
  - type: "debit" (string)
  - amount: 50.00 (number)
  - description: "Test withdrawal" (string)
  - paymentId: "pay_test_456" (string)
  - status: "pending" (string)
  - timestamp: [current timestamp]
  - balanceAfter: 450.00 (number)
```

## Cloud Functions (Optional)

For automated processes, create Cloud Functions:

### 1. Initialize Wallet on User Creation
```javascript
exports.initializeWallet = functions.auth.user().onCreate(async (user) => {
  await admin.firestore().collection('drivers').doc(user.uid).set({
    walletBalance: 0.0,
    lastUpdated: admin.firestore.FieldValue.serverTimestamp(),
  }, { merge: true });
});
```

### 2. Process Withdrawal Approval
```javascript
exports.approveWithdrawal = functions.https.onCall(async (data, context) => {
  // Admin only
  if (!context.auth.token.admin) {
    throw new functions.https.HttpsError('permission-denied', 'Admin only');
  }
  
  const { userId, transactionId } = data;
  
  const transactionRef = admin.firestore()
    .collection('drivers').doc(userId)
    .collection('transactions').doc(transactionId);
    
  await transactionRef.update({
    status: 'completed',
    approvedAt: admin.firestore.FieldValue.serverTimestamp(),
    approvedBy: context.auth.uid,
  });
  
  // Process actual bank transfer here
  
  return { success: true };
});
```

### 3. Send Transaction Notifications
```javascript
exports.onTransactionCreated = functions.firestore
  .document('drivers/{userId}/transactions/{transactionId}')
  .onCreate(async (snap, context) => {
    const transaction = snap.data();
    const userId = context.params.userId;
    
    // Get user's FCM token
    const userDoc = await admin.firestore()
      .collection('drivers').doc(userId).get();
    const fcmToken = userDoc.data()?.fcmToken;
    
    if (fcmToken) {
      const message = {
        notification: {
          title: transaction.type === 'credit' 
            ? 'Money Added!' 
            : 'Withdrawal Requested',
          body: `₹${transaction.amount} - ${transaction.description}`,
        },
        token: fcmToken,
      };
      
      await admin.messaging().send(message);
    }
  });
```

## Monitoring

### Important Metrics to Track:

1. **Total Wallet Balance**: Sum of all driver wallet balances
2. **Pending Withdrawals**: Count and amount of pending transactions
3. **Transaction Volume**: Daily/monthly transaction counts
4. **Failed Transactions**: Error rate and reasons

### Create Dashboard Queries:

```javascript
// Total wallet balance across all drivers
db.collection('drivers')
  .get()
  .then(snapshot => {
    const total = snapshot.docs.reduce((sum, doc) => 
      sum + (doc.data().walletBalance || 0), 0
    );
    console.log('Total: ₹', total);
  });

// Pending withdrawals
db.collectionGroup('transactions')
  .where('type', '==', 'debit')
  .where('status', '==', 'pending')
  .get()
  .then(snapshot => {
    console.log('Pending withdrawals:', snapshot.size);
  });
```

## Backup Strategy

1. **Enable Point-in-Time Recovery** in Firestore
2. **Export data daily** using Cloud Scheduler
3. **Keep transaction logs** for audit purposes
4. **Archive old transactions** after 1 year

## Testing Scenarios

### Test 1: Add Money
1. Login as driver
2. Navigate to wallet
3. Click "Add Money"
4. Enter amount: ₹100
5. Complete RazorPay payment with `success@razorpay`
6. Verify balance increased by ₹100
7. Check transaction appears in history

### Test 2: Withdraw Money
1. Ensure wallet has balance
2. Click "Withdraw Money"
3. Enter amount less than balance
4. Complete RazorPay verification
5. Verify balance decreased
6. Check transaction has "pending" status

### Test 3: Edge Cases
- Try withdrawing more than balance (should fail)
- Try entering negative amount (should validate)
- Test with no internet connection (should handle gracefully)
- Test with expired auth token (should re-authenticate)

## Troubleshooting

### Issue: Balance not updating
**Check**:
- Firebase transaction completed successfully
- `lastUpdated` timestamp is recent
- No console errors in app

### Issue: Transactions not showing
**Check**:
- Firestore index created
- User has read permissions
- Transaction documents have correct structure

### Issue: RazorPay payment successful but balance not updated
**Check**:
- Payment callback is being triggered
- `_handleAddMoneySuccess()` is being called
- No errors in WalletService
- Firebase connection is active

---

**Need Help?**
- Check Firebase Console → Firestore → Debug
- Check RazorPay Dashboard → Test Payments
- Enable debug logging: `debugPrint()` in code
- Review security rules and permissions
