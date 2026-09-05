package com.kovacsmaxi.clipghost

import android.content.Context
import android.media.AudioAttributes
import android.os.Build
import android.os.VibrationEffect
import android.os.Vibrator
import android.os.VibratorManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.kovacsmaxi.clipghost/vibrate"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "vibrateHardware") {
                val status = triggerDirectVibration()
                result.success(status)
            } else {
                result.notImplemented()
            }
        }
    }

    private fun triggerDirectVibration(): String {
        return try {
            val audioAttributes = AudioAttributes.Builder()
                .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                .setUsage(AudioAttributes.USAGE_ALARM)
                .build()

            val vibrator = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                val vm = getSystemService(Context.VIBRATOR_MANAGER_SERVICE) as VibratorManager
                vm.defaultVibrator
            } else {
                @Suppress("DEPRECATION")
                getSystemService(Context.VIBRATOR_SERVICE) as Vibrator
            }

            if (!vibrator.hasVibrator()) {
                return "ERR_NO_HARDWARE"
            }

            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                val effect = VibrationEffect.createOneShot(180, VibrationEffect.DEFAULT_AMPLITUDE)
                vibrator.vibrate(effect, audioAttributes)
            } else {
                @Suppress("DEPRECATION")
                vibrator.vibrate(180)
            }
            "VIBRATED_OK"
        } catch (e: Exception) {
            "ERR: ${e.message}"
        }
    }
}
