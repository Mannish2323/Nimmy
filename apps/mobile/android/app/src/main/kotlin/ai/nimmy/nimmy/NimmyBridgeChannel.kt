package ai.nimmy.nimmy

import android.content.Context
import android.content.pm.PackageManager
import android.os.BatteryManager
import android.os.Build
import androidx.core.content.ContextCompat
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/**
 * Small, allow-listed Flutter-to-Android bridge.
 *
 * Recording and autonomous background-service methods deliberately return an
 * explicit unavailable error in the MVP. They must not be enabled until the
 * user-started, visible foreground-recording milestone is implemented.
 */
class NimmyBridgeChannel(private val context: Context) : MethodChannel.MethodCallHandler {

    companion object {
        const val CHANNEL_NAME = "ai.nimmy.nimmy/bridge"

        fun register(messenger: BinaryMessenger, context: Context): MethodChannel {
            return MethodChannel(messenger, CHANNEL_NAME).also {
                it.setMethodCallHandler(NimmyBridgeChannel(context))
            }
        }
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "getDeviceInfo" -> getDeviceInfo(result)
            "launchApp" -> launchApp(call, result)
            "checkPermissions" -> checkPermissions(result)
            "startBackgroundService",
            "stopBackgroundService",
            "isServiceRunning",
            "startVoiceRecording",
            "stopVoiceRecording",
            "scheduleAlarm" -> result.error(
                "NOT_AVAILABLE_IN_MVP",
                "This Android capability is not available in the current Nimmy build.",
                null
            )
            else -> result.notImplemented()
        }
    }

    private fun getDeviceInfo(result: MethodChannel.Result) {
        val battery = context.getSystemService(Context.BATTERY_SERVICE) as? BatteryManager
        result.success(
            mapOf(
                "manufacturer" to Build.MANUFACTURER,
                "model" to Build.MODEL,
                "osVersion" to Build.VERSION.RELEASE,
                "sdkInt" to Build.VERSION.SDK_INT,
                "batteryLevel" to (battery?.getIntProperty(
                    BatteryManager.BATTERY_PROPERTY_CAPACITY
                ) ?: -1),
                "backgroundServiceAvailable" to false
            )
        )
    }

    private fun launchApp(call: MethodCall, result: MethodChannel.Result) {
        val packageName = call.argument<String>("packageName")
        if (packageName.isNullOrBlank()) {
            result.error("INVALID_ARGUMENT", "packageName is required", null)
            return
        }
        val launchIntent = context.packageManager.getLaunchIntentForPackage(packageName)
        if (launchIntent == null) {
            result.error("APP_NOT_FOUND", "The requested app is not installed.", null)
            return
        }
        launchIntent.addFlags(android.content.Intent.FLAG_ACTIVITY_NEW_TASK)
        context.startActivity(launchIntent)
        result.success(true)
    }

    private fun checkPermissions(result: MethodChannel.Result) {
        val microphone = ContextCompat.checkSelfPermission(
            context,
            android.Manifest.permission.RECORD_AUDIO
        ) == PackageManager.PERMISSION_GRANTED
        val notifications = Build.VERSION.SDK_INT < Build.VERSION_CODES.TIRAMISU ||
            ContextCompat.checkSelfPermission(
                context,
                android.Manifest.permission.POST_NOTIFICATIONS
            ) == PackageManager.PERMISSION_GRANTED
        result.success(mapOf("recordAudio" to microphone, "notifications" to notifications))
    }
}
