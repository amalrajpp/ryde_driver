# Quick Test Guide - Uber-Like Ride Request System

## 🚀 Quick Start Testing

### Step 1: Ensure Driver is Online
1. Open the driver app
2. Toggle the status switch to **"Online"**
3. This activates the ride request listener

### Step 2: Create Test Ride Request

#### Option A: Using Firestore Console
1. Go to Firebase Console → Firestore Database
2. Navigate to `booking` collection
3. Click "Add Document"
4. Use this data:

```json
{
  "status": "pending",
  "vehicle_type": "bike",
  "customer_id": "test_customer_123",
  "customer_name": "John Doe",
  "price": 150,
  "route": {
    "pickup_address": "MG Road, Bangalore",
    "dropoff_address": "Koramangala, Bangalore",
    "pickup_lat": 12.9715987,
    "pickup_lng": 77.5945627,
    "dropoff_lat": 12.9352400,
    "dropoff_lng": 77.6244800,
    "distance": "5.2 km",
    "estimated_time": "15 min"
  }
}
```

**Important**: Make sure the `vehicle_type` matches your driver's vehicle type!

#### Option B: Using Customer App
1. Open customer app
2. Request a ride
3. Driver should receive the popup automatically

### Step 3: Test Scenarios

#### ✅ Test 1: Accept Ride
1. Popup appears with 30-second timer
2. Click **"ACCEPT"** button
3. **Expected Result**:
   - Popup closes
   - Ride appears in "Ongoing Trips" section
   - Driver status changes to "assigned"
   - Booking status updates to "accepted"

#### ❌ Test 2: Decline Ride
1. Popup appears with timer
2. Click **"DECLINE"** button
3. **Expected Result**:
   - Popup closes
   - Ride disappears from view
   - Driver remains "online"
   - Driver can receive other requests

#### ⏰ Test 3: Timeout
1. Popup appears
2. Wait for timer to reach 00
3. **Expected Result**:
   - Popup auto-closes
   - Ride is auto-declined
   - Driver remains "online"

---

## 🔍 Verification Steps

### After Accept:
Check Firestore `booking` document:
```json
{
  "status": "accepted",  // Changed from "pending"
  "driver_id": "your_driver_uid",
  "driver_details": {
    "name": "Your Driver Name",
    "phone": "+91...",
    // ... other details
  },
  "accepted_at": "Timestamp"
}
```

Check Firestore `drivers` document:
```json
{
  "working": "assigned"  // Changed from "unassigned"
}
```

### After Decline:
- Booking remains "pending" in database
- Driver's `working` status stays "unassigned"
- Popup doesn't show again for this ride

---

## 🐛 Troubleshooting

### Popup Not Appearing?

#### Check 1: Driver Status
```dart
// In Firestore, check drivers/{uid}
{
  "status": "online"  // Must be "online", not "offline"
}
```

#### Check 2: Vehicle Type Match
```dart
// Driver's vehicle type
drivers/{uid}/vehicle/vehicle_type = "bike"

// Must match booking's vehicle type
booking/{id}/vehicle_type = "bike"
```

#### Check 3: Distance Check
- Driver must be within 10km of pickup location
- Check driver's current location in Firestore
- Temporarily increase radius in code for testing:

```dart
// In ride_request_service.dart, line ~115
final maxDistance = 50000.0; // 50km for testing
```

#### Check 4: Console Logs
Look for these debug messages:
```
🔔 Foreground notification: ...
✅ Ride accepted successfully
❌ Ride declined: ...
```

### Timer Not Working?
- Check if AnimationController is initialized
- Verify Timer is created in initState
- Ensure widget is mounted during updates

### Accept Button Not Responding?
1. Check Firestore permissions
2. Verify driver document exists
3. Check internet connection
4. Look for errors in console

---

## 📊 Test Coverage

### Functional Tests
- [ ] Popup appears for nearby pending rides
- [ ] Timer counts down from 30 to 0
- [ ] Accept button assigns ride to driver
- [ ] Decline button hides ride from driver
- [ ] Timeout auto-declines after 30 seconds
- [ ] Multiple requests handled sequentially
- [ ] Declined rides don't reappear

### UI Tests
- [ ] Timer changes color (green → orange → red)
- [ ] Pulse animation works
- [ ] Haptic feedback triggers
- [ ] All ride details display correctly
- [ ] Fare displays prominently
- [ ] Loading state shows during processing
- [ ] Buttons disable during processing

### Integration Tests
- [ ] Service initializes with dashboard
- [ ] Service starts when driver goes online
- [ ] Service stops when driver goes offline
- [ ] Firebase updates propagate correctly
- [ ] Driver location updates properly
- [ ] Customer receives notification on accept

---

## 🎯 Real-World Scenario Test

### Complete Flow Test:
1. **Customer Side**: Request a ride
2. **Driver Side**: Receive popup
3. **Driver Action**: Accept within 30 seconds
4. **Verification**: 
   - Driver sees ride in ongoing section
   - Customer sees "Driver Assigned"
   - Start navigation works
5. **Complete Ride**: Pick up → Drop off
6. **Go Online Again**: Ready for next request

---

## 📝 Test Data Template

For quick testing, use this template:

```json
{
  "status": "pending",
  "vehicle_type": "CHANGE_TO_YOUR_VEHICLE_TYPE",
  "customer_id": "test_123",
  "customer_name": "Test User",
  "price": 100,
  "route": {
    "pickup_address": "Your Current Location Name",
    "dropoff_address": "Any Destination",
    "pickup_lat": YOUR_DRIVER_CURRENT_LAT,
    "pickup_lng": YOUR_DRIVER_CURRENT_LNG,
    "dropoff_lat": 12.9716,
    "dropoff_lng": 77.5946,
    "distance": "5 km",
    "estimated_time": "10 min"
  }
}
```

**Pro Tip**: Set pickup location same as driver's current location for guaranteed proximity match!

---

## 🔧 Debug Mode

Enable detailed logging:

```dart
// In ride_request_service.dart
void _checkAndShowRideRequest(...) async {
  print('🔍 Checking ride: $rideId');
  print('📍 Driver: $driverLat, $driverLng');
  print('📍 Pickup: $pickupLat, $pickupLng');
  print('📏 Distance: ${distance}m');
  print('✅ Show: ${distance <= maxDistance}');
  
  // ... rest of code
}
```

---

## ✨ Success Indicators

You know it's working when:
1. ✅ Popup appears immediately when booking created
2. ✅ Timer counts down smoothly
3. ✅ Haptic feedback vibrates device
4. ✅ Accept updates database in <2 seconds
5. ✅ Driver assigned to ride correctly
6. ✅ Popup doesn't reappear after decline
7. ✅ System ready for next request after completion

---

## 🎓 Advanced Testing

### Load Test:
1. Create 5 pending bookings at once
2. Verify only nearby ones show
3. Check if popups queue properly

### Edge Cases:
1. **Poor Network**: Test with slow connection
2. **Multiple Drivers**: Same ride, different drivers
3. **Rapid Toggle**: Online → Offline → Online quickly
4. **Background App**: Test with app in background

---

## 📞 Need Help?

If tests fail:
1. Check `UBER_RIDE_REQUEST_SYSTEM.md` for troubleshooting
2. Review Firebase console for data
3. Check device logs for errors
4. Verify all setup steps completed

Happy Testing! 🚀
