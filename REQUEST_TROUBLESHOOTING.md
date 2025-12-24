# Driver Not Getting Requests - Troubleshooting Guide

## Step 1: Check Driver Status
Run the app and check the console logs when you toggle the status to ONLINE:

### Expected Logs:
```
🔄 Toggle status called: currentStatus=false
📍 Getting current location...
📍 Location obtained: [lat], [lng]
✅ Status updated to online in Firestore
🚀 RideRequestService: Initializing...
🔍 RideRequestService: Fetching driver data for [uid]
📊 RideRequestService: Driver status = online
📊 RideRequestService: Working status = unassigned
🚗 RideRequestService: Vehicle type = [your_vehicle_type]
✅ RideRequestService: Starting to listen for pending rides...
✅ RideRequestService: Listener setup complete!
```

### If You See:
- ❌ CurrentUser is null → **Authentication issue**
- ❌ Driver document not found → **Driver profile not created**
- ⚠️ Driver is offline → **Status not updating in Firestore**
- ⚠️ Driver is already assigned → **Working status stuck on 'assigned'**

---

## Step 2: Check Firestore Driver Document
Open Firebase Console → Firestore → `drivers` collection → Find your driver document

### Required Fields:
```json
{
  "status": "online",           // Must be "online"
  "working": "unassigned",      // Must be "unassigned"
  "location": {
    "lat": [number],
    "lng": [number]
  },
  "vehicle": {
    "vehicle_type": "[type]"    // Must match booking's vehicle_type
  }
}
```

**Fix**: If `working` is stuck on "assigned", manually change it to "unassigned"

---

## Step 3: Check Firestore Booking Documents
Open Firebase Console → Firestore → `booking` collection

### Requirements for a booking to show:
```json
{
  "status": "pending",           // Must be exactly "pending"
  "vehicle_type": "[type]",      // Must match driver's vehicle_type
  "route": {
    "pickup_lat": [number],
    "pickup_lng": [number]
  },
  "declined_by": []              // Should NOT contain your driver UID
  // Should NOT have "driver_id" field
}
```

### Distance Check:
The booking's pickup location must be within **10km** of the driver's location.

**Formula**: Distance between driver location and pickup location ≤ 10,000 meters

---

## Step 4: Test With a New Booking

### Option A: Create Test Booking (Firestore Console)
1. Go to Firestore → `booking` collection
2. Add a new document with these fields:

```json
{
  "status": "pending",
  "vehicle_type": "Bike",        // Match your driver's vehicle type
  "customer_id": "test_customer",
  "customer_name": "Test Customer",
  "price": 100,
  "route": {
    "pickup_address": "Test Pickup",
    "dropoff_address": "Test Dropoff",
    "pickup_lat": [YOUR_DRIVER_LAT + 0.001],    // Very close to driver
    "pickup_lng": [YOUR_DRIVER_LNG + 0.001],
    "dropoff_lat": [YOUR_DRIVER_LAT + 0.01],
    "dropoff_lng": [YOUR_DRIVER_LNG + 0.01],
    "distance": "2 km",
    "estimated_time": "5 mins"
  }
}
```

### Expected Behavior:
Within 1-2 seconds, you should see:
```
🆕 RideRequestService: New ride detected: [ride_id] (status: pending)
📍 RideRequestService: Checking distance for ride [ride_id]
   Driver location: ([lat], [lng])
   Pickup location: ([lat], [lng])
   Distance: [distance]m
✅ RideRequestService: Ride is nearby! Showing popup...
```

---

## Step 5: Common Issues & Fixes

### Issue 1: No Logs Appear
**Problem**: Service not initializing
**Fix**: Check dashboard.dart initState:
```dart
@override
void initState() {
  super.initState();
  WidgetsBinding.instance.addPostFrameCallback((_) {
    _rideRequestService.initialize(context);
  });
}
```

### Issue 2: "Ride too far"
**Problem**: Driver location or booking location is wrong
**Check**:
1. Driver's location in Firestore (should update when going online)
2. Booking's pickup_lat/pickup_lng values
3. Are they in the same city/area?

### Issue 3: All Old Requests Showing
**Problem**: Old bookings still marked as "pending"
**Fix**: Update old bookings' status to "expired" or "cancelled"

### Issue 4: Vehicle Type Mismatch
**Problem**: Driver has vehicle_type="Bike", booking has vehicle_type="Car"
**Fix**: Ensure vehicle types match exactly (case-sensitive)

### Issue 5: Driver ID in Booking
**Problem**: Booking already has a `driver_id` field
**Fix**: Remove the `driver_id` field from the booking document

---

## Step 6: Enable More Debug Logs

If you still don't see requests, check if bookings are being detected at all:

Look for this log:
```
🔔 RideRequestService: Received [X] booking changes
```

- If X = 0 → No bookings match your filters
- If X > 0 but no popup → Check the skip reasons in logs

---

## Quick Diagnostic Commands

### 1. Check if driver is online:
Firebase Console → Firestore → drivers → [your_uid] → Check `status` field

### 2. Check if listener is active:
Look for: `✅ RideRequestService: Listener setup complete!`

### 3. Force a test by running diagnostic screen:
In the app, tap the **bug icon** in the AppBar (orange button)

---

## Still Not Working?

Share these logs:
1. Console output when toggling online
2. Your driver document from Firestore (screenshot)
3. A sample booking document from Firestore (screenshot)
4. Any error messages in red

The debug logs will tell us exactly what's being filtered out!
