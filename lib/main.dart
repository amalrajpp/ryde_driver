import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Added for Auth Check
import 'package:flutter/material.dart';

// Your project imports
import 'package:ryde/driver_portal.dart';
import 'package:ryde/firebase_options.dart';
import 'package:ryde/driver_dashboard.dart';
import 'package:ryde/services/location_permission.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Initialize Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // 2. Request Permissions (Optional: consider awaiting if it returns a Future)
  requestLocationPermission();

  // 3. Check Authentication State
  User? currentUser = FirebaseAuth.instance.currentUser;

  // 4. Run appropriate App based on Auth state
  if (currentUser != null) {
    // User is already logged in -> Go directly to Dashboard
    runApp(const DriverDashboardApp());
  } else {
    // User is NOT logged in -> Go to Login Flow
    runApp(const MyApp());
  }
}
