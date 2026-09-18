package ai.nimmy.nimmy

import android.content.Context
import android.content.pm.PackageManager
import android.os.BatteryManager
import android.os.Build
import android.app.AlarmManager
import android.app.PendingIntent
import android.content.Intent
import android.speech.tts.TextToSpeech
import java.util.Locale
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

    private var textToSpeech: TextToSpeech? = null

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
            "speak" -> speak(call, result)
            "stopSpeaking" -> stopSpeaking(result)
            "scheduleAlarm" -> scheduleAlarm(call, result)
            "cancelAlarm" -> cancelAlarm(call, result)
            "startBackgroundService",
            "stopBackgroundService",
            "isServiceRunning",
            "startVoiceRecording",
            "stopVoiceRecording" -> result.error(
                "NOT_AVAILABLE_IN_MVP",
                "This Android capability is not available in the current Nimmy build.",
                null
            )
            else -> result.notImplemented()
        }
    }

    private fun speak(call: MethodCall, result: MethodChannel.Result) {
        val text = call.argument<String>("text")?.trim()
        if (text.isNullOrEmpty()) {
            result.error("INVALID_ARGUMENT", "text is required", null)
            return
        }

        val existing = textToSpeech
        if (existing != null) {
            speakWith(existing, text, result)
            return
        }

        textToSpeech = TextToSpeech(context) { status ->
            if (status == TextToSpeech.SUCCESS) {
                val ready = textToSpeech
                if (ready == null) {
                    result.error("TTS_UNAVAILABLE", "Text-to-speech engine is unavailable.", null)
                } else {
                    speakWith(ready, text, result)
                }
            } else {
                textToSpeech = null
                result.error("TTS_UNAVAILABLE", "Text-to-speech engine failed to initialize.", null)
            }
        }
    }

    private fun speakWith(
        engine: TextToSpeech,
        text: String,
        result: MethodChannel.Result
    ) {
        engine.stop()
        val languageStatus = engine.setLanguage(Locale("en", "IN"))
        if (languageStatus == TextToSpeech.LANG_MISSING_DATA ||
            languageStatus == TextToSpeech.LANG_NOT_SUPPORTED
        ) {
            result.error("TTS_LANGUAGE_UNAVAILABLE", "The configured speech language is unavailable.", null)
            return
        }
        engine.setSpeechRate(0.48f)
        val speakStatus = engine.speak(text, TextToSpeech.QUEUE_FLUSH, null, "nimmy-response")
        if (speakStatus == TextToSpeech.ERROR) {
            result.error("TTS_FAILED", "Text-to-speech could not start.", null)
        } else {
            result.success(true)
        }
    }

    private fun stopSpeaking(result: MethodChannel.Result) {
        textToSpeech?.stop()
        result.success(true)
    }

    private fun scheduleAlarm(call: MethodCall, result: MethodChannel.Result) {
        val title = call.argument<String>("title")?.trim()
        val body = call.argument<String>("body")?.trim()
        val triggerAtMillis = call.argument<Number>("triggerAtMillis")?.toLong()
        val id = call.argument<Number>("id")?.toInt()
        if (title.isNullOrEmpty() || body.isNullOrEmpty() || triggerAtMillis == null || id == null) {
            result.error("INVALID_ARGUMENT", "title, body, triggerAtMillis and id are required", null)
            return
        }
        if (triggerAtMillis <= System.currentTimeMillis()) {
            result.success(mapOf("scheduled" to false, "reason" to "past"))
            return
        }

        val intent = Intent(context, NimmyAlarmReceiver::class.java).apply {
            putExtra(NimmyAlarmReceiver.EXTRA_TITLE, title)
            putExtra(NimmyAlarmReceiver.EXTRA_BODY, body)
            putExtra(NimmyAlarmReceiver.EXTRA_ID, id)
        }
        val pendingIntent = PendingIntent.getBroadcast(
            context,
            id,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        alarmManager.setAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, triggerAtMillis, pendingIntent)
        result.success(mapOf("scheduled" to true))
    }

    private fun cancelAlarm(call: MethodCall, result: MethodChannel.Result) {
        val id = call.argument<Number>("id")?.toInt()
        if (id == null) {
            result.error("INVALID_ARGUMENT", "id is required", null)
            return
        }
        val intent = Intent(context, NimmyAlarmReceiver::class.java)
        val pendingIntent = PendingIntent.getBroadcast(
            context,
            id,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        alarmManager.cancel(pendingIntent)
        pendingIntent.cancel()
        result.success(true)
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
