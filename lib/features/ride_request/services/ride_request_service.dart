import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../screens/ride_request_popup.dart';

class RideRequestService {
  static final RideRequestService _instance = RideRequestService._internal();
  factory RideRequestService() => _instance;
  RideRequestService._internal();

  StreamSubscription<QuerySnapshot>? _rideRequestSubscription;
  final Set<String> _processedRideIds = {};
  final Set<String> _declinedRideIds = {};
  BuildContext? _activeContext;

  // Initialize the service
  void initialize(BuildContext context) {
    debugPrint('🚀 RideRequestService: Initializing...');
    _activeContext = context;
    _setupFCMListeners();
    _startListeningForRideRequests();
  }

  // Setup Firebase Cloud Messaging listeners
  void _setupFCMListeners() {
    // Foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('🔔 Foreground notification: ${message.notification?.title}');

      if (message.data['type'] == 'new_ride_request') {
        final rideId = message.data['ride_id'];
        if (rideId != null) {
          _fetchAndShowRideRequest(rideId);
        }
      }
    });

    // When app is opened from a notification
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('🔔 App opened from notification');

      if (message.data['type'] == 'new_ride_request') {
        final rideId = message.data['ride_id'];
        if (rideId != null) {
          _fetchAndShowRideRequest(rideId);
        }
      }
    });
  }

  // Start listening for new ride requests via Firestore
  void _startListeningForRideRequests() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      debugPrint('❌ RideRequestService: No user logged in');
      return;
    }

    debugPrint('🔍 RideRequestService: Fetching driver data for ${user.uid}');

    // Get driver's vehicle type and location
    final driverDoc = await FirebaseFirestore.instance
        .collection('drivers')
        .doc(user.uid)
        .get();

    if (!driverDoc.exists) {
      debugPrint('❌ RideRequestService: Driver document not found');
      return;
    }

    final driverData = driverDoc.data() as Map<String, dynamic>;
    final vehicleData = driverData['vehicle'] as Map<String, dynamic>? ?? {};
    final myVehicleType = vehicleData['vehicle_type'] ?? '';
    final driverStatus = driverData['status'] ?? 'offline';
    final workingStatus = driverData['working'] ?? 'unassigned';

    debugPrint('📊 RideRequestService: Driver status = $driverStatus');
    debugPrint('📊 RideRequestService: Working status = $workingStatus');
    debugPrint('🚗 RideRequestService: Vehicle type = $myVehicleType');

    if (driverStatus != 'online') {
      debugPrint(
        '⚠️ RideRequestService: Driver is offline, not listening for requests',
      );
      return;
    }

    if (workingStatus != 'unassigned') {
      debugPrint(
        '⚠️ RideRequestService: Driver is already assigned to a ride, not listening for new requests',
      );
      return;
    }

    debugPrint('✅ RideRequestService: Starting to listen for pending rides...');

    // Listen to pending ride requests matching driver's vehicle type
    _rideRequestSubscription = FirebaseFirestore.instance
        .collection('booking')
        .where('status', isEqualTo: 'pending')
        .where('vehicle_type', isEqualTo: myVehicleType)
        .snapshots()
        .listen(
          (snapshot) {
            debugPrint(
              '🔔 RideRequestService: Received ${snapshot.docChanges.length} booking changes',
            );

            for (var change in snapshot.docChanges) {
              if (change.type == DocumentChangeType.added) {
                final rideId = change.doc.id;
                final rideData = change.doc.data() as Map<String, dynamic>;
                final status = rideData['status'] ?? '';

                debugPrint(
                  '🆕 RideRequestService: New ride detected: $rideId (status: $status)',
                );

                // Verify status is still pending
                if (status != 'pending') {
                  debugPrint(
                    '⏭️ RideRequestService: Ride $rideId is not pending (status: $status), skipping',
                  );
                  continue;
                }

                // Check if ride has been accepted by any driver
                final driverId = rideData['driver_id'];
                if (driverId != null && driverId.toString().isNotEmpty) {
                  debugPrint(
                    '⏭️ RideRequestService: Ride $rideId already accepted by driver $driverId',
                  );
                  _processedRideIds.add(rideId); // Add to memory cache
                  continue;
                }

                // Check if this driver already declined this ride (from Firestore)
                final declinedBy = rideData['declined_by'] as List<dynamic>?;
                if (declinedBy != null && declinedBy.contains(user.uid)) {
                  debugPrint(
                    '⏭️ RideRequestService: Ride $rideId was previously declined by this driver',
                  );
                  _declinedRideIds.add(rideId); // Add to memory cache
                  continue;
                }

                // Skip if already processed or declined in current session
                if (_processedRideIds.contains(rideId)) {
                  debugPrint(
                    '⏭️ RideRequestService: Ride $rideId already processed',
                  );
                  continue;
                }

                if (_declinedRideIds.contains(rideId)) {
                  debugPrint(
                    '⏭️ RideRequestService: Ride $rideId already declined in this session',
                  );
                  continue;
                }

                // Check if ride is nearby
                _checkAndShowRideRequest(rideId, rideData, driverData);
              }

              // If a ride was modified (e.g., accepted by another driver), remove from tracking
              if (change.type == DocumentChangeType.modified) {
                final rideId = change.doc.id;
                final rideData = change.doc.data() as Map<String, dynamic>;
                final status = rideData['status'] ?? '';

                if (status != 'pending') {
                  debugPrint(
                    '🔄 RideRequestService: Ride $rideId status changed to $status',
                  );
                  _processedRideIds.remove(rideId);
                  _declinedRideIds.remove(rideId);
                }
              }
            }
          },
          onError: (error) {
            debugPrint(
              '❌ RideRequestService: Error listening to bookings: $error',
            );
          },
        );

    debugPrint('✅ RideRequestService: Listener setup complete!');
  }

  // Check if ride is nearby and show popup
  Future<void> _checkAndShowRideRequest(
    String rideId,
    Map<String, dynamic> rideData,
    Map<String, dynamic> driverData,
  ) async {
    // First, verify the ride is still pending (not accepted/declined by another driver)
    final freshRideDoc = await FirebaseFirestore.instance
        .collection('booking')
        .doc(rideId)
        .get();

    if (!freshRideDoc.exists) {
      debugPrint('⏭️ RideRequestService: Ride $rideId no longer exists');
      return;
    }

    final freshRideData = freshRideDoc.data() as Map<String, dynamic>;
    final currentStatus = freshRideData['status'] ?? '';

    if (currentStatus != 'pending') {
      debugPrint(
        '⏭️ RideRequestService: Ride $rideId status is $currentStatus (not pending), skipping',
      );
      return;
    }

    // Double-check driver is still unassigned before showing request
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final freshDriverDoc = await FirebaseFirestore.instance
          .collection('drivers')
          .doc(user.uid)
          .get();

      if (freshDriverDoc.exists) {
        final freshData = freshDriverDoc.data() as Map<String, dynamic>;
        final currentWorkingStatus = freshData['working'] ?? 'unassigned';

        if (currentWorkingStatus != 'unassigned') {
          debugPrint(
            '⏭️ RideRequestService: Driver status changed to $currentWorkingStatus, skipping request',
          );
          return;
        }
      }
    }

    final route = rideData['route'] as Map<String, dynamic>? ?? {};
    final pickupLat = (route['pickup_lat'] as num?)?.toDouble() ?? 0.0;
    final pickupLng = (route['pickup_lng'] as num?)?.toDouble() ?? 0.0;

    final driverLocation =
        driverData['location'] as Map<String, dynamic>? ?? {};
    final driverLat = (driverLocation['lat'] as num?)?.toDouble() ?? 0.0;
    final driverLng = (driverLocation['lng'] as num?)?.toDouble() ?? 0.0;

    debugPrint('📍 RideRequestService: Checking distance for ride $rideId');
    debugPrint('   Driver location: ($driverLat, $driverLng)');
    debugPrint('   Pickup location: ($pickupLat, $pickupLng)');

    // Calculate distance
    final distance = Geolocator.distanceBetween(
      driverLat,
      driverLng,
      pickupLat,
      pickupLng,
    );

    debugPrint('   Distance: ${distance.toStringAsFixed(0)}m');

    // Show request if within 10km (10000 meters)
    final maxDistance = 10000.0;
    if (distance <= maxDistance) {
      debugPrint('✅ RideRequestService: Ride is nearby! Showing popup...');
      _showRideRequestPopup(rideId, rideData);
    } else {
      debugPrint(
        '⏭️ RideRequestService: Ride too far (${(distance / 1000).toStringAsFixed(1)}km > ${maxDistance / 1000}km)',
      );
    }
  }

  // Fetch and show ride request by ID
  Future<void> _fetchAndShowRideRequest(String rideId) async {
    try {
      final rideDoc = await FirebaseFirestore.instance
          .collection('booking')
          .doc(rideId)
          .get();

      if (!rideDoc.exists) return;

      final rideData = rideDoc.data() as Map<String, dynamic>;
      final status = rideData['status'] ?? '';

      // Only show if still pending
      if (status == 'pending' &&
          !_processedRideIds.contains(rideId) &&
          !_declinedRideIds.contains(rideId)) {
        _showRideRequestPopup(rideId, rideData);
      }
    } catch (e) {
      debugPrint('Error fetching ride request: $e');
    }
  }

  // Show the ride request popup (Uber-style bottom sheet)
  void _showRideRequestPopup(String rideId, Map<String, dynamic> rideData) {
    if (_activeContext == null || !_activeContext!.mounted) return;

    // Mark as processed to avoid duplicate popups
    _processedRideIds.add(rideId);

    // Show as a full-screen overlay (Uber-style)
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
  }

  // Handle ride acceptance
  Future<void> _handleAcceptRide(
    String rideId,
    Map<String, dynamic> rideData,
  ) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      // First, verify the ride is still pending (race condition check)
      final rideDoc = await FirebaseFirestore.instance
          .collection('booking')
          .doc(rideId)
          .get();

      if (!rideDoc.exists) {
        debugPrint('❌ Ride $rideId no longer exists');
        return;
      }

      final currentRideData = rideDoc.data() as Map<String, dynamic>;
      final currentStatus = currentRideData['status'] ?? '';

      if (currentStatus != 'pending') {
        debugPrint('❌ Ride $rideId already ${currentStatus} by another driver');
        return;
      }

      // Get driver details
      final driverDoc = await FirebaseFirestore.instance
          .collection('drivers')
          .doc(user.uid)
          .get();

      if (!driverDoc.exists) return;

      final dData = driverDoc.data() as Map<String, dynamic>;
      final dVehicle = dData['vehicle'] as Map<String, dynamic>? ?? {};
      final dLocation = dData['location'] as Map<String, dynamic>? ?? {};

      // Update booking with driver details
      await FirebaseFirestore.instance.collection('booking').doc(rideId).update(
        {
          'status': 'accepted',
          'accepted_at': FieldValue.serverTimestamp(),
          'driver_id': user.uid,
          'driver_details': {
            'name': dData['driverName'] ?? 'Ryde Driver',
            'phone': dData['phone'] ?? '',
            'vehicle': dVehicle['model'] ?? '',
            'plate': dVehicle['vehicleRegistrationNumber'] ?? '',
            'rating': (dData['rating'] as num?)?.toDouble() ?? 5.0,
            'image': dData['avatar'] ?? 'https://i.pravatar.cc/150',
            'car_model':
                "${dVehicle['color'] ?? ''} ${dVehicle['model'] ?? ''}",
            'plate_number': dVehicle['vehicleRegistrationNumber'] ?? '',
          },
          'driver_location_lat': (dLocation['lat'] as num?)?.toDouble() ?? 0.0,
          'driver_location_lng': (dLocation['lng'] as num?)?.toDouble() ?? 0.0,
        },
      );

      // Update driver status
      await FirebaseFirestore.instance
          .collection('drivers')
          .doc(user.uid)
          .update({'working': 'assigned'});

      // Send notification to customer
      final customerId = rideData['customer_id'];
      if (customerId != null) {
        _sendNotificationToCustomer(
          customerId,
          'Ride Accepted',
          'Your driver ${dData['driverName'] ?? ''} is on the way!',
        );
      }

      debugPrint('✅ Ride accepted successfully');
    } catch (e) {
      debugPrint('❌ Error accepting ride: $e');
    }
  }

  // Handle ride decline
  Future<void> _handleDeclineRide(String rideId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    _declinedRideIds.add(rideId);
    debugPrint('❌ Ride declined: $rideId');

    try {
      // Add this driver to the declined_by list in Firestore
      await FirebaseFirestore.instance.collection('booking').doc(rideId).update(
        {
          'declined_by': FieldValue.arrayUnion([user.uid]),
          'last_declined_at': FieldValue.serverTimestamp(),
        },
      );
      debugPrint('✅ Added driver to declined_by list in Firestore');
    } catch (e) {
      debugPrint('❌ Error updating declined_by: $e');
    }
  }

  // Send notification to customer
  Future<void> _sendNotificationToCustomer(
    String customerId,
    String title,
    String body,
  ) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(customerId)
          .get();

      if (!doc.exists) return;

      final data = doc.data() as Map<String, dynamic>;
      final token = data['fcmToken'];

      if (token == null || token.toString().trim().isEmpty) return;

      // You can implement your notification service here
      // For now, just logging
      debugPrint('📤 Sending notification to customer: $title');
    } catch (e) {
      debugPrint('Error sending notification: $e');
    }
  }

  // Stop listening (but keep declined/processed ride history)
  void dispose() {
    _rideRequestSubscription?.cancel();
    // Don't clear _processedRideIds and _declinedRideIds
    // They should persist across online/offline toggles
  }

  // Restart listening (when driver goes online)
  void restart(BuildContext context) {
    debugPrint('🔄 RideRequestService: Restarting service...');
    _rideRequestSubscription?.cancel(); // Just cancel subscription
    initialize(context);
  }

  // Complete cleanup (only call when driver logs out or app closes)
  void completeDispose() {
    _rideRequestSubscription?.cancel();
    _processedRideIds.clear();
    _declinedRideIds.clear();
    _activeContext = null;
  }
}
