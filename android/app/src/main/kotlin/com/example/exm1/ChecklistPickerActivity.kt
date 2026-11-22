package com.example.exm1

import android.app.Activity
import android.app.AlertDialog
import android.graphics.Color
import android.graphics.Typeface
import android.graphics.drawable.GradientDrawable
import android.os.Bundle
import android.view.View
import android.view.ViewGroup
import android.view.WindowManager
import android.widget.ArrayAdapter
import android.widget.TextView
import org.json.JSONArray
import org.json.JSONObject

class ChecklistPickerActivity : Activity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        window?.setBackgroundDrawableResource(android.R.color.transparent)
        window?.addFlags(WindowManager.LayoutParams.FLAG_DIM_BEHIND)
        window?.attributes = window?.attributes?.apply { dimAmount = 0.4f }

        val widgetPrefs = getSharedPreferences("checklist_home_widget", MODE_PRIVATE)
        val boards = readBoardsSnapshot(widgetPrefs.getString("boardsJson", null))

        val labels = ArrayList<String>()
        val candidates = ArrayList<JSONObject>()
        for (index in 0 until boards.length()) {
            val board = boards.optJSONObject(index) ?: continue
            val title = board.optString("title", "").trim()
            if (title.isNotEmpty()) {
                labels.add(title)
                candidates.add(board)
            }
        }

        // The picker intentionally has no heading or item counts.
        // Compact dark rows with white text keep checklist names readable.
        val builder = AlertDialog.Builder(this)
            .setNegativeButton("بستن") { _, _ -> finish() }

        if (labels.isEmpty()) {
            builder.setMessage("هنوز چک‌لیستی ساخته نشده است.")
        } else {
            builder.setAdapter(
                object : ArrayAdapter<String>(this, android.R.layout.simple_list_item_1, labels) {
                    override fun getView(position: Int, convertView: View?, parent: ViewGroup): View {
                        val row = (convertView as? TextView) ?: TextView(this@ChecklistPickerActivity)
                        row.text = getItem(position)
                        row.setTextColor(Color.WHITE)
                        row.textSize = 14f
                        row.typeface = Typeface.create("sans-serif-medium", Typeface.NORMAL)
                        row.textDirection = View.TEXT_DIRECTION_FIRST_STRONG
                        row.setPadding(dp(12), dp(7), dp(12), dp(7))
                        row.minHeight = dp(36)

                        row.background = GradientDrawable().apply {
                            setColor(Color.rgb(38, 54, 75))
                            cornerRadius = dp(8).toFloat()
                        }
                        row.layoutParams = AbsListViewLayoutParams(
                            ViewGroup.LayoutParams.MATCH_PARENT,
                            ViewGroup.LayoutParams.WRAP_CONTENT
                        )
                        return row
                    }
                }
            ) { _, index ->
                val board = candidates[index]
                val rawItems = board.optJSONArray("items") ?: JSONArray()
                val output = ArrayList<String>()

                for (itemIndex in 0 until rawItems.length()) {
                    val item = rawItems.optJSONObject(itemIndex)
                    if (item != null) {
                        val text = item.optString("text", "").trim()
                        if (text.isNotEmpty()) {
                            val mark = if (item.optBoolean("done", false)) "✓" else "•"
                            val description = item.optString("description", "").trim()
                            output.add("$mark $text${if (description.isEmpty()) "" else " — $description"}")
                        }
                    } else {
                        val text = rawItems.optString(itemIndex, "").trim()
                        if (text.isNotEmpty()) {
                            output.add(if (text.startsWith("✓") || text.startsWith("•")) text else "• $text")
                        }
                    }
                }

                val selectedId = board.optString("id", "")
                widgetPrefs.edit().putString("selectedBoardId", selectedId).commit()
                getSharedPreferences("FlutterSharedPreferences", MODE_PRIVATE)
                    .edit()
                    .putString("flutter.selectedWidgetBoardId", selectedId)
                    .apply()

                ChecklistHomeWidgetProvider.showBoard(
                    this,
                    board.optString("title", "چک‌لیست"),
                    output
                )
                finish()
            }
        }

        val dialog = builder.create()
        dialog.setOnDismissListener {
            if (!isFinishing) finish()
        }
        dialog.show()
        dialog.window?.setBackgroundDrawableResource(android.R.color.white)
        dialog.window?.setLayout(
            (resources.displayMetrics.widthPixels * 0.76f).toInt(),
            WindowManager.LayoutParams.WRAP_CONTENT
        )
    }

    private fun dp(value: Int): Int =
        (value * resources.displayMetrics.density).toInt()

    private fun readBoardsSnapshot(nativeSnapshot: String?): JSONArray {
        val nativeBoards = parseBoards(nativeSnapshot)
        if (nativeBoards.length() > 0) return nativeBoards

        val flutterSnapshot = getSharedPreferences(
            "FlutterSharedPreferences",
            MODE_PRIVATE
        ).getString("flutter.boards", null)
        return parseBoards(flutterSnapshot)
    }

    private fun parseBoards(raw: String?): JSONArray {
        if (raw.isNullOrBlank()) return JSONArray()
        return try {
            val parsed = org.json.JSONTokener(raw).nextValue()
            when (parsed) {
                is JSONArray -> parsed
                is JSONObject -> parsed.optJSONArray("boards")
                    ?: parsed.optJSONArray("checklists")
                    ?: JSONArray()
                else -> JSONArray()
            }
        } catch (_: Exception) {
            JSONArray()
        }
    }

    private class AbsListViewLayoutParams(width: Int, height: Int) :
        android.widget.AbsListView.LayoutParams(width, height)
}
