import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

// Assuming these exist based on your imports
import 'package:ryde/dashboard.dart';
import 'package:ryde/earnings.dart';
import 'package:ryde/profile.dart';

// Define color constants
const Color kPrimaryYellow = Color(0xFFFFD700);
const Color kDarkText = Color(0xFF212121);
const Color kLightText = Color(0xFF757575);
const Color kBgColor = Color(0xFFF9F9F9);
const Color kIconBoxBg = Color(0xFFF0F0F0);

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

  @override
  void initState() {
    super.initState();

    _tabController = TabController(length: 3, vsync: this, initialIndex: 0);

    // LOCATION UPDATE
    _updateDriverLocation();

    // 🔥 NEW: FCM TOKEN SETUP
    _saveDeviceToken();
    _listenForTokenRefresh();
  }

  // -------------------------------------------------------------------------
  // 🔥 1. SAVE FCM TOKEN TO FIRESTORE
  // -------------------------------------------------------------------------
  Future<void> _saveDeviceToken() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      // Ask notification permission (iOS + Android 13)
      await FirebaseMessaging.instance.requestPermission();

      // Get token
      final String? token = await FirebaseMessaging.instance.getToken();

      if (token != null) {
        await FirebaseFirestore.instance
            .collection('drivers')
            .doc(user.uid)
            .set({'fcmToken': token}, SetOptions(merge: true));

        debugPrint("FCM Token Saved: $token");
      }
    } catch (e) {
      debugPrint("Error saving FCM token: $e");
    }
  }

  // -------------------------------------------------------------------------
  // 🔥 2. LISTEN FOR TOKEN AUTO REFRESH
  // -------------------------------------------------------------------------
  void _listenForTokenRefresh() {
    FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      await FirebaseFirestore.instance
          .collection('drivers')
          .doc(user.uid)
          .update({'fcmToken': newToken});

      debugPrint("FCM Token Updated (refreshed): $newToken");
    });
  }

  // -------------------------------------------------------------------------
  // LOCATION UPDATE LOGIC
  // -------------------------------------------------------------------------
  Future<void> _updateDriverLocation() async {
    try {
      // A. Check Services
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;

      // B. Check Permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return;
      }
      if (permission == LocationPermission.deniedForever) return;

      // C. Get Current Position
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      // D. Update Firestore
      User? user = FirebaseAuth.instance.currentUser;

      if (user != null) {
        await FirebaseFirestore.instance
            .collection('drivers')
            .doc(user.uid)
            .update({
              'location': {
                'lat': position.latitude,
                'lng': position.longitude,
                'heading': position.heading,
              },
              'status': 'online',
              'last_updated': FieldValue.serverTimestamp(),
            });

        debugPrint(
          "Location updated: ${position.latitude}, ${position.longitude}",
        );
      }
    } catch (e) {
      debugPrint("Error updating location: $e");
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text('Driver Dashboard'),
        actions: [
          IconButton(icon: const Icon(Icons.list), onPressed: () {}),
          IconButton(icon: const Icon(Icons.person), onPressed: () {}),
          const SizedBox(width: 8),
        ],
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
        children: const [
          DashboardScreen(),
          EarningScreen(),
          ProfileTabContent(),
        ],
      ),
    );
  }
}
