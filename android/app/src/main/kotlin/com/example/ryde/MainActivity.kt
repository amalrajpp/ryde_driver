package com.example.rydeagent

import android.app.Activity
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.PowerManager
import android.view.WindowManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.example.rydeagent/app_launcher"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "bringToForeground" -> {
                    try {
                        // Wake up the screen if it's off
                        val powerManager = getSystemService(Context.POWER_SERVICE) as PowerManager
                        val wakeLock = powerManager.newWakeLock(
                            PowerManager.SCREEN_BRIGHT_WAKE_LOCK or 
                            PowerManager.ACQUIRE_CAUSES_WAKEUP or 
                            PowerManager.ON_AFTER_RELEASE,
                            "RydeAgent::WakeLock"
                        )
                        wakeLock.acquire(5000) // 5 seconds

                        // Show the activity even if screen is locked
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O_MR1) {
                            setShowWhenLocked(true)
                            setTurnScreenOn(true)
                        } else {
                            window.addFlags(
                                WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED or
                                WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON
                            )
                        }

                        // Bring app to foreground
                        val intent = Intent(this, MainActivity::class.java)
                        intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                        intent.addFlags(Intent.FLAG_ACTIVITY_SINGLE_TOP)
                        intent.addFlags(Intent.FLAG_ACTIVITY_REORDER_TO_FRONT)
                        intent.addFlags(Intent.FLAG_ACTIVITY_CLEAR_TOP)
                        startActivity(intent)
                        
                        // Release the wake lock after a delay
                        android.os.Handler().postDelayed({
                            if (wakeLock.isHeld) {
                                wakeLock.release()
                            }
                        }, 5000)
                        
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("ERROR", "Failed to bring app to foreground: ${e.message}", null)
                    }
                }
                else -> result.notImplemented()
            }
        }
    }
}
