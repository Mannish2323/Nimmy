package ai.nimmy.nimmy

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.IBinder
import android.os.PowerManager
import android.util.Log
import androidx.core.app.NotificationCompat

/**
 * 🟣 NIMMY — Native Background Foreground Service (Kotlin)
 * ========================================================
 * Keeps Nimmy's cognitive sensing loop active on Android devices.
 * Displays persistent system notification and holds partial wake-lock.
 */
class NimmyForegroundService : Service() {

    companion object {
        private const val TAG = "NimmyForegroundService"
        const val CHANNEL_ID = "nimmy_daemon_channel"
        const val NOTIFICATION_ID = 4242

        const val ACTION_START = "ai.nimmy.action.START_SERVICE"
        const val ACTION_STOP = "ai.nimmy.action.STOP_SERVICE"

        var isRunning = false
            private set
    }

    private var wakeLock: PowerManager.WakeLock? = null
    private var audioDaemon: AudioRecordingDaemon? = null

    override fun onCreate() {
        super.onCreate()
        Log.i(TAG, "NimmyForegroundService created")
        createNotificationChannel()

        audioDaemon = AudioRecordingDaemon(cacheDir)
        audioDaemon?.onAmplitudeListener = { rms, peak ->
            // Audio metrics can be bridged or fed to VAD heuristic
            if (rms > 2500) {
                Log.d(TAG, "Voice activity detected (RMS: $rms, Peak: $peak)")
            }
        }
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        val action = intent?.action ?: ACTION_START

        when (action) {
            ACTION_STOP -> {
                stopForegroundService()
                return START_NOT_STICKY
            }
            ACTION_START -> {
                startForegroundServiceInternal()
            }
        }

        return START_STICKY
    }

    private fun startForegroundServiceInternal() {
        if (isRunning) return
        isRunning = true

        acquireWakeLock()

        val notification = buildNotification("Nimmy Core Active", "Cognitive subsystem online & listening")
        startForeground(NOTIFICATION_ID, notification)

        // Start background passive audio sensing
        audioDaemon?.startRecording()
        Log.i(TAG, "Nimmy foreground service started successfully")
    }

    private fun stopForegroundService() {
        Log.i(TAG, "Stopping Nimmy foreground service")
        audioDaemon?.stopRecording()
        releaseWakeLock()
        isRunning = false
        stopForeground(STOP_FOREGROUND_REMOVE)
        stopSelf()
    }

    private fun acquireWakeLock() {
        try {
            val powerManager = getSystemService(Context.POWER_SERVICE) as? PowerManager
            wakeLock = powerManager?.newWakeLock(
                PowerManager.PARTIAL_WAKE_LOCK,
                "Nimmy::AutonomousWakeLock"
            )?.apply {
                acquire(10 * 60 * 1000L) // 10 minutes timeout safety
            }
        } catch (e: Exception) {
            Log.e(TAG, "Failed to acquire wake lock", e)
        }
    }

    private fun releaseWakeLock() {
        try {
            if (wakeLock?.isHeld == true) {
                wakeLock?.release()
                wakeLock = null
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error releasing wake lock", e)
        }
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "Nimmy Autonomous Service",
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                description = "Persistent background service for autonomous AI assistance"
                setShowBadge(false)
            }
            val manager = getSystemService(Context.NOTIFICATION_SERVICE) as? NotificationManager
            manager?.createNotificationChannel(channel)
        }
    }

    private fun buildNotification(title: String, content: String): Notification {
        val launchIntent = packageManager.getLaunchIntentForPackage(packageName)
        val pendingIntent = PendingIntent.getActivity(
            this,
            0,
            launchIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle(title)
            .setContentText(content)
            .setSmallIcon(android.R.drawable.ic_dialog_info)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .setOngoing(true)
            .setContentIntent(pendingIntent)
            .build()
    }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onDestroy() {
        stopForegroundService()
        super.onDestroy()
        Log.i(TAG, "NimmyForegroundService destroyed")
    }
}
