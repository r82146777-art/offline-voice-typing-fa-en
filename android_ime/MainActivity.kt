package com.offlinevoicetyping.offline_voice_typing

import android.os.Handler
import android.os.Looper
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val methodChannelName = "offline_voice_typing/vosk"
    private val eventChannelName = "offline_voice_typing/vosk_events"
    private val mainHandler = Handler(Looper.getMainLooper())
    private var eventSink: EventChannel.EventSink? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        EventChannel(flutterEngine.dartExecutor.binaryMessenger, eventChannelName)
            .setStreamHandler(object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    eventSink = events
                }

                override fun onCancel(arguments: Any?) {
                    eventSink = null
                }
            })

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, methodChannelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "prepare" -> {
                        val lang = call.argument<String>("lang") ?: "fa"
                        Thread {
                            val ok = VoskEngine.prepare(applicationContext, lang)
                            mainHandler.post { result.success(ok) }
                        }.start()
                    }
                    "start" -> {
                        val lang = call.argument<String>("lang") ?: "fa"
                        VoskEngine.setListener(object : VoskEngine.Listener {
                            override fun onPartial(text: String) {
                                mainHandler.post {
                                    eventSink?.success(mapOf("type" to "partial", "text" to text))
                                }
                            }

                            override fun onFinal(text: String) {
                                mainHandler.post {
                                    eventSink?.success(mapOf("type" to "final", "text" to text))
                                }
                            }

                            override fun onError(message: String) {
                                mainHandler.post {
                                    eventSink?.success(mapOf("type" to "error", "text" to message))
                                }
                            }

                            override fun onStatus(status: String) {
                                mainHandler.post {
                                    eventSink?.success(mapOf("type" to "status", "text" to status))
                                }
                            }
                        })
                        Thread {
                            VoskEngine.startListening(applicationContext, lang)
                            mainHandler.post { result.success(true) }
                        }.start()
                    }
                    "stop" -> {
                        Thread {
                            VoskEngine.stopListening()
                            mainHandler.post { result.success(true) }
                        }.start()
                    }
                    "isListening" -> {
                        result.success(VoskEngine.isListening())
                    }
                    else -> result.notImplemented()
                }
            }
    }

    override fun onDestroy() {
        try {
            VoskEngine.stopListening()
        } catch (_: Exception) {
        }
        super.onDestroy()
    }
}
