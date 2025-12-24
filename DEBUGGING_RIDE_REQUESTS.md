# 🐛 Debugging Ride Request System

## Issue: Not Receiving Ride Requests

### ✅ Changes Made

1. **Removed duplicate UI** - The old "Available Rides" list was conflicting with the new popup system
2. **Added comprehensive logging** - You can now see exactly what's happening in the console
3. **Fixed initialization** - Service now properly restarts when driver goes online

---

## 🔍 How to Debug

### Step 1: Check Console Logs

When you toggle the driver status to **"Online"**, you should see:

```
🔄 RideRequestService: Restarting service...
🚀 RideRequestService: Initializing...
🔍 RideRequestService: Fetching driver data for [your-uid]
📊 RideRequestService: Driver status = online
🚗 RideRequestService: Vehicle type = bike
✅ RideRequestService: Starting to listen for pending rides...
✅ RideRequestService: Listener setup complete!
```

### Step 2: Create Test Booking

In Firebase Console, add a booking with:
```json
{
  "status": "pending",
  "vehicle_type": "bike",  ← MUST MATCH YOUR DRIVER'S VEHICLE TYPE
  "customer_name": "Test Customer",
  "price": 150,
  "route": {
    "pickup_address": "Test Location",
    "dropoff_address": "Test Destination", 
    "pickup_lat": 12.9716,  ← USE YOUR DRIVER'S CURRENT LOCATION
    "pickup_lng": 77.5946,
    "dropoff_lat": 12.9352,
    "dropoff_lng": 77.6245,
    "distance": "5 km",
    "estimated_time": "12 min"
  }
}
```

### Step 3: Watch Console

When booking is created, you should see:
```
🔔 RideRequestService: Received 1 booking changes
🆕 RideRequestService: New ride detected: [ride-id]
📍 RideRequestService: Checking distance for ride [ride-id]
   Driver location: (12.9716, 77.5946)
   Pickup location: (12.9716, 77.5946)
   Distance: 0m
✅ RideRequestService: Ride is nearby! Showing popup...
```

---

## 🚨 Common Issues & Solutions

### Issue 1: No logs when toggling online
**Problem**: Service not initializing
**Solution**: 
```dart
// Check dashboard.dart has:
@override
void initState() {
  super.initState();
  WidgetsBinding.instance.addPostFrameCallback((_) {
    _rideRequestService.initialize(context);
  });
}
```

### Issue 2: Log says "Driver is offline"
**Problem**: Status check happens before Firebase updates
**Solution**: Toggle OFF then ON again, or check Firestore `drivers/{uid}` has `status: "online"`

### Issue 3: Log says "Ride too far"
**Problem**: Distance calculation failing or pickup too far
**Check**:
1. Driver location in Firestore has valid lat/lng (not 0.0)
2. Pickup location is within 10km
3. Use same lat/lng for testing

**Temporary Fix**: In `ride_request_service.dart`, change:
```dart
final maxDistance = 50000.0; // 50km for testing
```

### Issue 4: Log says "Vehicle type mismatch"
**Problem**: Driver's vehicle type doesn't match booking
**Solution**: 
1. Check Firebase `drivers/{uid}/vehicle/vehicle_type`
2. Check Firebase `booking/{id}/vehicle_type`
3. They must match exactly (case-sensitive!)

### Issue 5: No logs at all after "Listener setup complete"
**Problem**: No matching bookings in Firestore
**Solution**:
1. Create a test booking with matching vehicle type
2. Ensure status = "pending"
3. Check Firestore rules allow reads

### Issue 6: "Already processed" or "Already declined"
**Problem**: Ride was shown before
**Solution**: 
- Go offline then online to clear the cache
- Or create a NEW booking with different data

---

## 🔧 Quick Fixes

### Force Show All Rides (Testing Only)

In `ride_request_service.dart`, temporarily comment out filters:

```dart
// TEMPORARY - FOR TESTING
_rideRequestSubscription = FirebaseFirestore.instance
    .collection('booking')
    .where('status', isEqualTo: 'pending')
    // .where('vehicle_type', isEqualTo: myVehicleType)  ← Comment this out
    .snapshots()
    .listen((snapshot) {
      // ...
      
      // Also skip distance check temporarily
      // if (distance <= maxDistance) {
        _showRideRequestPopup(rideId, rideData);
      // }
    });
```

### Check Driver Data

Add this to dashboard.dart for debugging:

```dart
@override
void initState() {
  super.initState();
  WidgetsBinding.instance.addPostFrameCallback((_) async {
    final doc = await FirebaseFirestore.instance
        .collection('drivers')
        .doc(currentUser?.uid)
        .get();
    print('🚗 Driver Data: ${doc.data()}');
    _rideRequestService.initialize(context);
  });
}
```

---

## 📊 Expected Log Flow

### Complete Successful Flow:

```
1️⃣ Driver Opens App
   └─ 🚀 RideRequestService: Initializing...
   └─ ⚠️ RideRequestService: Driver is offline, not listening

2️⃣ Driver Toggles Online
   └─ 🔄 RideRequestService: Restarting service...
   └─ 🚀 RideRequestService: Initializing...
   └─ 🔍 RideRequestService: Fetching driver data...
   └─ 📊 RideRequestService: Driver status = online
   └─ 🚗 RideRequestService: Vehicle type = bike
   └─ ✅ RideRequestService: Starting to listen...
   └─ ✅ RideRequestService: Listener setup complete!

3️⃣ Customer Requests Ride (or you create in Firebase)
   └─ 🔔 RideRequestService: Received 1 booking changes
   └─ 🆕 RideRequestService: New ride detected: xyz123
   └─ 📍 RideRequestService: Checking distance...
   └─    Driver location: (12.97, 77.59)
   └─    Pickup location: (12.97, 77.59)
   └─    Distance: 50m
   └─ ✅ RideRequestService: Ride is nearby! Showing popup...
   └─ 🎉 POPUP APPEARS! 

4️⃣ Driver Accepts
   └─ ✅ Ride accepted successfully
```

---

## 🎯 Checklist Before Testing

- [ ] Driver status is "online" in Firestore
- [ ] Driver location has valid lat/lng (not 0.0, 0.0)
- [ ] Booking has status = "pending"
- [ ] Booking vehicle_type matches driver's vehicle_type
- [ ] Pickup location is within 10km of driver
- [ ] Console logs are visible in your IDE/Terminal
- [ ] No firestore permission errors

---

## 📱 Testing Steps

1. **Open app**, check logs for initialization
2. **Toggle OFFLINE** (if already online)
3. **Toggle ONLINE**, watch for "Listener setup complete!"
4. **Create test booking** in Firebase Console
5. **Watch console** for distance check
6. **See popup appear** (or check error logs)

---

## 🆘 Still Not Working?

### Run this diagnostic:

```dart
// Add to dashboard.dart temporarily
Future<void> _diagnose() async {
  print('=== DIAGNOSTIC START ===');
  
  final user = FirebaseAuth.instance.currentUser;
  print('1. User: ${user?.uid ?? "NOT LOGGED IN"}');
  
  final driverDoc = await FirebaseFirestore.instance
      .collection('drivers')
      .doc(user?.uid)
      .get();
  print('2. Driver exists: ${driverDoc.exists}');
  print('3. Driver data: ${driverDoc.data()}');
  
  final bookings = await FirebaseFirestore.instance
      .collection('booking')
      .where('status', isEqualTo: 'pending')
      .get();
  print('4. Pending bookings: ${bookings.docs.length}');
  for (var doc in bookings.docs) {
    print('   - ${doc.id}: ${doc.data()}');
  }
  
  print('=== DIAGNOSTIC END ===');
}

// Call in initState:
_diagnose();
```

---

## ✅ Success Indicators

You'll know it's working when:
1. ✅ Logs show "Listener setup complete!"
2. ✅ Logs show "New ride detected" when booking created
3. ✅ Logs show distance calculation
4. ✅ Popup appears on screen
5. ✅ Accept button updates Firebase

---

Need more help? Check the logs and let me know what message you see!
