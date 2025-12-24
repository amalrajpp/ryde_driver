import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'package:permission_handler/permission_handler.dart';

class OverlayService {
  static final OverlayService _instance = OverlayService._internal();
  factory OverlayService() => _instance;
  OverlayService._internal();

  bool _isOverlayActive = false;

  /// Request overlay permission (Display over other apps)
  Future<bool> requestOverlayPermission() async {
    if (!await Permission.systemAlertWindow.isGranted) {
      final status = await Permission.systemAlertWindow.request();
      return status.isGranted;
    }
    return true;
  }

  /// Check if overlay permission is granted
  Future<bool> hasOverlayPermission() async {
    return await Permission.systemAlertWindow.isGranted;
  }

  /// Show floating overlay bubble when app is in background
  Future<void> showOverlayBubble({
    required String rideId,
    required String pickupAddress,
    required String customerName,
    required double fare,
  }) async {
    try {
      debugPrint('🔍 Attempting to show overlay for ride: $rideId');

      // Force close any previous overlay regardless of flag state
      debugPrint('🔄 Forcing close of any existing overlay...');
      try {
        await FlutterOverlayWindow.closeOverlay();
        _isOverlayActive = false;
        debugPrint('✅ Previous overlay closed (if any)');
      } catch (e) {
        debugPrint('⚠️ No previous overlay to close or error: $e');
        _isOverlayActive = false; // Reset flag anyway
      }

      final hasPermission = await hasOverlayPermission();
      debugPrint('🔍 Overlay permission status: $hasPermission');

      if (!hasPermission) {
        debugPrint('❌ Overlay permission not granted');
        return;
      }

      // Show overlay with ride details
      debugPrint(
        '🔔 Showing overlay: Customer=$customerName, Pickup=$pickupAddress, Fare=₹$fare',
      );

      await FlutterOverlayWindow.showOverlay(
        enableDrag: true,
        overlayTitle: "New Ride Request",
        overlayContent: "$customerName • ₹$fare",
        flag: OverlayFlag.defaultFlag,
        visibility: NotificationVisibility.visibilityPublic,
        positionGravity: PositionGravity.auto,
        width: WindowSize.matchParent,
        height: 300,
      );

      _isOverlayActive = true;
      debugPrint('✅ Overlay shown successfully for ride: $rideId');

      // Auto-close after 30 seconds
      Timer(const Duration(seconds: 30), () {
        debugPrint('⏰ Auto-closing overlay after 30 seconds');
        closeOverlay();
      });
    } catch (e) {
      debugPrint('❌ Error showing overlay: $e');
      debugPrint('❌ Error details: ${e.toString()}');
      _isOverlayActive = false;
    }
  }

  /// Close the overlay bubble
  Future<void> closeOverlay() async {
    try {
      debugPrint('🔄 Attempting to close overlay...');
      await FlutterOverlayWindow.closeOverlay();
      _isOverlayActive = false;
      debugPrint('✅ Overlay closed successfully');
    } catch (e) {
      debugPrint('⚠️ Error closing overlay (may already be closed): $e');
      _isOverlayActive = false; // Reset flag anyway
    }
  }

  /// Check if overlay is currently active
  bool get isOverlayActive => _isOverlayActive;

  /// Update overlay content
  Future<void> updateOverlay(Map<String, dynamic> data) async {
    try {
      if (_isOverlayActive) {
        // Send data to overlay
        await FlutterOverlayWindow.shareData(data);
        debugPrint('✅ Overlay data updated');
      }
    } catch (e) {
      debugPrint('❌ Error updating overlay: $e');
    }
  }
}
