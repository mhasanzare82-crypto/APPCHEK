package com.example.exm1
import android.app.Activity
import android.app.AlertDialog
import android.os.Bundle
import android.view.WindowManager
import android.widget.ArrayAdapter
import org.json.JSONArray
class ChecklistPickerActivity:Activity(){
 override fun onCreate(savedInstanceState:Bundle?){
  super.onCreate(savedInstanceState)
  window?.setBackgroundDrawableResource(android.R.color.transparent)
  window?.addFlags(WindowManager.LayoutParams.FLAG_DIM_BEHIND)
  window?.attributes=window?.attributes?.apply{dimAmount=0.4f}
  val shared=getSharedPreferences("FlutterSharedPreferences",MODE_PRIVATE)
  val boards=try{JSONArray(shared.getString("flutter.boards","[]")?:"[]")}catch(_:Exception){JSONArray()}
  val labels=ArrayList<String>();val candidates=ArrayList<org.json.JSONObject>()
  for(i in 0 until boards.length()){val b=boards.optJSONObject(i)?:continue;val title=b.optString("title","").trim();if(title.isNotEmpty()){labels.add("$title • ${b.optJSONArray("items")?.length()?:0} مورد");candidates.add(b)}}
  val dlg=AlertDialog.Builder(this).setTitle("انتخاب چک‌لیست برای ویجت")
   .setAdapter(ArrayAdapter(this,android.R.layout.simple_list_item_1,labels)){_,index->
    val b=candidates[index];val raw=b.optJSONArray("items")?:JSONArray();val output=ArrayList<String>()
    for(i in 0 until raw.length()){val item=raw.optJSONObject(i);if(item!=null){val text=item.optString("text","").trim();if(text.isNotEmpty()){val mark=if(item.optBoolean("done",false))"✓" else "•";val desc=item.optString("description","").trim();output.add("$mark $text${if(desc.isEmpty())"" else " — $desc"}")}}else{val text=raw.optString(i).trim();if(text.isNotEmpty())output.add("• $text")}}
    shared.edit().putString("flutter.selectedWidgetBoardId",b.optString("id","")).apply()
    ChecklistHomeWidgetProvider.showBoard(this,b.optString("title","چک‌لیست"),output);finish()
   }.setNegativeButton("بستن"){_,_->finish()}.create()
  dlg.setOnDismissListener{if(!isFinishing)finish()}
  dlg.show()
  if(labels.isEmpty())dlg.setMessage("هنوز چک‌لیستی ساخته نشده است. ابتدا داخل برنامه چک‌لیست بساز.")
  dlg.window?.setLayout((resources.displayMetrics.widthPixels*0.88f).toInt(),WindowManager.LayoutParams.WRAP_CONTENT)
 }
}