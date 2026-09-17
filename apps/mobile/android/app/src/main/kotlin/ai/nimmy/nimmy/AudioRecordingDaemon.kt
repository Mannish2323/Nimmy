package ai.nimmy.nimmy

import android.annotation.SuppressLint
import android.media.AudioFormat
import android.media.AudioRecord
import android.media.MediaRecorder
import android.util.Log
import java.io.File
import java.io.FileOutputStream
import java.io.IOException
import java.util.concurrent.atomic.AtomicBoolean
import kotlin.math.sqrt

/**
 * 🟣 NIMMY — Native Audio Recording & Wake-Word Daemon (Kotlin)
 * ==============================================================
 * High-performance 16kHz 16-bit PCM microphone capture.
 * Continuously computes RMS audio amplitude for voice activity detection (VAD).
 */
class AudioRecordingDaemon(private val cacheDir: File) {

    companion object {
        private const val TAG = "NimmyAudioDaemon"
        const val SAMPLE_RATE = 16000
        const val CHANNEL_CONFIG = AudioFormat.CHANNEL_IN_MONO
        const val AUDIO_FORMAT = AudioFormat.ENCODING_PCM_16BIT
    }

    private var audioRecord: AudioRecord? = null
    private var recordingThread: Thread? = null
    private val isRecording = AtomicBoolean(false)
    private var currentOutputFile: File? = null

    // Listener for real-time audio amplitude metrics
    var onAmplitudeListener: ((rms: Double, peak: Short) -> Unit)? = null

    @SuppressLint("MissingPermission")
    fun startRecording(): File? {
        if (isRecording.get()) {
            Log.w(TAG, "Recording is already active")
            return currentOutputFile
        }

        val minBufferSize = AudioRecord.getMinBufferSize(
            SAMPLE_RATE,
            CHANNEL_CONFIG,
            AUDIO_FORMAT
        )

        if (minBufferSize == AudioRecord.ERROR || minBufferSize == AudioRecord.ERROR_BAD_VALUE) {
            Log.e(TAG, "Unable to get minimum buffer size for AudioRecord")
            return null
        }

        val bufferSize = (minBufferSize * 2).coerceAtLeast(4096)

        try {
            audioRecord = AudioRecord(
                MediaRecorder.AudioSource.MIC,
                SAMPLE_RATE,
                CHANNEL_CONFIG,
                AUDIO_FORMAT,
                bufferSize
            )

            if (audioRecord?.state != AudioRecord.STATE_INITIALIZED) {
                Log.e(TAG, "AudioRecord initialization failed")
                audioRecord?.release()
                audioRecord = null
                return null
            }

            val timestamp = System.currentTimeMillis()
            val outputFile = File(cacheDir, "nimmy_voice_$timestamp.pcm")
            currentOutputFile = outputFile

            audioRecord?.startRecording()
            isRecording.set(true)

            recordingThread = Thread({
                writeAudioDataToFile(outputFile, bufferSize)
            }, "NimmyAudioCaptureThread")
            recordingThread?.start()

            Log.i(TAG, "Audio recording started -> ${outputFile.absolutePath}")
            return outputFile
        } catch (e: Exception) {
            Log.e(TAG, "Exception starting audio recording", e)
            stopRecording()
            return null
        }
    }

    private fun writeAudioDataToFile(file: File, bufferSize: Int) {
        val buffer = ShortArray(bufferSize / 2)
        var outputStream: FileOutputStream? = null

        try {
            outputStream = FileOutputStream(file)
            val byteBuffer = ByteArray(bufferSize)

            while (isRecording.get() && audioRecord?.recordingState == AudioRecord.RECORDSTATE_RECORDING) {
                val shortsRead = audioRecord?.read(buffer, 0, buffer.size) ?: 0

                if (shortsRead > 0) {
                    var sumSquares = 0.0
                    var maxPeak: Short = 0

                    for (i in 0 until shortsRead) {
                        val sample = buffer[i]
                        sumSquares += (sample * sample).toDouble()
                        if (kotlin.math.abs(sample.toInt()) > maxPeak) {
                            maxPeak = kotlin.math.abs(sample.toInt()).toShort()
                        }

                        // Convert short to little-endian 16-bit PCM bytes
                        val byteIdx = i * 2
                        byteBuffer[byteIdx] = (sample.toInt() and 0x00FF).toByte()
                        byteBuffer[byteIdx + 1] = ((sample.toInt() shr 8) and 0x00FF).toByte()
                    }

                    val rms = sqrt(sumSquares / shortsRead)
                    onAmplitudeListener?.invoke(rms, maxPeak)

                    outputStream.write(byteBuffer, 0, shortsRead * 2)
                }
            }
        } catch (e: IOException) {
            Log.e(TAG, "Error writing audio stream to file", e)
        } finally {
            try {
                outputStream?.close()
            } catch (e: IOException) {
                Log.e(TAG, "Error closing audio output stream", e)
            }
        }
    }

    fun stopRecording(): File? {
        if (!isRecording.get()) {
            return currentOutputFile
        }

        isRecording.set(false)

        try {
            audioRecord?.stop()
            audioRecord?.release()
            audioRecord = null
        } catch (e: Exception) {
            Log.e(TAG, "Error stopping AudioRecord", e)
        }

        try {
            recordingThread?.join(1000)
            recordingThread = null
        } catch (e: InterruptedException) {
            Log.e(TAG, "Interrupted while joining recording thread", e)
        }

        val result = currentOutputFile
        Log.i(TAG, "Audio recording stopped. Output file: ${result?.absolutePath} (${result?.length()} bytes)")
        return result
    }

    fun isRecording(): Boolean = isRecording.get()
}
