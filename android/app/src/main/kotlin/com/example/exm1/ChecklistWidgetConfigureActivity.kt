package com.example.exm1

import android.app.Activity
import android.app.AlertDialog
import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.Intent
import android.os.Bundle
import org.json.JSONArray

class ChecklistWidgetConfigureActivity : Activity() {
    private var widgetId = AppWidgetManager.INVALID_APPWIDGET_ID

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        widgetId = intent?.getIntExtra(
            AppWidgetManager.EXTRA_APPWIDGET_ID,
            AppWidgetManager.INVALID_APPWIDGET_ID
        ) ?: AppWidgetManager.INVALID_APPWIDGET_ID
        if (widgetId == AppWidgetManager.INVALID_APPWIDGET_ID) {
            setResult(RESULT_CANCELED)
            finish()
            return
        }

        val prefs = getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
        val raw = prefs.getString("flutter.boards", "[]") ?: "[]"
        val ids = ArrayList<String>()
        val names = ArrayList<String>()
        try {
            val boards = JSONArray(raw)
            for (i in 0 until boards.length()) {
                val board = boards.optJSONObject(i) ?: continue
                ids.add(board.optString("id"))
                names.add(board.optString("title", "چک‌لیست"))
            }
        } catch (_: Exception) { }

        if (names.isEmpty()) {
            AlertDialog.Builder(this)
                .setTitle("ویجت چک‌لیست")
                .setMessage("هنوز چک‌لیستی وجود ندارد. ابتدا در برنامه یک چک‌لیست بساز.")
                .setPositiveButton("باشه") { _, _ ->
                    setResult(RESULT_CANCELED)
                    finish()
                }
                .setOnCancelListener {
                    setResult(RESULT_CANCELED)
                    finish()
                }
                .show()
            return
        }

        AlertDialog.Builder(this)
            .setTitle("انتخاب چک‌لیست برای ویجت")
            .setItems(names.toTypedArray()) { _, which ->
                getSharedPreferences("APPCHEK_WIDGETS", Context.MODE_PRIVATE)
                    .edit().putString("board_$widgetId", ids[which]).apply()
                val result = Intent().putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, widgetId)
                setResult(RESULT_OK, result)
                ChecklistWidgetProvider.refreshAll(this)
                finish()
            }
            .setOnCancelListener {
                setResult(RESULT_CANCELED)
                finish()
            }
            .show()
    }
}
