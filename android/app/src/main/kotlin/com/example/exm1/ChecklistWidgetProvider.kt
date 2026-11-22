package com.example.exm1

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.text.SpannableString
import android.text.Spanned
import android.text.style.TypefaceSpan
import android.util.TypedValue
import android.widget.RemoteViews
import org.json.JSONArray

class ChecklistWidgetProvider : AppWidgetProvider() {
    override fun onUpdate(context: Context, manager: AppWidgetManager, ids: IntArray) {
        ids.forEach { id ->
            try {
                updateWidget(context, manager, id)
            } catch (error: Throwable) {
                android.util.Log.e("ChecklistWidget", "Widget update failed for id=$id", error)
                // Keep malformed preferences from crashing the launcher broadcast.
            }
        }
    }

    companion object {
        const val ACTION_REFRESH = "com.example.exm1.CHECKLIST_WIDGET_REFRESH"

        fun refreshAll(context: Context) {
            val manager = AppWidgetManager.getInstance(context)
            val component = ComponentName(context, ChecklistWidgetProvider::class.java)
            manager.getAppWidgetIds(component).forEach { updateWidget(context, manager, it) }
        }

        /**
         * Flutter's SharedPreferences Android implementation stores Dart int values as Long.
         * Reading those entries with SharedPreferences.getInt() throws ClassCastException,
         * which can crash the launcher/app while the widget is first being created.
         * Read numeric values through Number instead to support Flutter's stored types safely.
         */
        private fun numberPref(
            prefs: android.content.SharedPreferences,
            key: String,
            defaultValue: Number
        ): Number = (prefs.all[key] as? Number) ?: defaultValue

        private fun stringPref(
            prefs: android.content.SharedPreferences,
            key: String,
            defaultValue: String
        ): String = prefs.all[key] as? String ?: defaultValue

        private fun updateWidget(context: Context, manager: AppWidgetManager, widgetId: Int) {
            val flutterPrefs = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
            val raw = stringPref(flutterPrefs, "flutter.boards", "[]")
            val widgetPrefs = context.getSharedPreferences("APPCHEK_WIDGETS", Context.MODE_PRIVATE)
            val selectedBoardId = widgetPrefs.all["board_$widgetId"] as? String
            val backgroundColor = numberPref(flutterPrefs, "flutter.widgetBgColor", 0xFF6658D3.toLong()).toLong().toInt()
            val textColor = numberPref(flutterPrefs, "flutter.widgetTextColor", 0xFFFFFFFFL).toLong().toInt()
            val fontSize = numberPref(flutterPrefs, "flutter.widgetFontSize", 14f).toFloat()
            val fontFamily = stringPref(flutterPrefs, "flutter.widgetFontFamily", "sans-serif")

            var heading = "انتخاب چک‌لیست"
            var content = "برای انتخاب چک‌لیست، ویجت را لمس کن."
            try {
                val boards = JSONArray(raw)
                var selected: org.json.JSONObject? = null
                if (selectedBoardId != null) {
                    for (i in 0 until boards.length()) {
                        val board = boards.optJSONObject(i) ?: continue
                        if (board.optString("id") == selectedBoardId) {
                            selected = board
                            break
                        }
                    }
                }

                if (selected != null) {
                    heading = selected.optString("title", "چک‌لیست")
                    val items = selected.optJSONArray("items") ?: JSONArray()
                    val lines = ArrayList<String>()
                    for (j in 0 until items.length()) {
                        val item = items.optJSONObject(j)
                        val text = item?.optString("text", "")?.trim().orEmpty()
                        if (text.isNotEmpty()) lines.add("• $text")
                    }
                    content = if (lines.isEmpty()) "این چک‌لیست موردی ندارد." else lines.joinToString("\n")
                } else if (selectedBoardId != null) {
                    content = "چک‌لیست انتخاب‌شده پیدا نشد. برای انتخاب دوباره لمس کن."
                } else if (boards.length() == 0) {
                    content = "ابتدا در برنامه یک چک‌لیست بساز، سپس ویجت را لمس کن."
                }
            } catch (_: Exception) {
                content = "برای نمایش چک‌لیست، برنامه را باز و دوباره ذخیره کن."
            }

            val views = RemoteViews(context.packageName, R.layout.checklist_widget)
            views.setInt(R.id.widget_root, "setBackgroundColor", backgroundColor)
            val titleText = SpannableString(heading).apply {
                setSpan(TypefaceSpan(fontFamily), 0, length, Spanned.SPAN_EXCLUSIVE_EXCLUSIVE)
            }
            val itemsText = SpannableString(content).apply {
                setSpan(TypefaceSpan(fontFamily), 0, length, Spanned.SPAN_EXCLUSIVE_EXCLUSIVE)
            }
            views.setTextViewText(R.id.widget_title, titleText)
            views.setTextViewText(R.id.widget_items, itemsText)
            views.setTextColor(R.id.widget_title, textColor)
            views.setTextColor(R.id.widget_items, textColor)
            views.setTextViewTextSize(R.id.widget_title, TypedValue.COMPLEX_UNIT_SP, fontSize + 2f)
            views.setTextViewTextSize(R.id.widget_items, TypedValue.COMPLEX_UNIT_SP, fontSize)

            // Tapping the widget opens the checklist picker, not the app home screen.
            val pickerIntent = Intent(context, ChecklistWidgetConfigureActivity::class.java).apply {
                putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, widgetId)
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
            }
            val pending = PendingIntent.getActivity(
                context,
                widgetId,
                pickerIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            views.setOnClickPendingIntent(R.id.widget_root, pending)
            manager.updateAppWidget(widgetId, views)
        }
    }
}
