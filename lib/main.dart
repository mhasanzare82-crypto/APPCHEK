import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;
// ignore_for_file: deprecated_member_use, unused_local_variable, library_private_types_in_public_api
import 'package:excel/excel.dart' hide Border;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

final GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();
void main() async { WidgetsFlutterBinding.ensureInitialized(); runApp(const App()); }
String uid() => DateTime.now().microsecondsSinceEpoch.toString();
class Item {
 String id,text; bool done; int color;
 Item(this.id,this.text,{this.done=false,this.color=0xFF6658D3});
 Map<String,dynamic> toJson()=>{'id':id,'text':text,'done':done,'color':color};
 factory Item.from(Map m)=>Item((m['id']??uid()).toString(),(m['text']??m['title']??m['name']??'').toString(),done:m['done']==true||m['completed']==true,color:(m['color']??0xFF6658D3) as int);
}
class Folder { String id,name; int color; Folder(this.id,this.name,{this.color=0xFF6658D3}); Map<String,dynamic> toJson()=>{'id':id,'name':name,'color':color}; }
class Board {
 String id,title,folderId; List<Item> items; int color;
 Board(this.id,this.title,this.folderId,[List<Item>? items,this.color=0xFF6658D3]):items=items??[];
 Map<String,dynamic> toJson()=>{'id':id,'title':title,'folderId':folderId,'color':color,'items':items.map((e)=>e.toJson()).toList()};
 factory Board.from(Map m)=>Board((m['id']??uid()).toString(),(m['title']??m['name']??'چک‌لیست').toString(),(m['folderId']??m['folder_id']??'').toString(),((m['items']??m['tasks']??m['checks']??[]) as List).whereType<Map>().map(Item.from).toList(),(m['color']??0xFF6658D3) as int);
}
class App extends StatefulWidget { const App({super.key}); @override State<App> createState()=>_AppState(); }
class _AppState extends State<App> {
 final auth=LocalAuthentication(); List<Folder> folders=[]; List<Board> boards=[];
 bool ready=false,locked=false,biometric=false; List<int> palette=[0xFF6658D3,0xFF00897B,0xFFEF6C00,0xFF1976D2,0xFFD81B60,0xFF7E57C2]; double size=15,inputSize=15; String family='Vazirmatn'; Uint8List? fontBytes;
 @override void initState(){super.initState();load();}
 Future<void> load() async {
  final p=await SharedPreferences.getInstance();
  try {
   folders=(jsonDecode(p.getString('folders')??'[]') as List).whereType<Map>().map((m)=>Folder((m['id']??uid()).toString(),(m['name']??'').toString(),color:(m['color']??0xFF6658D3) as int)).toList();
   boards=(jsonDecode(p.getString('boards')??'[]') as List).whereType<Map>().map(Board.from).toList();
   size=p.getDouble('size')??15; inputSize=p.getDouble('inputSize')??15; biometric=p.getBool('bio')??false; palette=(p.getStringList('palette')??[]).map((v)=>int.tryParse(v)??0xFF6658D3).toList(); if(palette.isEmpty)palette=[0xFF6658D3,0xFF00897B,0xFFEF6C00,0xFF1976D2,0xFFD81B60,0xFF7E57C2];
   final raw=p.getString('font'); if(raw!=null){fontBytes=base64Decode(raw);await loadFont(fontBytes!);family='UserFont';}
  } catch (_) {}
  if(mounted)setState(()=>ready=true);
  if(biometric){locked=true;setState((){});unlock();}
 }
 Future<void> save() async {final p=await SharedPreferences.getInstance();await p.setString('folders',jsonEncode(folders.map((e)=>e.toJson()).toList()));await p.setString('boards',jsonEncode(boards.map((e)=>e.toJson()).toList()));await p.setDouble('size',size);await p.setDouble('inputSize',inputSize);await p.setStringList('palette',palette.map((v)=>v.toString()).toList());await p.setBool('bio',biometric);if(fontBytes!=null)await p.setString('font',base64Encode(fontBytes!));}
 Future<void> loadFont(Uint8List b) async {final l=FontLoader('UserFont')..addFont(Future.value(ByteData.sublistView(b)));await l.load();}
 int randomColor()=>palette[math.Random().nextInt(palette.length)];
 Future<void> colorSettings() async {final ctx=appNavigatorKey.currentContext;if(ctx==null)return;const options=[0xFF6658D3,0xFF00897B,0xFFEF6C00,0xFF1976D2,0xFFD81B60,0xFF7E57C2,0xFF00838F,0xFF5D4037,0xFF455A64,0xFF43A047,0xFFC0CA33,0xFFE53935,0xFF3949AB,0xFF8E24AA,0xFF6D4C41,0xFF546E7A];await showModalBottomSheet(context:ctx,showDragHandle:true,builder:(c)=>StatefulBuilder(builder:(c,refresh)=>Padding(padding:const EdgeInsets.all(20),child:Column(mainAxisSize:MainAxisSize.min,crossAxisAlignment:CrossAxisAlignment.stretch,children:[const Text('تم‌های رنگی',style:TextStyle(fontSize:20,fontWeight:FontWeight.bold)),const SizedBox(height:8),const Text('رنگ‌های انتخابی به‌صورت تصادفی برای پوشه‌ها، چک‌لیست‌ها و موارد جدید استفاده می‌شوند.'),const SizedBox(height:14),Wrap(spacing:12,runSpacing:12,children:options.map((v)=>InkWell(onTap:(){if(!palette.contains(v)){setState(()=>palette.add(v));save();refresh((){});}},child:Container(width:38,height:38,decoration:BoxDecoration(color:Color(v),shape:BoxShape.circle,border:Border.all(color:palette.contains(v)?Colors.black:Colors.transparent,width:2)),child:palette.contains(v)?const Icon(Icons.check,color:Colors.white,size:18):null))).toList()),const Divider(height:28),Wrap(spacing:12,runSpacing:12,children:palette.map((v)=>InputChip(label:Text(''),avatar:CircleAvatar(backgroundColor:Color(v)),onDeleted:palette.length>1?(){setState(()=>palette.remove(v));save();refresh((){});}:null)).toList()),Align(alignment:Alignment.centerLeft,child:TextButton.icon(onPressed:(){setState(()=>palette=[...options]);save();refresh((){});},icon:const Icon(Icons.refresh),label:const Text('بازنشانی تم‌ها')))]))));}
 void msg(String s){final ctx=appNavigatorKey.currentContext;if(ctx!=null)ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content:Text(s)));}
 Future<void> unlock() async {try{final ok=await auth.authenticate(localizedReason:'برای ورود به چک‌یار اثر انگشت یا چهره خود را تأیید کنید',options:const AuthenticationOptions(biometricOnly:true,stickyAuth:true));if(mounted&&ok)setState(()=>locked=false);}catch(_){msg('احراز هویت بیومتریک در دسترس نیست؛ تنظیمات قفل گوشی را بررسی کنید');}}
 Future<String?> pickName(String title,[String initial='']) async {final c=TextEditingController(text:initial);final ctx=appNavigatorKey.currentContext;if(ctx==null)return null;return showDialog<String>(context:ctx,builder:(d)=>AlertDialog(title:Text(title),content:TextField(controller:c,autofocus:true,style:TextStyle(fontSize:inputSize*15/size,fontFamily:family)),actions:[TextButton(onPressed:()=>Navigator.pop(d),child:const Text('انصراف')),FilledButton(onPressed:()=>Navigator.pop(d,c.text.trim()),child:const Text('ذخیره'))]));}
 Future<void> addFolder() async {final s=await pickName('پوشه جدید');if(s!=null&&s.isNotEmpty){setState(()=>folders.add(Folder(uid(),s,color:randomColor())));save();}}
 Future<void> addBoard(String folder) async {final s=await pickName('چک‌لیست جدید');if(s!=null&&s.isNotEmpty){setState(()=>boards.add(Board(uid(),s,folder, null, randomColor())));save();}}
 Future<void> backupOut() async {final data={'format':'checklist-backup','version':2,'folders':folders.map((e)=>e.toJson()).toList(),'boards':boards.map((e)=>e.toJson()).toList()};final d=await getTemporaryDirectory();final f=File('${d.path}/checklist-backup.json');await f.writeAsString(const JsonEncoder.withIndent('  ').convert(data));await Share.shareXFiles([XFile(f.path)],text:'پشتیبان چک‌یار');}
 Future<void> backupIn() async {final f=await FilePicker.platform.pickFiles(type:FileType.custom,allowedExtensions:['json','bak','txt'],withData:true);if(f==null)return;try{final b=f.files.single.bytes??await File(f.files.single.path!).readAsBytes();final x=jsonDecode(utf8.decode(b));final fm=x is Map?(x['folders']??x['categories']??[]):[];final bm=x is List?x:x is Map?(x['boards']??x['lists']??x['checklists']??x['data']??[]):[];final nf=(fm as List).whereType<Map>().map((m)=>Folder((m['id']??uid()).toString(),(m['name']??m['title']??'پوشه').toString(),color:(m['color']??0xFF6658D3) as int)).toList();final nb=(bm as List).whereType<Map>().map(Board.from).toList();if(nf.isEmpty&&nb.isEmpty)throw Exception();setState((){folders=nf;boards=nb;});await save();msg('بازیابی انجام شد');}catch(_){msg('فایل پشتیبان معتبر یا سازگار نیست');}}
 Future<void> excelOut([String? folder]) async {final e=Excel.createExcel();final s=e['Sheet1'];s.appendRow(['پوشه','چک‌لیست','مورد','انجام شده'].map((v)=>TextCellValue(v)).toList());for(final b in boards.where((x)=>folder==null||x.folderId==folder)){final fn=folders.where((x)=>x.id==b.folderId).firstOrNull?.name??'بدون پوشه';for(final i in b.items){s.appendRow([TextCellValue(fn),TextCellValue(b.title),TextCellValue(i.text),TextCellValue(i.done?'بله':'خیر')]);}if(b.items.isEmpty)s.appendRow([TextCellValue(fn),TextCellValue(b.title),TextCellValue(''),TextCellValue('')]);}final bytes=e.encode();if(bytes==null)return;final d=await getTemporaryDirectory();final f=File('${d.path}/checklists.xlsx');await f.writeAsBytes(bytes);await Share.shareXFiles([XFile(f.path)],text:'خروجی اکسل');}
 Future<void> excelIn() async {
  final f=await FilePicker.platform.pickFiles(type:FileType.custom,allowedExtensions:['xlsx','xls'],withData:true);
  if(f==null||f.files.single.bytes==null)return;
  try{
   final e=Excel.decodeBytes(f.files.single.bytes!);
   final sh=e.tables.values.first;
   if(sh.rows.isEmpty){msg('فایل اکسل خالی است');return;}
   String cell(List<Data?> row,int n)=>n<row.length?(row[n]?.value?.toString().trim()??''):'';
   final first=sh.rows.first.map((c)=>c?.value?.toString().trim().toLowerCase()??'').toList();
   final titleCol=first.indexWhere((v)=>v=='چک‌لیست'||v=='چک لیست'||v=='checklist'||v=='list'||v=='title');
   final itemCol=first.indexWhere((v)=>v=='مورد'||v=='آیتم'||v=='item'||v=='task');
   final exportedFormat=titleCol>=0&&itemCol>=0;
   final grouped=<String,List<String>>{};
   for(var r=exportedFormat?1:0;r<sh.rows.length;r++){
    final row=sh.rows[r];
    if(exportedFormat){
     final title=cell(row,titleCol).isEmpty?'واردشده از اکسل':cell(row,titleCol);
     final item=cell(row,itemCol);
     if(item.isNotEmpty)grouped.putIfAbsent(title,()=>[]).add(item);
    }else{
     final values=row.map((c)=>c?.value?.toString().trim()??'').where((v)=>v.isNotEmpty).toList();
     if(values.isNotEmpty)grouped.putIfAbsent('واردشده از اکسل',()=>[]).add(values.join(' - '));
    }
   }
   if(grouped.isEmpty){msg('هیچ موردی برای ورود در فایل پیدا نشد');return;}
   setState(()=>boards.addAll(grouped.entries.map((entry)=>Board(uid(),entry.key,'',entry.value.map((t)=>Item(uid(),t,color:randomColor())).toList()))));
   await save();
   msg('ورود اکسل انجام شد؛ هر ردیف به یک مورد چک‌لیست تبدیل شد');
  }catch(_){msg('فایل اکسل قابل خواندن نیست');}
 }
 Future<void> chooseFont() async {final f=await FilePicker.platform.pickFiles(type:FileType.custom,allowedExtensions:['ttf','otf'],withData:true);if(f==null||f.files.single.bytes==null)return;try{fontBytes=f.files.single.bytes;await loadFont(fontBytes!);setState(()=>family='UserFont');await save();}catch(_){msg('فایل فونت معتبر نیست');}}
 Future<void> settings() async {
  final ctx=appNavigatorKey.currentContext;if(ctx==null)return;
  await showModalBottomSheet(context:ctx,isScrollControlled:true,showDragHandle:true,builder:(c)=>StatefulBuilder(builder:(c,refresh)=>SafeArea(child:SingleChildScrollView(padding:EdgeInsets.fromLTRB(20,12,20,MediaQuery.of(c).viewInsets.bottom+24),child:Column(mainAxisSize:MainAxisSize.min,crossAxisAlignment:CrossAxisAlignment.stretch,children:[
   const Text('تنظیمات برنامه',style:TextStyle(fontSize:20,fontWeight:FontWeight.bold)),
   const SizedBox(height:12),
   const Text('ظاهر و نوشته‌ها',style:TextStyle(fontWeight:FontWeight.bold)),
   ListTile(contentPadding:EdgeInsets.zero,leading:const Icon(Icons.font_download),title:const Text('انتخاب فونت اختصاصی'),subtitle:Text(fontBytes==null?'فونت پیش‌فرض فعال است':'فونت اختصاصی فعال است'),onTap:()async{await chooseFont();refresh((){});}),
   Text('اندازه نوشته‌های برنامه: ${size.round()}'),
   Slider(value:size,min:12,max:25,divisions:13,label:size.round().toString(),onChanged:(v){setState(()=>size=v);refresh((){});save();}),
   Text('اندازه نوشته‌های ورودی: ${inputSize.round()}'),
   Slider(value:inputSize,min:12,max:25,divisions:13,label:inputSize.round().toString(),onChanged:(v){setState(()=>inputSize=v);refresh((){});save();}),
   TextField(style:TextStyle(fontSize:inputSize*15/size,fontFamily:family),decoration:const InputDecoration(hintText:'پیش‌نمایش نوشته ورودی',border:OutlineInputBorder())),
   const Divider(height:28),
   const Text('امنیت',style:TextStyle(fontWeight:FontWeight.bold)),
   SwitchListTile(contentPadding:EdgeInsets.zero,value:biometric,title:const Text('قفل اثر انگشت / تشخیص چهره'),subtitle:const Text('هنگام ورود به برنامه احراز هویت انجام می‌شود'),onChanged:(v)async{
    if(v){try{final supported=await auth.isDeviceSupported();final available=await auth.getAvailableBiometrics();if(!supported||available.isEmpty){msg('روی این دستگاه بیومتریک فعال یا قابل استفاده نیست');return;}final ok=await auth.authenticate(localizedReason:'برای فعال‌سازی قفل برنامه احراز هویت کنید',options:const AuthenticationOptions(biometricOnly:true,stickyAuth:true));if(!ok)return;}catch(_){msg('فعال‌سازی بیومتریک ناموفق بود؛ قفل صفحه و مجوزهای دستگاه را بررسی کنید');return;}}
    setState(()=>biometric=v);await save();refresh((){});
   }),
   const Divider(height:28),
   ListTile(leading:const Icon(Icons.palette_outlined),title:const Text('تنظیم تم‌های رنگی'),onTap:(){Navigator.pop(c);colorSettings();}),
   const Divider(height:12),
   const Text('ورود و خروجی اطلاعات',style:TextStyle(fontWeight:FontWeight.bold)),
   ListTile(leading:const Icon(Icons.backup),title:const Text('خروجی پشتیبان'),onTap:(){Navigator.pop(c);backupOut();}),
   ListTile(leading:const Icon(Icons.restore),title:const Text('بازیابی پشتیبان'),onTap:(){Navigator.pop(c);backupIn();}),
   ListTile(leading:const Icon(Icons.upload_file),title:const Text('ورود از اکسل'),onTap:(){Navigator.pop(c);excelIn();}),
   ListTile(leading:const Icon(Icons.download),title:const Text('خروجی اکسل'),onTap:(){Navigator.pop(c);excelOut();}),
  ])))));
 }
 @override Widget build(BuildContext context){final theme=ThemeData(useMaterial3:true,colorScheme:ColorScheme.fromSeed(seedColor:const Color(0xFF6658D3)),scaffoldBackgroundColor:const Color(0xFFF5F6FA),fontFamily:family);return MaterialApp(navigatorKey:appNavigatorKey,debugShowCheckedModeBanner:false,theme:theme,builder:(c,w)=>Directionality(textDirection:ui.TextDirection.rtl,child:MediaQuery(data:MediaQuery.of(c).copyWith(textScaler:TextScaler.linear(size/15)),child:w!)),home:!ready?const Scaffold(body:Center(child:CircularProgressIndicator())):locked?Scaffold(body:Center(child:FilledButton.icon(onPressed:unlock,icon:const Icon(Icons.fingerprint),label:const Text('باز کردن برنامه')))):Home(owner:this));}
}
class Home extends StatefulWidget {final _AppState owner;const Home({super.key,required this.owner});@override State<Home> createState()=>_HomeState();}
class _HomeState extends State<Home>{
 String? folder;
 int _backPressCount=0;
 Timer? _backPressTimer;
 @override void dispose(){_backPressTimer?.cancel();super.dispose();}
 void _handleBack(){
  if(folder!=null){setState(()=>folder=null);return;}
  _backPressCount++;
  _backPressTimer?.cancel();
  if(_backPressCount>=4){_backPressCount=0;SystemNavigator.pop();return;}
  _backPressTimer=Timer(const Duration(seconds:2),(){_backPressCount=0;});
  widget.owner.msg('برای خروج، دکمه بازگشت را ${4-_backPressCount} بار دیگر پشت سر هم فشار دهید');
 }
 Board? featured;
 @override void initState(){super.initState();final all=widget.owner.boards;if(all.isNotEmpty)featured=all[math.Random().nextInt(all.length)];}
 Future<void> addItem(Board b)async{final s=await widget.owner.pickName('مورد جدید');if(s!=null&&s.isNotEmpty){setState(()=>b.items.add(Item(uid(),s,color:widget.owner.randomColor())));widget.owner.save();}}
 @override Widget build(BuildContext context){final o=widget.owner;final inside=folder!=null;final lists=o.boards.where((b)=>b.folderId==(folder??'')).toList();final done=o.boards.fold<int>(0,(a,b)=>a+b.items.where((i)=>i.done).length);final total=o.boards.fold<int>(0,(a,b)=>a+b.items.length);return PopScope(canPop:false,onPopInvokedWithResult:(didPop,result){if(!didPop)_handleBack();},child:Scaffold(appBar:AppBar(title:Text(inside?(o.folders.where((f)=>f.id==folder).firstOrNull?.name??'پوشه'):'چک‌یار',style:const TextStyle(fontWeight:FontWeight.bold)),leading:inside?IconButton(onPressed:()=>setState(()=>folder=null),icon:const Icon(Icons.arrow_back)):null,actions:[IconButton(onPressed:o.colorSettings,icon:const Icon(Icons.palette_outlined),tooltip:'تنظیم تم‌های رنگی'),PopupMenuButton<String>(tooltip:'ورود و خروجی اطلاعات',icon:const Icon(Icons.import_export),onSelected:(v){switch(v){case 'excel_in':o.excelIn();break;case 'excel_out':o.excelOut();break;case 'backup_out':o.backupOut();break;case 'backup_in':o.backupIn();break;}},itemBuilder:(_)=>const [PopupMenuItem(value:'excel_in',child:ListTile(dense:true,leading:Icon(Icons.upload_file),title:Text('ورود از اکسل'))),PopupMenuItem(value:'excel_out',child:ListTile(dense:true,leading:Icon(Icons.download),title:Text('خروجی اکسل'))),PopupMenuDivider(),PopupMenuItem(value:'backup_out',child:ListTile(dense:true,leading:Icon(Icons.backup),title:Text('خروجی پشتیبان'))),PopupMenuItem(value:'backup_in',child:ListTile(dense:true,leading:Icon(Icons.restore),title:Text('بازیابی پشتیبان')))]),IconButton(onPressed:o.settings,icon:const Icon(Icons.tune),tooltip:'تنظیمات')]),floatingActionButton:inside?FilledButton.tonalIcon(onPressed:()=>o.addBoard(folder!),icon:const Icon(Icons.add,size:18),label:const Text('چک‌لیست جدید'),style:FilledButton.styleFrom(visualDensity:VisualDensity.compact,padding:const EdgeInsets.symmetric(horizontal:12,vertical:8))):Column(mainAxisSize:MainAxisSize.min,crossAxisAlignment:CrossAxisAlignment.end,children:[FilledButton.tonalIcon(heroTag:'new-folder',onPressed:o.addFolder,icon:const Icon(Icons.create_new_folder,size:18),label:const Text('پوشه جدید'),style:FilledButton.styleFrom(visualDensity:VisualDensity.compact,padding:const EdgeInsets.symmetric(horizontal:12,vertical:8))),const SizedBox(height:6),FilledButton.tonalIcon(heroTag:'new-checklist',onPressed:()=>o.addBoard(''),icon:const Icon(Icons.add_task,size:18),label:const Text('چک‌لیست جدید'),style:FilledButton.styleFrom(visualDensity:VisualDensity.compact,padding:const EdgeInsets.symmetric(horizontal:12,vertical:8)))]),body:ListView(padding:const EdgeInsets.all(18),children:[
 if(!inside)Container(padding:const EdgeInsets.symmetric(horizontal:16,vertical:11),decoration:BoxDecoration(gradient:const LinearGradient(colors:[Color(0xFF7569E0),Color(0xFF5144B8)]),borderRadius:BorderRadius.circular(16)),child:Row(children:[const Icon(Icons.auto_awesome_rounded,color:Colors.white70,size:18),const SizedBox(width:8),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,mainAxisSize:MainAxisSize.min,children:[const Text('پیشنهاد تصادفی از چک‌لیست‌های تو',style:TextStyle(color:Colors.white70,fontSize:11)),const SizedBox(height:3),Text(featured?.title??'هنوز چک‌لیستی برای نمایش وجود ندارد',maxLines:1,overflow:TextOverflow.ellipsis,style:const TextStyle(color:Colors.white,fontSize:16,fontWeight:FontWeight.bold))]))])),

 const SizedBox(height:22),Row(children:[Expanded(child:Text(inside?'چک‌لیست‌ها':'پوشه‌ها',style:const TextStyle(fontWeight:FontWeight.bold,fontSize:18))),Text(inside?'${lists.length}':'${o.folders.length}')]),
 if(!inside&&o.folders.isEmpty)const Padding(padding:EdgeInsets.all(24),child:Center(child:Text('برای شروع یک پوشه بساز'))),
 if(!inside)...o.folders.map((f){final n=o.boards.where((b)=>b.folderId==f.id).length;return InkWell(borderRadius:BorderRadius.circular(18),onTap:()=>setState(()=>folder=f.id),onLongPress:()=>showModalBottomSheet(context:context,builder:(c)=>Wrap(children:[ListTile(leading:const Icon(Icons.edit),title:const Text('ویرایش'),onTap:()async{Navigator.pop(c);final s=await o.pickName('نام پوشه',f.name);if(s!=null&&s.isNotEmpty){setState(()=>f.name=s);o.save();}}),ListTile(leading:const Icon(Icons.delete),title:const Text('حذف پوشه'),onTap:(){Navigator.pop(c);setState((){for(final b in o.boards){if(b.folderId==f.id)b.folderId='';}o.folders.remove(f);});o.save();})])),child:Container(width:double.infinity,margin:const EdgeInsets.only(bottom:10),padding:const EdgeInsets.all(16),decoration:BoxDecoration(color:Colors.white,borderRadius:BorderRadius.circular(18),border:Border.all(color:Color(f.color).withOpacity(.35))),child:Row(children:[Container(width:48,height:48,decoration:BoxDecoration(color:Color(f.color).withOpacity(.15),borderRadius:BorderRadius.circular(14)),child:Icon(Icons.folder_rounded,color:Color(f.color),size:27)),const SizedBox(width:14),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(f.name,style:TextStyle(fontWeight:FontWeight.bold,color:Color(f.color),fontSize:16)),const SizedBox(height:4),Text('$n چک‌لیست',style:const TextStyle(color:Colors.grey,fontSize:12))])),const Icon(Icons.arrow_back_ios_new,size:15,color:Colors.grey)])));}),
 if(!inside)...[const SizedBox(height:22),const Text('چک‌لیست‌های بدون پوشه',style:TextStyle(fontWeight:FontWeight.bold,fontSize:17))],
 if(lists.isEmpty)const Padding(padding:EdgeInsets.all(25),child:Center(child:Text('هنوز چک‌لیستی وجود ندارد'))),
 ...lists.map((b)=>Card(color:Color(b.color).withOpacity(.045),elevation:0,shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(18),side:BorderSide(color:Color(b.color).withOpacity(.28))),margin:const EdgeInsets.only(top:10),child:Padding(padding:const EdgeInsets.all(12),child:Column(children:[Row(children:[Expanded(child:Text(b.title,style:TextStyle(fontWeight:FontWeight.bold,fontSize:16,color:Color(b.color)))),PopupMenuButton<String>(onSelected:(v)async{if(v=='move'){final target=await showModalBottomSheet<String>(context:context,builder:(c)=>SafeArea(child:Wrap(children:[const ListTile(title:Text('انتقال چک‌لیست به')),...[ListTile(leading:const Icon(Icons.inbox_outlined),title:const Text('بدون پوشه'),onTap:()=>Navigator.pop(c,'')),...o.folders.map((f)=>ListTile(leading:Icon(Icons.folder,color:Color(f.color)),title:Text(f.name),onTap:()=>Navigator.pop(c,f.id)))]])));if(target!=null){setState(()=>b.folderId=target);o.save();}}else if(v=='edit'){final s=await o.pickName('ویرایش نام',b.title);if(s!=null&&s.isNotEmpty){setState(()=>b.title=s);o.save();}}else if(v=='delete'){setState(()=>o.boards.remove(b));o.save();}},itemBuilder:(_)=>const [PopupMenuItem(value:'move',child:Text('انتقال به پوشه')),PopupMenuItem(value:'edit',child:Text('ویرایش')),PopupMenuItem(value:'delete',child:Text('حذف'))])]),if(b.items.isNotEmpty)LinearProgressIndicator(value:b.items.where((i)=>i.done).length/b.items.length,minHeight:5,color:Color(b.color)),...b.items.map((i)=>CheckboxListTile(dense:true,contentPadding:EdgeInsets.zero,controlAffinity:ListTileControlAffinity.leading,value:i.done,title:Text(i.text,style:TextStyle(decoration:i.done?TextDecoration.lineThrough:null,color:Color(i.color))),onChanged:(v){setState(()=>i.done=v??false);o.save();},secondary:IconButton(icon:const Icon(Icons.close,size:18),onPressed:(){setState(()=>b.items.remove(i));o.save();}))),Align(alignment:Alignment.centerRight,child:TextButton.icon(onPressed:()=>addItem(b),icon:const Icon(Icons.add),label:const Text('افزودن مورد')))])))),

 ])));}
}
