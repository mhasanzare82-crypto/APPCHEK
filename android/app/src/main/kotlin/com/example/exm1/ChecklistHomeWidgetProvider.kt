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
  private const val PREFS="checklist_home_widget"
  fun saveBoardsSnapshot(context:Context,boardsJson:String,selectedBoardId:String){
   context.getSharedPreferences(PREFS,Context.MODE_PRIVATE).edit().putString("boardsJson",boardsJson).putString("selectedBoardId",selectedBoardId).commit()
  }
  fun saveAndRefresh(context:Context,title:String,items:List<String>,backgroundColor:Int,textColor:Int,fontFamily:String){
   context.getSharedPreferences(PREFS,Context.MODE_PRIVATE).edit().putString("title",title).putString("items",items.joinToString("\n")).putInt("backgroundColor",backgroundColor).putInt("textColor",textColor).putString("fontFamily",fontFamily).commit();refreshAll(context)
  }
  fun refreshAll(context:Context){val m=AppWidgetManager.getInstance(context);m.getAppWidgetIds(ComponentName(context,ChecklistHomeWidgetProvider::class.java)).forEach{render(context,m,it)}}
  fun showBoard(context:Context,title:String,items:List<String>){context.getSharedPreferences(PREFS,Context.MODE_PRIVATE).edit().putString("title",title).putString("items",items.joinToString("\n")).commit();refreshAll(context)}
  fun render(context:Context,manager:AppWidgetManager,id:Int){
   val p=context.getSharedPreferences(PREFS,Context.MODE_PRIVATE)
   val v=RemoteViews(context.packageName,R.layout.checklist_home_widget)
   val title=p.getString("title","چک‌لیست‌های من")?:"چک‌لیست‌های من"
   val items=p.getString("items","")?:""
   val content=if(items.isBlank())"این چک‌لیست هنوز موردی ندارد" else items

   val font=p.getString("fontFamily","sans")?:"sans"
   val isSerif=font=="serif"
   val isMono=font=="mono"

   v.setTextViewText(R.id.widget_title,title)
   v.setTextViewText(R.id.widget_title_serif,title)
   v.setTextViewText(R.id.widget_title_mono,title)
   v.setTextViewText(R.id.widget_content_sans,content)
   v.setTextViewText(R.id.widget_content_serif,content)
   v.setTextViewText(R.id.widget_content_mono,content)

   val textColor=p.getInt("textColor",0xFFFFFFFF.toInt())
   listOf(
    R.id.widget_title,
    R.id.widget_title_serif,
    R.id.widget_title_mono,
    R.id.widget_content_sans,
    R.id.widget_content_serif,
    R.id.widget_content_mono,
    R.id.widget_footer,
    R.id.widget_footer_serif,
    R.id.widget_footer_mono
   ).forEach { viewId -> v.setTextColor(viewId,textColor) }

   v.setViewVisibility(R.id.widget_title,if(!isSerif&&!isMono)View.VISIBLE else View.GONE)
   v.setViewVisibility(R.id.widget_title_serif,if(isSerif)View.VISIBLE else View.GONE)
   v.setViewVisibility(R.id.widget_title_mono,if(isMono)View.VISIBLE else View.GONE)
   v.setViewVisibility(R.id.widget_content_sans,if(!isSerif&&!isMono)View.VISIBLE else View.GONE)
   v.setViewVisibility(R.id.widget_content_serif,if(isSerif)View.VISIBLE else View.GONE)
   v.setViewVisibility(R.id.widget_content_mono,if(isMono)View.VISIBLE else View.GONE)
   v.setViewVisibility(R.id.widget_footer,if(!isSerif&&!isMono)View.VISIBLE else View.GONE)
   v.setViewVisibility(R.id.widget_footer_serif,if(isSerif)View.VISIBLE else View.GONE)
   v.setViewVisibility(R.id.widget_footer_mono,if(isMono)View.VISIBLE else View.GONE)

   v.setInt(R.id.widget_root,"setBackgroundColor",p.getInt("backgroundColor",0xFF202124.toInt()))
   val pi=PendingIntent.getActivity(context,7102,Intent(context,ChecklistPickerActivity::class.java),PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)
   v.setOnClickPendingIntent(R.id.widget_root,pi)
   manager.updateAppWidget(id,v)
  }
 }
 override fun onUpdate(context:Context,manager:AppWidgetManager,ids:IntArray){ids.forEach{render(context,manager,it)}}
}