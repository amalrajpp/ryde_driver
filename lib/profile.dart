import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ryde/document_screen.dart';
import 'package:ryde/driver_portal.dart';
import 'package:ryde/history_screen.dart';
// import 'package:ryde/main.dart'; // Import your main file if you need to navigate to MyApp

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> _handleLogout() async {
    try {
      await _auth.signOut();
      if (mounted) {
        // Navigate back to the very first screen (usually Login or MyApp)
        // and remove all previous screens from the stack so back button doesn't work.
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (context) => const LoginScreen(),
          ), // Replace with your actual Home Screen
          (Route<dynamic> route) => false,
        );
        // OR: If you aren't using named routes, use this:
        /*
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const MyApp()), // Replace MyApp with your LoginScreen
          (route) => false,
        );
        */
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error logging out: $e")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "My Account",
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 18),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // User Profile Card (dynamic)
            StreamBuilder<DocumentSnapshot<Map<String, dynamic>>?>(
              stream: _auth.currentUser == null
                  ? null
                  : _firestore
                        .collection('drivers')
                        .doc(_auth.currentUser!.uid)
                        .snapshots(),
              builder: (context, snapshot) {
                if (_auth.currentUser == null) {
                  return _buildProfileCard(data: null, loading: false);
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return _buildProfileCard(data: null, loading: true);
                }
                final data = snapshot.data?.data();
                return _buildProfileCard(data: data, loading: false);
              },
            ),

            const SizedBox(height: 20),

            // --- Menu Options List ---
            _buildMenuOption(
              icon: Icons.notifications,
              title: "Notifications",
              onTap: () {},
            ),
            _buildMenuOption(
              icon: Icons.history,
              title: "History",
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const HistoryScreen(),
                  ),
                );
              },
            ),
            _buildMenuOption(
              icon: Icons.directions_car_filled,
              title: "Vehicle Informations",
              isCarIcon: true,
              onTap: () {},
            ),
            _buildMenuOption(
              icon: Icons.folder,
              title: "Documents",
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const DocumentsScreen(),
                  ),
                );
              },
            ),
            _buildMenuOption(
              icon: Icons.credit_card,
              title: "Payment",
              onTap: () {},
            ),
            _buildMenuOption(
              icon: Icons.share,
              title: "Refer & Earn",
              onTap: () {},
            ),
            _buildMenuOption(
              icon: Icons.language,
              title: "Change Language",
              onTap: () {},
            ),
            _buildMenuOption(
              customIcon: const Text(
                "SOS",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Color(0xFF01221D),
                ),
              ),
              title: "SOS",
              onTap: () {},
            ),
            _buildMenuOption(
              icon: Icons.report_problem,
              title: "Reports",
              onTap: () {},
            ),

            // --- NEW LOGOUT OPTION ---
            const SizedBox(height: 20), // Extra spacing before logout
            _buildMenuOption(
              icon: Icons.logout,
              title: "Logout",
              onTap: _handleLogout,
              textColor: Colors.redAccent, // Optional: make text red
              iconColor: Colors.redAccent, // Optional: make icon red
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileCard({Map<String, dynamic>? data, bool loading = false}) {
    final displayName =
        data?['driverName'] as String? ??
        _auth.currentUser?.displayName ??
        'Driver';
    final trips = data?['trips'] ?? 0;
    final rating = data?['rating']?.toString() ?? '0.0';
    final photoUrl = data?['avatar'] as String?;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: Colors.pink[100],
            backgroundImage: photoUrl != null ? NetworkImage(photoUrl) : null,
            child: photoUrl == null
                ? Icon(Icons.face, size: 40, color: Colors.purple[900])
                : null,
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                loading
                    ? const SizedBox(
                        height: 18,
                        width: 120,
                        child: LinearProgressIndicator(minHeight: 6),
                      )
                    : Row(
                        children: [
                          Expanded(
                            child: Text(
                              displayName,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.edit, size: 18),
                            onPressed: () => _showEditNameDialog(displayName),
                          ),
                        ],
                      ),
                const SizedBox(height: 6),
                Text(
                  "Trips Taken : $trips",
                  style: const TextStyle(fontSize: 14, color: Colors.black87),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.star, color: Colors.amber, size: 20),
                    const SizedBox(width: 4),
                    Text(
                      rating,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
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

  Future<void> _showEditNameDialog(String currentName) async {
    final controller = TextEditingController(text: currentName);
    final user = _auth.currentUser;
    if (user == null) return;

    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit name'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'Name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final newName = controller.text.trim();
              if (newName.isNotEmpty) {
                await _firestore.collection('drivers').doc(user.uid).set({
                  'driverName': newName,
                }, SetOptions(merge: true));

                try {
                  await user.updateDisplayName(newName);
                } catch (_) {}
              }
              if (context.mounted) Navigator.of(context).pop();
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuOption({
    IconData? icon,
    Widget? customIcon,
    required String title,
    required VoidCallback onTap,
    bool isCarIcon = false,
    Color? textColor, // Added for logout styling
    Color? iconColor, // Added for logout styling
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.05),
            blurRadius: 2,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        onTap: onTap,
        leading:
            customIcon ??
            (isCarIcon
                ? Stack(
                    clipBehavior: Clip.none,
                    children: const [
                      Icon(
                        Icons.directions_car_outlined,
                        color: Color(0xFF01221D),
                        size: 28,
                      ),
                      Positioned(
                        top: -2,
                        right: -2,
                        child: Icon(
                          Icons.error,
                          size: 14,
                          color: Color(0xFF01221D),
                        ),
                      ),
                    ],
                  )
                : Icon(
                    icon,
                    color: iconColor ?? const Color(0xFF01221D),
                    size: 26,
                  )),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: textColor ?? Colors.black, // Use custom color if provided
          ),
        ),
        minLeadingWidth: 20,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
        visualDensity: const VisualDensity(vertical: -2),
      ),
    );
  }
}
