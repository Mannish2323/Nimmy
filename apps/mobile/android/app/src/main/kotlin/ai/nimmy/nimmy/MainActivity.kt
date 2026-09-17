package ai.nimmy.nimmy

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

/**
 * 🟣 NIMMY — Flutter Android Main Activity (Kotlin)
 * ==================================================
 * Registers the native Nimmy platform bridge channel on startup.
 */
class MainActivity : FlutterActivity() {

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // Register Nimmy native bridge channel
        NimmyBridgeChannel.register(
            flutterEngine.dartExecutor.binaryMessenger,
            applicationContext
        )
    }
}
