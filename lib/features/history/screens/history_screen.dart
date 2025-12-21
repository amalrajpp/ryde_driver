import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Using DefaultTabController for the 3 tabs
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: const Color(0xFF01221D), // Your App Theme Color
          title: const Text(
            "History",
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
          ),
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Column(
          children: [
            // Custom Tab Bar Container to get the White background effect
            Container(
              color: Colors.white,
              child: const TabBar(
                labelColor: Colors.black,
                unselectedLabelColor: Colors.grey,
                indicatorColor: Color(0xFF01221D),
                indicatorWeight: 3,
                labelStyle: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
                tabs: [
                  Tab(text: "Completed"),
                  Tab(text: "Upcoming"),
                  Tab(text: "Cancelled"),
                ],
              ),
            ),
            // The content of the tabs
            Expanded(
              child: TabBarView(
                children: [
                  _buildRidesList('completed'), // Completed Tab
                  _buildRidesList('upcoming'), // Upcoming Tab
                  _buildRidesList('cancelled'), // Cancelled Tab
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRidesList(String type) {
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      return const Center(child: Text("Please log in"));
    }

    // Define query based on type
    Query query = FirebaseFirestore.instance
        .collection('booking')
        .where('driver_id', isEqualTo: currentUser.uid);

    if (type == 'completed') {
      query = query.where('status', isEqualTo: 'completed');
    } else if (type == 'cancelled') {
      query = query.where('status', isEqualTo: 'cancelled');
    } else if (type == 'upcoming') {
      query = query.where(
        'status',
        whereIn: ['accepted', 'ongoing', 'in_progress', 'started'],
      );
    }

    query = query.orderBy('created_at', descending: true);

    return StreamBuilder<QuerySnapshot>(
      stream: query.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text("Error: ${snapshot.error}"));
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _buildEmptyState(type);
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            final doc = snapshot.data!.docs[index];
            final data = doc.data() as Map<String, dynamic>;
            return _buildRideCard(doc.id, data);
          },
        );
      },
    );
  }

  Widget _buildRideCard(String docId, Map<String, dynamic> data) {
    final status = data['status'] ?? 'unknown';
    final createdAt = data['created_at'] as Timestamp?;
    final price = (data['price'] as num?)?.toDouble() ?? 0.0;
    final route = data['route'] as Map<String, dynamic>? ?? {};
    final pickupAddress = route['pickup_address'] ?? 'Unknown';
    final dropoffAddress = route['dropoff_address'] ?? 'Unknown';
    final distance = route['distance'] ?? 'N/A';
    final duration = route['duration'] ?? 'N/A';

    final shortId = docId.length > 4
        ? docId.substring(docId.length - 4)
        : docId;
    final dateStr = createdAt != null
        ? _formatDate(createdAt.toDate())
        : 'Unknown date';

    Color statusColor;
    IconData statusIcon;

    if (status == 'completed') {
      statusColor = const Color(0xFF27AE60);
      statusIcon = Icons.check_circle;
    } else if (status == 'cancelled') {
      statusColor = const Color(0xFFE74C3C);
      statusIcon = Icons.cancel;
    } else {
      statusColor = const Color(0xFFF39C12);
      statusIcon = Icons.schedule;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header Section
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(statusIcon, color: statusColor, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      status.toUpperCase(),
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Text(
                  'Ride #$shortId',
                  style: const TextStyle(
                    color: Color(0xFF2D3436),
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          // Content Section
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Date and Time
                Row(
                  children: [
                    const Icon(
                      Icons.access_time,
                      size: 16,
                      color: Color(0xFFA4AAB3),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      dateStr,
                      style: const TextStyle(
                        color: Color(0xFFA4AAB3),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Pickup Location
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      margin: const EdgeInsets.only(top: 4),
                      width: 12,
                      height: 12,
                      decoration: const BoxDecoration(
                        color: Colors.blue,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Pickup',
                            style: TextStyle(
                              fontSize: 11,
                              color: Color(0xFFA4AAB3),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            pickupAddress,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.black87,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                // Dotted Line
                Container(
                  margin: const EdgeInsets.only(left: 5, top: 4, bottom: 4),
                  height: 20,
                  child: CustomPaint(painter: DottedLinePainter()),
                ),

                // Dropoff Location
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      margin: const EdgeInsets.only(top: 4),
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: Colors.green,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Dropoff',
                            style: TextStyle(
                              fontSize: 11,
                              color: Color(0xFFA4AAB3),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            dropoffAddress,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.black87,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),
                const Divider(height: 1),
                const SizedBox(height: 12),

                // Footer Info
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildInfoChip(Icons.straighten, distance.toString()),
                    _buildInfoChip(Icons.schedule, duration.toString()),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF01221D),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '₹${price.toStringAsFixed(0)}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: const Color(0xFF636E72)),
          const SizedBox(width: 4),
          Text(
            text,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF636E72),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String type) {
    String message;
    if (type == 'completed') {
      message = 'No completed rides yet';
    } else if (type == 'cancelled') {
      message = 'No cancelled rides';
    } else {
      message = 'No upcoming rides';
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            height: 200,
            width: 200,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.manage_search_rounded,
              size: 100,
              color: Colors.blue[300],
            ),
          ),
          const SizedBox(height: 30),
          Text(
            message,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.black54,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            "Your ride history will\nappear here.",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: Colors.grey, height: 1.5),
          ),
          const SizedBox(height: 100),
        ],
      ),
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

// Custom Painter for Dotted Line
class DottedLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey.shade300
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    const dashHeight = 3.0;
    const dashSpace = 3.0;
    double startY = 0;

    while (startY < size.height) {
      canvas.drawLine(Offset(0, startY), Offset(0, startY + dashHeight), paint);
      startY += dashHeight + dashSpace;
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
