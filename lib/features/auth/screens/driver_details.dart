import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'package:ryde/features/dashboard/screens/driver_dashboard.dart';
import 'package:ryde/features/dashboard/screens/secondary.dart';

class DriverRegistrationScreen extends StatefulWidget {
  const DriverRegistrationScreen({Key? key}) : super(key: key);

  @override
  State<DriverRegistrationScreen> createState() =>
      _DriverRegistrationScreenState();
}

class _DriverRegistrationScreenState extends State<DriverRegistrationScreen> {
  // --- EXISTING LOGIC STARTS ---
  final _formKey = GlobalKey<FormState>();
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;

  final String _cloudName = "dm9b7873j";
  final String _uploadPreset = "rydeapp";

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  String _selectedGender = 'Male';

  final TextEditingController _makeController = TextEditingController();
  final TextEditingController _modelController = TextEditingController();
  final TextEditingController _yearController =
      TextEditingController(); // NEW CONTROLLER
  final TextEditingController _colorController = TextEditingController();
  final TextEditingController _plateController = TextEditingController();
  String _selectedVehicleType = 'bike';

  File? _profileImage;
  File? _vehicleFrontImage;
  File? _vehicleBackImage;
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
            case 'Profile':
              _profileImage = File(pickedFile.path);
              break;
            case 'VehicleFront':
              _vehicleFrontImage = File(pickedFile.path);
              break;
            case 'VehicleBack':
              _vehicleBackImage = File(pickedFile.path);
              break;
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
      request.fields['folder'] = 'driver_documents';
      var response = await request.send();

      if (response.statusCode == 200) {
        var responseData = await http.Response.fromStream(response);
        var jsonResponse = jsonDecode(responseData.body);
        return jsonResponse['secure_url'];
      } else {
        return null;
      }
    } catch (e) {
      return null;
    }
  }

  Future<void> _submitData() async {
    if (!_formKey.currentState!.validate()) return;

    bool requiresLicense = _selectedVehicleType != 'cycle';

    if (_profileImage == null) {
      _showErrorSnackbar("Profile Photo is required.");
      return;
    }
    if (_vehicleFrontImage == null || _vehicleBackImage == null) {
      _showErrorSnackbar("Vehicle Front and Back photos are required.");
      return;
    }
    if (_aadhaarImage == null || _panImage == null) {
      _showErrorSnackbar("Aadhaar and PAN are required.");
      return;
    }
    if (requiresLicense && (_dlImage == null || _rcImage == null)) {
      _showErrorSnackbar("Driving License and RC are required.");
      return;
    }

    setState(() => _isLoading = true);

    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception("User not logged in");

      String? profileUrl = await _uploadToCloudinary(_profileImage);
      String? vehicleFrontUrl = await _uploadToCloudinary(_vehicleFrontImage);
      String? vehicleBackUrl = await _uploadToCloudinary(_vehicleBackImage);
      String? dlUrl = await _uploadToCloudinary(_dlImage);
      String? aadhaarUrl = await _uploadToCloudinary(_aadhaarImage);
      String? rcUrl = await _uploadToCloudinary(_rcImage);
      String? panUrl = await _uploadToCloudinary(_panImage);

      if (profileUrl == null ||
          vehicleFrontUrl == null ||
          vehicleBackUrl == null) {
        throw Exception("Failed to upload required images");
      }

      String userId = user.uid;

      Map<String, dynamic> driverData = {
        'id': userId,
        'driverName': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'gender': _selectedGender,
        'avatar': profileUrl,
        'createdAt': FieldValue.serverTimestamp(),
        'status': 'approved',
        'verified': 'approved',
        'walletBalance': 0,
        'totalRides': 0,
        'rating': 5.0,
        'location': {'lat': 0.0, 'lng': 0.0, 'heading': 0.0},
        'vehicle': {
          'vehicle_type': _selectedVehicleType,
          'make': _makeController.text.trim(),
          'model': _modelController.text.trim(),
          'vehicleManufactureYear': _yearController.text.trim(), // NEW FIELD
          'color': _colorController.text.trim(),
          'vehicleRegistrationNumber': _plateController.text
              .trim()
              .toUpperCase(),
          'vehiclePhotoFront': vehicleFrontUrl,
          'vehiclePhotoBack': vehicleBackUrl,
        },
        'documents': {
          'dl_url': dlUrl,
          'aadhaar_url': aadhaarUrl,
          'rc_url': rcUrl,
          'pan_url': panUrl,
          'is_verified': true,
        },
        'registeredOn': DateTime.now().toIso8601String(),
        'isRegistered': true,
        'working': 'unassigned',
        'phone': FirebaseAuth.instance.currentUser?.phoneNumber ?? '',
      };

      await FirebaseFirestore.instance
          .collection('drivers')
          .doc(userId)
          .set(driverData, SetOptions(merge: true));
      await addDriverDataToSecondaryApp(driverData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Success! Welcome aboard."),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => DriverDashboardApp()),
        );
      }
    } catch (e) {
      _showErrorSnackbar("Error: ${e.toString()}");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.redAccent),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text(
          "Complete Profile",
          style: TextStyle(fontWeight: FontWeight.w700, color: Colors.black87),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text(
                    "Uploading documents...",
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.only(bottom: 40),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    _buildHeaderSection(),

                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        children: [
                          _buildPersonalDetailsCard(),
                          const SizedBox(height: 16),
                          _buildVehicleDetailsCard(),
                          const SizedBox(height: 16),
                          _buildDocumentsCard(),
                          const SizedBox(height: 24),
                          _buildSubmitButton(),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildHeaderSection() {
    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: const EdgeInsets.only(bottom: 24, top: 10),
      margin: const EdgeInsets.only(bottom: 20),
      child: Column(
        children: [
          GestureDetector(
            onTap: () => _pickImage('Profile'),
            child: Stack(
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.blueAccent.withOpacity(0.3),
                      width: 2,
                    ),
                  ),
                  child: CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.grey[100],
                    backgroundImage: _profileImage != null
                        ? FileImage(_profileImage!)
                        : null,
                    child: _profileImage == null
                        ? Icon(Icons.person, size: 50, color: Colors.grey[300])
                        : null,
                  ),
                ),
                Positioned(
                  bottom: 4,
                  right: 4,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: Colors.blueAccent,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.camera_alt,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            "Upload Profile Photo",
            style: TextStyle(
              color: Colors.grey,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard({
    required String title,
    required List<Widget> children,
    required IconData icon,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: Colors.blueAccent, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const Divider(height: 24, color: Color(0xFFEEEEEE)),
          ...children,
        ],
      ),
    );
  }

  Widget _buildPersonalDetailsCard() {
    return _buildCard(
      title: "Personal Details",
      icon: Icons.person_outline,
      children: [
        _buildTextField(
          controller: _nameController,
          label: "Full Name",
          icon: Icons.badge_outlined,
          validator: (v) => v!.isEmpty ? "Required" : null,
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: _emailController,
          label: "Email (Optional)",
          icon: Icons.email_outlined,
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 16),
        _buildDropdownField(
          label: "Gender",
          value: _selectedGender,
          items: ['Male', 'Female', 'Other'],
          icon: Icons.wc,
          onChanged: (val) => setState(() => _selectedGender = val!),
        ),
      ],
    );
  }

  Widget _buildVehicleDetailsCard() {
    return _buildCard(
      title: "Vehicle Information",
      icon: Icons.directions_car_filled_outlined,
      children: [
        _buildDropdownField(
          label: "Vehicle Type",
          value: _selectedVehicleType,
          items: ['bike', 'car', 'van', 'cycle', 'scooter'],
          icon: Icons.commute,
          onChanged: (val) => setState(() => _selectedVehicleType = val!),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildTextField(
                controller: _makeController,
                label: "Make",
                hint: "Honda",
                validator: (v) => v!.isEmpty ? "Required" : null,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildTextField(
                controller: _modelController,
                label: "Model",
                hint: "Civic",
                validator: (v) => v!.isEmpty ? "Required" : null,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        // --- NEW ROW WITH YEAR ---
        Row(
          children: [
            Expanded(
              flex: 1,
              child: _buildTextField(
                controller: _yearController,
                label: "Year",
                hint: "2022",
                keyboardType: TextInputType.number,
                validator: (v) => v!.isEmpty ? "Req" : null,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: _buildTextField(
                controller: _colorController,
                label: "Color",
                hint: "Black",
                validator: (v) => v!.isEmpty ? "Required" : null,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: _plateController,
          label: "Plate Number",
          hint: "KA01AB1234",
          validator: (v) => v!.isEmpty ? "Required" : null,
        ),
      ],
    );
  }

  Widget _buildDocumentsCard() {
    return _buildCard(
      title: "Documents & Photos",
      icon: Icons.folder_shared_outlined,
      children: [
        const Text(
          "Ensure all photos are clear and text is readable.",
          style: TextStyle(color: Colors.grey, fontSize: 13),
        ),
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, constraints) {
            return GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.1,
              children: [
                _buildDocUploadBox(
                  "Vehicle Front",
                  _vehicleFrontImage,
                  "VehicleFront",
                ),
                _buildDocUploadBox(
                  "Vehicle Back",
                  _vehicleBackImage,
                  "VehicleBack",
                ),
                _buildDocUploadBox("Aadhaar Card", _aadhaarImage, "Aadhaar"),
                _buildDocUploadBox("PAN Card", _panImage, "PAN"),
                if (_selectedVehicleType != 'cycle') ...[
                  _buildDocUploadBox("Driving License", _dlImage, "DL"),
                  _buildDocUploadBox("Vehicle RC", _rcImage, "RC"),
                ],
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? hint,
    IconData? icon,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      style: const TextStyle(fontWeight: FontWeight.w500),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        filled: true,
        fillColor: Colors.grey[50],
        prefixIcon: icon != null
            ? Icon(icon, color: Colors.grey[500], size: 22)
            : null,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.blueAccent, width: 1.5),
        ),
        floatingLabelBehavior: FloatingLabelBehavior.auto,
      ),
    );
  }

  Widget _buildDropdownField({
    required String label,
    required String value,
    required List<String> items,
    required Function(String?) onChanged,
    IconData? icon,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      items: items.map((type) {
        return DropdownMenuItem(
          value: type,
          child: Text(
            type[0].toUpperCase() + type.substring(1),
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
        );
      }).toList(),
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: Colors.grey[50],
        prefixIcon: icon != null
            ? Icon(icon, color: Colors.grey[500], size: 22)
            : null,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
      ),
    );
  }

  Widget _buildDocUploadBox(String title, File? imageFile, String docType) {
    bool isSelected = imageFile != null;
    return GestureDetector(
      onTap: () => _pickImage(docType),
      child: Container(
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue[50] : Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: isSelected
              ? Border.all(color: Colors.blueAccent, width: 1.5)
              : Border.all(color: Colors.grey.shade300),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isSelected)
              Expanded(
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(10),
                  ),
                  child: Image.file(
                    imageFile,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
              )
            else
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.cloud_upload_outlined,
                      color: Colors.blueAccent.withOpacity(0.8),
                      size: 28,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Tap to Upload",
                      style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
              decoration: BoxDecoration(
                color: isSelected ? Colors.blueAccent : Colors.transparent,
                borderRadius: isSelected
                    ? const BorderRadius.vertical(bottom: Radius.circular(10))
                    : const BorderRadius.vertical(bottom: Radius.circular(12)),
              ),
              child: Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 11,
                  color: isSelected ? Colors.white : Colors.black87,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _submitData,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blueAccent,
          elevation: 5,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          shadowColor: Colors.blueAccent.withOpacity(0.4),
        ),
        child: const Text(
          "Submit Application",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }
}
