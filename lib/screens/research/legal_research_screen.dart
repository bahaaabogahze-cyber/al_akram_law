import 'package:flutter/material.dart';
import '../../core/colors.dart';
import '../../services/supabase_service.dart';

class LegalResearchScreen extends StatefulWidget {
  final String? initialText;
  const LegalResearchScreen({super.key, this.initialText});
  @override State<LegalResearchScreen> createState()=>_LegalResearchScreenState();
}
class _LegalResearchScreenState extends State<LegalResearchScreen> {
  late final TextEditingController _controller;
  String _category='الكل'; bool _loading=false; String? _error; List<Map<String,dynamic>> _results=[];
  List<String> _categories=['الكل'];
  @override void initState(){super.initState();_controller=TextEditingController(text:widget.initialText??'');_loadCategories();}
  Future<void> _loadCategories() async { try { final data=await SupabaseService.getLegalCategories(); if(mounted)setState(()=>_categories=['الكل',...data]); } catch (_) {} }
  @override void dispose(){_controller.dispose();super.dispose();}
  Future<void> _search() async {
    final q=_controller.text.trim(); if(q.isEmpty){setState(()=>_results=[]);return;}
    setState(() { _loading = true; _error = null; });
    try { final data=await SupabaseService.searchLegalArticles(q,category:_category=='الكل'?null:_category); if(mounted)setState(()=>_results=data); }
    catch(e){if(mounted)setState(()=>_error='تعذر تنفيذ البحث. تأكد من تشغيل migration قاعدة البيانات ومنح الدالة صلاحية التنفيذ للمستخدمين المسجلين.');}
    finally{if(mounted)setState(()=>_loading=false);}
  }
  @override Widget build(BuildContext context)=>Scaffold(backgroundColor:AppColors.background,appBar:AppBar(title:const Text('البحث القانوني السوري')),body:ListView(padding:const EdgeInsets.all(16),children:[
    Card(child:Padding(padding:const EdgeInsets.all(16),child:Column(children:[const Align(alignment:Alignment.centerRight,child:Text('ابحث في قاعدة النصوص القانونية الرسمية المضافة للنظام',style:TextStyle(fontWeight:FontWeight.bold,fontSize:17))),const SizedBox(height:10),TextField(controller:_controller,minLines:3,maxLines:7,textDirection:TextDirection.rtl,decoration:const InputDecoration(hintText:'اكتب المادة أو موضوع القضية أو الكلمات القانونية...',border:OutlineInputBorder())),const SizedBox(height:10),DropdownButtonFormField<String>(value:_category,decoration:const InputDecoration(labelText:'تصفية حسب المصدر',border:OutlineInputBorder()),items:_categories.map((v)=>DropdownMenuItem(value:v,child:Text(v))).toList(),onChanged:(v){if(v!=null)setState(()=>_category=v);}),const SizedBox(height:12),SizedBox(width:double.infinity,height:50,child:FilledButton.icon(onPressed:_loading?null:_search,icon:_loading?const SizedBox(width:18,height:18,child:CircularProgressIndicator(strokeWidth:2,color:Colors.white)):const Icon(Icons.search),label:const Text('بحث في قاعدة النصوص')))]))),
    const SizedBox(height:12),const Card(child:Padding(padding:EdgeInsets.all(14),child:Text('تنبيه مهني: هذه أداة بحث ومساعدة وليست بديلاً عن مراجعة النص الرسمي النافذ وآخر التعديلات والاجتهاد القضائي قبل اعتماد أي إجراء أو مذكرة.'))),
    if(_error!=null) Padding(padding:const EdgeInsets.all(16),child:Text(_error!,style:const TextStyle(color:Colors.red))),
    if(!_loading&&_controller.text.trim().isNotEmpty&&_results.isEmpty&&_error==null) const Padding(padding:EdgeInsets.all(20),child:Center(child:Text('لا توجد نتائج في قاعدة النصوص المتاحة حاليًا.'))),
    ..._results.map((a)=>Card(margin:const EdgeInsets.only(bottom:10),child:ExpansionTile(leading:const CircleAvatar(child:Icon(Icons.gavel)),title:Text('${a['article_number']??''} — ${a['title']??''}',style:const TextStyle(fontWeight:FontWeight.bold)),subtitle:Text(a['source_title']??''),childrenPadding:const EdgeInsets.fromLTRB(16,0,16,16),children:[Align(alignment:Alignment.centerRight,child:Text(a['content']??'')),if((a['official_reference']??'').toString().isNotEmpty) Align(alignment:Alignment.centerRight,child:Text('المرجع الرسمي: ${a['official_reference']}')),if((a['version_label']??'').toString().isNotEmpty) Align(alignment:Alignment.centerRight,child:Text('الإصدار: ${a['version_label']}')),if((a['source_url']??'').toString().isNotEmpty) Align(alignment:Alignment.centerRight,child:Text('المصدر: ${a['source_url']}'))]))),
  ]));
}
