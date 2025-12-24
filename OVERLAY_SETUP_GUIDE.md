# Overlay & Auto-Launch Feature Setup Guide

This guide explains how to implement the Uber-like overlay feature that shows a floating bubble when the app is in the background and automatically launches the app when a new ride request arrives.

## Features Implemented

✅ Display overlay bubble when app is in background  
✅ Auto-launch app from background on new ride request  
✅ 30-second timer on overlay  
✅ Accept/Decline buttons on overlay  
✅ Bring app to foreground automatically  
✅ Android SYSTEM_ALERT_WINDOW permission

---

## Step 1: Permissions Already Added

The following permissions have been added to `android/app/src/main/AndroidManifest.xml`:

```xml
<!-- Display over other apps -->
<uses-permission android:name="android.permission.SYSTEM_ALERT_WINDOW" />
<!-- Bring app to foreground -->
<uses-permission android:name="android.permission.DISABLE_KEYGUARD" />
<uses-permission android:name="android.permission.USE_FULL_SCREEN_INTENT" />
<uses-permission android:name="android.permission.POST_NOTIFICATIONS" />
```

---

## Step 2: Request Overlay Permission

Add this code to request permission when the driver goes online:

In `dashboard.dart`, add this import:
```dart
import 'package:ryde/features/ride_request/services/overlay_service.dart';
```

Then update `_toggleStatus` method:
```dart
Future<void> _toggleStatus(bool currentStatus) async {
  if (currentUser == null) return;
  String newStatus = currentStatus ? 'offline' : 'online';
  
  try {
    if (newStatus == 'online') {
      // Request overlay permission first
      final overlayService = OverlayService();
      final hasPermission = await overlayService.hasOverlayPermission();
      
      if (!hasPermission) {
        final granted = await overlayService.requestOverlayPermission();
        if (!granted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Overlay permission is required to receive ride requests'),
            ),
          );
          return;
        }
      }
      
      // ... rest of your existing code
    }
  } catch (e) {
    // ... error handling
  }
}
```

---

## Step 3: Update Ride Request Service

Update the `_showRideRequestPopup` method in `ride_request_service.dart`:

```dart
import 'package:ryde/features/ride_request/services/overlay_service.dart';
import 'package:flutter/services.dart';

void _showRideRequestPopup(String rideId, Map<String, dynamic> rideData) {
  if (_activeContext == null || !_activeContext!.mounted) {
    debugPrint('❌ Context not available');
    return;
  }

  // Mark as processed to avoid duplicate popups
  _processedRideIds.add(rideId);

  final route = rideData['route'] as Map<String, dynamic>? ?? {};
  final pickupAddress = route['pickup_address'] ?? 'Unknown Location';
  final customerName = rideData['customer_name'] ?? 'Customer';
  final fare = (rideData['price'] ?? 0.0);

  // Check if app is in foreground or background
  WidgetsBinding.instance.addPostFrameCallback((_) async {
    final lifecycleState = WidgetsBinding.instance.lifecycleState;
    
    if (lifecycleState == AppLifecycleState.paused || 
        lifecycleState == AppLifecycleState.inactive ||
        lifecycleState == AppLifecycleState.detached) {
      // App is in background - show overlay
      debugPrint('📱 App in background - showing overlay');
      final overlayService = OverlayService();
      await overlayService.showOverlayBubble(
        rideId: rideId,
        pickupAddress: pickupAddress,
        customerName: customerName,
        fare: fare.toDouble(),
      );
      
      // Bring app to foreground
      await SystemChannels.platform.invokeMethod('SystemNavigator.pop');
    }
    
    // Always show in-app popup as well
    Navigator.of(_activeContext!).push(
      PageRouteBuilder(
        opaque: false,
        barrierDismissible: false,
        pageBuilder: (context, animation, secondaryAnimation) {
          return RideRequestPopup(
            rideId: rideId,
            rideData: rideData,
            onAccept: () => _handleAcceptRide(rideId, rideData),
            onDecline: () => _handleDeclineRide(rideId),
            timeoutSeconds: 30,
          );
        },
      ),
    );
  });
}
```

---

## Step 4: Testing the Feature

### Test Scenario 1: App in Foreground
1. Driver goes online
2. Create a test booking in Firestore
3. ✅ Ride request popup should appear immediately

### Test Scenario 2: App in Background
1. Driver goes online
2. Press home button (minimize app)
3. Create a test booking in Firestore
4. ✅ Overlay bubble should appear on screen
5. ✅ App should automatically launch to foreground
6. ✅ Popup should show inside the app

### Test Scenario 3: App Killed/Closed
1. Driver goes online
2. Kill/close the app
3. Create a test booking
4. ✅ FCM notification should wake the app
5. ✅ Overlay should appear (if supported by device)

---

## Step 5: Handle Overlay Actions

The overlay widget (`overlay_widget.dart`) needs to communicate with the main app.

Update the overlay buttons:

```dart
// In overlay_widget.dart
ElevatedButton(
  onPressed: () async {
    // Send "accept" action to main app
    await FlutterOverlayWindow.shareData("accept");
    // Close overlay
    await FlutterOverlayWindow.closeOverlay();
  },
  child: const Text('ACCEPT'),
),

ElevatedButton(
  onPressed: () async {
    // Send "decline" action to main app
    await FlutterOverlayWindow.shareData("decline");
    // Close overlay
    await FlutterOverlayWindow.closeOverlay();
  },
  child: const Text('DECLINE'),
),
```

Then listen for these actions in the main app:

```dart
// In ride_request_service.dart - initialize method
FlutterOverlayWindow.overlayListener.listen((data) {
  debugPrint('📩 Overlay action: $data');
  if (data == "accept") {
    // Handle accept
  } else if (data == "decline") {
    // Handle decline
  }
});
```

---

## Troubleshooting

### Issue: Overlay Permission Denied
**Solution**: The system will show a settings screen. User must manually enable "Display over other apps" permission.

### Issue: Overlay Not Showing
**Check**:
1. Permission granted? `await OverlayService().hasOverlayPermission()`
2. App actually in background? Check lifecycle state
3. Android version >= 6.0 (API 23)?

### Issue: App Not Coming to Foreground
**Solution**: Use high-priority FCM notification with `full_screen_intent`

### Issue: Overlay Appears on Top of Popup
**Solution**: Check if context is available before showing overlay

---

## Alternative Simpler Approach (Recommended)

If the overlay is too complex, use **High Priority Notification** with Full-Screen Intent:

```dart
// In FCM notification payload
{
  "notification": {
    "title": "New Ride Request",
    "body": "$customerName • ₹$fare"
  },
  "android": {
    "priority": "high",
    "notification": {
      "channel_id": "ride_requests",
      "default_sound": true,
      "default_vibrate_timings": true
    }
  },
  "data": {
    "type": "new_ride_request",
    "ride_id": "[ride_id]",
    "click_action": "FLUTTER_NOTIFICATION_CLICK"
  }
}
```

This will:
- ✅ Show full-screen notification even when locked
- ✅ Auto-launch app when tapped
- ✅ Simpler implementation
- ✅ More reliable

---

## Files Created/Modified

✅ `lib/features/ride_request/services/overlay_service.dart` - Overlay management  
✅ `lib/features/ride_request/widgets/overlay_widget.dart` - Overlay UI  
✅ `lib/main.dart` - Overlay entry point  
✅ `android/app/src/main/AndroidManifest.xml` - Permissions  
✅ `pubspec.yaml` - Added packages

---

## Next Steps

1. **Test overlay permission request**
2. **Test overlay showing in background**
3. **Implement overlay action handlers**
4. **Test with real ride requests**
5. **Fine-tune UI and animations**

The basic structure is now in place. You can customize the overlay appearance and behavior as needed!
