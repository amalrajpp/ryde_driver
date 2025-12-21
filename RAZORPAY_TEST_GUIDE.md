# 🧪 RazorPay Test Payment Guide

## Quick Test Credentials

### 📱 Test Card Payment
```
Card Number: 4111 1111 1111 1111
CVV: 123
Expiry: 12/25 (any future date)
Name: Test User
OTP: Varies by test mode (see below)
```

**Common Test OTPs to Try:**
1. `123456` (Most common)
2. Skip OTP - Click "Skip" or "Continue" if available
3. Use the OTP sent to test phone number (if configured in RazorPay dashboard)

**⚠️ If OTP keeps failing, use UPI method instead (recommended):**

### 🎯 Test UPI IDs
```
success@razorpay    → Instant Success ✅
failure@razorpay    → Instant Failure ❌
```

### 🏦 Test Net Banking
- Select any bank
- Click "Success" on test page

---

## 📋 Step-by-Step Test Flow

### Method 1: Card Payment (Recommended)

1. **Open Payment Screen**
   - Go to Profile → Payment
   - Or Earnings → Withdraw Earnings

2. **Enter Amount**
   - Enter: `100` (₹100)

3. **Select Payment Method**
   - Choose "RazorPay"

4. **Click "Continue to Payment"**
   - RazorPay checkout opens

5. **Enter Card Details**
   ```
   Card Number: 4111 1111 1111 1111
   CVV: 123
   Expiry: 12/25
   Name: Test User
   ```

6. **Click "Pay"**
   - If OTP field appears: Enter `123456`
   - If no OTP field: Click Submit directly

7. **Success!** ✅
   - Green notification appears
   - Returns to previous screen

---

### Method 2: UPI Payment (Fastest)

1. Open payment screen
2. Enter amount: `100`
3. Select "RazorPay"
4. Click "Continue to Payment"
5. Select **UPI** tab
6. Enter: `success@razorpay`
7. Click Pay
8. Instant success! ✅

---

## 🔍 Common Test Scenarios

| Scenario | What to Use | Expected Result |
|----------|-------------|-----------------|
| Successful payment | Card: `4111...1111`, OTP: `123456` | ✅ Success |
| Successful payment (fast) | UPI: `success@razorpay` | ✅ Success |
| Failed payment | UPI: `failure@razorpay` | ❌ Failure |
| Cancelled payment | Start payment, click Back/Cancel | ❌ User cancelled |

---

## 💡 Important Notes

### About Test OTP
- **Standard Test OTP**: `123456`
- **Behavior**: May or may not be required depending on RazorPay's test flow
- **If prompted**: Always try `123456`
- **If not prompted**: Just click Submit/Pay

### About Test Cards
- **Always works**: `4111 1111 1111 1111`
- **CVV**: Any 3 digits work (commonly use `123`)
- **Expiry**: Any future date works
- **Name**: Any name works

### About Test Mode
- ✅ No real money is charged
- ✅ Payments auto-complete quickly
- ✅ Can test unlimited times
- ✅ All features available

---

## 🐛 Troubleshooting

### Issue: OTP Verification Failed (123456 not working)
This is a common issue with RazorPay test mode. **Solutions:**

**Solution 1: Use UPI Instead (RECOMMENDED - No OTP needed!)**
1. Open payment screen
2. Enter amount: `100`
3. Select RazorPay → Click Continue
4. In RazorPay checkout, select **UPI** tab
5. Enter: `success@razorpay`
6. Click Pay
7. ✅ Instant success, no OTP!

**Solution 2: Check RazorPay Dashboard Settings**
1. Go to https://dashboard.razorpay.com/
2. Navigate to Settings → Configuration
3. Check if test mode OTP is configured
4. Some accounts use custom test OTPs

**Solution 3: Try Different Card**
Some test cards don't require OTP:
- Try: `5267 3181 8797 5449` (Mastercard test card)
- Or use Net Banking option

**Solution 4: Use Net Banking**
1. Select RazorPay → Click Continue
2. Choose **Net Banking** tab
3. Select any bank
4. Click **Success** on test page
5. ✅ No OTP required!

**Why OTP might fail:**
- RazorPay test environment OTP behavior varies by account
- Some test modes require actual SMS to registered test number
- Default OTP might be disabled in your RazorPay account settings

### Issue: Payment Not Opening
**Check**:
- Internet connection active
- RazorPay key configured: `rzp_test_mLjOYPDdtvn3SX`
- Check console logs for errors

### Issue: Payment Succeeds but App Doesn't Respond
**Check**:
- Look for green success notification
- Check console for: `✅ Payment Success: pay_xxxxx`
- Screen should close automatically

---

## 📊 Test Results to Expect

### Console Logs (Success):
```
💳 Processing RazorPay payment for ₹100
🔑 RazorPay Opening with Key: rzp_test_mLjOYPDdtvn3SX
💰 Amount: ₹100.0 (10000 paise)
✅ Payment Success: pay_MjBqxxxxxxxxxxx
```

### User Interface (Success):
- Green SnackBar: "Payment Successful! ID: pay_xxxxx"
- Screen closes
- Returns to previous screen

### Console Logs (Failure):
```
💳 Processing RazorPay payment for ₹100
🔑 RazorPay Opening with Key: rzp_test_mLjOYPDdtvn3SX
💰 Amount: ₹100.0 (10000 paise)
❌ Payment Failed: 2 - Payment cancelled by user
```

### User Interface (Failure):
- Red SnackBar: "Payment Failed: Payment cancelled by user"
- Stays on payment screen
- Can try again

---

## 🎯 Quick Test Checklist

- [ ] App installed and running
- [ ] Navigate to payment screen
- [ ] Enter amount: `100`
- [ ] Select RazorPay
- [ ] Click Continue
- [ ] RazorPay checkout opens ✅
- [ ] Enter test card: `4111 1111 1111 1111`
- [ ] CVV: `123`, Expiry: `12/25`
- [ ] Click Pay
- [ ] Enter OTP if prompted: `123456`
- [ ] Payment succeeds ✅
- [ ] Green notification appears ✅
- [ ] Screen closes ✅

---

## 📞 Support

If you still face issues:
1. Check console logs for detailed errors
2. Try UPI test payment: `success@razorpay`
3. Verify internet connection
4. Restart the app
5. Check RazorPay dashboard for test mode status

---

**Last Updated**: December 20, 2025  
**RazorPay Test Key**: `rzp_test_mLjOYPDdtvn3SX`  
**Test Mode**: ✅ Active  
**Standard Test OTP**: `123456`
