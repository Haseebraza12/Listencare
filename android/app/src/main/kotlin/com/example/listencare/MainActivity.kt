package com.example.listencare

import io.flutter.embedding.android.FlutterActivity
import android.os.Build
import android.speech.SpeechRecognizer
import android.content.Intent
import android.provider.Settings
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger,
            "listencare/speech_capabilities").setMethodCallHandler { call, result ->
            if (call.method == "isRecognitionAvailable") {
                result.success(SpeechRecognizer.isRecognitionAvailable(this) ||
                    (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S &&
                    SpeechRecognizer.isOnDeviceRecognitionAvailable(this)))
            } else if (call.method == "supportsOffline") {
                result.success(Build.VERSION.SDK_INT >= Build.VERSION_CODES.S &&
                    SpeechRecognizer.isOnDeviceRecognitionAvailable(this))
            } else if (call.method == "openSpeechSettings") {
                val intent = Intent(Settings.ACTION_VOICE_INPUT_SETTINGS)
                if (intent.resolveActivity(packageManager) != null) {
                    startActivity(intent)
                } else {
                    startActivity(Intent(Settings.ACTION_SETTINGS))
                }
                result.success(null)
            } else {
                result.notImplemented()
            }
        }
    }
}
