import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DocumentsScreen extends StatelessWidget {
  const DocumentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "My Documents",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: user == null
          ? const Center(child: Text("Please login first"))
          : StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('drivers')
                  .doc(user.uid)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || !snapshot.data!.exists) {
                  return const Center(child: Text("No driver data found"));
                }

                final data = snapshot.data!.data() as Map<String, dynamic>;
                // Access the 'documents' map from your Firestore screenshot
                final docsMap =
                    data['documents'] as Map<String, dynamic>? ?? {};

                // Check verification status
                final bool isVerified = docsMap['is_verified'] ?? false;

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildStatusCard(isVerified),
                      const SizedBox(height: 20),
                      const Text(
                        "Uploaded Documents",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Pass the specific URL keys from your database
                      _buildDocTile(
                        context,
                        "Aadhaar Card",
                        docsMap['aadhaar_url'],
                      ),
                      _buildDocTile(
                        context,
                        "Driving License",
                        docsMap['dl_url'],
                      ),
                      _buildDocTile(context, "PAN Card", docsMap['pan_url']),
                      _buildDocTile(context, "RC Book", docsMap['rc_url']),
                    ],
                  ),
                );
              },
            ),
    );
  }

  Widget _buildStatusCard(bool verified) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: verified ? Colors.green.shade50 : Colors.orange.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: verified ? Colors.green : Colors.orange),
      ),
      child: Row(
        children: [
          Icon(
            verified ? Icons.check_circle : Icons.pending,
            color: verified ? Colors.green : Colors.orange,
            size: 30,
          ),
          const SizedBox(width: 15),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                verified ? "Profile Verified" : "Verification Pending",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: verified
                      ? Colors.green.shade800
                      : Colors.orange.shade900,
                ),
              ),
              Text(
                verified
                    ? "You are ready to accept rides"
                    : "Admin is reviewing your documents",
                style: const TextStyle(fontSize: 12, color: Colors.black54),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDocTile(BuildContext context, String title, String? url) {
    final isUploaded = url != null && url.isNotEmpty;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      elevation: 2,
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isUploaded ? Colors.blue.shade50 : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            Icons.description,
            color: isUploaded ? Colors.blue : Colors.grey,
          ),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(
          isUploaded ? "Uploaded" : "Not uploaded",
          style: TextStyle(
            color: isUploaded ? Colors.green : Colors.red,
            fontSize: 12,
          ),
        ),
        trailing: isUploaded
            ? IconButton(
                icon: const Icon(Icons.visibility, color: Colors.black54),
                onPressed: () {
                  // Show the image in a dialog
                  showDialog(
                    context: context,
                    builder: (_) => Dialog(child: Image.network(url)),
                  );
                },
              )
            : const Icon(Icons.warning_amber, color: Colors.red),
      ),
    );
  }
}
