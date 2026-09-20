package ai.nimmy.nimmy

import android.content.Context
import java.util.concurrent.CopyOnWriteArraySet

/**
 * Process-local status/event boundary between the microphone foreground
 * service and Flutter. Events contain state and scores only; raw audio is
 * never retained or forwarded across the bridge.
 */
object WakeWordRuntime {
    @Volatile
    var status: String = STATUS_STOPPED
        private set

    @Volatile
    var serviceRunning: Boolean = false
        private set

    private val listeners = CopyOnWriteArraySet<(Map<String, Any?>) -> Unit>()

    @Volatile
    private var latestEvent: Map<String, Any?> = statusEvent(STATUS_STOPPED)

    fun subscribe(listener: (Map<String, Any?>) -> Unit) {
        listeners.add(listener)
        listener(latestEvent)
    }

    fun unsubscribe(listener: (Map<String, Any?>) -> Unit) {
        listeners.remove(listener)
    }

    fun updateStatus(
        value: String,
        running: Boolean = serviceRunning,
        reason: String? = null
    ) {
        status = value
        serviceRunning = running
        publish(statusEvent(value, reason))
    }

    fun publishDetection(phrase: String, score: Float) {
        status = STATUS_WAKE_DETECTED
        publish(
            mapOf(
                "type" to "wake_detected",
                "status" to STATUS_WAKE_DETECTED,
                "phrase" to phrase,
                "score" to score.toDouble(),
                "timestamp" to System.currentTimeMillis(),
                "local" to true
            )
        )
    }

    fun publishError(code: String, message: String, recovery: String) {
        status = STATUS_ERROR
        publish(
            mapOf(
                "type" to "error",
                "status" to STATUS_ERROR,
                "errorCode" to code,
                "message" to message,
                "recovery" to recovery,
                "timestamp" to System.currentTimeMillis(),
                "local" to true
            )
        )
    }

    private fun publish(event: Map<String, Any?>) {
        latestEvent = event
        listeners.forEach { listener -> listener(event) }
    }

    private fun statusEvent(value: String, reason: String? = null): Map<String, Any?> =
        mapOf(
            "type" to "status",
            "status" to value,
            "reason" to reason,
            "timestamp" to System.currentTimeMillis(),
            "local" to true
        )

    const val STATUS_STOPPED = "stopped"
    const val STATUS_STARTING = "starting"
    const val STATUS_ACTIVE = "active"
    const val STATUS_PAUSED = "paused"
    const val STATUS_WAKE_DETECTED = "wake_detected"
    const val STATUS_ERROR = "error"
}

/** Required on-device feature models plus the app-specific Nimmy classifier. */
object WakeWordAssets {
    const val MEL_MODEL = "melspectrogram.onnx"
    const val EMBEDDING_MODEL = "embedding_model.onnx"
    const val NIMMY_MODEL = "wakeword/nimmy.onnx"

    val required = listOf(MEL_MODEL, EMBEDDING_MODEL, NIMMY_MODEL)

    fun missing(context: Context): List<String> = required.filterNot { path ->
        try {
            context.assets.open(path).use { input -> input.read() }
            true
        } catch (_: Exception) {
            false
        }
    }
}
