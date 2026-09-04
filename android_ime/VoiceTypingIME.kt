package com.offlinevoicetyping.offline_voice_typing

import android.Manifest
import android.content.Intent
import android.content.pm.PackageManager
import android.inputmethodservice.InputMethodService
import android.os.Handler
import android.os.Looper
import android.view.View
import android.view.inputmethod.EditorInfo
import android.widget.Button
import android.widget.ImageButton
import android.widget.TextView
import android.widget.Toast
import androidx.core.content.ContextCompat

/** Offline IME. Does not init Vosk until the user taps the mic. */
class VoiceTypingIME : InputMethodService() {

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
            val ic = currentInputConnection
            if (ic != null) {
                if (!ic.performEditorAction(EditorInfo.IME_ACTION_DONE)) {
                    ic.commitText("\n", 1)
                }
            }
        }
        btnLang?.setOnClickListener {
            languageFa = !languageFa
            btnLang.text = if (languageFa) "FA" else "EN"
            statusText?.text =
                if (languageFa) "فارسی آفلاین — میکروفون را بزنید"
                else "English offline — tap mic"
        }
        btnSettings?.setOnClickListener {
            try {
                val i = Intent(this, MainActivity::class.java)
                i.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                startActivity(i)
            } catch (_: Exception) {
            }
        }

        statusText?.text = "کیبورد آفلاین — میکروفون را بزنید"
        return view
    }

    private fun toggleListening() {
        try {
            if (VoskEngine.isListening()) {
                stopListening()
            } else {
                startListening()
            }
        } catch (t: Throwable) {
            statusText?.text = "خطا: ${t.message}"
        }
    }

    private fun startListening() {
        if (ContextCompat.checkSelfPermission(this, Manifest.permission.RECORD_AUDIO)
            != PackageManager.PERMISSION_GRANTED
        ) {
            statusText?.text = "مجوز میکروفون لازم است — اپ را باز کنید"
            Toast.makeText(
                this,
                "ابتدا اپ تایپ صوتی آفلاین را باز کنید و مجوز میکروفون بدهید",
                Toast.LENGTH_LONG
            ).show()
            try {
                val i = Intent(this, MainActivity::class.java)
                i.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                startActivity(i)
            } catch (_: Exception) {
            }
            return
        }

        statusText?.text = "در حال آماده‌سازی مدل آفلاین..."
        VoskEngine.setListener(object : VoskEngine.Listener {
            override fun onPartial(text: String) {
                mainHandler.post { statusText?.text = text }
            }

            override fun onFinal(text: String) {
                mainHandler.post {
                    if (text.isNotBlank()) {
                        currentInputConnection?.commitText("$text ", 1)
                        statusText?.text = "ثبت شد (آفلاین)"
                    }
                }
            }

            override fun onError(message: String) {
                mainHandler.post { statusText?.text = message }
            }

            override fun onStatus(status: String) {
                mainHandler.post {
                    if (status == "listening") {
                        statusText?.text =
                            if (languageFa) "گوش می‌دهم — آفلاین"
                            else "Listening — offline"
                        micButton?.isSelected = true
                    } else {
                        micButton?.isSelected = false
                    }
                }
            }
        })

        Thread({
            try {
                VoskEngine.startListening(
                    applicationContext,
                    if (languageFa) "fa" else "en"
                )
            } catch (t: Throwable) {
                mainHandler.post {
                    statusText?.text = "خطا: ${t.message}"
                }
            }
        }, "ime-vosk").start()
    }

    private fun stopListening() {
        try {
            VoskEngine.stopListening()
        } catch (_: Throwable) {
        }
        statusText?.text =
            if (languageFa) "آماده — آفلاین" else "Ready — offline"
        micButton?.isSelected = false
    }

    override fun onDestroy() {
        try {
            VoskEngine.stopListening()
        } catch (_: Throwable) {
        }
        super.onDestroy()
    }
}
