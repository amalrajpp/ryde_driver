import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

// Your project imports
import 'package:ryde/driver_portal.dart';
import 'package:ryde/firebase_options.dart';
import 'package:ryde/driver_dashboard.dart';
import 'package:ryde/secondary.dart';
import 'package:ryde/services/location_permission.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // -----------------------------------------------------------
  // 1. Initialize PRIMARY Firebase (Your Ryde App)
  // -----------------------------------------------------------
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

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

  // 3. Request Permissions
  // Ideally, await this if it involves user interaction, otherwise fire-and-forget is okay.
  requestLocationPermission();

  // 4. Check Authentication State (For the PRIMARY 'Ryde' App)
  // Note: This checks the user for your MAIN app, not the parcel app.
  User? currentUser = FirebaseAuth.instance.currentUser;

  // 5. Run appropriate App based on Auth state
  if (currentUser != null) {
    // User is logged into Ryde -> Go directly to Dashboard
    runApp(const DriverDashboardApp());
  } else {
    // User is NOT logged into Ryde -> Go to Login Flow
    runApp(const MyApp());
  }
}
