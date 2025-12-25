import 'package:flutter/services.dart';
import 'package:flutter/material.dart';

class AppLauncherService {
  static const platform = MethodChannel('com.example.rydeagent/app_launcher');

  /// Bring the app to foreground
  static Future<bool> bringToForeground() async {
    try {
      debugPrint(
        '🚀 [AppLauncher] Calling native method to bring app to foreground...',
      );
      final result = await platform.invokeMethod('bringToForeground');
      debugPrint('✅ [AppLauncher] Native call returned: $result');
      return result == true;
    } on PlatformException catch (e) {
      debugPrint('❌ [AppLauncher] PlatformException: ${e.code} - ${e.message}');
      debugPrint('❌ [AppLauncher] Details: ${e.details}');
      return false;
    } catch (e) {
      debugPrint('❌ [AppLauncher] Unexpected error: $e');
      debugPrint('❌ [AppLauncher] Error type: ${e.runtimeType}');
      return false;
    }
  }
}
