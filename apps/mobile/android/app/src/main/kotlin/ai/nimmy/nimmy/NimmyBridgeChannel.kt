package ai.nimmy.nimmy

import android.Manifest
import android.app.AlarmManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.os.BatteryManager
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.speech.tts.TextToSpeech
import android.speech.tts.UtteranceProgressListener
import androidx.core.content.ContextCompat
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.util.Locale
import java.util.UUID

/**
 * Allow-listed Flutter-to-Android bridge. Wake detection can control only its
 * microphone foreground service and emit events; it receives no database,
 * network, repository, or tool-execution authority.
 */
class NimmyBridgeChannel(private val context: Context) :
    MethodChannel.MethodCallHandler,
    EventChannel.StreamHandler {

    private val mainHandler = Handler(Looper.getMainLooper())
    private var eventSink: EventChannel.EventSink? = null
    private var textToSpeech: TextToSpeech? = null
    private var pendingSpeechResult: MethodChannel.Result? = null
    private var pendingSpeechId: String? = null
    private val wakeEventListener: (Map<String, Any?>) -> Unit = { event ->
        mainHandler.post { eventSink?.success(event) }
    }

    companion object {
        const val CHANNEL_NAME = "ai.nimmy.nimmy/bridge"
        const val EVENT_CHANNEL_NAME = "ai.nimmy.nimmy/wake_events"

        fun register(messenger: BinaryMessenger, context: Context) {
            val handler = NimmyBridgeChannel(context.applicationContext)
            MethodChannel(messenger, CHANNEL_NAME).setMethodCallHandler(handler)
            EventChannel(messenger, EVENT_CHANNEL_NAME).setStreamHandler(handler)
        }
    }

    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        eventSink = events
        WakeWordRuntime.subscribe(wakeEventListener)
    }

    override fun onCancel(arguments: Any?) {
        WakeWordRuntime.unsubscribe(wakeEventListener)
        eventSink = null
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
            "getWakeWordCapabilities", "getWakeWordStatus" ->
                result.success(wakeWordCapabilities())
            "startWakeWordDetection" -> startWakeWordDetection(call, result)
            "stopWakeWordDetection" -> stopWakeWordDetection(result)
            "pauseWakeWordDetection" -> pauseWakeWordDetection(call, result)
            "resumeWakeWordDetection" -> resumeWakeWordDetection(result)
            "isServiceRunning" -> result.success(WakeWordRuntime.serviceRunning)
            "startBackgroundService",
            "stopBackgroundService",
            "startVoiceRecording",
            "stopVoiceRecording" -> result.error(
                "NOT_AVAILABLE_IN_MVP",
                "Background recording is not available. Wake detection uses a separate visible service.",
                null
            )
            else -> result.notImplemented()
        }
    }

    private fun wakeWordCapabilities(): Map<String, Any?> {
        val missingAssets = WakeWordAssets.missing(context)
        return mapOf(
            "supported" to true,
            "local" to true,
            "serviceRunning" to WakeWordRuntime.serviceRunning,
            "status" to WakeWordRuntime.status,
            "microphonePermission" to hasPermission(Manifest.permission.RECORD_AUDIO),
            "notificationPermission" to hasNotificationPermission(),
            "modelInstalled" to !missingAssets.contains(WakeWordAssets.NIMMY_MODEL),
            "featureModelsInstalled" to
                !missingAssets.contains(WakeWordAssets.MEL_MODEL) &&
                !missingAssets.contains(WakeWordAssets.EMBEDDING_MODEL),
            "missingAssets" to missingAssets,
            "phrases" to listOf("Hey Nimmy", "Nimmy"),
            "requiresVisibleNotification" to true,
            "canAutoStartAfterBoot" to false,
            "minimumAndroidSdk" to 23
        )
    }

    private fun startWakeWordDetection(call: MethodCall, result: MethodChannel.Result) {
        val capabilities = wakeWordCapabilities()
        val missing = capabilities["missingAssets"] as List<*>
        if (missing.isNotEmpty()) {
            result.success(
                operationFailure(
                    "WAKE_ENGINE_UNAVAILABLE",
                    "The trained Nimmy wake-word model is not installed.",
                    "Install wakeword/nimmy.onnx and retry.",
                    extras = mapOf("missingAssets" to missing)
                )
            )
            return
        }
        if (!hasPermission(Manifest.permission.RECORD_AUDIO)) {
            result.success(
                operationFailure(
                    "MIC_PERMISSION_DENIED",
                    "Microphone permission is required for wake detection.",
                    "Enable microphone access in Nimmy permissions."
                )
            )
            return
        }
        if (!hasNotificationPermission()) {
            result.success(
                operationFailure(
                    "NOTIFICATION_PERMISSION_DENIED",
                    "A visible notification is required while the microphone is active.",
                    "Enable Nimmy notifications and retry."
                )
            )
            return
        }

        val threshold = (call.argument<Number>("threshold")?.toFloat() ?: 0.50f)
            .coerceIn(0.05f, 0.95f)
        val serviceIntent = Intent(context, NimmyForegroundService::class.java).apply {
            action = NimmyForegroundService.ACTION_START
            putExtra(NimmyForegroundService.EXTRA_THRESHOLD, threshold)
        }
        try {
            ContextCompat.startForegroundService(context, serviceIntent)
            result.success(
                mapOf(
                    "success" to true,
                    "status" to WakeWordRuntime.STATUS_STARTING,
                    "local" to true
                )
            )
        } catch (error: Throwable) {
            WakeWordRuntime.publishError(
                "BACKGROUND_RESTRICTION",
                "Android prevented the microphone service from starting.",
                "Open Nimmy and enable wake detection while the app is visible."
            )
            result.success(
                operationFailure(
                    "BACKGROUND_RESTRICTION",
                    "Android prevented the microphone service from starting.",
                    "Open Nimmy and retry while the app is visible."
                )
            )
        }
    }

    private fun stopWakeWordDetection(result: MethodChannel.Result) {
        val stopped = context.stopService(Intent(context, NimmyForegroundService::class.java))
        WakeWordRuntime.updateStatus(
            WakeWordRuntime.STATUS_STOPPED,
            running = false,
            reason = "user_stopped"
        )
        result.success(mapOf("success" to true, "wasRunning" to stopped, "status" to "stopped"))
    }

    private fun pauseWakeWordDetection(call: MethodCall, result: MethodChannel.Result) {
        if (!WakeWordRuntime.serviceRunning) {
            result.success(operationFailure("SERVICE_NOT_RUNNING", "Wake detection is not active.", "Enable wake detection first."))
            return
        }
        val intent = Intent(context, NimmyForegroundService::class.java).apply {
            action = NimmyForegroundService.ACTION_PAUSE
            putExtra(
                NimmyForegroundService.EXTRA_REASON,
                call.argument<String>("reason") ?: "voice_pipeline"
            )
        }
        context.startService(intent)
        result.success(mapOf("success" to true, "status" to "pausing"))
    }

    private fun resumeWakeWordDetection(result: MethodChannel.Result) {
        if (!WakeWordRuntime.serviceRunning) {
            result.success(operationFailure("SERVICE_NOT_RUNNING", "Wake detection is not active.", "Enable wake detection first."))
            return
        }
        val intent = Intent(context, NimmyForegroundService::class.java).apply {
            action = NimmyForegroundService.ACTION_RESUME
        }
        context.startService(intent)
        result.success(mapOf("success" to true, "status" to "resuming"))
    }

    private fun operationFailure(
        code: String,
        message: String,
        recovery: String,
        extras: Map<String, Any?> = emptyMap()
    ): Map<String, Any?> = mapOf(
        "success" to false,
        "errorCode" to code,
        "message" to message,
        "recovery" to recovery
    ) + extras

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

    private fun speakWith(engine: TextToSpeech, text: String, result: MethodChannel.Result) {
        finishPendingSpeech(success = false)
        engine.stop()
        val languageStatus = engine.setLanguage(Locale("en", "IN"))
        if (languageStatus == TextToSpeech.LANG_MISSING_DATA ||
            languageStatus == TextToSpeech.LANG_NOT_SUPPORTED
        ) {
            result.error("TTS_LANGUAGE_UNAVAILABLE", "The configured speech language is unavailable.", null)
            return
        }

        val utteranceId = "nimmy-${UUID.randomUUID()}"
        pendingSpeechResult = result
        pendingSpeechId = utteranceId
        engine.setSpeechRate(0.92f)
        engine.setOnUtteranceProgressListener(object : UtteranceProgressListener() {
            override fun onStart(id: String?) = Unit

            override fun onDone(id: String?) {
                if (id == utteranceId) finishPendingSpeech(success = true)
            }

            @Deprecated("Deprecated in Java")
            override fun onError(id: String?) {
                if (id == utteranceId) finishPendingSpeech(success = false, errorCode = "TTS_FAILED")
            }

            override fun onError(id: String?, errorCode: Int) {
                if (id == utteranceId) finishPendingSpeech(success = false, errorCode = "TTS_FAILED")
            }
        })
        val speakStatus = engine.speak(text, TextToSpeech.QUEUE_FLUSH, null, utteranceId)
        if (speakStatus == TextToSpeech.ERROR) {
            finishPendingSpeech(success = false, errorCode = "TTS_FAILED")
        }
    }

    private fun finishPendingSpeech(success: Boolean, errorCode: String? = null) {
        val pending = pendingSpeechResult ?: return
        pendingSpeechResult = null
        pendingSpeechId = null
        mainHandler.post {
            if (errorCode == null) {
                pending.success(success)
            } else {
                pending.error(errorCode, "Text-to-speech did not complete.", null)
            }
        }
    }

    private fun stopSpeaking(result: MethodChannel.Result) {
        textToSpeech?.stop()
        finishPendingSpeech(success = false)
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
                "batteryLevel" to (battery?.getIntProperty(BatteryManager.BATTERY_PROPERTY_CAPACITY) ?: -1),
                "backgroundServiceAvailable" to false,
                "wakeWordForegroundServiceSupported" to (Build.VERSION.SDK_INT >= 23)
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
        launchIntent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        context.startActivity(launchIntent)
        result.success(true)
    }

    private fun checkPermissions(result: MethodChannel.Result) {
        result.success(
            mapOf(
                "recordAudio" to hasPermission(Manifest.permission.RECORD_AUDIO),
                "notifications" to hasNotificationPermission()
            )
        )
    }

    private fun hasPermission(permission: String): Boolean =
        ContextCompat.checkSelfPermission(context, permission) == PackageManager.PERMISSION_GRANTED

    private fun hasNotificationPermission(): Boolean =
        Build.VERSION.SDK_INT < Build.VERSION_CODES.TIRAMISU ||
            hasPermission(Manifest.permission.POST_NOTIFICATIONS)
}
