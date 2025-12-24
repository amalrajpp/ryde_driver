import 'package:flutter/services.dart';
import 'package:flutter/material.dart';

class AppLauncherService {
  static const platform = MethodChannel('com.example.rydeagent/app_launcher');

  /// Bring the app to foreground
  static Future<bool> bringToForeground() async {
    try {
      debugPrint('🚀 Attempting to bring app to foreground...');
      final result = await platform.invokeMethod('bringToForeground');
      debugPrint('✅ App brought to foreground: $result');
      return result == true;
    } on PlatformException catch (e) {
      debugPrint('❌ Failed to bring app to foreground: ${e.message}');
      return false;
    } catch (e) {
      debugPrint('❌ Error bringing app to foreground: $e');
      return false;
    }
  }
}
