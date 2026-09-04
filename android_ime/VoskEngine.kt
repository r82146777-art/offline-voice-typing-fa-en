package com.offlinevoicetyping.offline_voice_typing

import android.content.Context
import android.os.Handler
import android.os.Looper
import android.util.Log
import org.json.JSONObject
import org.vosk.LibVosk
import org.vosk.LogLevel
import org.vosk.Model
import org.vosk.Recognizer
import org.vosk.android.RecognitionListener
import org.vosk.android.SpeechService
import java.io.File
import java.io.FileOutputStream
import java.io.IOException
import java.util.concurrent.atomic.AtomicBoolean

/**
 * Offline Vosk using official SpeechService. Only one language model is loaded.
 * All native/Error failures are caught so the process does not die.
 */
object VoskEngine {
    private const val TAG = "VoskEngine"
    private const val SAMPLE_RATE = 16000.0f

    private val mainHandler = Handler(Looper.getMainLooper())
    private val listening = AtomicBoolean(false)
    private val preparing = AtomicBoolean(false)

    @Volatile private var model: Model? = null
    @Volatile private var recognizer: Recognizer? = null
    @Volatile private var speechService: SpeechService? = null
    @Volatile private var loadedLang: String? = null
    @Volatile var currentLang: String = "fa"

    interface Listener {
        fun onPartial(text: String)
        fun onFinal(text: String)
        fun onError(message: String)
        fun onStatus(status: String)
    }

    @Volatile
    private var listener: Listener? = null

    fun setListener(l: Listener?) {
        listener = l
    }

    fun isListening(): Boolean = listening.get()

    @Synchronized
    fun prepare(context: Context, lang: String): Boolean {
        if (model != null && loadedLang == lang) return true
        if (!preparing.compareAndSet(false, true)) {
            // another prepare in flight
            var spins = 0
            while (preparing.get() && spins < 200) {
                try { Thread.sleep(100) } catch (_: InterruptedException) {}
                spins++
            }
            return model != null && loadedLang == lang
        }
        try {
            try {
                LibVosk.setLogLevel(LogLevel.WARNINGS)
            } catch (t: Throwable) {
                Log.e(TAG, "LibVosk init failed", t)
                postError("کتابخانه آفلاین لود نشد: ${t.javaClass.simpleName}")
                return false
            }

            stopInternal()
            closeModel()

            currentLang = lang
            val assetDir = if (lang == "en") "model-en" else "model-fa"
            val path = try {
                unpackAssetModel(context, assetDir)
            } catch (t: Throwable) {
                Log.e(TAG, "unpack failed", t)
                postError("استخراج مدل ناموفق: ${t.message}")
                return false
            }

            val conf = File(path, "conf/model.conf")
            val mdl = File(path, "am/final.mdl")
            if (!conf.exists() && !mdl.exists()) {
                postError("فایل مدل ناقص است")
                return false
            }

            model = try {
                Model(path)
            } catch (t: Throwable) {
                Log.e(TAG, "Model() failed", t)
                postError("بارگذاری مدل: ${t.javaClass.simpleName}: ${t.message}")
                return false
            }
            loadedLang = lang
            Log.i(TAG, "Model ready for $lang at $path")
            return true
        } catch (t: Throwable) {
            Log.e(TAG, "prepare failed", t)
            postError("آماده‌سازی: ${t.javaClass.simpleName}: ${t.message}")
            closeModel()
            return false
        } finally {
            preparing.set(false)
        }
    }

    fun startListening(context: Context, lang: String = currentLang) {
        if (listening.get()) return
        try {
            if (!prepare(context, lang)) return

            val m = model
            if (m == null) {
                postError("مدل آماده نیست")
                return
            }

            // SpeechService must be started on main thread
            mainHandler.post {
                try {
                    stopInternal()
                    recognizer = Recognizer(m, SAMPLE_RATE)
                    val rec = recognizer ?: return@post
                    val service = SpeechService(rec, SAMPLE_RATE)
                    speechService = service
                    val ok = service.startListening(object : RecognitionListener {
                        override fun onPartialResult(hypothesis: String?) {
                            val t = extractText(hypothesis, "partial")
                            if (t.isNotBlank()) listener?.onPartial(t)
                        }

                        override fun onResult(hypothesis: String?) {
                            val t = extractText(hypothesis, "text")
                            if (t.isNotBlank()) listener?.onFinal(t)
                        }

                        override fun onFinalResult(hypothesis: String?) {
                            val t = extractText(hypothesis, "text")
                            if (t.isNotBlank()) listener?.onFinal(t)
                            listening.set(false)
                            listener?.onStatus("idle")
                        }

                        override fun onError(exception: Exception?) {
                            listening.set(false)
                            postError(exception?.message ?: "خطای تشخیص صدا")
                            listener?.onStatus("idle")
                        }

                        override fun onTimeout() {
                            listening.set(false)
                            listener?.onStatus("idle")
                        }
                    })
                    if (ok) {
                        listening.set(true)
                        listener?.onStatus("listening")
                    } else {
                        listening.set(false)
                        postError("میکروفون در دسترس نیست")
                    }
                } catch (t: Throwable) {
                    listening.set(false)
                    Log.e(TAG, "startListening main", t)
                    postError("${t.javaClass.simpleName}: ${t.message}")
                }
            }
        } catch (t: Throwable) {
            listening.set(false)
            Log.e(TAG, "startListening", t)
            postError("${t.javaClass.simpleName}: ${t.message}")
        }
    }

    fun stopListening() {
        mainHandler.post {
            try {
                stopInternal()
            } catch (t: Throwable) {
                Log.e(TAG, "stop", t)
            } finally {
                listening.set(false)
                listener?.onStatus("idle")
            }
        }
    }

    private fun stopInternal() {
        try {
            speechService?.stop()
        } catch (_: Throwable) {
        }
        try {
            speechService?.shutdown()
        } catch (_: Throwable) {
        }
        speechService = null
        try {
            recognizer?.close()
        } catch (_: Throwable) {
        }
        recognizer = null
        listening.set(false)
    }

    private fun closeModel() {
        try {
            model?.close()
        } catch (_: Throwable) {
        }
        model = null
        loadedLang = null
    }

    private fun postError(msg: String) {
        mainHandler.post { listener?.onError(msg) }
    }

    private fun unpackAssetModel(context: Context, assetDir: String): String {
        val dest = File(context.filesDir, "vosk/$assetDir")
        val ready = File(dest, ".ready")
        val conf = File(dest, "conf/model.conf")
        val mdl = File(dest, "am/final.mdl")
        if (ready.exists() && (conf.exists() || mdl.exists())) {
            return dest.absolutePath
        }
        if (dest.exists()) {
            dest.deleteRecursively()
        }
        dest.mkdirs()
        val listed = context.assets.list(assetDir)
        if (listed.isNullOrEmpty()) {
            throw IOException("Asset folder missing: $assetDir")
        }
        copyAssetFolder(context, assetDir, dest)
        if (!File(dest, "conf/model.conf").exists() && !File(dest, "am/final.mdl").exists()) {
            throw IOException("Unpacked model is incomplete")
        }
        ready.writeText("ok")
        return dest.absolutePath
    }

    private fun copyAssetFolder(context: Context, assetDir: String, dest: File) {
        dest.mkdirs()
        val names = context.assets.list(assetDir) ?: return
        for (name in names) {
            val path = "$assetDir/$name"
            val children = context.assets.list(path)
            if (children.isNullOrEmpty()) {
                context.assets.open(path).use { input ->
                    FileOutputStream(File(dest, name)).use { output ->
                        input.copyTo(output)
                    }
                }
            } else {
                copyAssetFolder(context, path, File(dest, name))
            }
        }
    }

    private fun extractText(json: String?, key: String): String {
        if (json.isNullOrBlank()) return ""
        return try {
            JSONObject(json).optString(key, "").trim()
        } catch (_: Exception) {
            ""
        }
    }
}
