package com.offlinevoicetyping.offline_voice_typing

import android.Manifest
import android.content.Intent
import android.content.pm.PackageManager
import android.inputmethodservice.InputMethodService
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.speech.RecognitionListener
import android.speech.RecognizerIntent
import android.speech.SpeechRecognizer
import android.view.View
import android.view.inputmethod.EditorInfo
import android.widget.Button
import android.widget.ImageButton
import android.widget.LinearLayout
import android.widget.TextView
import android.widget.Toast
import androidx.core.content.ContextCompat
import java.util.Locale

/**
 * کیبورد تایپ صوتی سیستم — در لیست کیبوردهای گوشی ظاهر می‌شود.
 * با دکمه میکروفون صحبت می‌کنید و متن داخل هر فیلد درج می‌شود.
 */
class VoiceTypingIME : InputMethodService() {

    private var speechRecognizer: SpeechRecognizer? = null
    private var isListening = false
    private var statusText: TextView? = null
    private var micButton: ImageButton? = null
    private var languageFa = true
    private val mainHandler = Handler(Looper.getMainLooper())

    override fun onCreateInputView(): View {
        val view = layoutInflater.inflate(R.layout.ime_keyboard, null)

        statusText = view.findViewById(R.id.ime_status)
        micButton = view.findViewById(R.id.ime_mic)
        val btnSpace = view.findViewById<Button>(R.id.ime_space)
        val btnDelete = view.findViewById<Button>(R.id.ime_delete)
        val btnEnter = view.findViewById<Button>(R.id.ime_enter)
        val btnLang = view.findViewById<Button>(R.id.ime_lang)
        val btnSettings = view.findViewById<Button>(R.id.ime_settings)

        micButton?.setOnClickListener { toggleListening() }
        btnSpace?.setOnClickListener { currentInputConnection?.commitText(" ", 1) }
        btnDelete?.setOnClickListener {
            currentInputConnection?.deleteSurroundingText(1, 0)
        }
        btnEnter?.setOnClickListener {
            currentInputConnection?.performEditorAction(EditorInfo.IME_ACTION_DONE)
                ?: currentInputConnection?.commitText("\n", 1)
        }
        btnLang?.setOnClickListener {
            languageFa = !languageFa
            btnLang.text = if (languageFa) "FA" else "EN"
            statusText?.text = if (languageFa) "زبان: فارسی" else "Language: English"
        }
        btnSettings?.setOnClickListener {
            try {
                val i = Intent(this, MainActivity::class.java)
                i.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                startActivity(i)
            } catch (_: Exception) {}
        }

        statusText?.text = "آماده — میکروفون را بزنید"
        return view
    }

    private fun toggleListening() {
        if (isListening) {
            stopListening()
        } else {
            startListening()
        }
    }

    private fun startListening() {
        if (ContextCompat.checkSelfPermission(this, Manifest.permission.RECORD_AUDIO)
            != PackageManager.PERMISSION_GRANTED
        ) {
            statusText?.text = "مجوز میکروفون لازم است — اپ را باز کنید"
            Toast.makeText(this, "ابتدا اپ را باز کنید و مجوز میکروفون بدهید", Toast.LENGTH_LONG).show()
            try {
                val i = Intent(this, MainActivity::class.java)
                i.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                startActivity(i)
            } catch (_: Exception) {}
            return
        }

        if (!SpeechRecognizer.isRecognitionAvailable(this)) {
            statusText?.text = "تشخیص گفتار سیستم در دسترس نیست"
            // هنوز امکان درج دستی با دکمه‌ها هست
            return
        }

        try {
            speechRecognizer?.destroy()
            speechRecognizer = SpeechRecognizer.createSpeechRecognizer(this)
            speechRecognizer?.setRecognitionListener(object : RecognitionListener {
                override fun onReadyForSpeech(params: Bundle?) {
                    statusText?.text = if (languageFa) "گوش می‌دهم..." else "Listening..."
                }

                override fun onBeginningOfSpeech() {}
                override fun onRmsChanged(rmsdB: Float) {}
                override fun onBufferReceived(buffer: ByteArray?) {}
                override fun onPartialResults(partialResults: Bundle?) {
                    val matches = partialResults?.getStringArrayList(SpeechRecognizer.RESULTS_RECOGNITION)
                    val text = matches?.firstOrNull()
                    if (!text.isNullOrBlank()) {
                        statusText?.text = text
                    }
                }

                override fun onResults(results: Bundle?) {
                    val matches = results?.getStringArrayList(SpeechRecognizer.RESULTS_RECOGNITION)
                    val text = matches?.firstOrNull()?.trim()
                    if (!text.isNullOrBlank()) {
                        currentInputConnection?.commitText("$text ", 1)
                        statusText?.text = if (languageFa) "ثبت شد ✓" else "Committed ✓"
                    } else {
                        statusText?.text = if (languageFa) "چیزی شنیده نشد" else "No speech"
                    }
                    isListening = false
                    updateMicUi()
                }

                override fun onError(error: Int) {
                    statusText?.text = when (error) {
                        SpeechRecognizer.ERROR_NO_MATCH -> if (languageFa) "تشخیص نشد" else "No match"
                        SpeechRecognizer.ERROR_SPEECH_TIMEOUT -> if (languageFa) "زمان تمام" else "Timeout"
                        SpeechRecognizer.ERROR_INSUFFICIENT_PERMISSIONS -> "مجوز میکروفون"
                        else -> if (languageFa) "خطا ($error)" else "Error ($error)"
                    }
                    isListening = false
                    updateMicUi()
                }

                override fun onEndOfSpeech() {
                    statusText?.text = if (languageFa) "در حال پردازش..." else "Processing..."
                }

                override fun onEvent(eventType: Int, params: Bundle?) {}
            })

            val intent = Intent(RecognizerIntent.ACTION_RECOGNIZE_SPEECH).apply {
                putExtra(RecognizerIntent.EXTRA_LANGUAGE_MODEL, RecognizerIntent.LANGUAGE_MODEL_FREE_FORM)
                putExtra(
                    RecognizerIntent.EXTRA_LANGUAGE,
                    if (languageFa) "fa-IR" else Locale.US.toLanguageTag()
                )
                putExtra(RecognizerIntent.EXTRA_PARTIAL_RESULTS, true)
                putExtra(RecognizerIntent.EXTRA_MAX_RESULTS, 3)
            }

            isListening = true
            updateMicUi()
            speechRecognizer?.startListening(intent)
        } catch (e: Exception) {
            statusText?.text = "خطا: ${e.message}"
            isListening = false
            updateMicUi()
        }
    }

    private fun stopListening() {
        try {
            speechRecognizer?.stopListening()
        } catch (_: Exception) {}
        isListening = false
        updateMicUi()
        statusText?.text = if (languageFa) "آماده" else "Ready"
    }

    private fun updateMicUi() {
        mainHandler.post {
            micButton?.alpha = if (isListening) 1f else 0.9f
            micButton?.isSelected = isListening
        }
    }

    override fun onDestroy() {
        try {
            speechRecognizer?.destroy()
        } catch (_: Exception) {}
        speechRecognizer = null
        super.onDestroy()
    }
}
