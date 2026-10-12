package com.example.listencare

import io.flutter.embedding.android.FlutterActivity
import android.os.Build
import android.speech.SpeechRecognizer
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger,
            "listencare/speech_capabilities").setMethodCallHandler { call, result ->
            if (call.method == "supportsOffline") {
                result.success(Build.VERSION.SDK_INT >= Build.VERSION_CODES.S &&
                    SpeechRecognizer.isOnDeviceRecognitionAvailable(this))
            } else {
                result.notImplemented()
            }
        }
    }
}
