import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class RideRequestDiagnostic extends StatefulWidget {
  const RideRequestDiagnostic({super.key});

  @override
  State<RideRequestDiagnostic> createState() => _RideRequestDiagnosticState();
}

class _RideRequestDiagnosticState extends State<RideRequestDiagnostic> {
  String _diagnosticResult = 'Tap button to run diagnostic...';
  bool _isRunning = false;

  Future<void> _runDiagnostic() async {
    setState(() {
      _isRunning = true;
      _diagnosticResult = 'Running diagnostic...\n\n';
    });

    String result = '';

    try {
      // 1. Check User
      result += '=== STEP 1: CHECK USER ===\n';
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        result += '❌ NO USER LOGGED IN\n';
        setState(() {
          _diagnosticResult = result;
          _isRunning = false;
        });
        return;
      }
      result += '✅ User ID: ${user.uid}\n';
      result += '   Email: ${user.email ?? "N/A"}\n\n';

      // 2. Check Driver Document
      result += '=== STEP 2: CHECK DRIVER DOCUMENT ===\n';
      final driverDoc = await FirebaseFirestore.instance
          .collection('drivers')
          .doc(user.uid)
          .get();

      if (!driverDoc.exists) {
        result += '❌ DRIVER DOCUMENT NOT FOUND\n';
        setState(() {
          _diagnosticResult = result;
          _isRunning = false;
        });
        return;
      }

      final driverData = driverDoc.data() as Map<String, dynamic>;
      result += '✅ Driver document exists\n';
      result += '   Status: ${driverData['status'] ?? "N/A"}\n';

      final vehicleData = driverData['vehicle'] as Map<String, dynamic>? ?? {};
      result += '   Vehicle Type: ${vehicleData['vehicle_type'] ?? "N/A"}\n';

      final locationData =
          driverData['location'] as Map<String, dynamic>? ?? {};
      final lat = locationData['lat'] ?? 0.0;
      final lng = locationData['lng'] ?? 0.0;
      result += '   Location: ($lat, $lng)\n';

      if (lat == 0.0 && lng == 0.0) {
        result += '   ⚠️ WARNING: Location is 0,0 - may cause issues\n';
      }
      result += '\n';

      // 3. Check Pending Bookings
      result += '=== STEP 3: CHECK PENDING BOOKINGS ===\n';
      final allPendingBookings = await FirebaseFirestore.instance
          .collection('booking')
          .where('status', isEqualTo: 'pending')
          .get();

      result += 'Total pending bookings: ${allPendingBookings.docs.length}\n\n';

      if (allPendingBookings.docs.isEmpty) {
        result += '⚠️ NO PENDING BOOKINGS FOUND\n';
        result += '   Create a test booking in Firebase Console\n\n';
      } else {
        for (var doc in allPendingBookings.docs) {
          final data = doc.data();
          result += '📋 Booking ID: ${doc.id}\n';
          result += '   Vehicle Type: ${data['vehicle_type'] ?? "N/A"}\n';
          result += '   Price: ₹${data['price'] ?? 0}\n';

          final route = data['route'] as Map<String, dynamic>? ?? {};
          result += '   Pickup: ${route['pickup_address'] ?? "N/A"}\n';

          final pickupLat = (route['pickup_lat'] as num?)?.toDouble() ?? 0.0;
          final pickupLng = (route['pickup_lng'] as num?)?.toDouble() ?? 0.0;
          result += '   Location: ($pickupLat, $pickupLng)\n';

          // Check if matches driver
          final bookingVehicleType = data['vehicle_type'] ?? '';
          final driverVehicleType = vehicleData['vehicle_type'] ?? '';

          if (bookingVehicleType == driverVehicleType) {
            result += '   ✅ Vehicle type MATCHES\n';
          } else {
            result +=
                '   ❌ Vehicle type MISMATCH (driver: $driverVehicleType)\n';
          }

          result += '\n';
        }
      }

      // 4. Check Matching Bookings
      result += '=== STEP 4: CHECK MATCHING BOOKINGS ===\n';
      final myVehicleType = vehicleData['vehicle_type'] ?? '';
      final matchingBookings = await FirebaseFirestore.instance
          .collection('booking')
          .where('status', isEqualTo: 'pending')
          .where('vehicle_type', isEqualTo: myVehicleType)
          .get();

      result +=
          'Bookings matching your vehicle type ($myVehicleType): ${matchingBookings.docs.length}\n\n';

      if (matchingBookings.docs.isEmpty) {
        result += '❌ NO MATCHING BOOKINGS\n';
        result += '   Possible reasons:\n';
        result += '   1. No pending bookings\n';
        result += '   2. Vehicle type mismatch\n';
        result += '   3. All bookings already accepted\n\n';
      }

      // 5. Summary
      result += '=== SUMMARY ===\n';
      if (driverData['status'] != 'online') {
        result += '❌ Driver is OFFLINE - Toggle online to receive requests\n';
      } else if (matchingBookings.docs.isEmpty) {
        result += '❌ No matching bookings available\n';
      } else if (lat == 0.0 && lng == 0.0) {
        result += '⚠️ Invalid location - may not show nearby rides\n';
      } else {
        result += '✅ Everything looks good!\n';
        result += '   - Driver is online\n';
        result +=
            '   - ${matchingBookings.docs.length} matching booking(s) found\n';
        result += '   - Location is valid\n';
        result += '\n';
        result += '🔍 If popup still not showing:\n';
        result += '   1. Check console logs for "RideRequestService"\n';
        result += '   2. Verify bookings are within 10km\n';
        result += '   3. Try toggling offline then online\n';
      }
    } catch (e) {
      result += '\n❌ ERROR: $e\n';
    }

    setState(() {
      _diagnosticResult = result;
      _isRunning = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ride Request Diagnostic'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isRunning ? null : _runDiagnostic,
                icon: _isRunning
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(Icons.play_arrow),
                label: Text(_isRunning ? 'Running...' : 'Run Diagnostic'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: SelectableText(
                  _diagnosticResult,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 13,
                    height: 1.5,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
