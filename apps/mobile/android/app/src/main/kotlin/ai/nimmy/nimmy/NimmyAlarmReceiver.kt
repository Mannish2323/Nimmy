package ai.nimmy.nimmy

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build
import android.util.Log
import androidx.core.app.NotificationCompat

/**
 * 🟣 NIMMY — Native Alarm & Reminder Broadcast Receiver (Kotlin)
 * ==============================================================
 * Triggers hardware notifications when scheduled tasks and reminders fire.
 */
class NimmyAlarmReceiver : BroadcastReceiver() {

    companion object {
        private const val TAG = "NimmyAlarmReceiver"
        const val ALARM_CHANNEL_ID = "nimmy_alarm_channel"
        const val EXTRA_TITLE = "extra_alarm_title"
        const val EXTRA_BODY = "extra_alarm_body"
        const val EXTRA_ID = "extra_alarm_id"
    }

    override fun onReceive(context: Context, intent: Intent) {
        val title = intent.getStringExtra(EXTRA_TITLE) ?: "Nimmy Reminder"
        val body = intent.getStringExtra(EXTRA_BODY) ?: "You have a scheduled reminder."
        val notificationId = intent.getIntExtra(EXTRA_ID, System.currentTimeMillis().toInt())

        Log.i(TAG, "Alarm received: $title - $body (ID: $notificationId)")

        createAlarmChannel(context)
        showNotification(context, title, body, notificationId)
    }

    private fun createAlarmChannel(context: Context) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                ALARM_CHANNEL_ID,
                "Nimmy Reminders & Alarms",
                NotificationManager.IMPORTANCE_HIGH
            ).apply {
                description = "High-priority notifications for scheduled assistant actions"
                enableVibration(true)
            }
            val manager = context.getSystemService(Context.NOTIFICATION_SERVICE) as? NotificationManager
            manager?.createNotificationChannel(channel)
        }
    }

    private fun showNotification(context: Context, title: String, body: String, notificationId: Int) {
        val launchIntent = context.packageManager.getLaunchIntentForPackage(context.packageName)
        val pendingIntent = PendingIntent.getActivity(
            context,
            notificationId,
            launchIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val notification = NotificationCompat.Builder(context, ALARM_CHANNEL_ID)
            .setContentTitle(title)
            .setContentText(body)
            .setSmallIcon(android.R.drawable.ic_lock_idle_alarm)
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .setAutoCancel(true)
            .setContentIntent(pendingIntent)
            .build()

        val manager = context.getSystemService(Context.NOTIFICATION_SERVICE) as? NotificationManager
        manager?.notify(notificationId, notification)
    }
}
