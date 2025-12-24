import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';

// Your project imports
import 'package:ryde/features/auth/screens/driver_portal.dart';
import 'package:ryde/core/constants/firebase_options.dart';
import 'package:ryde/features/dashboard/screens/driver_dashboard.dart';
import 'package:ryde/core/services/location_permission.dart';
import 'package:ryde/payment_module/config/payment_config.dart';
import 'package:ryde/features/ride_request/widgets/overlay_widget.dart';

// FCM Background Message Handler
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  debugPrint('🔔 Background message received: ${message.notification?.title}');

  // Log that a ride request came in - the Firestore listener will handle showing the popup
  if (message.notification?.title?.contains('Ride Request') == true) {
    debugPrint('🚗 Ride request notification received in background');
    debugPrint(
      '📱 App will show popup when Firestore listener detects new booking',
    );
  }
}

// Overlay entry point
@pragma("vm:entry-point")
void overlayMain() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    const MaterialApp(debugShowCheckedModeBanner: false, home: OverlayApp()),
  );
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // -----------------------------------------------------------
  // 1. Initialize PRIMARY Firebase (Your Ryde App)
  // -----------------------------------------------------------
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // -----------------------------------------------------------
  // 1.1 Register FCM Background Message Handler
  // -----------------------------------------------------------
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  debugPrint('✅ FCM background handler registered');

  // -----------------------------------------------------------
  // 2. Initialize SECONDARY Firebase (Parcel Delivery System)
  // -----------------------------------------------------------
  // We give it a specific name 'parcelApp' to distinguish it.
  await Firebase.initializeApp(
    name: 'parcelApp',
    options: const FirebaseOptions(
      apiKey: "AIzaSyBStAL2CRzLS14_ShD3gtpU8axRQaVOZVU",
      appId: "1:343169981401:web:7629528d73a42d183597c8",
      messagingSenderId: "343169981401",
      projectId: "parcel-delivery-system-5ff64",
      storageBucket: "parcel-delivery-system-5ff64.firebasestorage.app",
      // authDomain is optional but good to have if using web-based auth flows
      authDomain: "parcel-delivery-system-5ff64.firebaseapp.com",
    ),
  );

  // -----------------------------------------------------------
  // 3. Initialize RazorPay Payment Gateway
  // -----------------------------------------------------------
  if (PaymentConfig.isRazorPayConfigured) {
    print('✅ RazorPay configured successfully');
  } else {
    print('⚠️ RazorPay not configured. Add keys to PaymentConfig.');
  }

  // 4. Request Permissions
  // Ideally, await this if it involves user interaction, otherwise fire-and-forget is okay.
  requestLocationPermission();

  // 5. Check Authentication State (For the PRIMARY 'Ryde' App)
  // Note: This checks the user for your MAIN app, not the parcel app.
  User? currentUser = FirebaseAuth.instance.currentUser;

  // 6. Run appropriate App based on Auth state
  if (currentUser != null) {
    // User is logged into Ryde -> Go directly to Dashboard
    runApp(const DriverDashboardApp());
  } else {
    // User is NOT logged into Ryde -> Go to Login Flow
    runApp(const MyApp());
  }
}
