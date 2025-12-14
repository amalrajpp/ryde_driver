import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

Future<void> addDriverDataToSecondaryApp(
  Map<String, dynamic> driverData,
) async {
  try {
    // 1. Get the Secondary App Instance
    final secondaryApp = Firebase.app('parcelApp');
    final parcelFirestore = FirebaseFirestore.instanceFor(app: secondaryApp);
    Map<String, dynamic> secondaryAppData = Map.from(driverData);

    // 3. Extract lat/lng from the existing 'location' map
    // (Defaulting to 0.0 if missing to prevent crashes)
    Map<String, dynamic> locMap =
        driverData['location'] ?? {'lat': 0.0, 'lng': 0.0};
    double lat = (locMap['lat'] as num?)?.toDouble() ?? 0.0;
    double lng = (locMap['lng'] as num?)?.toDouble() ?? 0.0;

    // 4. ADD the new field 'currentLocation' as a GeoPoint
    secondaryAppData['currentLocation'] = GeoPoint(lat, lng);
    /*
    // 2. Define the exact data from the screenshot
    final Map<String, dynamic> driverData = {
      "name": " Kumar",
      "email": "rahul@gmail.com",
      "phone": "+9115727278527",
      "gender": "Male",
      "location": "Bhimtal", // The text location name
      // "Current Location (GeoPoint)" -> Converted to actual Firestore GeoPoint
      "currentLocation": const GeoPoint(29.346805450319135, 79.55277524460767),

      "status": "inactive",
      "available": "offline",
      "verifiedStatus": "approved",
      "rating": 0, // Storing as number
      "shortId":
          "6472", // Storing as string to preserve leading zeros if needed
      // "Wallet Balance" -> ₹1500 (Storing as number 1500 is safer for calculations)
      "walletBalance": 1500,

      // "Created At" -> November 19, 2025 – 12:17:53 PM
      "createdAt": Timestamp.fromDate(DateTime(2025, 11, 19, 12, 17, 53)),

      "avatarUrl":
          "https://res.cloudinary.com/dewtc6liq/image/upload/v1763534871/qba0goxfmxi1u1mtqk7d.jpg",
    };

    // 3. Write to Firestore
    // You can use a specific ID (like the user's UID) or generate a new one.
    // Here I am using the 'short_id' or email as a reference,
    // but usually, you should use the Auth UID (user.uid).
*/
    final user = FirebaseAuth.instance.currentUser;
    String uniqueShortId = await _generateUniqueShortId(parcelFirestore);
    secondaryAppData['shortId'] = uniqueShortId;
    await parcelFirestore
        .collection('agents') // Assuming collection name is 'drivers'
        .doc(
          user!.uid,
        ) // ⚠️ Replace this with: FirebaseAuth.instance.currentUser!.uid
        .set(secondaryAppData);

    debugPrint("✅ Data added to Secondary App successfully!");
  } catch (e) {
    debugPrint("❌ Error adding data: $e");
  }
}

// --- Helper Function to Generate Unique ID ---
Future<String> _generateUniqueShortId(FirebaseFirestore firestore) async {
  final random = Random();

  while (true) {
    // Generate random 4-digit number (1000 to 9999)
    String shortId = (1000 + random.nextInt(9000)).toString();

    // Check if this ID already exists in the 'agents' collection
    final QuerySnapshot result = await firestore
        .collection('agents')
        .where('shortId', isEqualTo: shortId)
        .get();

    // If result is empty, the ID is unique. Return it.
    if (result.docs.isEmpty) {
      return shortId;
    }
    // If not empty, the loop runs again to generate a new ID.
  }
}
