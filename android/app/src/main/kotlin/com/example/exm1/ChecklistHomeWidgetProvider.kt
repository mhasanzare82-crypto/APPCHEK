package com.example.exm1

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.graphics.Color
import android.widget.RemoteViews

class ChecklistHomeWidgetProvider : AppWidgetProvider() {
    companion object {
        private const val PREFS = "checklist_home_widget"
        private const val OPEN_ACTION = "com.example.exm1.OPEN_CHECKLIST_WIDGET"
        private const val UPDATE_ACTION = "com.example.exm1.UPDATE_CHECKLIST_WIDGET"

        fun render(context: Context, manager: AppWidgetManager, widgetId: Int) {
            val prefs = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
            val views = RemoteViews(context.packageName, R.layout.checklist_home_widget)
            views.setTextViewText(R.id.widget_title, prefs.getString("title", "چک‌لیست‌های من"))
            val items = prefs.getString("items", "") ?: ""
            views.setTextViewText(R.id.widget_content, if (items.isBlank()) "این چک‌لیست هنوز موردی ندارد" else items)
            views.setInt(R.id.widget_root, "setBackgroundColor", prefs.getInt("backgroundColor", 0xFF202124.toInt()))
            val fontStyle = when (prefs.getString("fontFamily", "sans")) {
                "serif" -> R.style.WidgetChecklistSerif
                "mono" -> R.style.WidgetChecklistMono
                else -> R.style.WidgetChecklistSans
            }
            views.setInt(R.id.widget_content, "setTextAppearance", fontStyle)
            views.setInt(R.id.widget_title, "setTextAppearance", R.style.WidgetChecklistTitle)
            val intent = Intent(context, MainActivity::class.java).apply {
                action = OPEN_ACTION
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP or Intent.FLAG_ACTIVITY_SINGLE_TOP
            }
            val pending = PendingIntent.getActivity(context, 7102, intent, PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)
            views.setOnClickPendingIntent(R.id.widget_root, pending)
            manager.updateAppWidget(widgetId, views)
        }
    }

    override fun onReceive(context: Context, intent: Intent) {
        super.onReceive(context, intent)
        if (intent.action == UPDATE_ACTION) {
            val title = intent.getStringExtra("title") ?: "چک‌لیستی انتخاب نشده"
            val items = intent.getStringArrayListExtra("items") ?: arrayListOf()
            context.getSharedPreferences(PREFS, Context.MODE_PRIVATE).edit()
                .putString("title", title)
                .putString("items", items.joinToString("\n"))
                .putInt("backgroundColor", intent.getIntExtra("backgroundColor", 0xFF202124.toInt()))
                .putString("fontFamily", intent.getStringExtra("fontFamily") ?: "sans")
                .apply()
            val manager = AppWidgetManager.getInstance(context)
            val ids = manager.getAppWidgetIds(ComponentName(context, ChecklistHomeWidgetProvider::class.java))
            ids.forEach { render(context, manager, it) }
        }
    }

    override fun onUpdate(context: Context, manager: AppWidgetManager, ids: IntArray) {
        ids.forEach { render(context, manager, it) }
    }
}
