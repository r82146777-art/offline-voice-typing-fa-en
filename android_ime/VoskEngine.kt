package com.offlinevoicetyping.offline_voice_typing

import android.content.Context
import android.media.AudioFormat
import android.media.AudioRecord
import android.media.MediaRecorder
import android.util.Log
import org.json.JSONObject
import org.vosk.Model
import org.vosk.Recognizer
import org.vosk.LibVosk
import org.vosk.LogLevel
import java.io.File
import java.io.FileOutputStream
import java.util.concurrent.atomic.AtomicBoolean
import java.util.zip.ZipInputStream

/**
 * موتور تشخیص گفتار آفلاین با Vosk بومی.
 * هم از اپ Flutter و هم از IME استفاده می‌شود.
 */
object VoskEngine {
    private const val TAG = "VoskEngine"
    private const val SAMPLE_RATE = 16000

    private var modelFa: Model? = null
    private var modelEn: Model? = null
    private var recognizer: Recognizer? = null
    private var audioRecord: AudioRecord? = null
    private var listenThread: Thread? = null
    private val listening = AtomicBoolean(false)

    @Volatile
    var currentLang: String = "fa"

    fun interface Listener {
        fun onPartial(text: String)
        fun onFinal(text: String)
        fun onError(message: String)
        fun onStatus(status: String)
    }

    private var listener: Listener? = null

    fun setListener(l: Listener?) {
        listener = l
    }

    fun ensureModel(context: Context, lang: String): String? {
        return try {
            val folder = if (lang == "en") {
                "vosk-model-small-en-us-0.15"
            } else {
                "vosk-model-small-fa-0.42"
            }
            val assetZip = if (lang == "en") {
                "models/vosk-model-small-en-us-0.15.zip"
            } else {
                "models/vosk-model-small-fa-0.42.zip"
            }

            val outDir = File(context.filesDir, "vosk_models/$folder")
            val marker = File(outDir, "am/final.mdl")
            if (marker.exists()) {
                return outDir.absolutePath
            }

            // پاکسازی ناقص
            if (outDir.exists()) {
                outDir.deleteRecursively()
            }
            outDir.parentFile?.mkdirs()

            // استخراج از assets (مسیر flutter: flutter_assets/assets/models/...)
            val assetPaths = listOf(
                "flutter_assets/assets/$assetZip",
                "assets/$assetZip",
                assetZip
            )

            var opened = false
            for (path in assetPaths) {
                try {
                    context.assets.open(path).use { input ->
                        ZipInputStream(input).use { zis ->
                            var entry = zis.nextEntry
                            val buffer = ByteArray(8192)
                            while (entry != null) {
                                val name = entry.name.replace("\\", "/")
                                val target = File(context.filesDir, "vosk_models/$name")
                                if (entry.isDirectory) {
                                    target.mkdirs()
                                } else {
                                    target.parentFile?.mkdirs()
                                    FileOutputStream(target).use { fos ->
                                        var len: Int
                                        while (zis.read(buffer).also { len = it } > 0) {
                                            fos.write(buffer, 0, len)
                                        }
                                    }
                                }
                                zis.closeEntry()
                                entry = zis.nextEntry
                            }
                        }
                    }
                    opened = true
                    break
                } catch (e: Exception) {
                    Log.w(TAG, "Asset path failed: $path (${e.message})")
                }
            }

            if (!opened) {
                Log.e(TAG, "Could not open model asset for $lang")
                return null
            }

            // پیدا کردن مسیر واقعی مدل
            val found = findModelRoot(File(context.filesDir, "vosk_models"))
            if (found != null) {
                Log.i(TAG, "Model ready at $found")
                return found
            }
            if (marker.exists()) return outDir.absolutePath

            Log.e(TAG, "Model extracted but final.mdl not found")
            null
        } catch (e: Exception) {
            Log.e(TAG, "ensureModel failed", e)
            null
        }
    }

    private fun findModelRoot(base: File): String? {
        if (!base.exists()) return null
        val queue = ArrayDeque<File>()
        queue.add(base)
        while (queue.isNotEmpty()) {
            val dir = queue.removeFirst()
            val mdl = File(dir, "am/final.mdl")
            if (mdl.exists()) return dir.absolutePath
            dir.listFiles()?.filter { it.isDirectory }?.forEach { queue.add(it) }
        }
        return null
    }

    @Synchronized
    fun prepare(context: Context, lang: String): Boolean {
        return try {
            LibVosk.setLogLevel(LogLevel.WARNINGS)
            currentLang = lang
            val path = ensureModel(context, lang) ?: return false

            val model = if (lang == "en") {
                if (modelEn == null) modelEn = Model(path)
                modelEn!!
            } else {
                if (modelFa == null) modelFa = Model(path)
                modelFa!!
            }

            recognizer?.close()
            recognizer = Recognizer(model, SAMPLE_RATE.toFloat())
            true
        } catch (e: Exception) {
            Log.e(TAG, "prepare failed", e)
            listener?.onError("آماده‌سازی مدل: ${e.message}")
            false
        }
    }

    @Synchronized
    fun startListening(context: Context, lang: String = currentLang) {
        if (listening.get()) return

        try {
            if (recognizer == null || currentLang != lang) {
                if (!prepare(context, lang)) {
                    listener?.onError("مدل آفلاین آماده نشد")
                    return
                }
            }

            val minBuf = AudioRecord.getMinBufferSize(
                SAMPLE_RATE,
                AudioFormat.CHANNEL_IN_MONO,
                AudioFormat.ENCODING_PCM_16BIT
            )
            if (minBuf == AudioRecord.ERROR || minBuf == AudioRecord.ERROR_BAD_VALUE) {
                listener?.onError("میکروفون در دسترس نیست")
                return
            }

            val bufferSize = minBuf.coerceAtLeast(SAMPLE_RATE / 2)

            audioRecord?.release()
            audioRecord = AudioRecord(
                MediaRecorder.AudioSource.VOICE_RECOGNITION,
                SAMPLE_RATE,
                AudioFormat.CHANNEL_IN_MONO,
                AudioFormat.ENCODING_PCM_16BIT,
                bufferSize
            )

            if (audioRecord?.state != AudioRecord.STATE_INITIALIZED) {
                listener?.onError("راه‌اندازی میکروفون ناموفق")
                return
            }

            listening.set(true)
            audioRecord?.startRecording()
            listener?.onStatus("listening")

            listenThread = Thread({
                val buf = ShortArray(bufferSize / 2)
                while (listening.get()) {
                    val read = audioRecord?.read(buf, 0, buf.size) ?: -1
                    if (read > 0) {
                        val rec = recognizer ?: break
                        if (rec.acceptWaveForm(buf, read)) {
                            val result = rec.result
                            val text = extractText(result, "text")
                            if (text.isNotBlank()) {
                                listener?.onFinal(text)
                            }
                        } else {
                            val partial = extractText(rec.partialResult, "partial")
                            if (partial.isNotBlank()) {
                                listener?.onPartial(partial)
                            }
                        }
                    }
                }
                // نتیجه نهایی
                try {
                    val finalJson = recognizer?.finalResult
                    val text = extractText(finalJson, "text")
                    if (text.isNotBlank()) {
                        listener?.onFinal(text)
                    }
                } catch (_: Exception) {
                }
                listener?.onStatus("idle")
            }, "vosk-listen").also { it.start() }
        } catch (e: SecurityException) {
            listening.set(false)
            listener?.onError("مجوز میکروفون داده نشده")
        } catch (e: Exception) {
            listening.set(false)
            Log.e(TAG, "startListening failed", e)
            listener?.onError(e.message ?: "خطای ناشناخته")
        }
    }

    @Synchronized
    fun stopListening() {
        listening.set(false)
        try {
            audioRecord?.stop()
        } catch (_: Exception) {
        }
        try {
            audioRecord?.release()
        } catch (_: Exception) {
        }
        audioRecord = null
        try {
            listenThread?.join(1500)
        } catch (_: Exception) {
        }
        listenThread = null
        listener?.onStatus("idle")
    }

    fun isListening(): Boolean = listening.get()

    private fun extractText(json: String?, key: String): String {
        if (json.isNullOrBlank()) return ""
        return try {
            JSONObject(json).optString(key, "").trim()
        } catch (_: Exception) {
            ""
        }
    }
}
