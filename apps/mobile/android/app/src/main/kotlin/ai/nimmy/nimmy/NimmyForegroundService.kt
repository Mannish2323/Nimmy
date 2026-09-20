package ai.nimmy.nimmy

import android.Manifest
import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Intent
import android.content.pm.PackageManager
import android.content.pm.ServiceInfo
import android.os.Build
import android.os.IBinder
import android.util.Log
import androidx.core.app.NotificationCompat
import androidx.core.app.ServiceCompat
import androidx.core.content.ContextCompat
import com.rementia.openwakeword.lib.WakeWordEngine
import com.rementia.openwakeword.lib.model.DetectionMode
import com.rementia.openwakeword.lib.model.WakeWordModel
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.Job
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancel
import kotlinx.coroutines.flow.collect
import kotlinx.coroutines.launch

/**
 * Visible, user-enabled microphone foreground service for local wake-word
 * detection. It has no repository, network, tool, or database dependency.
 * The service emits only state, phrase, timestamp, and confidence metadata.
 */
class NimmyForegroundService : Service() {
    private val scope = CoroutineScope(SupervisorJob() + Dispatchers.Default)
    @Volatile
    private var wakeWordEngine: WakeWordEngine? = null
    private var detectionJob: Job? = null
    private var startJob: Job? = null
    private var threshold = DEFAULT_THRESHOLD

    override fun onCreate() {
        super.onCreate()
        createNotificationChannel()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        when (intent?.action ?: ACTION_START) {
            ACTION_STOP -> stopWakeDetection("user_stopped")
            ACTION_PAUSE -> pauseWakeDetection(intent?.getStringExtra(EXTRA_REASON) ?: "voice_pipeline")
            ACTION_RESUME -> resumeWakeDetection()
            ACTION_START -> {
                threshold = intent?.getFloatExtra(EXTRA_THRESHOLD, DEFAULT_THRESHOLD)
                    ?.coerceIn(MIN_THRESHOLD, MAX_THRESHOLD)
                    ?: DEFAULT_THRESHOLD
                startWakeDetection()
            }
        }
        return START_NOT_STICKY
    }

    private fun startWakeDetection() {
        try {
            ServiceCompat.startForeground(
                this,
                NOTIFICATION_ID,
                notification("Starting local wake detection…"),
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                    ServiceInfo.FOREGROUND_SERVICE_TYPE_MICROPHONE
                } else {
                    0
                }
            )
        } catch (error: Throwable) {
            Log.e(TAG, "Foreground service start failed", error)
            failAndStop(
                "FOREGROUND_START_FAILED",
                "Foreground service could not start: ${error.message ?: "permission or policy restriction"}",
                "Open Nimmy and restart wake detection."
            )
            return
        }
        WakeWordRuntime.updateStatus(WakeWordRuntime.STATUS_STARTING, running = true)

        if (!hasMicrophonePermission()) {
            failAndStop(
                "MIC_PERMISSION_DENIED",
                "Microphone permission is required for hands-free wake detection.",
                "Open Nimmy and enable microphone access."
            )
            return
        }
        if (!hasVisibleNotificationPermission()) {
            failAndStop(
                "NOTIFICATION_PERMISSION_DENIED",
                "A visible notification is required while wake detection uses the microphone.",
                "Open Nimmy and enable notifications."
            )
            return
        }

        val missingAssets = WakeWordAssets.missing(this)
        if (missingAssets.isNotEmpty()) {
            failAndStop(
                "WAKE_ENGINE_UNAVAILABLE",
                "The local Nimmy wake-word model is not installed.",
                "Install and validate wakeword/nimmy.onnx, then try again."
            )
            return
        }

        if (wakeWordEngine != null) {
            resumeWakeDetection()
            return
        }

        if (startJob?.isActive == true) {
            return
        }

        startJob = scope.launch {
            try {
                if (wakeWordEngine != null) {
                    resumeWakeDetection()
                    return@launch
                }
                val engine = WakeWordEngine(
                    context = applicationContext,
                    models = listOf(
                        WakeWordModel(
                            name = WAKE_PHRASE_LABEL,
                            modelPath = WakeWordAssets.NIMMY_MODEL,
                            threshold = threshold
                        )
                    ),
                    detectionMode = DetectionMode.SINGLE_BEST,
                    detectionCooldownMs = DETECTION_COOLDOWN_MS
                )
                wakeWordEngine = engine
                detectionJob = scope.launch {
                    engine.detections.collect { detection ->
                        engine.stop()
                        WakeWordRuntime.publishDetection(
                            phrase = detection.model.name,
                            score = detection.score
                        )
                        updateNotification("Wake detected — listening for your command")
                    }
                }
                engine.start()
                WakeWordRuntime.updateStatus(WakeWordRuntime.STATUS_ACTIVE, running = true)
                updateNotification("Wake detection active • Say “Hey Nimmy”")
            } catch (error: Throwable) {
                Log.e(TAG, "Local wake detector failed", error)
                failAndStop(
                    "WAKE_ENGINE_UNAVAILABLE",
                    "Local wake detection could not start on this device.",
                    "Return to Nimmy and retry or use the microphone button."
                )
            }
        }
    }

    private fun pauseWakeDetection(reason: String) {
        wakeWordEngine?.stop()
        WakeWordRuntime.updateStatus(
            WakeWordRuntime.STATUS_PAUSED,
            running = WakeWordRuntime.serviceRunning,
            reason = reason
        )
        updateNotification("Wake detection paused while Nimmy is handling audio")
    }

    private fun resumeWakeDetection() {
        if (!WakeWordRuntime.serviceRunning || wakeWordEngine == null) {
            startWakeDetection()
            return
        }
        if (!hasMicrophonePermission()) {
            failAndStop(
                "MIC_PERMISSION_DENIED",
                "Microphone permission was revoked.",
                "Enable microphone access before restarting wake detection."
            )
            return
        }
        try {
            wakeWordEngine?.start()
            WakeWordRuntime.updateStatus(WakeWordRuntime.STATUS_ACTIVE, running = true)
            updateNotification("Wake detection active • Say “Hey Nimmy”")
        } catch (error: Throwable) {
            Log.e(TAG, "Unable to resume local wake detector", error)
            failAndStop(
                "MIC_UNAVAILABLE",
                "The microphone is unavailable to the wake detector.",
                "Close other microphone apps and retry."
            )
        }
    }

    private fun stopWakeDetection(reason: String) {
        startJob?.cancel()
        startJob = null
        detectionJob?.cancel()
        detectionJob = null
        wakeWordEngine?.release()
        wakeWordEngine = null
        WakeWordRuntime.updateStatus(
            WakeWordRuntime.STATUS_STOPPED,
            running = false,
            reason = reason
        )
        ServiceCompat.stopForeground(this, ServiceCompat.STOP_FOREGROUND_REMOVE)
        stopSelf()
    }

    private fun failAndStop(code: String, message: String, recovery: String) {
        WakeWordRuntime.publishError(code, message, recovery)
        startJob?.cancel()
        startJob = null
        detectionJob?.cancel()
        detectionJob = null
        wakeWordEngine?.release()
        wakeWordEngine = null
        ServiceCompat.stopForeground(this, ServiceCompat.STOP_FOREGROUND_REMOVE)
        stopSelf()
    }

    private fun hasMicrophonePermission(): Boolean =
        ContextCompat.checkSelfPermission(this, Manifest.permission.RECORD_AUDIO) ==
            PackageManager.PERMISSION_GRANTED

    private fun hasVisibleNotificationPermission(): Boolean =
        Build.VERSION.SDK_INT < Build.VERSION_CODES.TIRAMISU ||
            ContextCompat.checkSelfPermission(this, Manifest.permission.POST_NOTIFICATIONS) ==
            PackageManager.PERMISSION_GRANTED

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        val manager = getSystemService(NotificationManager::class.java)
        val channel = NotificationChannel(
            NOTIFICATION_CHANNEL_ID,
            "Nimmy wake detection",
            NotificationManager.IMPORTANCE_LOW
        ).apply {
            description = "Shows when Nimmy is listening locally for its wake phrase."
            setSound(null, null)
            enableVibration(false)
            setShowBadge(false)
        }
        manager.createNotificationChannel(channel)
    }

    private fun notification(content: String): Notification {
        val openAppIntent = Intent(this, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_SINGLE_TOP or Intent.FLAG_ACTIVITY_CLEAR_TOP
        }
        val openApp = PendingIntent.getActivity(
            this,
            0,
            openAppIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        val stopIntent = Intent(this, NimmyForegroundService::class.java).apply {
            action = ACTION_STOP
        }
        val stopAction = PendingIntent.getService(
            this,
            1,
            stopIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        return NotificationCompat.Builder(this, NOTIFICATION_CHANNEL_ID)
            .setSmallIcon(R.drawable.ic_nimmy_mic)
            .setContentTitle("Nimmy microphone active")
            .setContentText(content)
            .setContentIntent(openApp)
            .setCategory(NotificationCompat.CATEGORY_SERVICE)
            .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
            .setOngoing(true)
            .setOnlyAlertOnce(true)
            .addAction(0, "Turn off", stopAction)
            .build()
    }

    private fun updateNotification(content: String) {
        val manager = getSystemService(NotificationManager::class.java)
        manager.notify(NOTIFICATION_ID, notification(content))
    }

    override fun onDestroy() {
        detectionJob?.cancel()
        wakeWordEngine?.release()
        wakeWordEngine = null
        scope.cancel()
        if (WakeWordRuntime.serviceRunning) {
            WakeWordRuntime.updateStatus(
                WakeWordRuntime.STATUS_STOPPED,
                running = false,
                reason = "service_destroyed"
            )
        }
        super.onDestroy()
    }

    override fun onBind(intent: Intent?): IBinder? = null

    companion object {
        private const val TAG = "NimmyWakeService"
        private const val NOTIFICATION_CHANNEL_ID = "nimmy_wake_detection"
        private const val NOTIFICATION_ID = 41021
        private const val WAKE_PHRASE_LABEL = "Hey Nimmy / Nimmy"
        private const val DETECTION_COOLDOWN_MS = 2_500L
        private const val DEFAULT_THRESHOLD = 0.50f
        private const val MIN_THRESHOLD = 0.05f
        private const val MAX_THRESHOLD = 0.95f

        const val ACTION_START = "ai.nimmy.nimmy.action.START_WAKE_DETECTION"
        const val ACTION_STOP = "ai.nimmy.nimmy.action.STOP_WAKE_DETECTION"
        const val ACTION_PAUSE = "ai.nimmy.nimmy.action.PAUSE_WAKE_DETECTION"
        const val ACTION_RESUME = "ai.nimmy.nimmy.action.RESUME_WAKE_DETECTION"
        const val EXTRA_REASON = "reason"
        const val EXTRA_THRESHOLD = "threshold"
    }
}
