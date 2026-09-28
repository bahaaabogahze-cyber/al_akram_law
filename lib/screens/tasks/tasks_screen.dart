import 'package:flutter/material.dart';
import '../../core/colors.dart';
import '../../services/local_store.dart';

class TasksScreen extends StatefulWidget { const TasksScreen({super.key}); @override State<TasksScreen> createState() => _TasksScreenState(); }
class _TasksScreenState extends State<TasksScreen> {
  List<Map<String,dynamic>> _items=[]; bool _loading=true;
  @override void initState(){super.initState();_load();}
  Future<void> _load() async { try { final x=await LocalStore.getTasks(); if(mounted)setState((){_items=x;_loading=false;}); } catch(e){if(mounted){setState(()=>_loading=false);_snack('تعذر تحميل المهام: $e');}} }
  void _snack(String s)=>ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(s)));
  Future<void> _add() async {
    final c=TextEditingController(); final d=TextEditingController(); final form=GlobalKey<FormState>();
    await showDialog(context:context,builder:(ctx)=>AlertDialog(title:const Text('مهمة جديدة'),content:Form(key:form,child:Column(mainAxisSize:MainAxisSize.min,children:[TextFormField(controller:c,decoration:const InputDecoration(labelText:'عنوان المهمة'),validator:(v)=>v==null||v.trim().isEmpty?'أدخل العنوان':null),TextFormField(controller:d,decoration:const InputDecoration(labelText:'الوصف'))])),actions:[TextButton(onPressed:()=>Navigator.pop(ctx),child:const Text('إلغاء')),FilledButton(onPressed:()async{if(!form.currentState!.validate())return;try{await LocalStore.saveTask({'id':DateTime.now().microsecondsSinceEpoch.toString(),'title':c.text.trim(),'description':d.text.trim(),'priority':'normal','completed':false});if(ctx.mounted)Navigator.pop(ctx);await _load();}catch(e){_snack('تعذر الحفظ: $e');}},child:const Text('حفظ'))])); c.dispose();d.dispose();
  }
  @override Widget build(BuildContext context)=>Scaffold(backgroundColor:AppColors.background,appBar:AppBar(title:const Text('المهام')),body:_loading?const Center(child:CircularProgressIndicator()):_items.isEmpty?const Center(child:Text('لا توجد مهام.')):RefreshIndicator(onRefresh:_load,child:ListView.builder(padding:const EdgeInsets.all(16),itemCount:_items.length,itemBuilder:(_,i){final t=_items[i];final done=t['completed']==true;return Card(child:CheckboxListTile(value:done,onChanged:(v)async{await LocalStore.setTaskCompleted(t['id'].toString(),v??false);await _load();},title:Text(t['title']??'',style:TextStyle(decoration:done?TextDecoration.lineThrough:null,fontWeight:FontWeight.bold)),subtitle:Text(t['description']??''),secondary:IconButton(icon:const Icon(Icons.delete_outline),onPressed:()async{await LocalStore.deleteTask(t['id'].toString());await _load();})));})),floatingActionButton:FloatingActionButton.extended(onPressed:_add,backgroundColor:AppColors.primary,icon:const Icon(Icons.add,color:Colors.white),label:const Text('إضافة مهمة',style:TextStyle(color:Colors.white))));
}
