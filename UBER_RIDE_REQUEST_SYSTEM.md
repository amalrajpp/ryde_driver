# Uber-Like Ride Request System Implementation

## Overview
This implementation provides an **Uber-style ride request workflow** where drivers receive time-limited ride requests with a modern, intuitive UI and must accept within a specified timeout period (default: 30 seconds).

---

## ✨ Features

### 1. **Time-Limited Request Popup**
- ⏱️ **30-second countdown timer** with visual pulse animation
- 🎨 **Color-coded timer**: Green → Orange → Red (based on remaining time)
- 📳 **Haptic feedback** alerts when request arrives
- 🚫 **Non-dismissible dialog** - Driver must explicitly accept or decline
- ⚡ **Auto-decline** after timeout

### 2. **Beautiful Uber-Like UI**
- 💰 **Prominent fare display** in highlighted badge
- 📍 **Pickup and drop-off locations** with distinct icons
- 📊 **Trip statistics**: Distance and estimated time
- 👤 **Customer information** with profile avatar
- 🎨 **Material Design 3** with smooth animations

### 3. **Intelligent Request Distribution**
- 🌍 **Proximity-based matching**: Only shows requests within 10km radius
- 🚗 **Vehicle type filtering**: Matches driver's vehicle type
- 🔄 **Real-time updates** via Firebase Firestore streams
- 🔔 **Push notifications** via Firebase Cloud Messaging (FCM)
- 🚦 **Status-aware**: Only active when driver is online

### 4. **Request Management**
- ✅ **Accept**: Automatically assigns driver to ride
- ❌ **Decline**: Hides request from this driver
- ⏰ **Timeout**: Auto-declines if no action taken
- 🔄 **Multi-request handling**: Processes requests one at a time

---

## 📁 File Structure

```
lib/
├── features/
│   ├── ride_request/
│   │   ├── screens/
│   │   │   └── ride_request_popup.dart      # UI popup component
│   │   └── services/
│   │       └── ride_request_service.dart     # Request handling logic
│   └── dashboard/
│       └── screens/
│           └── dashboard.dart                # Integrated with service
```

---

## 🔧 How It Works

### 1. Service Initialization
When the `DashboardScreen` loads:
```dart
@override
void initState() {
  super.initState();
  WidgetsBinding.instance.addPostFrameCallback((_) {
    _rideRequestService.initialize(context);
  });
}
```

### 2. Driver Goes Online
When driver toggles status to "online":
```dart
_rideRequestService.clearDeclinedRides();
_rideRequestService.restart(context);
```
This starts:
- Firestore snapshot listener for pending rides
- FCM notification listener
- Location-based filtering

### 3. Request Detection
The service listens for:
- **Firestore changes**: Real-time database updates
- **FCM notifications**: Push notifications from backend

When a new "pending" ride appears:
```dart
.collection('booking')
.where('status', isEqualTo: 'pending')
.where('vehicle_type', isEqualTo: myVehicleType)
.snapshots()
```

### 4. Proximity Check
Before showing popup:
```dart
final distance = Geolocator.distanceBetween(
  driverLat, driverLng,
  pickupLat, pickupLng,
);

if (distance <= 10000.0) { // Within 10km
  _showRideRequestPopup(rideId, rideData);
}
```

### 5. Popup Display
Shows modal dialog with:
- Countdown timer (30 seconds)
- Ride details
- Accept/Decline buttons

### 6. Driver Actions

**Accept:**
```dart
- Updates booking status to "accepted"
- Assigns driver_id and driver_details
- Updates driver status to "assigned"
- Sends push notification to customer
- Closes popup
```

**Decline:**
```dart
- Adds ride to declined list
- Hides from this driver
- Closes popup
- Keeps driver available for other requests
```

**Timeout:**
```dart
- Automatically triggers decline
- Returns driver to available pool
```

---

## 🎨 UI Components

### Timer Header
- **Circular timer** with pulse animation
- **Color transitions**: Green (>20s) → Orange (>10s) → Red (<10s)
- **Large countdown** display

### Customer Section
- Profile avatar (placeholder or actual image)
- Customer name
- Vehicle type requested
- **Fare badge** (prominent green highlight)

### Trip Stats
- **Distance**: Total trip distance
- **Estimated time**: Calculated duration
- Separated by vertical divider

### Location Details
- **Pickup**: Green circle icon
- **Drop-off**: Red pin icon
- Full addresses with ellipsis overflow
- Label badges ("PICKUP", "DROP-OFF")

### Action Buttons
- **Decline**: Gray outlined button (1x width)
- **Accept**: Green elevated button (2x width)
- Disabled during processing
- Loading indicator on accept

---

## 🔔 Notification Flow

### Backend to Driver
```
Customer requests ride
    ↓
Backend creates booking (status: "pending")
    ↓
Firestore triggers change
    ↓
Driver's app detects new document
    ↓
Service checks proximity & vehicle match
    ↓
Shows popup if criteria met
```

### Optional FCM Integration
```
Backend sends FCM notification
    ↓
Driver app receives push
    ↓
FCM handler extracts ride_id
    ↓
Fetches full ride details from Firestore
    ↓
Shows popup
```

---

## 🔥 Firebase Structure

### Required Data in `booking` Collection:
```json
{
  "booking_id": "unique_id",
  "status": "pending",
  "vehicle_type": "bike",
  "customer_id": "user_uid",
  "customer_name": "John Doe",
  "price": 150,
  "route": {
    "pickup_address": "123 Main St, City",
    "dropoff_address": "456 Market St, City",
    "pickup_lat": 12.9715987,
    "pickup_lng": 77.5945627,
    "dropoff_lat": 12.2958104,
    "dropoff_lng": 76.6393805,
    "distance": "5.2 km",
    "estimated_time": "15 min"
  }
}
```

### Updated on Accept:
```json
{
  "status": "accepted",
  "accepted_at": Timestamp,
  "driver_id": "driver_uid",
  "driver_details": {
    "name": "Driver Name",
    "phone": "+91xxxxxxxxxx",
    "vehicle": "Honda Activa",
    "plate": "KA01AB1234",
    "rating": 4.8,
    "image": "https://...",
    "car_model": "Red Honda Activa",
    "plate_number": "KA01AB1234"
  },
  "driver_location_lat": 12.9715987,
  "driver_location_lng": 77.5945627
}
```

---

## 🎯 Key Advantages

### 1. **Fair Distribution**
- Only nearby drivers see requests
- Vehicle type matching prevents mismatches
- Time limit ensures quick decisions

### 2. **Better UX**
- Non-intrusive but attention-grabbing
- Clear information display
- Easy accept/decline actions

### 3. **Efficient**
- Real-time updates (no polling)
- Automatic cleanup of expired requests
- Prevents duplicate popups

### 4. **Scalable**
- Firestore handles concurrent requests
- Supports multiple drivers simultaneously
- No backend changes needed for basic functionality

---

## 🚀 Usage Example

### In Dashboard Screen:
```dart
class _DashboardScreenState extends State<DashboardScreen> {
  final RideRequestService _rideRequestService = RideRequestService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _rideRequestService.initialize(context);
    });
  }

  @override
  void dispose() {
    _rideRequestService.dispose();
    super.dispose();
  }

  Future<void> _toggleStatus(bool currentStatus) async {
    String newStatus = currentStatus ? 'offline' : 'online';
    if (newStatus == 'online') {
      _rideRequestService.restart(context);
    } else {
      _rideRequestService.dispose();
    }
  }
}
```

### Standalone Popup (Manual Trigger):
```dart
showDialog(
  context: context,
  barrierDismissible: false,
  builder: (context) => RideRequestPopup(
    rideId: 'ride_123',
    rideData: rideData,
    onAccept: () {
      // Handle acceptance
      print('Ride accepted');
    },
    onDecline: () {
      // Handle decline
      print('Ride declined');
    },
    timeoutSeconds: 30,
  ),
);
```

---

## ⚙️ Configuration

### Adjust Timeout Duration:
```dart
RideRequestPopup(
  timeoutSeconds: 45, // Change from default 30
  // ...
)
```

### Change Proximity Radius:
In `ride_request_service.dart`:
```dart
final maxDistance = 15000.0; // 15km instead of 10km
```

### Customize Timer Colors:
In `ride_request_popup.dart`:
```dart
Color _getTimerColor() {
  if (_remainingSeconds > 25) return Colors.green;
  if (_remainingSeconds > 15) return Colors.orange;
  return Colors.red;
}
```

---

## 📱 Testing

### 1. Test Request Flow:
```dart
// Create a test booking in Firestore
FirebaseFirestore.instance.collection('booking').add({
  'status': 'pending',
  'vehicle_type': 'bike',
  'customer_name': 'Test Customer',
  'price': 100,
  'route': {
    'pickup_address': 'Test Pickup Location',
    'dropoff_address': 'Test Drop Location',
    'pickup_lat': YOUR_DRIVER_LAT,  // Same as driver for testing
    'pickup_lng': YOUR_DRIVER_LNG,
    'dropoff_lat': DESTINATION_LAT,
    'dropoff_lng': DESTINATION_LNG,
    'distance': '5 km',
    'estimated_time': '10 min',
  },
});
```

### 2. Test Timeout:
- Let the timer run to 0
- Verify auto-decline behavior

### 3. Test Accept:
- Click accept before timeout
- Check booking status updated
- Verify driver assignment

### 4. Test Decline:
- Click decline
- Verify ride hidden from driver
- Confirm driver still online

---

## 🛠️ Troubleshooting

### Popup Not Showing?
1. ✅ Check driver status is "online"
2. ✅ Verify vehicle type matches booking
3. ✅ Ensure driver within 10km of pickup
4. ✅ Check Firestore rules allow read access

### Timer Not Counting Down?
1. ✅ Check timer initialization in `initState`
2. ✅ Verify `setState` calls in timer callback

### Accept Not Working?
1. ✅ Check Firestore write permissions
2. ✅ Verify driver document exists
3. ✅ Ensure all required fields present

### Multiple Popups Appearing?
1. ✅ Check `_processedRideIds` set is working
2. ✅ Verify `barrierDismissible: false`
3. ✅ Ensure proper cleanup in dispose

---

## 🎓 Best Practices

1. **Always dispose service**: Prevent memory leaks
2. **Handle edge cases**: Network errors, missing data
3. **Test offline behavior**: What happens when connection lost?
4. **Optimize queries**: Use indexes for better performance
5. **Add analytics**: Track acceptance rates, timeout frequency
6. **Implement sound**: Add actual audio alerts (optional)
7. **Error boundaries**: Wrap critical code in try-catch
8. **User feedback**: Show loading states, error messages

---

## 🔮 Future Enhancements

### 1. **Surge Pricing Indicator**
Show if ride has surge multiplier applied

### 2. **Route Preview**
Mini map showing pickup location

### 3. **Customer Rating**
Display customer's rating before acceptance

### 4. **Sound Alerts**
Custom audio notification (requires `audioplayers` package)

### 5. **Batch Requests**
Show multiple requests if available

### 6. **Smart Ranking**
Priority based on earnings, distance, customer rating

### 7. **Acceptance History**
Track which rides driver accepted/declined

### 8. **Push Notification Handling**
Full FCM implementation with custom notification channels

---

## 📞 Support

If you encounter issues:
1. Check Firestore console for data structure
2. Verify Firebase configuration
3. Review debug logs for error messages
4. Test with mock data first

---

## 🎉 Summary

This implementation provides a production-ready, Uber-like ride request system with:
- ✅ Time-limited acceptance (30s default)
- ✅ Beautiful, intuitive UI
- ✅ Real-time Firebase integration
- ✅ Proximity-based matching
- ✅ Efficient request handling
- ✅ Easy to customize and extend

The system is ready to use and can handle real-world ride request scenarios effectively!
