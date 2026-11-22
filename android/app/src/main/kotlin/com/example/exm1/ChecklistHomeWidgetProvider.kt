package com.example.exm1

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.view.View
import android.widget.RemoteViews

class ChecklistHomeWidgetProvider : AppWidgetProvider() {
    companion object {
        private const val PREFS = "checklist_home_widget"
        private const val OPEN_ACTION = "com.example.exm1.OPEN_CHECKLIST_WIDGET"

        /** Save data before refreshing so new widget instances render the same state. */
        fun saveAndRefresh(
            context: Context,
            title: String,
            items: List<String>,
            backgroundColor: Int,
            fontFamily: String
        ) {
            context.getSharedPreferences(PREFS, Context.MODE_PRIVATE).edit()
                .putString("title", title)
                .putString("items", items.joinToString("\n"))
                .putInt("backgroundColor", backgroundColor)
                .putString("fontFamily", fontFamily)
                .commit()

            val manager = AppWidgetManager.getInstance(context)
            val ids = manager.getAppWidgetIds(
                ComponentName(context, ChecklistHomeWidgetProvider::class.java)
            )
            ids.forEach { render(context, manager, it) }
        }

        fun render(context: Context, manager: AppWidgetManager, widgetId: Int) {
            val prefs = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
            val views = RemoteViews(context.packageName, R.layout.checklist_home_widget)

            val title = prefs.getString("title", "چک‌لیست‌های من") ?: "چک‌لیست‌های من"
            val items = prefs.getString("items", "") ?: ""
            val content = if (items.isBlank()) "این چک‌لیست هنوز موردی ندارد" else items
            views.setTextViewText(R.id.widget_title, title)

            val fontFamily = prefs.getString("fontFamily", "sans") ?: "sans"
            val visibleContentId = when (fontFamily) {
                "serif" -> R.id.widget_content_serif
                "mono" -> R.id.widget_content_mono
                else -> R.id.widget_content_sans
            }

            views.setTextViewText(R.id.widget_content_sans, content)
            views.setTextViewText(R.id.widget_content_serif, content)
            views.setTextViewText(R.id.widget_content_mono, content)
            views.setViewVisibility(
                R.id.widget_content_sans,
                if (visibleContentId == R.id.widget_content_sans) View.VISIBLE else View.GONE
            )
            views.setViewVisibility(
                R.id.widget_content_serif,
                if (visibleContentId == R.id.widget_content_serif) View.VISIBLE else View.GONE
            )
            views.setViewVisibility(
                R.id.widget_content_mono,
                if (visibleContentId == R.id.widget_content_mono) View.VISIBLE else View.GONE
            )

            val backgroundColor = prefs.getInt("backgroundColor", 0xFF202124.toInt())
            views.setInt(R.id.widget_root, "setBackgroundColor", backgroundColor)

            val intent = Intent(context, MainActivity::class.java).apply {
                action = OPEN_ACTION
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or
                    Intent.FLAG_ACTIVITY_CLEAR_TOP or
                    Intent.FLAG_ACTIVITY_SINGLE_TOP
            }
            val pending = PendingIntent.getActivity(
                context,
                7102,
                intent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            views.setOnClickPendingIntent(R.id.widget_root, pending)
            manager.updateAppWidget(widgetId, views)
        }
    }

    override fun onUpdate(context: Context, manager: AppWidgetManager, ids: IntArray) {
        ids.forEach { render(context, manager, it) }
    }
}
