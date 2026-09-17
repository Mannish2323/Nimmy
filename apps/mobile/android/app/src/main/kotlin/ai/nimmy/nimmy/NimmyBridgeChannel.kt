package ai.nimmy.nimmy

import android.app.AlarmManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.os.BatteryManager
import android.os.Build
import android.util.Log
import androidx.core.content.ContextCompat
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.File

/**
 * 🟣 NIMMY — Flutter-to-Kotlin Platform MethodChannel Bridge
 * ==========================================================
 * Connects Flutter Dart UI to Android system APIs, services, and hardware.
 */
class NimmyBridgeChannel(private val context: Context) : MethodChannel.MethodCallHandler {

    companion object {
        private const val TAG = "NimmyBridgeChannel"
        const val CHANNEL_NAME = "ai.nimmy.nimmy/bridge"

        fun register(messenger: BinaryMessenger, context: Context): MethodChannel {
            val channel = MethodChannel(messenger, CHANNEL_NAME)
            val handler = NimmyBridgeChannel(context)
            channel.setMethodCallHandler(handler)
            Log.i(TAG, "Nimmy platform bridge registered on channel: $CHANNEL_NAME")
            return channel
        }
    }

    private var activeRecordingDaemon: AudioRecordingDaemon? = null

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "startBackgroundService" -> handleStartBackgroundService(result)
            "stopBackgroundService" -> handleStopBackgroundService(result)
            "isServiceRunning" -> result.success(NimmyForegroundService.isRunning)

            "startVoiceRecording" -> handleStartVoiceRecording(result)
            "stopVoiceRecording" -> handleStopVoiceRecording(result)

            "scheduleAlarm" -> handleScheduleAlarm(call, result)
            "getDeviceInfo" -> handleGetDeviceInfo(result)
            "launchApp" -> handleLaunchApp(call, result)
            "checkPermissions" -> handleCheckPermissions(result)

            else -> result.notImplemented()
        }
    }

    private fun handleStartBackgroundService(result: MethodChannel.Result) {
        try {
            val intent = Intent(context, NimmyForegroundService::class.java).apply {
                action = NimmyForegroundService.ACTION_START
            }
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                context.startForegroundService(intent)
            } else {
                context.startService(intent)
            }
            result.success(true)
        } catch (e: Exception) {
            Log.e(TAG, "Error starting foreground service", e)
            result.error("SERVICE_ERROR", e.localizedMessage, null)
        }
    }

    private fun handleStopBackgroundService(result: MethodChannel.Result) {
        try {
            val intent = Intent(context, NimmyForegroundService::class.java).apply {
                action = NimmyForegroundService.ACTION_STOP
            }
            context.startService(intent)
            result.success(true)
        } catch (e: Exception) {
            Log.e(TAG, "Error stopping foreground service", e)
            result.error("SERVICE_ERROR", e.localizedMessage, null)
        }
    }

    private fun handleStartVoiceRecording(result: MethodChannel.Result) {
        try {
            if (activeRecordingDaemon == null) {
                activeRecordingDaemon = AudioRecordingDaemon(context.cacheDir)
            }
            val file = activeRecordingDaemon?.startRecording()
            if (file != null) {
                result.success(mapOf(
                    "status" to "recording",
                    "filePath" to file.absolutePath
                ))
            } else {
                result.error("RECORDING_FAILED", "Could not initialize AudioRecord", null)
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error in startVoiceRecording", e)
            result.error("RECORDING_ERROR", e.localizedMessage, null)
        }
    }

    private fun handleStopVoiceRecording(result: MethodChannel.Result) {
        try {
            val file = activeRecordingDaemon?.stopRecording()
            if (file != null && file.exists()) {
                result.success(mapOf(
                    "status" to "stopped",
                    "filePath" to file.absolutePath,
                    "fileSizeBytes" to file.length()
                ))
            } else {
                result.success(mapOf(
                    "status" to "stopped",
                    "filePath" to null,
                    "fileSizeBytes" to 0
                ))
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error in stopVoiceRecording", e)
            result.error("RECORDING_ERROR", e.localizedMessage, null)
        }
    }

    private fun handleScheduleAlarm(call: MethodCall, result: MethodChannel.Result) {
        val title = call.argument<String>("title") ?: "Nimmy Task"
        val body = call.argument<String>("body") ?: "Time for your scheduled task"
        val triggerAtMillis = call.argument<Long>("triggerAtMillis") ?: (System.currentTimeMillis() + 60000)
        val alarmId = call.argument<Int>("id") ?: System.currentTimeMillis().toInt()

        try {
            val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as? AlarmManager
            val intent = Intent(context, NimmyAlarmReceiver::class.java).apply {
                action = "ai.nimmy.ACTION_ALARM"
                putExtra(NimmyAlarmReceiver.EXTRA_TITLE, title)
                putExtra(NimmyAlarmReceiver.EXTRA_BODY, body)
                putExtra(NimmyAlarmReceiver.EXTRA_ID, alarmId)
            }

            val pendingIntent = PendingIntent.getBroadcast(
                context,
                alarmId,
                intent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )

            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                alarmManager?.setExactAndAllowWhileIdle(
                    AlarmManager.RTC_WAKEUP,
                    triggerAtMillis,
                    pendingIntent
                )
            } else {
                alarmManager?.setExact(
                    AlarmManager.RTC_WAKEUP,
                    triggerAtMillis,
                    pendingIntent
                )
            }

            result.success(mapOf("scheduled" to true, "alarmId" to alarmId))
        } catch (e: Exception) {
            Log.e(TAG, "Error scheduling alarm", e)
            result.error("ALARM_ERROR", e.localizedMessage, null)
        }
    }

    private fun handleGetDeviceInfo(result: MethodChannel.Result) {
        val batteryManager = context.getSystemService(Context.BATTERY_SERVICE) as? BatteryManager
        val batteryLevel = batteryManager?.getIntProperty(BatteryManager.BATTERY_PROPERTY_CAPACITY) ?: -1

        val info = mapOf(
            "manufacturer" to Build.MANUFACTURER,
            "model" to Build.MODEL,
            "osVersion" to Build.VERSION.RELEASE,
            "sdkInt" to Build.VERSION.SDK_INT,
            "batteryLevel" to batteryLevel,
            "isBackgroundServiceRunning" to NimmyForegroundService.isRunning
        )
        result.success(info)
    }

    private fun handleLaunchApp(call: MethodCall, result: MethodChannel.Result) {
        val packageName = call.argument<String>("packageName")
        if (packageName.isNullOrBlank()) {
            result.error("INVALID_ARGUMENT", "packageName is required", null)
            return
        }

        try {
            val launchIntent = context.packageManager.getLaunchIntentForPackage(packageName)
            if (launchIntent != null) {
                launchIntent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                context.startActivity(launchIntent)
                result.success(true)
            } else {
                result.error("APP_NOT_FOUND", "Package $packageName not found", null)
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error launching app: $packageName", e)
            result.error("LAUNCH_ERROR", e.localizedMessage, null)
        }
    }

    private fun handleCheckPermissions(result: MethodChannel.Result) {
        val recordAudioGranted = ContextCompat.checkSelfPermission(
            context,
            android.Manifest.permission.RECORD_AUDIO
        ) == PackageManager.PERMISSION_GRANTED

        val notificationsGranted = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            ContextCompat.checkSelfPermission(
                context,
                android.Manifest.permission.POST_NOTIFICATIONS
            ) == PackageManager.PERMISSION_GRANTED
        } else {
            true
        }

        result.success(mapOf(
            "recordAudio" to recordAudioGranted,
            "notifications" to notificationsGranted
        ))
    }
}
