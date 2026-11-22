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
import 'widgets/checklist_widget.dart';

final GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();
void main() async { WidgetsFlutterBinding.ensureInitialized(); runApp(const App()); }
String uid() => DateTime.now().microsecondsSinceEpoch.toString();
class Item {
 String id,text,description; bool done; int color;
 Item(this.id,this.text,{this.description='',this.done=false,this.color=0xFF6658D3});
 Map<String,dynamic> toJson()=>{'id':id,'text':text,'description':description,'done':done,'color':color};
 factory Item.from(Map m)=>Item((m['id']??uid()).toString(),(m['text']??m['title']??m['name']??'').toString(),description:(m['description']??m['note']??'').toString(),done:m['done']==true||m['completed']==true,color:(m['color']??0xFF6658D3) as int);
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
 final ChecklistWidgetService checklistWidgetService=ChecklistWidgetService();
 final auth=LocalAuthentication(); List<Folder> folders=[]; List<Board> boards=[];
 bool ready=false,locked=false,biometric=false; List<int> palette=[0xFF6658D3,0xFF00897B,0xFFEF6C00,0xFF1976D2,0xFFD81B60,0xFF7E57C2]; double size=15,inputSize=15; String family='Vazirmatn'; Uint8List? fontBytes;
 int widgetBackground=0xFF202124; int widgetTextColor=0xFFFFFFFF; String widgetFont='sans'; String selectedWidgetBoardId='';
 @override void initState(){super.initState();load();}
 Future<void> load() async {
  final p=await SharedPreferences.getInstance();
  try {
   folders=(jsonDecode(p.getString('folders')??'[]') as List).whereType<Map>().map((m)=>Folder((m['id']??uid()).toString(),(m['name']??'').toString(),color:(m['color']??0xFF6658D3) as int)).toList();
   boards=(jsonDecode(p.getString('boards')??'[]') as List).whereType<Map>().map(Board.from).toList();
   size=p.getDouble('size')??15; inputSize=p.getDouble('inputSize')??15; biometric=p.getBool('bio')??false;
   widgetBackground=p.getInt('widgetBackground')??0xFF202124; widgetTextColor=p.getInt('widgetTextColor')??0xFFFFFFFF; widgetFont=p.getString('widgetFont')??'sans'; selectedWidgetBoardId=p.getString('selectedWidgetBoardId')??''; palette=(p.getStringList('palette')??[]).map((v)=>int.tryParse(v)??0xFF6658D3).toList(); if(palette.isEmpty)palette=[0xFF6658D3,0xFF00897B,0xFFEF6C00,0xFF1976D2,0xFFD81B60,0xFF7E57C2];
   final raw=p.getString('font'); if(raw!=null){fontBytes=base64Decode(raw);await loadFont(fontBytes!);family='UserFont';}
  } catch (_) {}
  if(mounted)setState(()=>ready=true);
  if(biometric){locked=true;setState((){});unlock();}
 }
 Future<void> save() async {final p=await SharedPreferences.getInstance();await p.setString('folders',jsonEncode(folders.map((e)=>e.toJson()).toList()));await p.setString('boards',jsonEncode(boards.map((e)=>e.toJson()).toList()));await p.setDouble('size',size);await p.setDouble('inputSize',inputSize);await p.setStringList('palette',palette.map((v)=>v.toString()).toList());await p.setBool('bio',biometric);if(fontBytes!=null)await p.setString('font',base64Encode(fontBytes!));await p.setInt('widgetBackground',widgetBackground);await p.setInt('widgetTextColor',widgetTextColor);await p.setString('widgetFont',widgetFont);await p.setString('selectedWidgetBoardId',selectedWidgetBoardId);await syncChecklistWidget();}
 Future<void> loadFont(Uint8List b) async {final l=FontLoader('UserFont')..addFont(Future.value(ByteData.sublistView(b)));await l.load();}
 int randomColor()=>palette[math.Random().nextInt(palette.length)];
 Future<void> syncChecklistWidget() async {
  await checklistWidgetService.sync(
   boards: boards.map((board)=>ChecklistWidgetBoardOption(id:board.id,title:board.title,itemCount:board.items.length)).toList(),
   selectedBoardId: selectedWidgetBoardId,
   backgroundColor: widgetBackground,
   textColor: widgetTextColor,
   fontFamily: widgetFont,
   itemsFor: (option) {
    final board=boards.firstWhere((entry)=>entry.id==option.id);
    return board.items.map((item)=>'${item.done?'✓':'•'} ${item.text}${item.description.trim().isEmpty?'':' — ${item.description}'}').toList();
   },
  );
 }
 Future<void> pickSliderColor({required String title, required int initial, required ValueChanged<int> onChanged}) async {
  final ctx=appNavigatorKey.currentContext;if(ctx==null)return;
  final hsl=HSLColor.fromColor(Color(initial));
  double hue=hsl.hue,saturation=hsl.saturation,lightness=hsl.lightness;
  await showModalBottomSheet(context:ctx,showDragHandle:true,builder:(c)=>StatefulBuilder(builder:(c,refresh){
   final color=HSLColor.fromAHSL(1,hue,saturation,lightness).toColor();
   return Padding(padding:const EdgeInsets.fromLTRB(20,16,20,28),child:Column(mainAxisSize:MainAxisSize.min,crossAxisAlignment:CrossAxisAlignment.stretch,children:[
    Text(title,style:const TextStyle(fontSize:18,fontWeight:FontWeight.bold)),
    const SizedBox(height:14),Container(height:42,decoration:BoxDecoration(color:color,borderRadius:BorderRadius.circular(12))),
    Text('ته‌رنگ: ${hue.round()}°'),Slider(value:hue,min:0,max:360,onChanged:(v)=>refresh(()=>hue=v)),
    Text('اشباع: ${(saturation*100).round()}٪'),Slider(value:saturation,min:0,max:1,onChanged:(v)=>refresh(()=>saturation=v)),
    Text('روشنایی: ${(lightness*100).round()}٪'),Slider(value:lightness,min:0,max:1,onChanged:(v)=>refresh(()=>lightness=v)),
    const SizedBox(height:8),FilledButton(onPressed:(){onChanged(color.value);Navigator.pop(c);},child:const Text('ذخیره رنگ'))
   ]));
  }));
 }
 void msg(String s){final ctx=appNavigatorKey.currentContext;if(ctx!=null)ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content:Text(s)));}
 Future<void> unlock() async {try{final ok=await auth.authenticate(localizedReason:'برای ورود به چک‌یار اثر انگشت یا چهره خود را تأیید کنید',options:const AuthenticationOptions(biometricOnly:true,stickyAuth:true));if(mounted&&ok)setState(()=>locked=false);}catch(_){msg('احراز هویت بیومتریک در دسترس نیست؛ تنظیمات قفل گوشی را بررسی کنید');}}
 Future<String?> pickName(String title,[String initial='']) async {final c=TextEditingController(text:initial);final ctx=appNavigatorKey.currentContext;if(ctx==null)return null;return showDialog<String>(context:ctx,builder:(d)=>AlertDialog(title:Text(title),content:TextField(controller:c,autofocus:true,style:TextStyle(fontSize:inputSize*15/size,fontFamily:family)),actions:[TextButton(onPressed:()=>Navigator.pop(d),child:const Text('انصراف')),FilledButton(onPressed:()=>Navigator.pop(d,c.text.trim()),child:const Text('ذخیره'))]));}
 Future<void> addFolder() async {final s=await pickName('پوشه جدید');if(s!=null&&s.isNotEmpty){setState(()=>folders.add(Folder(uid(),s,color:randomColor())));save();}}
 Future<void> addBoard(String folder) async {final s=await pickName('چک‌لیست جدید');if(s!=null&&s.isNotEmpty){setState(()=>boards.add(Board(uid(),s,folder, null, randomColor())));save();}}
 Future<void> backupOut() async {final data={'format':'checklist-backup','version':2,'folders':folders.map((e)=>e.toJson()).toList(),'boards':boards.map((e)=>e.toJson()).toList()};final d=await getTemporaryDirectory();final f=File('${d.path}/checklist-backup.json');await f.writeAsString(const JsonEncoder.withIndent('  ').convert(data));await Share.shareXFiles([XFile(f.path)],text:'پشتیبان چک‌یار');}
 Future<void> backupIn() async {final f=await FilePicker.platform.pickFiles(type:FileType.custom,allowedExtensions:['json','bak','txt'],withData:true);if(f==null)return;try{final b=f.files.single.bytes??await File(f.files.single.path!).readAsBytes();final x=jsonDecode(utf8.decode(b));final fm=x is Map?(x['folders']??x['categories']??[]):[];final bm=x is List?x:x is Map?(x['boards']??x['lists']??x['checklists']??x['data']??[]):[];final nf=(fm as List).whereType<Map>().map((m)=>Folder((m['id']??uid()).toString(),(m['name']??m['title']??'پوشه').toString(),color:(m['color']??0xFF6658D3) as int)).toList();final nb=(bm as List).whereType<Map>().map(Board.from).toList();if(nf.isEmpty&&nb.isEmpty)throw Exception();setState((){folders=nf;boards=nb;});await save();msg('بازیابی انجام شد');}catch(_){msg('فایل پشتیبان معتبر یا سازگار نیست');}}
 Future<void> excelOut([String? folder]) async {
  final selectedBoards=boards.where((board)=>folder==null||board.folderId==folder).toList();
  if(selectedBoards.isEmpty){msg('چک‌لیستی برای خروجی گرفتن وجود ندارد');return;}
  final excel=Excel.createExcel();
  final sheet=excel['Sheet1'];
  final maxItems=selectedBoards.fold<int>(0,(max,board)=>board.items.length>max?board.items.length:max);
  final totalRows=2+(maxItems*2);
  for(var rowIndex=0;rowIndex<totalRows;rowIndex++){
   final row=<CellValue?>[];
   for(final board in selectedBoards){
    String value='';
    if(rowIndex==0){
     value=folders.where((entry)=>entry.id==board.folderId).firstOrNull?.name??'';
    }else if(rowIndex==1){
     value=board.title;
    }else{
     final offset=rowIndex-2;
     final itemIndex=offset~/2;
     if(itemIndex<board.items.length){
      final item=board.items[itemIndex];
      value=offset.isEven?item.text:item.description;
     }
    }
    row.add(TextCellValue(value));
   }
   sheet.appendRow(row);
  }
  final bytes=excel.encode();
  if(bytes==null){msg('ساخت فایل اکسل ناموفق بود');return;}
  final directory=await getTemporaryDirectory();
  final output=File('${directory.path}/checklists.xlsx');
  await output.writeAsBytes(bytes);
  await Share.shareXFiles([XFile(output.path)],text:'خروجی اکسل');
 }
 Future<void> excelIn() async {
  final picked=await FilePicker.platform.pickFiles(type:FileType.custom,allowedExtensions:['xlsx','xls'],withData:true);
  if(picked==null||picked.files.single.bytes==null)return;
  try{
   final excel=Excel.decodeBytes(picked.files.single.bytes!);
   if(excel.tables.isEmpty){msg('فایل اکسل شیت معتبری ندارد');return;}
   final sheet=excel.tables.values.first;
   if(sheet.rows.isEmpty){msg('فایل اکسل خالی است');return;}
   String cellAt(int rowIndex,int columnIndex){
    if(rowIndex<0||rowIndex>=sheet.rows.length)return '';
    final row=sheet.rows[rowIndex];
    if(columnIndex<0||columnIndex>=row.length)return '';
    return row[columnIndex]?.value?.toString().trim()??'';
   }

   // پشتیبانی از قالب قدیمی جدولی برای فایل‌هایی که قبلاً از برنامه خروجی گرفته‌اند.
   final first=sheet.rows.first.map((cell)=>cell?.value?.toString().trim().toLowerCase()??'').toList();
   final titleCol=first.indexWhere((value)=>value=='چک‌لیست'||value=='چک لیست'||value=='checklist'||value=='list'||value=='title');
   final itemCol=first.indexWhere((value)=>value=='مورد'||value=='آیتم'||value=='item'||value=='task');
   final importedFolders=<Folder>[];
   final importedBoards=<Board>[];

   if(titleCol>=0&&itemCol>=0){
    final grouped=<String,List<String>>{};
    for(var rowIndex=1;rowIndex<sheet.rows.length;rowIndex++){
     final title=cellAt(rowIndex,titleCol).isEmpty?'واردشده از اکسل':cellAt(rowIndex,titleCol);
     final item=cellAt(rowIndex,itemCol);
     if(item.isNotEmpty)grouped.putIfAbsent(title,()=>[]).add(item);
    }
    importedBoards.addAll(grouped.entries.map((entry)=>Board(uid(),entry.key,'',entry.value.map((text)=>Item(uid(),text,color:randomColor())).toList(),randomColor())));
   }else{
    final maxColumns=sheet.rows.fold<int>(0,(max,row)=>row.length>max?row.length:max);
    for(var columnIndex=0;columnIndex<maxColumns;columnIndex++){
     final folderName=cellAt(0,columnIndex);
     final title=cellAt(1,columnIndex);
     if(title.isEmpty)continue;

     var folderId='';
     if(folderName.isNotEmpty){
      Folder? existing;
      for(final candidate in [...folders,...importedFolders]){
       if(candidate.name==folderName){existing=candidate;break;}
      }
      if(existing==null){
       existing=Folder(uid(),folderName,color:randomColor());
       importedFolders.add(existing);
      }
      folderId=existing.id;
     }

     final items=<Item>[];
     for(var rowIndex=2;rowIndex<sheet.rows.length;rowIndex+=2){
      final itemText=cellAt(rowIndex,columnIndex);
      final description=cellAt(rowIndex+1,columnIndex);
      if(itemText.isEmpty)continue;
      items.add(Item(uid(),itemText,description:description,color:randomColor()));
     }
     importedBoards.add(Board(uid(),title,folderId,items,randomColor()));
    }
   }

   if(importedBoards.isEmpty){msg('هیچ چک‌لیست معتبری در فایل اکسل پیدا نشد');return;}
   setState((){
    folders.addAll(importedFolders);
    boards.addAll(importedBoards);
   });
   await save();
   msg('ورود اکسل انجام شد؛ پوشه‌ها، چک‌لیست‌ها، موارد و توضیحات وارد شدند');
  }catch(_){
   msg('فایل اکسل قابل خواندن نیست یا ساختار آن معتبر نیست');
  }
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
   ChecklistWidgetSettings(
    backgroundColor:widgetBackground,
    textColor:widgetTextColor,
    fontFamily:widgetFont,
    onChangeBackground:()async{await pickSliderColor(title:'رنگ پس‌زمینه ویجت',initial:widgetBackground,onChanged:(v){widgetBackground=v;});await save();refresh((){});},
    onChangeTextColor:()async{await pickSliderColor(title:'رنگ متن ویجت',initial:widgetTextColor,onChanged:(v){widgetTextColor=v;});await save();refresh((){});},
    onFontChanged:(value)async{widgetFont=value;await save();refresh((){});},
   ),
   const Divider(height:28),
   const Text('امنیت',style:TextStyle(fontWeight:FontWeight.bold)),
   SwitchListTile(contentPadding:EdgeInsets.zero,value:biometric,title:const Text('قفل اثر انگشت / تشخیص چهره'),subtitle:const Text('هنگام ورود به برنامه احراز هویت انجام می‌شود'),onChanged:(v)async{
    if(v){try{final supported=await auth.isDeviceSupported();final available=await auth.getAvailableBiometrics();if(!supported||available.isEmpty){msg('روی این دستگاه بیومتریک فعال یا قابل استفاده نیست');return;}final ok=await auth.authenticate(localizedReason:'برای فعال‌سازی قفل برنامه احراز هویت کنید',options:const AuthenticationOptions(biometricOnly:true,stickyAuth:true));if(!ok)return;}catch(_){msg('فعال‌سازی بیومتریک ناموفق بود؛ قفل صفحه و مجوزهای دستگاه را بررسی کنید');return;}}
    setState(()=>biometric=v);await save();refresh((){});
   }),
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
 @override void initState(){super.initState();final all=widget.owner.boards;if(all.isNotEmpty)featured=all[math.Random().nextInt(all.length)];WidgetsBinding.instance.addPostFrameCallback((_)async{try{await widget.owner.syncChecklistWidget();}catch(_){}});}
 Future<void> addItem(Board b)async{
  final title=TextEditingController();final description=TextEditingController();final ctx=appNavigatorKey.currentContext;if(ctx==null)return;
  Future<void> commit(BuildContext dialogContext)async{final value=title.text.trim();if(value.isEmpty)return;setState(()=>b.items.add(Item(uid(),value,description:description.text.trim(),color:widget.owner.randomColor())));await widget.owner.save();if(dialogContext.mounted)Navigator.pop(dialogContext);}
  await showDialog<void>(context:ctx,builder:(dialogContext)=>StatefulBuilder(builder:(dialogContext,refresh)=>AlertDialog(
   title:const Text('مورد جدید'),
   content:SingleChildScrollView(child:Column(mainAxisSize:MainAxisSize.min,crossAxisAlignment:CrossAxisAlignment.stretch,children:[
    TextField(controller:title,autofocus:true,style:TextStyle(fontSize:widget.owner.inputSize*15/widget.owner.size,fontFamily:widget.owner.family),decoration:const InputDecoration(labelText:'عنوان مورد',hintText:'عنوان مورد را بنویس',border:OutlineInputBorder()),onChanged:(_)=>refresh((){})),
    if(title.text.trim().isNotEmpty)...[
     const SizedBox(height:12),
     Container(padding:const EdgeInsets.all(10),decoration:BoxDecoration(color:Theme.of(dialogContext).colorScheme.surfaceContainerHighest.withOpacity(.45),borderRadius:BorderRadius.circular(12),border:Border.all(color:Theme.of(dialogContext).colorScheme.outlineVariant)),child:Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:[
      Row(children:[const Expanded(child:Text('توضیحات این مورد',style:TextStyle(fontWeight:FontWeight.w600))),TextButton.icon(onPressed:()=>commit(dialogContext),icon:const Icon(Icons.save_outlined,size:18),label:const Text('بستن و ذخیره'))]),
      TextField(controller:description,minLines:2,maxLines:5,style:TextStyle(fontSize:widget.owner.inputSize*15/widget.owner.size,fontFamily:widget.owner.family),decoration:const InputDecoration(hintText:'توضیحات اختیاری را اینجا بنویس',border:OutlineInputBorder(),isDense:true))
     ]))
    ]
   ])),
   actions:[TextButton(onPressed:()=>Navigator.pop(dialogContext),child:const Text('انصراف')),FilledButton(onPressed:()=>commit(dialogContext),child:const Text('ذخیره مورد'))]
  )));
  title.dispose();description.dispose();
 }
 Future<void> editFolder(Folder f) async {final name=await widget.owner.pickName('ویرایش نام پوشه',f.name);if(name!=null&&name.trim().isNotEmpty){setState(()=>f.name=name.trim());await widget.owner.save();}}
 Future<void> deleteFolder(Folder f) async {final ok=await showDialog<bool>(context:context,builder:(d)=>AlertDialog(title:const Text('حذف پوشه'),content:Text('پوشه «${f.name}» حذف شود؟ چک‌لیست‌های داخل آن حذف نمی‌شوند و به بخش بدون پوشه منتقل خواهند شد.'),actions:[TextButton(onPressed:()=>Navigator.pop(d,false),child:const Text('انصراف')),FilledButton(onPressed:()=>Navigator.pop(d,true),child:const Text('حذف پوشه'))]));if(ok==true){setState((){for(final b in widget.owner.boards){if(b.folderId==f.id)b.folderId='';}widget.owner.folders.remove(f);});await widget.owner.save();widget.owner.msg('پوشه حذف شد؛ چک‌لیست‌ها حفظ شدند');}}
 @override Widget build(BuildContext context){final o=widget.owner;final inside=folder!=null;final lists=o.boards.where((b)=>b.folderId==(folder??'')).toList();final done=o.boards.fold<int>(0,(a,b)=>a+b.items.where((i)=>i.done).length);final total=o.boards.fold<int>(0,(a,b)=>a+b.items.length);return PopScope(canPop:false,onPopInvokedWithResult:(didPop,result){if(!didPop)_handleBack();},child:Scaffold(appBar:AppBar(title:Text(inside?(o.folders.where((f)=>f.id==folder).firstOrNull?.name??'پوشه'):'چک‌یار',style:const TextStyle(fontWeight:FontWeight.bold)),leading:inside?IconButton(onPressed:()=>setState(()=>folder=null),icon:const Icon(Icons.arrow_back)):null,actions:[PopupMenuButton<String>(tooltip:'ورود و خروجی اطلاعات',icon:const Icon(Icons.import_export),onSelected:(v){switch(v){case 'excel_in':o.excelIn();break;case 'excel_out':o.excelOut();break;case 'backup_out':o.backupOut();break;case 'backup_in':o.backupIn();break;}},itemBuilder:(_)=>const [PopupMenuItem(value:'excel_in',child:ListTile(dense:true,leading:Icon(Icons.upload_file),title:Text('ورود از اکسل'))),PopupMenuItem(value:'excel_out',child:ListTile(dense:true,leading:Icon(Icons.download),title:Text('خروجی اکسل'))),PopupMenuDivider(),PopupMenuItem(value:'backup_out',child:ListTile(dense:true,leading:Icon(Icons.backup),title:Text('خروجی پشتیبان'))),PopupMenuItem(value:'backup_in',child:ListTile(dense:true,leading:Icon(Icons.restore),title:Text('بازیابی پشتیبان')))]),IconButton(onPressed:o.settings,icon:const Icon(Icons.tune),tooltip:'تنظیمات')]),floatingActionButton:inside?FilledButton.tonalIcon(onPressed:()=>o.addBoard(folder!),icon:const Icon(Icons.add,size:18),label:const Text('چک‌لیست جدید'),style:FilledButton.styleFrom(visualDensity:VisualDensity.compact,padding:const EdgeInsets.symmetric(horizontal:12,vertical:8))):Column(mainAxisSize:MainAxisSize.min,crossAxisAlignment:CrossAxisAlignment.end,children:[FilledButton.tonalIcon(onPressed:o.addFolder,icon:const Icon(Icons.create_new_folder,size:18),label:const Text('پوشه جدید'),style:FilledButton.styleFrom(visualDensity:VisualDensity.compact,padding:const EdgeInsets.symmetric(horizontal:12,vertical:8))),const SizedBox(height:6),FilledButton.tonalIcon(onPressed:()=>o.addBoard(''),icon:const Icon(Icons.add_task,size:18),label:const Text('چک‌لیست جدید'),style:FilledButton.styleFrom(visualDensity:VisualDensity.compact,padding:const EdgeInsets.symmetric(horizontal:12,vertical:8)))]),body:ListView(padding:const EdgeInsets.all(18),children:[
 if(!inside)Container(padding:const EdgeInsets.symmetric(horizontal:16,vertical:11),decoration:BoxDecoration(gradient:const LinearGradient(colors:[Color(0xFF7569E0),Color(0xFF5144B8)]),borderRadius:BorderRadius.circular(16)),child:Row(children:[const Icon(Icons.auto_awesome_rounded,color:Colors.white70,size:18),const SizedBox(width:8),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,mainAxisSize:MainAxisSize.min,children:[const Text('پیشنهاد تصادفی از چک‌لیست‌های تو',style:TextStyle(color:Colors.white70,fontSize:11)),const SizedBox(height:3),Text(featured?.title??'هنوز چک‌لیستی برای نمایش وجود ندارد',maxLines:1,overflow:TextOverflow.ellipsis,style:const TextStyle(color:Colors.white,fontSize:16,fontWeight:FontWeight.bold))]))])),

 const SizedBox(height:22),Row(children:[Expanded(child:Text(inside?'چک‌لیست‌ها':'پوشه‌ها',style:const TextStyle(fontWeight:FontWeight.bold,fontSize:18))),Text(inside?'${lists.length}':'${o.folders.length}')]),
 if(!inside&&o.folders.isEmpty)const Padding(padding:EdgeInsets.all(24),child:Center(child:Text('برای شروع یک پوشه بساز'))),
 if(!inside)...o.folders.map((f){final n=o.boards.where((b)=>b.folderId==f.id).length;return InkWell(borderRadius:BorderRadius.circular(18),onTap:()=>setState(()=>folder=f.id),onLongPress:()=>editFolder(f),child:Container(width:double.infinity,margin:const EdgeInsets.only(bottom:10),padding:const EdgeInsets.all(16),decoration:BoxDecoration(color:Colors.white,borderRadius:BorderRadius.circular(18),border:Border.all(color:Color(f.color).withOpacity(.35))),child:Row(children:[Container(width:48,height:48,decoration:BoxDecoration(color:Color(f.color).withOpacity(.15),borderRadius:BorderRadius.circular(14)),child:Icon(Icons.folder_rounded,color:Color(f.color),size:27)),const SizedBox(width:14),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(f.name,style:TextStyle(fontWeight:FontWeight.bold,color:Color(f.color),fontSize:16)),const SizedBox(height:4),Text('$n چک‌لیست',style:const TextStyle(color:Colors.grey,fontSize:12))])),PopupMenuButton<String>(tooltip:'تنظیمات پوشه',onSelected:(v){if(v=='edit')editFolder(f);if(v=='delete')deleteFolder(f);},itemBuilder:(_)=>const [PopupMenuItem(value:'edit',child:ListTile(dense:true,leading:Icon(Icons.edit),title:Text('ویرایش نام'))),PopupMenuItem(value:'delete',child:ListTile(dense:true,leading:Icon(Icons.delete_outline),title:Text('حذف پوشه')))])])));}),
 if(!inside)...[const SizedBox(height:22),const Text('چک‌لیست‌های بدون پوشه',style:TextStyle(fontWeight:FontWeight.bold,fontSize:17))],
 if(lists.isEmpty)const Padding(padding:EdgeInsets.all(25),child:Center(child:Text('هنوز چک‌لیستی وجود ندارد'))),
 ...lists.map((b)=>Card(color:Color(b.color).withOpacity(.045),elevation:0,shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(18),side:BorderSide(color:Color(b.color).withOpacity(.28))),margin:const EdgeInsets.only(top:10),clipBehavior:Clip.antiAlias,child:ExpansionTile(tilePadding:const EdgeInsets.symmetric(horizontal:14,vertical:4),childrenPadding:const EdgeInsets.fromLTRB(14,0,14,12),iconColor:Color(b.color),collapsedIconColor:Color(b.color),title:Row(children:[Expanded(child:Text(b.title,style:TextStyle(fontWeight:FontWeight.bold,fontSize:16,color:Color(b.color)))),PopupMenuButton<String>(onSelected:(v)async{if(v=='move'){final target=await showModalBottomSheet<String>(context:context,builder:(c)=>SafeArea(child:Wrap(children:[const ListTile(title:Text('انتقال چک‌لیست به')),...[ListTile(leading:const Icon(Icons.inbox_outlined),title:const Text('بدون پوشه'),onTap:()=>Navigator.pop(c,'')),...o.folders.map((f)=>ListTile(leading:Icon(Icons.folder,color:Color(f.color)),title:Text(f.name),onTap:()=>Navigator.pop(c,f.id)))]])));if(target!=null){setState(()=>b.folderId=target);o.save();}}else if(v=='card_color'){await o.pickSliderColor(title:'رنگ کارت چک‌لیست',initial:b.color,onChanged:(value){setState(()=>b.color=value);o.save();});}else if(v=='edit'){final s=await o.pickName('ویرایش نام',b.title);if(s!=null&&s.isNotEmpty){setState(()=>b.title=s);o.save();}}else if(v=='delete'){setState(()=>o.boards.remove(b));o.save();}},itemBuilder:(_)=>[const PopupMenuItem(value:'card_color',child:Row(children:[Icon(Icons.color_lens_outlined,size:19),SizedBox(width:8),Text('تغییر رنگ کارت')])),const PopupMenuItem(value:'move',child:Text('انتقال به پوشه')),const PopupMenuItem(value:'edit',child:Text('ویرایش')),const PopupMenuItem(value:'delete',child:Text('حذف'))])]),subtitle:Text('${b.items.where((i)=>i.done).length} از ${b.items.length} مورد انجام شده',style:const TextStyle(fontSize:12,color:Colors.grey)),children:[if(b.items.isNotEmpty)Padding(padding:const EdgeInsets.only(bottom:10),child:ClipRRect(borderRadius:BorderRadius.circular(8),child:LinearProgressIndicator(value:b.items.where((i)=>i.done).length/b.items.length,minHeight:5,color:Color(b.color)))),...b.items.map((i)=>CheckboxListTile(dense:true,contentPadding:EdgeInsets.zero,controlAffinity:ListTileControlAffinity.leading,value:i.done,title:Column(crossAxisAlignment:CrossAxisAlignment.start,mainAxisSize:MainAxisSize.min,children:[Text(i.text,style:TextStyle(decoration:i.done?TextDecoration.lineThrough:null,color:Color(i.color))),if(i.description.trim().isNotEmpty)Padding(padding:const EdgeInsets.only(top:3),child:Text(i.description,style:TextStyle(fontSize:12,color:Colors.grey.shade700,decoration:i.done?TextDecoration.lineThrough:null))) ]),onChanged:(v){setState(()=>i.done=v??false);o.save();},secondary:IconButton(icon:const Icon(Icons.close,size:18),onPressed:(){setState(()=>b.items.remove(i));o.save();}))),Align(alignment:Alignment.centerRight,child:TextButton.icon(onPressed:()=>addItem(b),icon:const Icon(Icons.add),label:const Text('افزودن مورد')))])))

 ])));}
}
