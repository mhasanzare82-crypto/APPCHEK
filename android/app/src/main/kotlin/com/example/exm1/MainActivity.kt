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

    override fun onCreate(savedInstanceState: android.os.Bundle?) {
        super.onCreate(savedInstanceState)
        widgetLaunchPending = intent?.action == openWidgetAction
    }

    override fun onResume() {
        super.onResume()
        val selected = getSharedPreferences("FlutterSharedPreferences", MODE_PRIVATE)
            .getString("flutter.selectedWidgetBoardId", null)
        if (!selected.isNullOrBlank()) {
            widgetChannel?.invokeMethod("widgetChecklistSelected", selected)
        }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        if (intent.action == openWidgetAction) {
            // Send a single event if Flutter is already active. Otherwise leave it
            // pending for Flutter to consume after its widget handler is installed.
            val channel = widgetChannel
            if (channel != null) {
                channel.invokeMethod("widgetOpened", null)
            } else {
                widgetLaunchPending = true
            }
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
                    val selectedBoardId = call.argument<String>("selectedBoardId") ?: ""
                    val boardsJson = call.argument<String>("boardsJson") ?: "[]"
                    ChecklistHomeWidgetProvider.saveBoardsSnapshot(this, boardsJson, selectedBoardId)
                    ChecklistHomeWidgetProvider.saveAndRefresh(
                        context = this,
                        title = title,
                        items = items,
                        backgroundColor = backgroundColor,
                        fontFamily = fontFamily
                    )
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }
    }
}
