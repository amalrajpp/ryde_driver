import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'package:ryde/driver_dashboard.dart';

class DriverRegistrationScreen extends StatefulWidget {
  const DriverRegistrationScreen({Key? key}) : super(key: key);

  @override
  State<DriverRegistrationScreen> createState() =>
      _DriverRegistrationScreenState();
}

class _DriverRegistrationScreenState extends State<DriverRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;

  // --- CLOUDINARY CONFIGURATION ---
  // Replace these with your actual credentials
  final String _cloudName = "dm9b7873j";
  final String _uploadPreset = "rydeapp";

  // Personal Details
  final TextEditingController _nameController = TextEditingController();

  // Vehicle Details
  final TextEditingController _makeController = TextEditingController();
  final TextEditingController _modelController = TextEditingController();
  final TextEditingController _colorController = TextEditingController();
  final TextEditingController _plateController = TextEditingController();
  String _selectedVehicleType = 'bike';

  // Documents
  File? _dlImage;
  File? _aadhaarImage;
  File? _rcImage;
  File? _panImage;

  Future<void> _pickImage(String docType) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 50,
      );

      if (pickedFile != null) {
        setState(() {
          switch (docType) {
            case 'DL':
              _dlImage = File(pickedFile.path);
              break;
            case 'Aadhaar':
              _aadhaarImage = File(pickedFile.path);
              break;
            case 'RC':
              _rcImage = File(pickedFile.path);
              break;
            case 'PAN':
              _panImage = File(pickedFile.path);
              break;
          }
        });
      }
    } catch (e) {
      debugPrint("Error picking image: $e");
    }
  }

  // --- CLOUDINARY UPLOAD FUNCTION ---
  Future<String?> _uploadToCloudinary(File? file) async {
    if (file == null) return null;

    try {
      var uri = Uri.parse(
        "https://api.cloudinary.com/v1_1/$_cloudName/image/upload",
      );
      var request = http.MultipartRequest("POST", uri);

      // Add the file
      var multipartFile = await http.MultipartFile.fromPath('file', file.path);
      request.files.add(multipartFile);

      // Add the upload preset
      request.fields['upload_preset'] = _uploadPreset;
      request.fields['folder'] =
          'driver_documents'; // Optional: Folder in Cloudinary

      var response = await request.send();

      if (response.statusCode == 200) {
        var responseData = await http.Response.fromStream(response);
        var jsonResponse = jsonDecode(responseData.body);
        return jsonResponse['secure_url']; // This is the public URL
      } else {
        print("Cloudinary Upload Failed: ${response.statusCode}");
        return null;
      }
    } catch (e) {
      print("Error uploading to Cloudinary: $e");
      return null;
    }
  }

  Future<void> _submitData() async {
    if (!_formKey.currentState!.validate()) return;

    // Vehicle Logic: Cycles don't need DL/RC
    bool requiresLicense = _selectedVehicleType != 'cycle';

    if (_aadhaarImage == null || _panImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Aadhaar and PAN are required.")),
      );
      return;
    }

    if (requiresLicense && (_dlImage == null || _rcImage == null)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Driving License and RC are required.")),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception("User not logged in");

      // 1. Upload Documents to Cloudinary
      String? dlUrl = await _uploadToCloudinary(_dlImage);
      String? aadhaarUrl = await _uploadToCloudinary(_aadhaarImage);
      String? rcUrl = await _uploadToCloudinary(_rcImage);
      String? panUrl = await _uploadToCloudinary(_panImage);

      // Check if uploads were successful
      if (aadhaarUrl == null || panUrl == null) {
        throw Exception("Failed to upload mandatory documents");
      }

      // 2. Prepare Data Structure
      String userId = user.uid;

      Map<String, dynamic> driverData = {
        'id': userId,
        'driverName': _nameController.text.trim(),
        'createdAt': FieldValue.serverTimestamp(),
        'status': 'pending_approval',
        'totalRides': 0,
        'rating': 5.0, // Default start rating
        // Location
        'location': {'lat': 0.0, 'lng': 0.0, 'heading': 0.0},

        // Vehicle Map
        'vehicle': {
          'vehicle_type': _selectedVehicleType,
          'make': _makeController.text.trim(),
          'model': _modelController.text.trim(),
          'color': _colorController.text.trim(),
          'plate': _plateController.text.trim().toUpperCase(),
        },

        // Documents Map containing Cloudinary URLs
        'documents': {
          'dl_url': dlUrl,
          'aadhaar_url': aadhaarUrl,
          'rc_url': rcUrl,
          'pan_url': panUrl,
          'is_verified': false,
        },
        'registeredOn': DateTime.now().toIso8601String(),
        'isRegistered': true,
        'working': 'unassigned',
      };

      // 3. Save to Firestore
      await FirebaseFirestore.instance
          .collection('drivers')
          .doc(userId)
          .set(driverData, SetOptions(merge: true));

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Registration Submitted Successfully!")),
      );
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => DriverDashboardApp()),
      );

      // Navigate to next screen
      // Navigator.pushReplacementNamed(context, '/home');
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: ${e.toString()}")));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Upload Driver Details")),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionTitle("Personal Details"),
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: "Full Name",
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) => v!.isEmpty ? "Required" : null,
                    ),
                    const SizedBox(height: 20),

                    _buildSectionTitle("Vehicle Information"),
                    DropdownButtonFormField<String>(
                      value: _selectedVehicleType,
                      decoration: const InputDecoration(
                        labelText: "Vehicle Type",
                        border: OutlineInputBorder(),
                      ),
                      items: ['bike', 'car', 'van', 'cycle', 'scooter'].map((
                        type,
                      ) {
                        return DropdownMenuItem(
                          value: type,
                          child: Text(type.toUpperCase()),
                        );
                      }).toList(),
                      onChanged: (val) =>
                          setState(() => _selectedVehicleType = val!),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _makeController,
                            decoration: const InputDecoration(
                              labelText: "Make (e.g. Honda)",
                              border: OutlineInputBorder(),
                            ),
                            validator: (v) => v!.isEmpty ? "Required" : null,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextFormField(
                            controller: _modelController,
                            decoration: const InputDecoration(
                              labelText: "Model (e.g. City)",
                              border: OutlineInputBorder(),
                            ),
                            validator: (v) => v!.isEmpty ? "Required" : null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _colorController,
                            decoration: const InputDecoration(
                              labelText: "Color",
                              border: OutlineInputBorder(),
                            ),
                            validator: (v) => v!.isEmpty ? "Required" : null,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextFormField(
                            controller: _plateController,
                            decoration: const InputDecoration(
                              labelText: "Plate No.",
                              border: OutlineInputBorder(),
                            ),
                            validator: (v) => v!.isEmpty ? "Required" : null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    _buildSectionTitle("Document Upload"),
                    const Text(
                      "Tap to select images from gallery",
                      style: TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 10),

                    GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 2,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                      children: [
                        _buildDocCard("Aadhaar Card", _aadhaarImage, "Aadhaar"),
                        _buildDocCard("PAN Card", _panImage, "PAN"),
                        if (_selectedVehicleType != 'cycle') ...[
                          _buildDocCard("Driving License", _dlImage, "DL"),
                          _buildDocCard("Vehicle RC", _rcImage, "RC"),
                        ],
                      ],
                    ),

                    const SizedBox(height: 30),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _submitData,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue[800],
                        ),
                        child: const Text(
                          "SUBMIT",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        title,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildDocCard(String title, File? imageFile, String docType) {
    return GestureDetector(
      onTap: () => _pickImage(docType),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade400),
          borderRadius: BorderRadius.circular(10),
          color: Colors.grey.shade100,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
              child: imageFile != null
                  ? ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(10),
                      ),
                      child: Image.file(
                        imageFile,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    )
                  : Icon(Icons.cloud_upload, size: 40, color: Colors.blue[800]),
            ),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 5),
              decoration: BoxDecoration(
                color: imageFile != null ? Colors.green[100] : Colors.white,
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(10),
                ),
              ),
              child: Text(
                imageFile != null ? "Ready to Upload" : title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  color: imageFile != null ? Colors.green[800] : Colors.black87,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
