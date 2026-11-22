package com.example.exm1

import android.content.Intent
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterFragmentActivity() {
    private var widgetLaunchPending = false
    private var widgetChannel: MethodChannel? = null
    private val channelName = "checklist_widget"
    private val openWidgetAction = "com.example.exm1.OPEN_CHECKLIST_WIDGET"
    private val updateWidgetAction = "com.example.exm1.UPDATE_CHECKLIST_WIDGET"

    override fun onCreate(savedInstanceState: android.os.Bundle?) {
        super.onCreate(savedInstanceState)
        widgetLaunchPending = intent?.action == openWidgetAction
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        if (intent.action == openWidgetAction) {
            widgetLaunchPending = true
            widgetChannel?.invokeMethod("widgetOpened", null)
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        widgetChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
        widgetChannel?.setMethodCallHandler { call, result ->
                when (call.method) {
                    "consumeWidgetLaunch" -> {
                        val pending = widgetLaunchPending
                        widgetLaunchPending = false
                        result.success(pending)
                    }
                    "updateWidget" -> {
                        val title = call.argument<String>("title") ?: "چک‌لیستی انتخاب نشده"
                        val items = call.argument<List<String>>("items") ?: emptyList()
                        val backgroundColor = call.argument<Int>("backgroundColor") ?: 0xFF202124.toInt()
                        val fontFamily = call.argument<String>("fontFamily") ?: "sans"
                        sendBroadcast(Intent(this, ChecklistHomeWidgetProvider::class.java).apply {
                            action = updateWidgetAction
                            putExtra("title", title)
                            putStringArrayListExtra("items", ArrayList(items))
                            putExtra("backgroundColor", backgroundColor)
                            putExtra("fontFamily", fontFamily)
                        })
                        result.success(true)
                    }
                    else -> result.notImplemented()
                }
            }
    }
}
