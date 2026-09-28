import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/supabase_service.dart';
import '../home/home_screen.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget { const LoginScreen({super.key}); @override State<LoginScreen> createState()=>_LoginScreenState(); }
class _LoginScreenState extends State<LoginScreen> {
  final _formKey=GlobalKey<FormState>(); final _email=TextEditingController(); final _password=TextEditingController(); bool _loading=false; bool _obscure=true;
  @override void dispose(){_email.dispose();_password.dispose();super.dispose();}
  Future<void> _login() async { if(!_formKey.currentState!.validate())return; setState(()=>_loading=true); try{
    if(SupabaseService.isConfigured){ await SupabaseService.signIn(_email.text.trim(),_password.text); }
    else { final p=await SharedPreferences.getInstance(); final e=p.getString('accountEmail'); final pw=p.getString('accountPassword'); if(e==null||pw==null) throw Exception('لا يوجد حساب على هذا الجهاز.'); if(e.toLowerCase()!=_email.text.trim().toLowerCase()||pw!=_password.text) throw Exception('البريد الإلكتروني أو كلمة المرور غير صحيحة.'); await p.setBool('isLoggedIn',true); }
    if(mounted)Navigator.pushAndRemoveUntil(context,MaterialPageRoute(builder:(_)=>const HomeScreen()),(_)=>false);
  }catch(e){if(mounted)_show(_friendly(e));}finally{if(mounted)setState(()=>_loading=false);}}
  String _friendly(Object e){ final s=e.toString(); if(s.contains('Invalid login credentials'))return 'البريد الإلكتروني أو كلمة المرور غير صحيحة.'; if(s.contains('Email not confirmed'))return 'يرجى تأكيد البريد الإلكتروني قبل تسجيل الدخول.'; return s.replaceFirst('Exception: ',''); }
  void _show(String t)=>ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(t)));
  InputDecoration _dec(String l,IconData i)=>InputDecoration(labelText:l,prefixIcon:Icon(i),border:OutlineInputBorder(borderRadius:BorderRadius.circular(12)));
  @override Widget build(BuildContext context)=>Scaffold(backgroundColor:const Color(0xFF1A237E),body:SafeArea(child:SingleChildScrollView(child:Column(children:[const SizedBox(height:60),const Icon(Icons.balance,color:Color(0xFFD4AF37),size:90),const SizedBox(height:15),const Text('الأكرم للمحاماة',style:TextStyle(color:Colors.white,fontSize:29,fontWeight:FontWeight.bold)),const Text('نظام إدارة المحاماة السورية',style:TextStyle(color:Color(0xFFD4AF37))),const SizedBox(height:45),Container(padding:const EdgeInsets.fromLTRB(26,30,26,26),decoration:const BoxDecoration(color:Colors.white,borderRadius:BorderRadius.vertical(top:Radius.circular(30))),child:Form(key:_formKey,child:Column(children:[const Align(alignment:Alignment.centerRight,child:Text('تسجيل الدخول',style:TextStyle(fontSize:24,fontWeight:FontWeight.bold,color:Color(0xFF1A237E)))),const SizedBox(height:22),TextFormField(controller:_email,keyboardType:TextInputType.emailAddress,textDirection:TextDirection.ltr,decoration:_dec('البريد الإلكتروني',Icons.email_outlined),validator:(v)=>v==null||!v.contains('@')?'أدخل بريداً إلكترونياً صحيحاً':null),const SizedBox(height:15),TextFormField(controller:_password,obscureText:_obscure,decoration:_dec('كلمة المرور',Icons.lock_outline).copyWith(suffixIcon:IconButton(onPressed:()=>setState(()=>_obscure=!_obscure),icon:Icon(_obscure?Icons.visibility_off:Icons.visibility))),validator:(v)=>v==null||v.length<6?'كلمة المرور 6 أحرف على الأقل':null),const SizedBox(height:22),SizedBox(width:double.infinity,height:54,child:ElevatedButton(onPressed:_loading?null:_login,style:ElevatedButton.styleFrom(backgroundColor:const Color(0xFF1A237E),foregroundColor:Colors.white),child:_loading?const CircularProgressIndicator(color:Colors.white):const Text('تسجيل الدخول',style:TextStyle(fontSize:17,fontWeight:FontWeight.bold)))),const SizedBox(height:12),TextButton(onPressed:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>const RegisterScreen())),child:const Text('إنشاء حساب جديد'))])))])));
}

