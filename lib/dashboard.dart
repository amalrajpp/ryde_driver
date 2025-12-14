import 'dart:io';
import 'dart:convert'; // Required for jsonDecode & encode
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Required for OTP Input Formatter
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
  final List<String> _declinedRideIds = [];

  // ⚠️ CONFIGURATION: REPLACE THESE WITH YOUR ACTUAL KEYS
  final String _cloudName = "dm9b7873j";
  final String _uploadPreset = "rydeapp";
  final String _notificationServerUrl =
      "https://ryde-notifications.onrender.com/send-single";

  // --- NOTIFICATION HELPER ---
  Future<void> _sendNotification(
    String customerId,
    String title,
    String body,
  ) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection("users")
          .doc(customerId)
          .get();

      if (!doc.exists) return;
      final data = doc.data() as Map<String, dynamic>;
      String? token = data["fcmToken"];

      if (token == null || token.trim().isEmpty) return;

      await http.post(
        Uri.parse(_notificationServerUrl),
        headers: {"Content-Type": "application/json; charset=UTF-8"},
        body: jsonEncode({"token": token, "title": title, "body": body}),
      );
    } catch (e) {
      debugPrint("Error sending notification: $e");
    }
  }

  // --- ACTIONS ---
  Future<void> _toggleStatus(bool currentStatus) async {
    if (currentUser == null) return;
    String newStatus = currentStatus ? 'offline' : 'online';
    try {
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
        ).showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    }
  }

  Future<void> _acceptRide(String rideId) async {
    if (currentUser == null) return;
    try {
      DocumentSnapshot bookingDoc = await FirebaseFirestore.instance
          .collection('booking')
          .doc(rideId)
          .get();
      String? customerId;
      if (bookingDoc.exists) {
        customerId = (bookingDoc.data() as Map<String, dynamic>)['customer_id'];
      }

      DocumentSnapshot driverDoc = await FirebaseFirestore.instance
          .collection('drivers')
          .doc(currentUser!.uid)
          .get();
      if (!driverDoc.exists) return;

      final dData = driverDoc.data() as Map<String, dynamic>;
      final dVehicle = dData['vehicle'] as Map<String, dynamic>? ?? {};
      final dLocation = dData['location'] as Map<String, dynamic>? ?? {};

      await FirebaseFirestore.instance.collection('booking').doc(rideId).update(
        {
          'status': 'accepted',
          'accepted_at': FieldValue.serverTimestamp(),
          'driver_id': currentUser!.uid,
          'driver_details': {
            'name': dData['driverName'] ?? 'Ryde Driver',
            'phone': dData['phone'] ?? '',
            'rating': (dData['rating'] as num?)?.toDouble() ?? 5.0,
            'image': dData['profile_image'] ?? 'https://i.pravatar.cc/150',
            'car_model':
                "${dVehicle['color'] ?? ''} ${dVehicle['model'] ?? ''}",
            'plate_number': dVehicle['plate'] ?? '',
          },
          'driver_location_lat': (dLocation['lat'] as num?)?.toDouble() ?? 0.0,
          'driver_location_lng': (dLocation['lng'] as num?)?.toDouble() ?? 0.0,
        },
      );

      await FirebaseFirestore.instance
          .collection('drivers')
          .doc(currentUser!.uid)
          .update({'working': 'assigned'});

      if (customerId != null) {
        _sendNotification(
          customerId,
          "Ride Accepted",
          "Your driver ${dData['driverName'] ?? ''} is on the way!",
        );
      }
    } catch (e) {
      debugPrint("Error accepting ride: $e");
    }
  }

  Future<void> _declineRide(String rideId) async {
    setState(() {
      _declinedRideIds.add(rideId);
    });
  }

  // --- OTP DIALOG LOGIC ---
  Future<void> _showOtpVerificationDialog({
    required BuildContext context,
    required String requiredOtp,
    required String title,
    required VoidCallback onSuccess,
  }) async {
    final TextEditingController otpController = TextEditingController();
    String? errorText;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(title),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text("Ask the customer for the 4-digit PIN."),
                  const SizedBox(height: 15),
                  TextField(
                    controller: otpController,
                    keyboardType: TextInputType.number,
                    maxLength: 4,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 5,
                    ),
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: InputDecoration(
                      hintText: "0000",
                      errorText: errorText,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      counterText: "",
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Cancel"),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (otpController.text == requiredOtp) {
                      Navigator.pop(context); // Close dialog
                      onSuccess(); // Run success callback
                    } else {
                      setState(() {
                        errorText = "Incorrect PIN";
                      });
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text("Verify"),
                ),
              ],
            );
          },
        );
      },
    );
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

        await FirebaseFirestore.instance.collection('booking').doc(rideId).update({
          // Update status: 'started' means Pickup Done (In Progress), 'completed' means Dropoff Done
          'status': newStatus == 'started' ? 'in_progress' : 'completed',
          if (newStatus == 'started')
            'started_at': FieldValue.serverTimestamp(),
          if (newStatus == 'completed')
            'completed_at': FieldValue.serverTimestamp(),
          if (newStatus == 'started') 'pickup_proof_url': downloadUrl,
          if (newStatus == 'completed') 'delivery_proof_url': downloadUrl,
        });

        if (newStatus == 'completed') {
          await FirebaseFirestore.instance
              .collection('drivers')
              .doc(currentUser!.uid)
              .update({'working': 'unassigned'});
        }

        DocumentSnapshot bookingDoc = await FirebaseFirestore.instance
            .collection('booking')
            .doc(rideId)
            .get();
        String? customerId =
            (bookingDoc.data() as Map<String, dynamic>)['customer_id'];

        if (mounted) {
          Navigator.pop(context); // Close Sheet
          if (newStatus == 'started' && customerId != null) {
            _sendNotification(
              customerId,
              "Pickup Confirmed",
              "Your package has been picked up!",
            );
          } else if (customerId != null) {
            _sendNotification(
              customerId,
              "Delivered",
              "Your package has been successfully delivered.",
            );
          }
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                newStatus == 'started' ? "Pickup Confirmed" : "Ride Completed",
              ),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        throw Exception("Cloudinary Error");
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Upload failed: $e")));
      }
    }
  }

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
                  const Text(
                    "PIN Verified. Take a photo of the package to continue.",
                    style: TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Expanded(
                    child: GestureDetector(
                      onTap: () async {
                        final XFile? photo = await _picker.pickImage(
                          source: ImageSource.camera,
                          imageQuality: 50,
                        );
                        if (photo != null) {
                          setModalState(() => _image = File(photo.path));
                        }
                      },
                      child: Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey[300]!),
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
                              if (mounted)
                                setModalState(() => _isUploading = false);
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isUploading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                              "Submit Proof",
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
                child: Container(width: 40, height: 4, color: Colors.grey[300]),
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
    if (customerId == null) return;
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
          customerName: "Customer",
          customerPhone: "",
          specialInstructions: 'See delivery details',
          orderId: orderId,
          driverId: currentUser!.uid,
          customerId: customerId,
          bookingStatus: bookingData['status'] ?? "",
        ),
      ),
    );
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
                      _buildStatusCard(isOnline, earnings),
                      const SizedBox(height: 30),
                      if (isOnline) ...[
                        _buildOngoingRidesList(),
                        const SizedBox(height: 20),
                        _buildAvailableRidesList(driverData),
                        const SizedBox(height: 30),
                        _buildRecentRidesList(),
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

  // --- SUB-WIDGETS (Cards & Lists) ---

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
          .where(
            'status',
            whereIn: ['accepted', 'ongoing', 'started', 'in_progress'],
          )
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

  Widget _buildOngoingRideCard(String docId, Map<String, dynamic> data) {
    final route = data['route'] as Map<String, dynamic>? ?? {};
    final vehicle = data['vehicle'] as Map<String, dynamic>? ?? {};
    final status = data['status'] as String? ?? '';

    // EXTRACT SECURITY OTPs
    final security = data['security'] as Map<String, dynamic>? ?? {};
    final String? pickupOtp = security['pickup_otp']?.toString();
    final String? deliveryOtp = security['delivery_otp']?.toString();

    // Determine Phase: 'accepted'/'ongoing' = pickup phase. 'in_progress'/'started' = delivery phase.
    bool isHeadingToPickup = status == 'accepted' || status == 'ongoing';
    bool isHeadingToDropoff = status == 'in_progress' || status == 'started';

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

          // OTP Buttons
          if (isHeadingToPickup) ...[
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  if (pickupOtp != null) {
                    _showOtpVerificationDialog(
                      context: context,
                      requiredOtp: pickupOtp,
                      title: "Pickup Verification",
                      onSuccess: () => _showProofBottomSheet(docId, 'started'),
                    );
                  } else {
                    _showProofBottomSheet(docId, 'started'); // Fallback
                  }
                },
                icon: const Icon(Icons.lock_open, color: Colors.white),
                label: const Text(
                  "Verify Pickup (PIN)",
                  style: TextStyle(color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00C853),
                ),
              ),
            ),
          ],
          if (isHeadingToDropoff) ...[
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  if (deliveryOtp != null) {
                    _showOtpVerificationDialog(
                      context: context,
                      requiredOtp: deliveryOtp,
                      title: "Delivery Verification",
                      onSuccess: () =>
                          _showProofBottomSheet(docId, 'completed'),
                    );
                  } else {
                    _showProofBottomSheet(docId, 'completed'); // Fallback
                  }
                },
                icon: const Icon(Icons.lock_open, color: Colors.white),
                label: const Text(
                  "Verify Delivery (PIN)",
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

  Widget _buildAvailableRidesList(Map<String, dynamic> driverData) {
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

            final nearbyDocs = snapshot.data!.docs.where((doc) {
              if (_declinedRideIds.contains(doc.id)) return false;
              final data = doc.data() as Map<String, dynamic>;
              final route = data['route'] as Map<String, dynamic>? ?? {};
              final double pickupLat =
                  (route['pickup_lat'] as num?)?.toDouble() ?? 0.0;
              final double pickupLng =
                  (route['pickup_lng'] as num?)?.toDouble() ?? 0.0;

              if (driverLat == 0.0 || pickupLat == 0.0) return false;
              double distanceInMeters = Geolocator.distanceBetween(
                driverLat,
                driverLng,
                pickupLat,
                pickupLng,
              );
              return distanceInMeters <= 10000; // 5km Radius
            }).toList();

            if (nearbyDocs.isEmpty) {
              return _buildEmptyState("No requests nearby (within 10km)");
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

  Widget _buildRecentRidesList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('booking')
          .where('driver_id', isEqualTo: currentUser!.uid)
          .where('status', whereIn: ['completed', 'cancelled'])
          .orderBy('created_at', descending: true)
          .limit(10)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const SizedBox();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Recent Rides",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 15),
            ...snapshot.data!.docs.map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              final docId = doc.id;
              final status = data['status'] ?? 'unknown';
              final createdAt = data['created_at'] as Timestamp?;
              final price = (data['price'] as num?)?.toDouble() ?? 0.0;
              final route = data['route'] as Map<String, dynamic>? ?? {};
              final pickupAddress = route['pickup_address'] ?? 'Unknown';
              final dropoffAddress = route['dropoff_address'] ?? 'Unknown';

              final shortId = docId.length > 4
                  ? docId.substring(docId.length - 4)
                  : docId;
              final dateStr = createdAt != null
                  ? _formatDate(createdAt.toDate())
                  : 'Unknown date';
              final statusColor = status == 'completed'
                  ? const Color(0xFF27AE60)
                  : const Color(0xFFE74C3C);
              final statusIcon = status == 'completed'
                  ? Icons.check_circle
                  : Icons.cancel;

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Ride #$shortId',
                          style: const TextStyle(
                            color: Color(0xFF2D3436),
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Row(
                          children: [
                            Icon(statusIcon, color: statusColor, size: 18),
                            const SizedBox(width: 6),
                            Text(
                              status.toUpperCase(),
                              style: TextStyle(
                                color: statusColor,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      dateStr,
                      style: const TextStyle(
                        color: Color(0xFFA4AAB3),
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.circle, color: Colors.blue, size: 10),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            pickupAddress,
                            style: const TextStyle(
                              fontSize: 13,
                              color: Colors.black87,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.square, color: Colors.green, size: 10),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            dropoffAddress,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[600],
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Price',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          '₹${price.toStringAsFixed(2)}',
                          style: const TextStyle(
                            color: Color(0xFF27AE60),
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        );
      },
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

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = DateTime(now.year, now.month, now.day - 1);
    final dateToCheck = DateTime(date.year, date.month, date.day);

    if (dateToCheck == today) {
      return 'Today ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } else if (dateToCheck == yesterday) {
      return 'Yesterday ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } else {
      return '${date.day}/${date.month}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    }
  }
}
