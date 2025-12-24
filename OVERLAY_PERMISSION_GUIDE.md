# Overlay Permission - When & How It Appears

## ✅ **YES - The app WILL ask for overlay permission!**

### When the Permission Dialog Appears:

1. **First Time Going Online**
   - Driver opens app
   - Taps the toggle to go **ONLINE**
   - 📱 **Permission dialog appears**: "Allow Ryde Agent to display over other apps?"
   - Options: "Don't allow" | "Settings"

2. **What Happens When Driver Clicks "Settings"**
   - Android takes driver to Settings → "Display over other apps"
   - Driver manually enables the toggle for "Ryde Agent"
   - Driver returns to app
   - Next time going online: Permission will be granted automatically

3. **If Permission Denied**
   - Driver can still go online
   - Ride requests will work in-app (foreground)
   - ❌ But overlay won't show when app is in background
   - Orange snackbar appears: "Display over other apps permission is required..."

---

## Flow Diagram:

```
Driver Taps "Go Online"
         ↓
  Check Permission
         ↓
    ┌────────────┐
    │ Granted?   │
    └────────────┘
         ↓
    NO  │  YES
        │
        ├─→ Show Permission Dialog
        │   "Allow display over other apps?"
        │         ↓
        │    ┌─────────┐
        │    │Settings?│
        │    └─────────┘
        │         ↓
        │    Open Settings
        │    Driver enables manually
        │         ↓
        └─→ Continue going online
            Get location
            Update Firestore
            Start listening for rides
```

---

## Console Logs You'll See:

### First Time (No Permission):
```
🔄 Toggle status called: currentStatus=false
🔄 Attempting to change status to: online
📱 Requesting overlay permission...
[Permission dialog appears on screen]
✅ Overlay permission granted  (or ❌ denied)
📍 Getting current location...
📍 Location obtained: 12.9716, 77.5946
✅ Status updated to online in Firestore
🔄 RideRequestService: Restarting service...
```

### Second Time (Permission Already Granted):
```
🔄 Toggle status called: currentStatus=false
🔄 Attempting to change status to: online
✅ Overlay permission already granted
📍 Getting current location...
📍 Location obtained: 12.9716, 77.5946
✅ Status updated to online in Firestore
```

---

## What the Permission Dialog Looks Like:

```
┌─────────────────────────────────────┐
│  Display over other apps            │
│                                     │
│  Allow Ryde Agent to display over  │
│  other apps?                        │
│                                     │
│  This lets the app display a       │
│  floating window on top of other   │
│  apps.                              │
│                                     │
│  [ Don't allow ]   [ Settings ]    │
└─────────────────────────────────────┘
```

When driver taps **"Settings"**, they'll see:

```
┌─────────────────────────────────────┐
│  ← Display over other apps          │
│                                     │
│  Search apps                        │
│                                     │
│  [A]                                │
│  App 1                              │
│  App 2                              │
│                                     │
│  [R]                                │
│  Ryde Agent              [ OFF ]    │  ← Driver toggles this ON
│                                     │
│  [S]                                │
│  Some App                           │
└─────────────────────────────────────┘
```

---

## Testing It:

1. **Clean Install** (recommended for testing):
   ```bash
   flutter clean
   flutter run
   ```

2. **In the App**:
   - Login as driver
   - Tap "Go Online" toggle
   - ✅ Permission dialog should appear!

3. **If Dialog Doesn't Appear**:
   - Check Android version (must be ≥ 6.0 / API 23)
   - Check console logs
   - Permission might already be granted (check app settings)

---

## How to Revoke Permission (For Testing):

1. Go to: **Settings → Apps → Ryde Agent → Display over other apps**
2. Toggle **OFF**
3. Reopen app and go online
4. Permission dialog will appear again!

---

## Important Notes:

✅ Permission is requested **only when going online**  
✅ Permission is requested **only once** (unless revoked)  
✅ App works without permission (just no overlay in background)  
✅ Driver can manually enable in settings anytime  

The permission request is now fully integrated! 🎉
