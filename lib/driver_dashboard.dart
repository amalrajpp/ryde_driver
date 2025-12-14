import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart'; // For defaultTargetPlatform
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

// Your existing imports
import 'package:ryde/dashboard.dart';
import 'package:ryde/earnings.dart';
import 'package:ryde/profile.dart';

// Define color constants
const Color kPrimaryYellow = Color(0xFFFFD700);
const Color kDarkText = Color(0xFF212121);
const Color kLightText = Color(0xFF757575);
const Color kBgColor = Color(0xFFF9F9F9);

class DriverDashboardApp extends StatelessWidget {
  const DriverDashboardApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Driver Dashboard UI',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: kBgColor,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          elevation: 0,
          iconTheme: IconThemeData(color: kDarkText),
          titleTextStyle: TextStyle(
            color: kDarkText,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        useMaterial3: true,
      ),
      home: const DriverDashboardScreen(),
    );
  }
}

class DriverDashboardScreen extends StatefulWidget {
  const DriverDashboardScreen({super.key});

  @override
  State<DriverDashboardScreen> createState() => _DriverDashboardScreenState();
}

class _DriverDashboardScreenState extends State<DriverDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Stream Subscription for handling location updates
  StreamSubscription<Position>? _positionStreamSubscription;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this, initialIndex: 0);

    // 1. Setup FCM
    _saveDeviceToken();
    _listenForTokenRefresh();

    // 2. Start Live Location Tracking (Foreground & Background)
    _startLocationUpdates();
  }

  // -------------------------------------------------------------------------
  // 🔥 LIVE LOCATION UPDATES (FOREGROUND & BACKGROUND)
  // -------------------------------------------------------------------------
  Future<void> _startLocationUpdates() async {
    // A. Check Services
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      debugPrint("Location services are disabled.");
      return;
    }

    // B. Check Permissions
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        debugPrint("Location permissions are denied");
        return;
      }
    }
    if (permission == LocationPermission.deniedForever) {
      debugPrint("Location permissions are permanently denied");
      return;
    }

    // C. Define Location Settings for Background Support
    LocationSettings locationSettings;

    if (defaultTargetPlatform == TargetPlatform.android) {
      // ANDROID SPECIFIC SETTINGS
      locationSettings = AndroidSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 0, // Update if moved 10 meters (helps battery)
        forceLocationManager: true,
        intervalDuration: const Duration(seconds: 10), // Force update every 10s
        // Foreground Notification Config (REQUIRED for background access)
        foregroundNotificationConfig: const ForegroundNotificationConfig(
          notificationTitle: "Ryde Driver",
          notificationText: "Tracking your location for rides...",
          notificationIcon: AndroidResource(
            name: 'ic_launcher',
          ), // Ensure this icon exists
          enableWakeLock: true, // Keeps CPU awake for updates
        ),
      );
    } else if (defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.macOS) {
      // IOS SPECIFIC SETTINGS
      locationSettings = AppleSettings(
        accuracy: LocationAccuracy.high,
        activityType: ActivityType.automotiveNavigation,
        distanceFilter: 10,
        pauseLocationUpdatesAutomatically: false, // Important for background
        showBackgroundLocationIndicator: true,
      );
    } else {
      locationSettings = const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
      );
    }

    // D. Start Listening to the Stream
    _positionStreamSubscription =
        Geolocator.getPositionStream(locationSettings: locationSettings).listen(
          (Position position) {
            _updateFirestoreLocation(position);
            _updateParcelLocation(position);
          },
        );
  }

  Future<void> _updateFirestoreLocation(Position position) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        await FirebaseFirestore.instance
            .collection('drivers')
            .doc(user.uid)
            .update({
              'location': {
                'lat': position.latitude,
                'lng': position.longitude,
                'heading': position.heading,
              },
              // We don't force 'status' here to avoid overwriting 'offline' if set manually
              'last_updated': FieldValue.serverTimestamp(),
            });
        debugPrint(
          "📍 Location Updated: ${position.latitude}, ${position.longitude}",
        );
      } catch (e) {
        debugPrint("Error pushing location to Firestore: $e");
      }
    }
  }

  Future<void> _updateParcelLocation(Position position) async {
    // 1. Get the current user
    final user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      try {
        // 2. Get the Secondary App Instance
        final secondaryApp = Firebase.app('parcelApp');

        // 3. Get the Firestore instance specifically for that app
        final parcelFirestore = FirebaseFirestore.instanceFor(
          app: secondaryApp,
        );

        // 4. Perform the update
        await parcelFirestore.collection('agents').doc(user.uid).update({
          // CHANGED: Using GeoPoint for 'currentLocation'
          'currentLocation': GeoPoint(position.latitude, position.longitude),
          'last_updated': FieldValue.serverTimestamp(),
        }); // CRITICAL: merge: true prevents deleting other data

        // debugPrint("📦 Parcel System Location Updated");
      } catch (e) {
        debugPrint("Error pushing to Parcel Firestore: $e");
      }
    }
  }

  // -------------------------------------------------------------------------
  // FCM TOKEN LOGIC
  // -------------------------------------------------------------------------
  Future<void> _saveDeviceToken() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;
      await FirebaseMessaging.instance.requestPermission();
      final String? token = await FirebaseMessaging.instance.getToken();
      if (token != null) {
        await FirebaseFirestore.instance
            .collection('drivers')
            .doc(user.uid)
            .set({'fcmToken': token}, SetOptions(merge: true));
      }
    } catch (e) {
      debugPrint("Error saving FCM token: $e");
    }
  }

  void _listenForTokenRefresh() {
    FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance
            .collection('drivers')
            .doc(user.uid)
            .update({'fcmToken': newToken});
      }
    });
  }

  @override
  void dispose() {
    // Stop tracking when the dashboard is completely closed (e.g. logout)
    _positionStreamSubscription?.cancel();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text('Driver Dashboard'),

        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48.0),
          child: Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              indicatorColor: kPrimaryYellow,
              indicatorWeight: 3.0,
              labelColor: kDarkText,
              unselectedLabelColor: kLightText,
              labelStyle: const TextStyle(fontWeight: FontWeight.w600),
              tabs: const [
                Tab(text: 'Dashboard'),
                Tab(text: 'Earnings'),
                Tab(text: 'Profile'),
              ],
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [DashboardScreen(), EarningsScreen(), AccountScreen()],
      ),
    );
  }
}
