import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;

class VehicleInformationScreen extends StatefulWidget {
  const VehicleInformationScreen({super.key});

  @override
  State<VehicleInformationScreen> createState() =>
      _VehicleInformationScreenState();
}

class _VehicleInformationScreenState extends State<VehicleInformationScreen> {
  final _formKey = GlobalKey<FormState>();
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;
  bool _isEditing = false;

  // Cloudinary Configuration
  final String _cloudName = "dm9b7873j";
  final String _uploadPreset = "rydeapp";

  // Controllers
  final TextEditingController _makeController = TextEditingController();
  final TextEditingController _modelController = TextEditingController();
  final TextEditingController _yearController = TextEditingController();
  final TextEditingController _colorController = TextEditingController();
  final TextEditingController _plateController = TextEditingController();
  String _selectedVehicleType = 'bike';

  // Images
  File? _vehicleFrontImage;
  File? _vehicleBackImage;
  String? _existingFrontUrl;
  String? _existingBackUrl;

  @override
  void initState() {
    super.initState();
    _loadVehicleData();
  }

  @override
  void dispose() {
    _makeController.dispose();
    _modelController.dispose();
    _yearController.dispose();
    _colorController.dispose();
    _plateController.dispose();
    super.dispose();
  }

  Future<void> _loadVehicleData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final doc = await FirebaseFirestore.instance
          .collection('drivers')
          .doc(user.uid)
          .get();

      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        final vehicle = data['vehicle'] as Map<String, dynamic>? ?? {};

        setState(() {
          _makeController.text = vehicle['make'] ?? '';
          _modelController.text = vehicle['model'] ?? '';
          _yearController.text = vehicle['vehicleManufactureYear'] ?? '';
          _colorController.text = vehicle['color'] ?? '';
          _plateController.text = vehicle['vehicleRegistrationNumber'] ?? '';
          _selectedVehicleType = vehicle['vehicle_type'] ?? 'bike';
          _existingFrontUrl = vehicle['vehiclePhotoFront'];
          _existingBackUrl = vehicle['vehiclePhotoBack'];
        });
      }
    } catch (e) {
      debugPrint("Error loading vehicle data: $e");
    }
  }

  Future<void> _pickImage(String type) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 70,
      );

      if (pickedFile != null) {
        setState(() {
          if (type == 'front') {
            _vehicleFrontImage = File(pickedFile.path);
          } else {
            _vehicleBackImage = File(pickedFile.path);
          }
        });
      }
    } catch (e) {
      _showSnackbar("Error picking image: $e", Colors.red);
    }
  }

  Future<String?> _uploadToCloudinary(File? file) async {
    if (file == null) return null;
    try {
      var uri = Uri.parse(
        "https://api.cloudinary.com/v1_1/$_cloudName/image/upload",
      );
      var request = http.MultipartRequest("POST", uri);
      var multipartFile = await http.MultipartFile.fromPath('file', file.path);
      request.files.add(multipartFile);
      request.fields['upload_preset'] = _uploadPreset;
      request.fields['folder'] = 'vehicle_photos';

      var response = await request.send();

      if (response.statusCode == 200) {
        var responseData = await http.Response.fromStream(response);
        var jsonResponse = jsonDecode(responseData.body);
        return jsonResponse['secure_url'];
      } else {
        return null;
      }
    } catch (e) {
      debugPrint("Upload error: $e");
      return null;
    }
  }

  Future<void> _saveVehicleData() async {
    if (!_formKey.currentState!.validate()) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => _isLoading = true);

    try {
      // Upload new images if selected
      String? frontUrl = _existingFrontUrl;
      String? backUrl = _existingBackUrl;

      if (_vehicleFrontImage != null) {
        frontUrl = await _uploadToCloudinary(_vehicleFrontImage);
        if (frontUrl == null) {
          throw Exception("Failed to upload front image");
        }
      }

      if (_vehicleBackImage != null) {
        backUrl = await _uploadToCloudinary(_vehicleBackImage);
        if (backUrl == null) {
          throw Exception("Failed to upload back image");
        }
      }

      // Update Firestore
      await FirebaseFirestore.instance
          .collection('drivers')
          .doc(user.uid)
          .update({
            'vehicle': {
              'vehicle_type': _selectedVehicleType,
              'make': _makeController.text.trim(),
              'model': _modelController.text.trim(),
              'vehicleManufactureYear': _yearController.text.trim(),
              'color': _colorController.text.trim(),
              'vehicleRegistrationNumber': _plateController.text
                  .trim()
                  .toUpperCase(),
              'vehiclePhotoFront': frontUrl,
              'vehiclePhotoBack': backUrl,
            },
          });

      setState(() {
        _isEditing = false;
        _vehicleFrontImage = null;
        _vehicleBackImage = null;
        _existingFrontUrl = frontUrl;
        _existingBackUrl = backUrl;
      });

      _showSnackbar("Vehicle information updated successfully!", Colors.green);
    } catch (e) {
      _showSnackbar("Error saving data: $e", Colors.red);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showSnackbar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF01221D),
        title: const Text(
          "Vehicle Information",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (!_isEditing)
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.white),
              onPressed: () => setState(() => _isEditing = true),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Vehicle Type Section
                    _buildSectionHeader("Vehicle Type"),
                    const SizedBox(height: 12),
                    _buildVehicleTypeSelector(),
                    const SizedBox(height: 24),

                    // Vehicle Details Section
                    _buildSectionHeader("Vehicle Details"),
                    const SizedBox(height: 12),
                    _buildTextField(
                      controller: _makeController,
                      label: "Make/Brand",
                      hint: "e.g., Honda, Toyota",
                      icon: Icons.business,
                      enabled: _isEditing,
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _modelController,
                      label: "Model",
                      hint: "e.g., Civic, Corolla",
                      icon: Icons.directions_car,
                      enabled: _isEditing,
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _yearController,
                      label: "Year",
                      hint: "e.g., 2020",
                      icon: Icons.calendar_today,
                      enabled: _isEditing,
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _colorController,
                      label: "Color",
                      hint: "e.g., Black, White",
                      icon: Icons.color_lens,
                      enabled: _isEditing,
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _plateController,
                      label: "Registration Number",
                      hint: "e.g., MH12AB1234",
                      icon: Icons.pin,
                      enabled: _isEditing,
                      textCapitalization: TextCapitalization.characters,
                    ),
                    const SizedBox(height: 24),

                    // Vehicle Photos Section
                    _buildSectionHeader("Vehicle Photos"),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildImagePicker(
                            "Front View",
                            _vehicleFrontImage,
                            _existingFrontUrl,
                            'front',
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildImagePicker(
                            "Back View",
                            _vehicleBackImage,
                            _existingBackUrl,
                            'back',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),

                    // Save Button
                    if (_isEditing)
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _saveVehicleData,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF01221D),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            "Save Changes",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    if (_isEditing) const SizedBox(height: 12),
                    if (_isEditing)
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: OutlinedButton(
                          onPressed: () {
                            setState(() {
                              _isEditing = false;
                              _vehicleFrontImage = null;
                              _vehicleBackImage = null;
                            });
                            _loadVehicleData();
                          },
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0xFF01221D)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            "Cancel",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF01221D),
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

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Color(0xFF2D3436),
      ),
    );
  }

  Widget _buildVehicleTypeSelector() {
    final types = [
      {'value': 'bike', 'label': 'Bike', 'icon': Icons.two_wheeler},
      {'value': 'car', 'label': 'Car', 'icon': Icons.directions_car},
      {'value': 'auto', 'label': 'Auto', 'icon': Icons.local_taxi},
      {'value': 'cycle', 'label': 'Cycle', 'icon': Icons.pedal_bike},
    ];

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: types.map((type) {
        final isSelected = _selectedVehicleType == type['value'];
        return InkWell(
          onTap: _isEditing
              ? () => setState(
                  () => _selectedVehicleType = type['value'] as String,
                )
              : null,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: isSelected
                  ? const Color(0xFF01221D)
                  : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected
                    ? const Color(0xFF01221D)
                    : Colors.grey.shade300,
                width: 2,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  type['icon'] as IconData,
                  color: isSelected ? Colors.white : Colors.grey.shade700,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  type['label'] as String,
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.grey.shade700,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required bool enabled,
    TextInputType keyboardType = TextInputType.text,
    TextCapitalization textCapitalization = TextCapitalization.none,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF636E72),
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          enabled: enabled,
          keyboardType: keyboardType,
          textCapitalization: textCapitalization,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, color: const Color(0xFF636E72)),
            filled: true,
            fillColor: enabled ? Colors.white : Colors.grey.shade100,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF01221D), width: 2),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return '$label is required';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildImagePicker(
    String label,
    File? imageFile,
    String? existingUrl,
    String type,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF636E72),
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: _isEditing ? () => _pickImage(type) : null,
          child: Container(
            height: 150,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: imageFile != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(imageFile, fit: BoxFit.cover),
                  )
                : existingUrl != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Stack(
                      children: [
                        Image.network(
                          existingUrl,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: double.infinity,
                        ),
                        if (_isEditing)
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.black26,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.camera_alt,
                                color: Colors.white,
                                size: 32,
                              ),
                            ),
                          ),
                      ],
                    ),
                  )
                : Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.add_photo_alternate,
                          size: 40,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _isEditing ? "Tap to add" : "No photo",
                          style: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
        ),
      ],
    );
  }
}
