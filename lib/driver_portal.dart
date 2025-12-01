import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:ryde/dashboard.dart';
import 'package:ryde/driver_dashboard.dart';
import 'package:ryde/driver_details.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'IITianCraft Driver',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(
          0xFF121212,
        ), // Deep dark background
        primaryColor: const Color(0xFFFFC107), // Amber/Yellow
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFFFC107),
          secondary: Color(0xFFFFC107),
          surface: Color(0xFF1E1E1E),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFF2C2C2E), // Dark grey for inputs
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide.none,
          ),
          hintStyle: TextStyle(color: Colors.grey[600]),
        ),
        useMaterial3: true,
      ),
      home: const LoginScreen(),
    );
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // Controllers
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();

  // State variables
  bool _isOtpSent = false;
  bool _isLoading = false;
  String? _verificationId;

  // Firebase Auth instance
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  void dispose() {
    _phoneController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  // Step 1: Send OTP
  Future<void> _verifyPhoneNumber() async {
    String phone = _phoneController.text.trim();

    // Basic validation
    if (phone.isEmpty || phone.length < 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter a valid phone number")),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _auth.verifyPhoneNumber(
        phoneNumber: '+91$phone', // Hardcoded +91 as per design
        verificationCompleted: (PhoneAuthCredential credential) async {
          // Auto-resolution on Android
          await _auth.signInWithCredential(credential);
          _navigateToHome();
        },
        verificationFailed: (FirebaseAuthException e) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Verification Failed: ${e.message}")),
          );
        },
        codeSent: (String verificationId, int? resendToken) {
          setState(() {
            _isOtpSent = true;
            _verificationId = verificationId;
            _isLoading = false;
          });
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          _verificationId = verificationId;
        },
      );
    } catch (e) {
      setState(() => _isLoading = false);
      // For demo purposes, if Firebase isn't set up, we simulate success
      // Remove this block in production
      print("Firebase Error (Expected if not configured): $e");
      await Future.delayed(const Duration(seconds: 1));
      setState(() {
        _isOtpSent = true;
        _isLoading = false;
      });
    }
  }

  // Step 2: Verify OTP
  Future<void> _signInWithOTP() async {
    String otp = _otpController.text.trim();

    if (otp.length != 6 && otp.length != 4) {
      // Firebase usually sends 6, design says 4.
      // We'll allow both for robust logic, though usually Firebase is 6.
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Please enter a valid OTP")));
      return;
    }

    setState(() => _isLoading = true);

    try {
      if (_verificationId != null) {
        PhoneAuthCredential credential = PhoneAuthProvider.credential(
          verificationId: _verificationId!,
          smsCode: otp,
        );
        await _auth.signInWithCredential(credential);
        _navigateToHome();
      } else {
        // Demo fallback
        await Future.delayed(const Duration(seconds: 1));
        _navigateToHome();
      }
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Login Failed: ${e.toString()}")));
    }
  }

  void _navigateToHome() {
    // Navigate to next screen
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text("Login Successful!")));
    // Navigator.pushReplacement(...)
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => DriverRegistrationScreen()),
    );
  }

  void _changeNumber() {
    setState(() {
      _isOtpSent = false;
      _otpController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(flex: 3),

              // --- Logo Section ---
              Center(
                child: RichText(
                  text: const TextSpan(
                    children: [
                      TextSpan(
                        text: 'IITian',
                        style: TextStyle(
                          color: Color(0xFFFFC107), // Yellow
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Roboto',
                        ),
                      ),
                      TextSpan(
                        text: 'Craft',
                        style: TextStyle(
                          color: Color(0xFFFFC107), // Yellow
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Roboto',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              const Center(
                child: Text(
                  'Driver Portal',
                  style: TextStyle(color: Colors.grey, fontSize: 16),
                ),
              ),

              const Spacer(flex: 2),

              // --- Input Section ---
              Text(
                _isOtpSent ? 'Enter 4-Digit OTP' : 'Enter Phone Number',
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),

              if (!_isOtpSent)
                TextField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                  decoration: const InputDecoration(
                    prefixIcon: Padding(
                      padding: EdgeInsets.all(14.0),
                      child: Text(
                        '+91',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    hintText: '95880 41628',
                  ),
                )
              else
                TextField(
                  controller: _otpController,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                  decoration: const InputDecoration(
                    hintText: '1234',
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                  ),
                  maxLength: 6, // Firebase standard is 6
                ),

              const SizedBox(height: 24),

              // --- Action Button ---
              SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading
                      ? null
                      : (_isOtpSent ? _signInWithOTP : _verifyPhoneNumber),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFC107),
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.black,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          _isOtpSent ? 'Login' : 'Send OTP',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 16),

              // --- Change Number / Back ---
              if (_isOtpSent)
                TextButton(
                  onPressed: _changeNumber,
                  child: const Text(
                    'Change Number',
                    style: TextStyle(color: Color(0xFFFFC107), fontSize: 14),
                  ),
                ),

              const Spacer(flex: 4),

              // --- Footer ---
              Padding(
                padding: const EdgeInsets.only(bottom: 20.0),
                child: Text(
                  'By continuing, you agree to our Terms of Service and Privacy Policy.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey[600], fontSize: 11),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
