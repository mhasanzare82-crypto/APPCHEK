package com.example.exm1

import android.app.Activity
import android.app.AlertDialog
import android.os.Bundle
import android.view.WindowManager
import android.widget.ArrayAdapter
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
                val items = board.optJSONArray("items") ?: JSONArray()
                labels.add("$title • ${items.length()} مورد")
                candidates.add(board)
            }
        }

        val builder = AlertDialog.Builder(this)
            .setTitle("انتخاب چک‌لیست برای ویجت")
            .setNegativeButton("بستن") { _, _ -> finish() }

        if (labels.isEmpty()) {
            builder.setMessage("هنوز چک‌لیستی ساخته نشده است. ابتدا داخل برنامه چک‌لیست بساز.")
        } else {
            builder.setAdapter(
                ArrayAdapter(this, android.R.layout.simple_list_item_1, labels)
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
                            output.add(
                                if (text.startsWith("✓") || text.startsWith("•")) text
                                else "• $text"
                            )
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
        dialog.window?.setLayout(
            (resources.displayMetrics.widthPixels * 0.88f).toInt(),
            WindowManager.LayoutParams.WRAP_CONTENT
        )
    }

    private fun readBoardsSnapshot(nativeSnapshot: String?): JSONArray {
        val nativeBoards = parseBoards(nativeSnapshot)
        if (nativeBoards.length() > 0) return nativeBoards

        // Compatibility fallback for installations where the widget has not
        // received its first native snapshot yet. Flutter stores the JSON string
        // under this key in its Android SharedPreferences file.
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
                is JSONObject -> {
                    val nested = parsed.optJSONArray("boards")
                        ?: parsed.optJSONArray("checklists")
                    nested ?: JSONArray()
                }
                else -> JSONArray()
            }
        } catch (_: Exception) {
            JSONArray()
        }
    }
}
