package ai.nimmy.nimmy

import android.app.Service
import android.content.Intent
import android.os.IBinder

/**
 * Reserved architecture boundary for a future, visible foreground service.
 * It is intentionally not registered in AndroidManifest.xml in the MVP.
 */
class NimmyForegroundService : Service() {
    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        stopSelf()
        return START_NOT_STICKY
    }

    override fun onBind(intent: Intent?): IBinder? = null
}
