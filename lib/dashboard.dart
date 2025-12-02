import 'dart:io';
import 'dart:convert'; // Required for jsonDecode
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http; // Use standard HTTP package
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart'; // REQUIRED for distance calculation
import 'package:ryde/driver_navigation.dart'; // Ensure this file exists

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final User? currentUser = FirebaseAuth.instance.currentUser;

  // ⚠️ CONFIGURATION: REPLACE THESE WITH YOUR ACTUAL CLOUDINARY KEYS
  final String _cloudName = "dm9b7873j";
  final String _uploadPreset = "rydeapp";

  // --- ACTIONS ---

  Future<void> _toggleStatus(bool currentStatus) async {
    if (currentUser == null) return;
    String newStatus = currentStatus ? 'offline' : 'online';
    try {
      // If going online, update location first to ensure fresh data
      if (newStatus == 'online') {
        Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );
        await FirebaseFirestore.instance
            .collection('drivers')
            .doc(currentUser!.uid)
            .update({
              'status': newStatus,
              'location': {
                'lat': position.latitude,
                'lng': position.longitude,
                'heading': position.heading,
              },
              'last_updated': FieldValue.serverTimestamp(),
            });
      } else {
        await FirebaseFirestore.instance
            .collection('drivers')
            .doc(currentUser!.uid)
            .update({
              'status': newStatus,
              'last_updated': FieldValue.serverTimestamp(),
            });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error updating status: $e")));
      }
    }
  }

  // --- ACCEPT RIDE (Writes Driver Details) ---
  Future<void> _acceptRide(String rideId) async {
    if (currentUser == null) return;

    try {
      // 1. Fetch current driver details
      DocumentSnapshot driverDoc = await FirebaseFirestore.instance
          .collection('drivers')
          .doc(currentUser!.uid)
          .get();

      if (!driverDoc.exists) return;

      final dData = driverDoc.data() as Map<String, dynamic>;
      final dVehicle = dData['vehicle'] as Map<String, dynamic>? ?? {};
      final dLocation = dData['location'] as Map<String, dynamic>? ?? {};

      // 2. Update the booking
      await FirebaseFirestore.instance.collection('booking').doc(rideId).update({
        'status': 'accepted', // This matches the new query filter
        'accepted_at': FieldValue.serverTimestamp(),
        'driver_id': currentUser!.uid,
        'driver_details': {
          'name': dData['driverName'] ?? 'Ryde Driver',
          'phone': dData['phone'] ?? '',
          'rating': (dData['rating'] as num?)?.toDouble() ?? 5.0,
          'image': dData['profile_image'] ?? 'https://i.pravatar.cc/150',
          'car_model': "${dVehicle['color'] ?? ''} ${dVehicle['model'] ?? ''}",
          'plate_number': dVehicle['plate'] ?? '',
        },
        // Save driver's current location so user can draw the route immediately
        'driver_location_lat': (dLocation['lat'] as num?)?.toDouble() ?? 0.0,
        'driver_location_lng': (dLocation['lng'] as num?)?.toDouble() ?? 0.0,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Ride Accepted! Navigate to Pickup."),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error accepting ride: $e")));
      }
    }
  }

  Future<void> _declineRide(String rideId) async {
    try {
      // Simple implementation: Just show a message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Ride hidden (Refresh to remove from list)"),
        ),
      );
    } catch (e) {
      // Handle error
    }
  }

  // --- CLOUDINARY UPLOAD LOGIC ---

  Future<void> _uploadProofAndConfirm(
    String rideId,
    String newStatus,
    File imageFile,
  ) async {
    try {
      final url = Uri.parse(
        'https://api.cloudinary.com/v1_1/$_cloudName/image/upload',
      );

      final request = http.MultipartRequest('POST', url)
        ..fields['upload_preset'] = _uploadPreset
        ..files.add(await http.MultipartFile.fromPath('file', imageFile.path));

      final response = await request.send();

      if (response.statusCode == 200) {
        final responseData = await response.stream.bytesToString();
        final jsonMap = jsonDecode(responseData);
        String downloadUrl = jsonMap['secure_url'];

        await FirebaseFirestore.instance
            .collection('booking')
            .doc(rideId)
            .update({
              'status': newStatus,
              if (newStatus == 'started')
                'started_at': FieldValue.serverTimestamp(),
              if (newStatus == 'completed')
                'completed_at': FieldValue.serverTimestamp(),
              if (newStatus == 'started') 'pickup_proof_url': downloadUrl,
              if (newStatus == 'completed') 'delivery_proof_url': downloadUrl,
            });

        if (mounted) {
          Navigator.pop(context);
          String message = newStatus == 'started'
              ? "Pickup Confirmed! Heading to Dropoff."
              : "Delivery Confirmed! Ride Completed.";

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(message), backgroundColor: Colors.green),
          );
        }
      } else {
        throw Exception("Cloudinary Error: ${response.statusCode}");
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Upload failed: $e")));
      }
    }
  }

  // --- BOTTOM SHEETS ---

  void _showProofBottomSheet(String rideId, String newStatus) {
    File? _image;
    bool _isUploading = false;
    final ImagePicker _picker = ImagePicker();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Container(
              height: 600,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      color: Colors.grey[300],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    newStatus == 'started'
                        ? "Confirm Pickup"
                        : "Confirm Delivery",
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    newStatus == 'started'
                        ? "Take a photo of the package to confirm pickup."
                        : "Take a photo of the delivered item to complete the ride.",
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 20),
                  Expanded(
                    child: GestureDetector(
                      onTap: () async {
                        try {
                          final XFile? photo = await _picker.pickImage(
                            source: ImageSource.camera,
                            imageQuality: 50,
                          );
                          if (photo != null) {
                            setModalState(() {
                              _image = File(photo.path);
                            });
                          }
                        } catch (e) {
                          debugPrint("Camera Error: $e");
                        }
                      },
                      child: Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.grey[300]!,
                            style: BorderStyle.solid,
                          ),
                        ),
                        child: _image == null
                            ? Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.camera_alt,
                                    size: 50,
                                    color: Colors.grey[400],
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    "Tap to open camera",
                                    style: TextStyle(color: Colors.grey[500]),
                                  ),
                                ],
                              )
                            : ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: Image.file(_image!, fit: BoxFit.cover),
                              ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: (_image == null || _isUploading)
                          ? null
                          : () async {
                              setModalState(() => _isUploading = true);
                              await _uploadProofAndConfirm(
                                rideId,
                                newStatus,
                                _image!,
                              );
                              if (mounted) {
                                setModalState(() => _isUploading = false);
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isUploading
                          ? const SizedBox(
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text(
                              "Submit & Confirm",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showDeliveryDetails(
    BuildContext context,
    Map<String, dynamic> bookingData,
  ) {
    final pickupDetails =
        bookingData['pickup_details'] as Map<String, dynamic>? ?? {};
    final dropoffDetails =
        bookingData['dropoff_details'] as Map<String, dynamic>? ?? {};
    final parcelDetails =
        bookingData['parcel_details'] as Map<String, dynamic>? ?? {};

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.4,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                "Delivery Details",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),
              _buildDetailSection(
                title: "Pick-up Info",
                icon: Icons.upload_rounded,
                iconColor: Colors.blue,
                details: pickupDetails,
                defaultName: "Sender",
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Divider(),
              ),
              _buildDetailSection(
                title: "Drop-off Info",
                icon: Icons.download_rounded,
                iconColor: Colors.red,
                details: dropoffDetails,
                defaultName: "Receiver",
              ),
              if (parcelDetails.isNotEmpty) ...[
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Divider(),
                ),
                _buildParcelSection(parcelDetails),
              ],
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    "Close",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- WIDGET HELPERS ---

  Widget _buildParcelSection(Map<String, dynamic> details) {
    final weight = details['weight_range']?.toString() ?? "Unknown";
    final type = details['type']?.toString() ?? "Parcel";
    final description = details['description']?.toString() ?? "";
    final dimensions = details['dimensions'] as Map<String, dynamic>? ?? {};

    String dimText = "";
    if (dimensions.isNotEmpty) {
      final l = dimensions['l']?.toString() ?? "";
      final w = dimensions['w']?.toString() ?? "";
      final h = dimensions['h']?.toString() ?? "";
      if (l.isNotEmpty && w.isNotEmpty && h.isNotEmpty) {
        dimText = "$l x $w x $h cm";
      }
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.orange.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.inventory_2_rounded,
            color: Colors.orange,
            size: 22,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Parcel Info",
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                "$weight • $type",
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (dimText.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  "Dim: $dimText",
                  style: const TextStyle(fontSize: 13, color: Colors.black54),
                ),
              ],
              if (description.isNotEmpty) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: Text(
                    description,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[800],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDetailSection({
    required String title,
    required IconData icon,
    required Color iconColor,
    required Map<String, dynamic> details,
    required String defaultName,
  }) {
    final name = details['name']?.toString() ?? defaultName;
    final phone = details['phone']?.toString() ?? "N/A";
    final building = details['building']?.toString() ?? "";
    final unit = details['unit']?.toString() ?? "";
    final instructions = details['instructions']?.toString() ?? "";

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: iconColor, size: 22),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                name,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.phone, size: 14, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    "+91 $phone",
                    style: const TextStyle(fontSize: 14, color: Colors.black87),
                  ),
                ],
              ),
              if (building.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  "$building ${unit.isNotEmpty ? '• $unit' : ''}",
                  style: const TextStyle(fontSize: 13, color: Colors.black54),
                ),
              ],
              if (instructions.isNotEmpty) ...[
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    "Note: $instructions",
                    style: TextStyle(
                      fontSize: 13,
                      fontStyle: FontStyle.italic,
                      color: Colors.grey[700],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  // --- NAVIGATION ---

  Future<void> _startNavigation(
    String orderId,
    Map<String, dynamic> bookingData,
  ) async {
    String? customerId = bookingData['customer_id'];
    if (customerId == null || customerId.isEmpty) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (c) => const Center(child: CircularProgressIndicator()),
    );

    try {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(customerId)
          .get();
      Navigator.pop(context);

      String name = "Customer";
      String phone = "";
      if (userDoc.exists) {
        final userData = userDoc.data() as Map<String, dynamic>;
        name = "${userData['firstName'] ?? ''} ${userData['lastName'] ?? ''}";
        phone = userData['phone'] ?? "";
      }

      final route = bookingData['route'] as Map<String, dynamic>? ?? {};

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => DriverNavigationScreen(
            dropoffLat: (route['dropoff_lat'] as num?)?.toDouble() ?? 0.0,
            dropoffLng: (route['dropoff_lng'] as num?)?.toDouble() ?? 0.0,
            pickupLat: (route['pickup_lat'] as num?)?.toDouble() ?? 0.0,
            pickupLng: (route['pickup_lng'] as num?)?.toDouble() ?? 0.0,
            parcelType: "Parcel",
            customerName: name.trim().isEmpty ? "Customer" : name,
            customerPhone: phone,
            specialInstructions: 'See delivery details',
            orderId: orderId,
            driverId: currentUser!.uid,
            customerId: customerId,
            bookingStatus: bookingData['status'] ?? "",
          ),
        ),
      );
    } catch (e) {
      Navigator.pop(context);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  // --- MAIN BUILD ---

  @override
  Widget build(BuildContext context) {
    if (currentUser == null) {
      return const Scaffold(body: Center(child: Text("Please log in")));
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          "Driver Dashboard",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
        automaticallyImplyLeading: false,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('drivers')
            .doc(currentUser!.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError)
            return const Center(child: Text("Error loading data"));
          if (snapshot.connectionState == ConnectionState.waiting)
            return const Center(child: CircularProgressIndicator());

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text("Driver profile not found"));
          }

          var driverData = snapshot.data!.data() as Map<String, dynamic>;
          String status = driverData['status'] ?? 'offline';
          bool isOnline = status == 'online';
          double earnings = (driverData['todayEarnings'] ?? 0.0).toDouble();

          return Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 1. Status Card
                      _buildStatusCard(isOnline, earnings),
                      const SizedBox(height: 30),

                      // 2. Rides Lists
                      if (isOnline) ...[
                        _buildOngoingRidesList(),
                        const SizedBox(height: 20),
                        // 3. Available Rides (Geo-filtered)
                        _buildAvailableRidesList(driverData),
                      ] else
                        _buildOfflineView(isOnline),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStatusCard(bool isOnline, double earnings) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 5,
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Status",
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Transform.scale(
                scale: 0.8,
                child: Switch(
                  value: isOnline,
                  onChanged: (val) => _toggleStatus(isOnline),
                  activeColor: Colors.green,
                  activeTrackColor: const Color(0xFFFFF59D),
                ),
              ),
            ],
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              isOnline ? "Online" : "Offline",
              style: TextStyle(
                color: isOnline ? Colors.green : Colors.red,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 20),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 20),
            decoration: BoxDecoration(
              color: const Color(0xFFFFFBE6),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                const Text(
                  "Today's Earnings",
                  style: TextStyle(color: Colors.grey, fontSize: 14),
                ),
                const SizedBox(height: 5),
                Text(
                  "₹${earnings.toStringAsFixed(2)}",
                  style: const TextStyle(
                    color: Colors.black87,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOfflineView(bool isOnline) {
    return Center(
      child: Column(
        children: [
          const SizedBox(height: 40),
          GestureDetector(
            onTap: () => _toggleStatus(isOnline),
            child: Container(
              padding: const EdgeInsets.all(25),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.power_settings_new,
                size: 40,
                color: Colors.grey,
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            "You're Offline",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 5),
          const Text(
            "Go online to start receiving requests",
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildOngoingRidesList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('booking')
          .where('driver_id', isEqualTo: currentUser!.uid)
          // CHANGED: Added 'accepted' to whereIn so new rides appear immediately
          .where('status', whereIn: ['accepted', 'ongoing', 'started'])
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const SizedBox();
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Ongoing Trip",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.blueAccent,
              ),
            ),
            const SizedBox(height: 15),
            ...snapshot.data!.docs.map(
              (doc) => _buildOngoingRideCard(
                doc.id,
                doc.data() as Map<String, dynamic>,
              ),
            ),
          ],
        );
      },
    );
  }

  // --- UPDATED: NEARBY FILTER LOGIC (5km Radius) ---
  Widget _buildAvailableRidesList(Map<String, dynamic> driverData) {
    // 1. Get Driver Vehicle Type & Location
    final driverVehicle = driverData['vehicle'] as Map<String, dynamic>? ?? {};
    final String myVehicleType =
        driverVehicle['vehicle_type']?.toString().toLowerCase() ?? 'car';

    final driverLoc = driverData['location'] as Map<String, dynamic>? ?? {};
    final double driverLat = (driverLoc['lat'] as num?)?.toDouble() ?? 0.0;
    final double driverLng = (driverLoc['lng'] as num?)?.toDouble() ?? 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Nearby Requests",
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 15),
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('booking')
              // Only fetch rides that are 'pending' and match my vehicle type
              .where('status', isEqualTo: 'pending')
              .where('vehicle_type', isEqualTo: myVehicleType)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return _buildEmptyState("No requests found");
            }

            // --- GEO-FILTERING ---
            final nearbyDocs = snapshot.data!.docs.where((doc) {
              final data = doc.data() as Map<String, dynamic>;
              final route = data['route'] as Map<String, dynamic>? ?? {};

              final double pickupLat =
                  (route['pickup_lat'] as num?)?.toDouble() ?? 0.0;
              final double pickupLng =
                  (route['pickup_lng'] as num?)?.toDouble() ?? 0.0;

              if (driverLat == 0.0 || pickupLat == 0.0) return false;

              // Calculate distance in METERS
              double distanceInMeters = Geolocator.distanceBetween(
                driverLat,
                driverLng,
                pickupLat,
                pickupLng,
              );

              // 5000 meters = 5 km radius
              return distanceInMeters <= 5000;
            }).toList();

            if (nearbyDocs.isEmpty) {
              return _buildEmptyState("No requests nearby (within 5km)");
            }

            return Column(
              children: nearbyDocs
                  .map(
                    (doc) => _buildAvailableRideCard(
                      doc.id,
                      doc.data() as Map<String, dynamic>,
                    ),
                  )
                  .toList(),
            );
          },
        ),
      ],
    );
  }

  Widget _buildEmptyState(String message) {
    return Container(
      padding: const EdgeInsets.all(30),
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          const Icon(Icons.location_off_outlined, size: 40, color: Colors.grey),
          const SizedBox(height: 10),
          Text(message, style: const TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  // --- CARDS ---

  Widget _buildOngoingRideCard(String docId, Map<String, dynamic> data) {
    final route = data['route'] as Map<String, dynamic>? ?? {};
    final vehicle = data['vehicle'] as Map<String, dynamic>? ?? {};
    final status = data['status'] as String? ?? '';

    // CHANGED: Treat both 'accepted' and 'ongoing' as "Heading to Pickup"
    bool isHeadingToPickup = status == 'accepted' || status == 'ongoing';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blue.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          _buildRouteInfo(route),
          const Divider(height: 30),
          _buildStatsRow(vehicle, route, data),
          const SizedBox(height: 15),
          TextButton.icon(
            onPressed: () => _showDeliveryDetails(context, data),
            icon: const Icon(Icons.info_outline, size: 18),
            label: const Text("View Delivery Details"),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _startNavigation(docId, data),
              icon: const Icon(Icons.navigation, color: Colors.white),
              // CHANGED: Logic for button label
              label: Text(
                isHeadingToPickup
                    ? "Navigate to Pickup"
                    : "Navigate to Dropoff",
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          // CHANGED: Show Pickup confirmation if Heading to Pickup
          if (isHeadingToPickup) ...[
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                // Clicking this sets status to 'started'
                onPressed: () => _showProofBottomSheet(docId, 'started'),
                icon: const Icon(Icons.camera_alt, color: Colors.white),
                label: const Text(
                  "Confirm Pickup (Photo)",
                  style: TextStyle(color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00C853),
                ),
              ),
            ),
          ],
          if (status == 'started') ...[
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                // Clicking this sets status to 'completed'
                onPressed: () => _showProofBottomSheet(docId, 'completed'),
                icon: const Icon(Icons.check_circle, color: Colors.white),
                label: const Text(
                  "Confirm Delivery (Photo)",
                  style: TextStyle(color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAvailableRideCard(String docId, Map<String, dynamic> data) {
    final route = data['route'] as Map<String, dynamic>? ?? {};
    final vehicle = data['vehicle'] as Map<String, dynamic>? ?? {};

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.05),
            spreadRadius: 2,
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  "NEW REQUEST",
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ),
              Text(
                "₹${data['price']?.toString() ?? '0'}",
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          _buildRouteInfo(route),
          const Divider(height: 30),
          _buildStatsRow(vehicle, route, data),
          const SizedBox(height: 10),
          Center(
            child: TextButton.icon(
              onPressed: () => _showDeliveryDetails(context, data),
              icon: const Icon(
                Icons.info_outline,
                size: 20,
                color: Colors.blueAccent,
              ),
              label: const Text(
                "View Delivery Details",
                style: TextStyle(
                  color: Colors.blueAccent,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(height: 15),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () => _acceptRide(docId),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00C853),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    "Accept",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _declineRide(docId),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    "Decline",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[600],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRouteInfo(Map<String, dynamic> route) {
    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.circle, color: Colors.blue, size: 12),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                route['pickup_address'] ?? 'Unknown Pickup',
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
        Container(
          margin: const EdgeInsets.only(left: 5.5),
          height: 20,
          width: 1,
          color: Colors.grey[300],
        ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.square, color: Colors.green, size: 12),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                route['dropoff_address'] ?? 'Unknown Dropoff',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatsRow(
    Map<String, dynamic> vehicle,
    Map<String, dynamic> route,
    Map<String, dynamic> data,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildInfoColumn(
          Icons.local_shipping,
          "Type",
          data['vehicle_type']?.toString().toUpperCase() ?? 'STD',
        ),
        _buildInfoColumn(
          Icons.straighten,
          "Distance",
          "${route['distance_km']?.toString() ?? '--'} km",
        ),
        _buildInfoColumn(
          Icons.timer,
          "Est. Time",
          "${route['duration_mins']?.toString() ?? '--'} min",
        ),
      ],
    );
  }

  Widget _buildInfoColumn(IconData icon, String label, String value) {
    return Column(
      children: [
        Icon(icon, color: Colors.orange, size: 20),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(color: Colors.grey[400], fontSize: 10)),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ],
    );
  }
}
