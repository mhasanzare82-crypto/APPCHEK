package com.example.exm1

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.widget.RemoteViews
import org.json.JSONArray
import kotlin.random.Random

class ChecklistWidgetProvider : AppWidgetProvider() {
    override fun onUpdate(context: Context, manager: AppWidgetManager, ids: IntArray) {
        ids.forEach { updateWidget(context, manager, it) }
    }

    companion object {
        const val ACTION_REFRESH = "com.example.exm1.CHECKLIST_WIDGET_REFRESH"

        fun refreshAll(context: Context) {
            val manager = AppWidgetManager.getInstance(context)
            val component = ComponentName(context, ChecklistWidgetProvider::class.java)
            manager.getAppWidgetIds(component).forEach { updateWidget(context, manager, it) }
        }

        private fun updateWidget(context: Context, manager: AppWidgetManager, widgetId: Int) {
            val flutterPrefs = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
            val raw = flutterPrefs.getString("flutter.boards", "[]") ?: "[]"
            var heading = "ویجت چک‌لیست"
            var content = "از منوی سه‌نقطه چک‌لیست‌ها، گزینه «نمایش در ویجت» را برای چند چک‌لیست فعال کن."
            try {
                val boards = JSONArray(raw)
                val eligible = ArrayList<org.json.JSONObject>()
                for (i in 0 until boards.length()) {
                    val board = boards.optJSONObject(i) ?: continue
                    if (board.optBoolean("showInWidget", false)) eligible.add(board)
                }
                if (eligible.isNotEmpty()) {
                    val selected = eligible[Random.nextInt(eligible.size)]
                    heading = selected.optString("title", "چک‌لیست")
                    val items = selected.optJSONArray("items") ?: JSONArray()
                    val lines = ArrayList<String>()
                    for (j in 0 until items.length()) {
                        val item = items.optJSONObject(j)
                        val text = item?.optString("text", "")?.trim().orEmpty()
                        if (text.isNotEmpty()) lines.add("• $text")
                    }
                    content = if (lines.isEmpty()) "این چک‌لیست موردی ندارد." else lines.joinToString("\n")
                }
            } catch (_: Exception) {
                content = "برای نمایش چک‌لیست، برنامه را باز و دوباره ذخیره کن."
            }

            val views = RemoteViews(context.packageName, R.layout.checklist_widget)
            views.setTextViewText(R.id.widget_title, heading)
            views.setTextViewText(R.id.widget_items, content)
            val launchIntent = context.packageManager.getLaunchIntentForPackage(context.packageName)?.apply {
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
            }
            if (launchIntent != null) {
                val pending = PendingIntent.getActivity(
                    context, widgetId, launchIntent,
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                )
                views.setOnClickPendingIntent(R.id.widget_root, pending)
            }
            manager.updateAppWidget(widgetId, views)
        }
    }
}
