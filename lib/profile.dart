import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Define color constants
const Color kPrimaryYellow = Color(0xFFFFD700);
const Color kDarkText = Color(0xFF212121);
const Color kLightText = Color(0xFF757575);
const Color kBgColor = Color(0xFFF9F9F9);
const Color kIconBoxBg = Color(0xFFF0F0F0);

class ProfileTabContent extends StatelessWidget {
  const ProfileTabContent({super.key});

  // Helper to handle Logout
  Future<void> _handleLogout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    // Assuming you have a wrapper that listens to Auth state,
    // or you can manually navigate to login:
    // Navigator.of(context).pushReplacementNamed('/login');
  }

  @override
  Widget build(BuildContext context) {
    final User? currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      return const Center(child: Text("Please log in to view profile"));
    }

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('drivers')
          .doc(currentUser.uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(child: Text("Something went wrong"));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const Center(child: Text("Profile not found"));
        }

        // 1. Extract Data from Backend
        final data = snapshot.data!.data() as Map<String, dynamic>;

        // Profile Data
        final String name = data['driverName'] ?? 'Driver';
        final double rating = (data['rating'] as num?)?.toDouble() ?? 5.0;
        final int totalRides = data['totalRides'] ?? 0;

        // Vehicle Data (Nested Map)
        final vehicle = data['vehicle'] as Map<String, dynamic>? ?? {};
        final String vehicleMake = vehicle['make'] ?? '';
        final String vehicleModel = vehicle['model'] ?? 'Vehicle';
        final String vehicleColor = vehicle['color'] ?? '';
        final String vehiclePlate = vehicle['plate'] ?? 'No Plate';
        final String vehicleType = vehicle['vehicle_type'] ?? 'Car';

        // Construct dynamic strings
        final String vehicleSubtitle =
            "$vehicleColor $vehicleMake $vehicleModel • $vehiclePlate";

        return SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              // 1. The Top Profile Card (Dynamic)
              _buildProfileHeaderCard(name, rating, totalRides),
              const SizedBox(height: 25),

              // 2. The List Options menu
              _buildMenuItem(
                icon: Icons.directions_car_filled,
                title: 'Vehicle Information',
                subtitle: vehicleSubtitle, // Data from Backend
                onTap: () {
                  // Navigate to vehicle edit screen
                },
              ),
              _buildMenuItem(
                icon: Icons.description,
                title: 'Documents',
                subtitle: 'License, RC, Aadhaar ($vehicleType)',
                onTap: () {},
              ),
              _buildMenuItem(
                icon: Icons.account_balance,
                title: 'Earnings & Payouts',
                subtitle: 'Bank Account, Tax Info',
                onTap: () {},
              ),
              _buildMenuItem(
                icon: Icons.help,
                title: 'Support',
                subtitle: 'Help Center, Contact Us',
                onTap: () {},
              ),
              _buildMenuItem(
                icon: Icons.logout, // Changed icon for utility
                title: 'Log Out',
                subtitle: 'Sign out of your account',
                isLastItem: true,
                onTap: () => _handleLogout(context),
              ),
            ],
          ),
        );
      },
    );
  }

  // Widget for the top card
  Widget _buildProfileHeaderCard(String name, double rating, int rides) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 30.0, horizontal: 20.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          // Avatar
          CircleAvatar(
            radius: 45,
            backgroundColor: kBgColor,
            // You can add a 'profile_pic_url' field to your backend later
            backgroundImage: const NetworkImage(
              'https://i.pravatar.cc/300?img=12',
            ),
          ),
          const SizedBox(height: 15),
          // Name (Backend)
          Text(
            name,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: kDarkText,
            ),
          ),
          const SizedBox(height: 8),
          // Rating Row (Backend)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.star, color: kPrimaryYellow, size: 20),
              const SizedBox(width: 5),
              Text(
                '${rating.toStringAsFixed(1)} ($rides rides)',
                style: const TextStyle(color: kLightText, fontSize: 16),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap, // Added onTap handler
    bool isLastItem = false,
  }) {
    return Column(
      children: [
        ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 0,
            vertical: 8,
          ),
          leading: Container(
            height: 50,
            width: 50,
            decoration: BoxDecoration(
              color: kIconBoxBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: kLightText, size: 24),
          ),
          title: Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 16,
              color: kDarkText,
            ),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4.0),
            child: Text(
              subtitle,
              style: const TextStyle(color: kLightText, fontSize: 14),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          trailing: const Icon(Icons.chevron_right, color: kLightText),
          onTap: onTap,
        ),
        if (!isLastItem)
          const Divider(height: 1, color: Color(0xFFEEEEEE), indent: 60),
      ],
    );
  }
}
