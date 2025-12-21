import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart'; // Import Geolocator
import 'package:ryde/features/dashboard/screens/chat_screen.dart';
import 'package:url_launcher/url_launcher.dart';

class DriverNavigationScreen extends StatefulWidget {
  final double dropoffLat;
  final double dropoffLng;
  final double pickupLat;
  final double pickupLng;
  final String customerName;
  final String customerPhone;
  final String parcelType;
  final String specialInstructions;
  final String orderId;
  final String driverId;
  final String customerId;
  final String bookingStatus; // Added bookingStatus

  const DriverNavigationScreen({
    super.key,
    required this.dropoffLat,
    required this.dropoffLng,
    required this.pickupLat,
    required this.pickupLng,
    required this.customerName,
    required this.customerPhone,
    required this.parcelType,
    required this.specialInstructions,
    required this.orderId,
    required this.driverId,
    required this.customerId,
    required this.bookingStatus, // Required in constructor
  });

  @override
  State<DriverNavigationScreen> createState() => _DriverNavigationScreenState();
}

class _DriverNavigationScreenState extends State<DriverNavigationScreen> {
  final Completer<GoogleMapController> _mapController = Completer();

  // !!! REPLACE THIS WITH YOUR GOOGLE CLOUD API KEY (Enable Directions API) !!!
  final String _googleApiKey = "YOUR_GOOGLE_API_KEY";

  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};

  String _instructionText = "Calculating route...";
  String _distanceText = "--";
  String _etaText = "-- mins";

  // To store dynamic destination based on status
  late double targetLat;
  late double targetLng;

  @override
  void initState() {
    super.initState();
    _determineTargetLocation();
    // We don't call _setMarkers here immediately because we need current location first
    _getRealTimeDirections();
  }

  // Helper to determine where we are going based on status
  void _determineTargetLocation() {
    // Default to navigating to the Pickup location unless the booking status
    // explicitly indicates that the trip has started and the driver should
    // be navigating to the Dropoff instead.
    // Treat common "trip started" statuses as dropoff-stage.
    final status = widget.bookingStatus.toLowerCase();
    if (status == 'started' || status == 'in_progress' || status == 'on_trip') {
      // Driver is already on the trip -> navigate to Dropoff
      targetLat = widget.dropoffLat;
      targetLng = widget.dropoffLng;
    } else {
      // Otherwise (accepted, ongoing, etc.) -> navigate to Pickup
      targetLat = widget.pickupLat;
      targetLng = widget.pickupLng;
    }
  }

  // --- 1. FETCH ROUTE FROM GOOGLE (Using Current Location) ---
  Future<void> _getRealTimeDirections() async {
    try {
      // 1. Get Driver's Current Location
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      // 2. Prepare Origin (Driver) and Destination (Target)
      String origin = "${position.latitude},${position.longitude}";
      String destination = "$targetLat,$targetLng";

      final String url =
          "https://maps.googleapis.com/maps/api/directions/json?origin=$origin&destination=$destination&mode=driving&key=$_googleApiKey";

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        if (json['status'] == 'OK' && json['routes'].isNotEmpty) {
          final route = json['routes'][0];
          final leg = route['legs'][0];

          final points = _decodePolyline(route['overview_polyline']['points']);
          String rawInstruction = leg['steps'].isNotEmpty
              ? leg['steps'][0]['html_instructions']
              : "Head to destination";

          if (mounted) {
            setState(() {
              // Draw Route
              _polylines.add(
                Polyline(
                  polylineId: const PolylineId('route'),
                  points: points,
                  color: const Color(0xFF007AFF),
                  width: 5,
                ),
              );

              // Update Markers based on Real-Time Data
              _markers.clear();
              // Marker for Driver (Current Location)
              _markers.add(
                Marker(
                  markerId: const MarkerId('driver'),
                  position: LatLng(position.latitude, position.longitude),
                  icon: BitmapDescriptor.defaultMarkerWithHue(
                    BitmapDescriptor.hueAzure,
                  ),
                  infoWindow: const InfoWindow(title: "My Location"),
                ),
              );

              // Marker for Destination
              _markers.add(
                Marker(
                  markerId: const MarkerId('destination'),
                  position: LatLng(targetLat, targetLng),
                  icon: BitmapDescriptor.defaultMarkerWithHue(
                    widget.bookingStatus == 'ongoing'
                        ? BitmapDescriptor
                              .hueBlue // Blue for Pickup
                        : BitmapDescriptor.hueRed,
                  ), // Red for Dropoff
                  infoWindow: InfoWindow(
                    title: widget.bookingStatus == 'ongoing'
                        ? "Pickup Point"
                        : "Dropoff Point",
                  ),
                ),
              );

              _distanceText = leg['distance']['text'];
              _etaText = leg['duration']['text'];
              _instructionText = rawInstruction.replaceAll(
                RegExp(r"<[^>]*>"),
                '',
              );
            });
            _fitCameraToRoute(points);
          }
        }
      }
    } catch (e) {
      debugPrint("Error fetching directions: $e");
    }
  }

  // --- 2. OPEN EXTERNAL GOOGLE MAPS (Dynamic Destination) ---
  Future<void> _launchExternalMaps() async {
    // Uses the targetLat/Lng determined by status
    final Uri url = Uri.parse(
      "google.navigation:q=$targetLat,$targetLng&mode=d",
    );
    if (!await launchUrl(url)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Could not launch Google Maps")),
      );
    }
  }

  // --- HELPER METHODS ---
  List<LatLng> _decodePolyline(String encoded) {
    List<LatLng> points = [];
    int index = 0, len = encoded.length;
    int lat = 0, lng = 0;
    while (index < len) {
      int b, shift = 0, result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lat += dlat;
      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lng += dlng;
      points.add(LatLng(lat / 1E5, lng / 1E5));
    }
    return points;
  }

  Future<void> _fitCameraToRoute(List<LatLng> points) async {
    if (points.isEmpty) return;
    final controller = await _mapController.future;
    double minLat = points.first.latitude, minLng = points.first.longitude;
    double maxLat = points.first.latitude, maxLng = points.first.longitude;
    for (var p in points) {
      if (p.latitude < minLat) minLat = p.latitude;
      if (p.latitude > maxLat) maxLat = p.latitude;
      if (p.longitude < minLng) minLng = p.longitude;
      if (p.longitude > maxLng) maxLng = p.longitude;
    }
    controller.animateCamera(
      CameraUpdate.newLatLngBounds(
        LatLngBounds(
          southwest: LatLng(minLat, minLng),
          northeast: LatLng(maxLat, maxLng),
        ),
        100,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // MAP BACKGROUND
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: LatLng(widget.pickupLat, widget.pickupLng),
              zoom: 15,
            ),
            markers: _markers,
            polylines: _polylines,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            onMapCreated: (c) => _mapController.complete(c),
          ),

          // OVERLAY UI
          SafeArea(
            child: Stack(
              children: [
                // TOP INSTRUCTIONS
                Positioned(
                  top: 10,
                  left: 16,
                  right: 16,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _distanceText,
                              style: const TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            Text(
                              _instructionText,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 18,
                                color: Colors.black54,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: const Column(
                          children: [
                            Text(
                              "35",
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            Text("mph", style: TextStyle(fontSize: 12)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // TRAFFIC CARD
                Positioned(
                  top: 130,
                  left: 16,
                  right: 16,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(color: Colors.black12, blurRadius: 10),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.traffic, color: Colors.green),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  "Traffic: Light",
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                Text("ETA: $_etaText"),
                              ],
                            ),
                          ],
                        ),
                        ElevatedButton(
                          onPressed: () {},
                          child: const Text("Alt Route"),
                        ),
                      ],
                    ),
                  ),
                ),

                // FLOATING BUTTONS (LEFT)
                Positioned(
                  left: 16,
                  bottom: 240,
                  child: Column(
                    children: [
                      // NAVIGATE BUTTON (Opens External Maps)
                      FloatingActionButton(
                        heroTag: "nav",
                        onPressed: _launchExternalMaps,
                        backgroundColor: Colors.yellow[700],
                        child: const Icon(
                          Icons.turn_right,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 16),
                      FloatingActionButton(
                        heroTag: "loc",
                        onPressed: () async {
                          // RE-CENTER ON DRIVER LOCATION
                          try {
                            Position pos =
                                await Geolocator.getCurrentPosition();
                            (await _mapController.future).animateCamera(
                              CameraUpdate.newLatLng(
                                LatLng(pos.latitude, pos.longitude),
                              ),
                            );
                          } catch (e) {
                            debugPrint("Error getting location: $e");
                          }
                        },
                        backgroundColor: Colors.white,
                        child: const Icon(
                          Icons.my_location,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                ),

                // CLOSE BUTTON (RIGHT)
                Positioned(
                  right: 16,
                  bottom: 310,
                  child: FloatingActionButton(
                    heroTag: "close",
                    onPressed: () => Navigator.pop(context),
                    backgroundColor: Colors.red,
                    child: const Icon(Icons.close, color: Colors.white),
                  ),
                ),

                // BOTTOM SHEET
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(24, 12, 24, 30),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(24),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: Container(
                            width: 40,
                            height: 4,
                            margin: const EdgeInsets.only(bottom: 20),
                            color: Colors.grey[300],
                          ),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  "Delivering to",
                                  style: TextStyle(color: Colors.grey),
                                ),
                                Text(
                                  widget.customerName,
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  widget.customerPhone,
                                  style: const TextStyle(color: Colors.grey),
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                // Inside your BottomSheet
                                CircleAvatar(
                                  backgroundColor: Colors.blue,
                                  child: IconButton(
                                    icon: const Icon(
                                      Icons.chat,
                                      color: Colors.white,
                                    ),
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => ChatScreen(
                                            orderId: widget.orderId,
                                            senderId: widget
                                                .driverId, // The driver is the sender here
                                            receiverId: widget
                                                .customerId, // You need to pass the Customer UID too, or retrieve it
                                            receiverName: widget.customerName,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                                const SizedBox(width: 10),
                                CircleAvatar(
                                  backgroundColor: Colors.green,
                                  child: IconButton(
                                    onPressed: () => launchUrl(
                                      Uri.parse("tel:${widget.customerPhone}"),
                                    ),
                                    icon: const Icon(
                                      Icons.phone,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text("Parcel Type"),
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.grey[100],
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(widget.parcelType),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 20),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text("Instructions"),
                                  Text(
                                    widget.specialInstructions,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
