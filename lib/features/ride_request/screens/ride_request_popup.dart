import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Uber-style bottom sheet for ride requests
/// Slides up from bottom with timer and auto-dismisses on timeout
class RideRequestPopup extends StatefulWidget {
  final String rideId;
  final Map<String, dynamic> rideData;
  final VoidCallback onAccept;
  final VoidCallback onDecline;
  final int timeoutSeconds;

  const RideRequestPopup({
    super.key,
    required this.rideId,
    required this.rideData,
    required this.onAccept,
    required this.onDecline,
    this.timeoutSeconds = 30,
  });

  @override
  State<RideRequestPopup> createState() => _RideRequestPopupState();
}

class _RideRequestPopupState extends State<RideRequestPopup>
    with TickerProviderStateMixin {
  late Timer _timer;
  late int _remainingSeconds;
  late AnimationController _pulseController;
  late AnimationController _slideController;
  late Animation<double> _slideAnimation;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _remainingSeconds = widget.timeoutSeconds;

    // Setup pulse animation for timer
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);

    // Setup slide-up animation (Uber-style)
    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _slideAnimation = CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    );

    // Start animations
    _slideController.forward();

    // Start countdown timer
    _startTimer();

    // Haptic feedback
    _playAlertSound();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        setState(() {
          _remainingSeconds--;
        });
      } else {
        _handleTimeout();
      }
    });
  }

  Future<void> _playAlertSound() async {
    try {
      HapticFeedback.heavyImpact();
      await Future.delayed(const Duration(milliseconds: 100));
      HapticFeedback.heavyImpact();
      await Future.delayed(const Duration(milliseconds: 100));
      HapticFeedback.heavyImpact();
    } catch (e) {
      debugPrint("Error playing alert: $e");
    }
  }

  void _handleTimeout() {
    _timer.cancel();
    widget.onDecline();
    _slideController.reverse().then((_) => Navigator.of(context).pop());
  }

  void _handleAccept() async {
    if (_isProcessing) return;

    setState(() {
      _isProcessing = true;
    });

    _timer.cancel();
    widget.onAccept();
    _slideController.reverse().then((_) => Navigator.of(context).pop());
  }

  void _handleDecline() {
    if (_isProcessing) return;

    _timer.cancel();
    widget.onDecline();
    _slideController.reverse().then((_) => Navigator.of(context).pop());
  }

  String _formatTime(int seconds) {
    return seconds.toString().padLeft(2, '0');
  }

  Color _getTimerColor() {
    if (_remainingSeconds > 20) return const Color(0xFF00C853);
    if (_remainingSeconds > 10) return Colors.orange;
    return Colors.red;
  }

  @override
  void dispose() {
    _timer.cancel();
    _pulseController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final route = widget.rideData['route'] as Map<String, dynamic>? ?? {};
    final pickupAddress = route['pickup_address'] ?? 'Unknown Location';
    final dropoffAddress = route['dropoff_address'] ?? 'Unknown Destination';
    final distance = route['distance'] ?? '0 km';
    final estimatedTime = route['estimated_time'] ?? '0 min';
    final fare = widget.rideData['price'] ?? 0.0;
    final vehicleType = widget.rideData['vehicle_type'] ?? 'Standard';
    final customerName = widget.rideData['customer_name'] ?? 'Customer';

    return WillPopScope(
      onWillPop: () async => false,
      child: Material(
        color: Colors.transparent,
        child: AnimatedBuilder(
          animation: _slideAnimation,
          builder: (context, child) {
            return Stack(
              children: [
                // Semi-transparent overlay
                Positioned.fill(
                  child: GestureDetector(
                    onTap: () {}, // Prevent dismissal
                    child: Container(
                      color: Colors.black.withOpacity(
                        0.5 * _slideAnimation.value,
                      ),
                    ),
                  ),
                ),
                // Bottom sheet sliding up from bottom
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Transform.translate(
                    offset: Offset(
                      0,
                      MediaQuery.of(context).size.height *
                          (1 - _slideAnimation.value),
                    ),
                    child: _buildBottomSheetContent(
                      context,
                      pickupAddress,
                      dropoffAddress,
                      distance,
                      estimatedTime,
                      fare,
                      vehicleType,
                      customerName,
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildBottomSheetContent(
    BuildContext context,
    String pickupAddress,
    String dropoffAddress,
    String distance,
    String estimatedTime,
    dynamic fare,
    String vehicleType,
    String customerName,
  ) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 20,
            spreadRadius: 5,
            offset: Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),

            // Timer and New Request Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'NEW RIDE REQUEST',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                      color: Colors.grey,
                    ),
                  ),
                  // Circular Timer
                  AnimatedBuilder(
                    animation: _pulseController,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: 1.0 + (_pulseController.value * 0.1),
                        child: Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: _getTimerColor(),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: _getTimerColor().withOpacity(0.4),
                                blurRadius: 10,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              _formatTime(_remainingSeconds),
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Main Content
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Customer Info & Fare
                  Row(
                    children: [
                      // Customer Avatar
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.person,
                          color: Colors.grey,
                          size: 32,
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Customer Name & Vehicle Type
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              customerName,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF2D3436),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              vehicleType,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Fare Badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF00C853),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            Text(
                              '₹${fare.toStringAsFixed(0)}',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Trip Stats
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatItem(Icons.route, distance, 'Distance'),
                      Container(width: 1, height: 40, color: Colors.grey[300]),
                      _buildStatItem(Icons.access_time, estimatedTime, 'Time'),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Pickup Location
                  _buildLocationRow(
                    icon: Icons.circle,
                    iconColor: const Color(0xFF00C853),
                    label: 'PICKUP',
                    address: pickupAddress,
                  ),

                  const SizedBox(height: 16),

                  // Dropoff Location
                  _buildLocationRow(
                    icon: Icons.location_on,
                    iconColor: Colors.red,
                    label: 'DROP-OFF',
                    address: dropoffAddress,
                  ),

                  const SizedBox(height: 32),

                  // Action Buttons (Uber-style)
                  Row(
                    children: [
                      // Decline Button
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _isProcessing ? null : _handleDecline,
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            side: BorderSide(
                              color: Colors.grey[400]!,
                              width: 2,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            'DECLINE',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[700],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Accept Button (2x larger)
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          onPressed: _isProcessing ? null : _handleAccept,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            backgroundColor: const Color(0xFF000000),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          child: _isProcessing
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text(
                                  'ACCEPT',
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

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, color: Colors.grey[700], size: 28),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2D3436),
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 13, color: Colors.grey[600])),
      ],
    );
  }

  Widget _buildLocationRow({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String address,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: iconColor, size: 18),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[600],
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                address,
                style: const TextStyle(
                  fontSize: 15,
                  color: Color(0xFF2D3436),
                  height: 1.4,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
