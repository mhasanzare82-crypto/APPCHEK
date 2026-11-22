package com.example.exm1

import android.content.Context
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterFragmentActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "appchek/checklist_widget")
            .setMethodCallHandler { call, result ->
                if (call.method == "refreshWidgets") {
                    ChecklistWidgetProvider.refreshAll(applicationContext)
                    result.success(null)
                } else {
                    result.notImplemented()
                }
            }
    }
}
