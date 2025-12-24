import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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

    // Setup slide animation (Uber-style)
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

    // Play alert sound
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
      // Vibrate device to alert driver
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
    Navigator.of(context).pop();
  }

  void _handleAccept() async {
    if (_isProcessing) return;

    setState(() {
      _isProcessing = true;
    });

    _timer.cancel();
    widget.onAccept();
    Navigator.of(context).pop();
  }

  void _handleDecline() {
    if (_isProcessing) return;

    _timer.cancel();
    widget.onDecline();
    Navigator.of(context).pop();
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
      onWillPop: () async => false, // Prevent dismissing
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
              // Bottom sheet sliding up
              Positioned(
                left: 0,
                right: 0,
                bottom:
                    -MediaQuery.of(context).size.height *
                    (1 - _slideAnimation.value),
                child: _buildBottomSheet(
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
            ],
          );
        },
      ),
    );
  }

  Widget _buildBottomSheet(
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Timer Header with Pulse Animation
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  decoration: BoxDecoration(
                    color: _getTimerColor(),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(24),
                      topRight: Radius.circular(24),
                    ),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'NEW RIDE REQUEST',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 12),
                      AnimatedBuilder(
                        animation: _pulseController,
                        builder: (context, child) {
                          return Transform.scale(
                            scale: 1.0 + (_pulseController.value * 0.1),
                            child: Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.white.withOpacity(0.3),
                                    blurRadius: 20,
                                    spreadRadius: 5,
                                  ),
                                ],
                              ),
                              child: Center(
                                child: Text(
                                  _formatTime(_remainingSeconds),
                                  style: TextStyle(
                                    fontSize: 36,
                                    fontWeight: FontWeight.bold,
                                    color: _getTimerColor(),
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'seconds to accept',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),

                // Ride Details
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Customer Info
                      Row(
                        children: [
                          Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.person,
                              color: Colors.grey,
                              size: 28,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  customerName,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF2D3436),
                                  ),
                                ),
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
                          // Fare
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF00C853).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              children: [
                                const Text(
                                  'FARE',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Color(0xFF00C853),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  '₹${fare.toStringAsFixed(0)}',
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF00C853),
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
                          _buildStatItem(
                            Icons.straighten,
                            distance,
                            'Distance',
                          ),
                          Container(
                            width: 1,
                            height: 30,
                            color: Colors.grey[300],
                          ),
                          _buildStatItem(
                            Icons.access_time,
                            estimatedTime,
                            'Time',
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),
                      const Divider(),
                      const SizedBox(height: 16),

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

                      const SizedBox(height: 24),

                      // Action Buttons
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: _isProcessing ? null : _handleDecline,
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
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
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 2,
                            child: ElevatedButton(
                              onPressed: _isProcessing ? null : _handleAccept,
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                backgroundColor: const Color(0xFF00C853),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 4,
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
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, color: Colors.grey[600], size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2D3436),
          ),
        ),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
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
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: iconColor, size: 16),
        ),
        const SizedBox(width: 12),
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
              const SizedBox(height: 2),
              Text(
                address,
                style: const TextStyle(
                  fontSize: 14,
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
