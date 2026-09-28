import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/supabase_config.dart';

class SupabaseService {
  static const url = String.fromEnvironment('SUPABASE_URL', defaultValue: SupabaseConfig.url);
  static const publishableKey = String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY', defaultValue: SupabaseConfig.publishableKey);

  static bool get isConfigured => url.isNotEmpty && publishableKey.isNotEmpty;
  static SupabaseClient get client => Supabase.instance.client;
  static User? get user => isConfigured ? client.auth.currentUser : null;
  static String get uid => user!.id;

  static Future<void> initialize() async {
    if (!isConfigured) return;
    await Supabase.initialize(
      url: url,
      publishableKey: publishableKey,
      authOptions: const FlutterAuthClientOptions(authFlowType: AuthFlowType.pkce),
    );
  }

  static Future<AuthResponse> signIn(String email, String password) =>
      client.auth.signInWithPassword(email: email, password: password);

  static Future<AuthResponse> signUp({
    required String email,
    required String password,
    required Map<String, dynamic> profile,
  }) async {
    final response = await client.auth.signUp(email: email, password: password, data: profile);
    if (response.user != null && response.session != null) {
      await upsertProfile(response.user!.id, email, profile);
    }
    return response;
  }

  static Future<Map<String, dynamic>?> getProfile() async {
    final row = await client.from('profiles').select().eq('id', uid).maybeSingle();
    return row == null ? null : Map<String, dynamic>.from(row);
  }

  static Future<void> upsertProfile(String id, String email, Map<String, dynamic> data) async {
    await client.from('profiles').upsert({
      'id': id,
      'email': email,
      ...data,
      'updated_at': DateTime.now().toIso8601String(),
    });
  }

  static Future<List<Map<String, dynamic>>> getClients() async {
    final rows = await client.from('clients').select().eq('user_id', uid).order('created_at', ascending: false);
    return rows.map((r) => Map<String, dynamic>.from(r)).toList();
  }

  static Future<Map<String, dynamic>> saveClient(Map<String, dynamic> clientData) async {
    final payload = <String, dynamic>{
      'user_id': uid,
      'full_name': clientData['full_name'] ?? clientData['name'],
      'national_id': clientData['national_id'],
      'phone': clientData['phone'],
      'email': clientData['email'],
      'address': clientData['address'],
      'notes': clientData['notes'],
      'updated_at': DateTime.now().toIso8601String(),
    };
    final existingId = clientData['id']?.toString();
    if (existingId != null && RegExp(r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[1-5][0-9a-fA-F]{3}-[89abAB][0-9a-fA-F]{3}-[0-9a-fA-F]{12}$').hasMatch(existingId)) {
      payload['id'] = existingId;
    }
    final row = await client.from('clients').upsert(payload).select().single();
    return Map<String, dynamic>.from(row);
  }

  static Future<void> deleteClient(String id) async {
    await client.from('clients').delete().eq('id', id).eq('user_id', uid);
  }

  static Future<List<Map<String, dynamic>>> getTasks() async {
    final rows = await client.from('tasks').select().eq('user_id', uid).order('due_at', ascending: true);
    return rows.map((r) => Map<String, dynamic>.from(r)).toList();
  }

  static Future<Map<String, dynamic>> saveTask(Map<String, dynamic> task) async {
    final payload = <String, dynamic>{
      'user_id': uid,
      'case_id': task['case_id'],
      'title': task['title'],
      'description': task['description'],
      'due_at': task['due_at'],
      'priority': task['priority'] ?? 'normal',
      'completed': task['completed'] ?? false,
      'updated_at': DateTime.now().toIso8601String(),
    };
    final existingId = task['id']?.toString();
    if (existingId != null && RegExp(r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[1-5][0-9a-fA-F]{3}-[89abAB][0-9a-fA-F]{3}-[0-9a-fA-F]{12}$').hasMatch(existingId)) {
      payload['id'] = existingId;
    }
    final row = await client.from('tasks').upsert(payload).select().single();
    return Map<String, dynamic>.from(row);
  }

  static Future<void> deleteTask(String id) async {
    await client.from('tasks').delete().eq('id', id).eq('user_id', uid);
  }

  static Future<void> setTaskCompleted(String id, bool completed) async {
    await client.from('tasks').update({'completed': completed, 'updated_at': DateTime.now().toIso8601String()}).eq('id', id).eq('user_id', uid);
  }

  static Future<List<String>> getLegalCategories() async {
    final rows = await client.from('legal_sources').select('title').eq('is_current', true).order('title');
    return rows.map((r) => r['title']?.toString() ?? '').where((x) => x.isNotEmpty).toSet().toList();
  }

  static Future<List<Map<String, dynamic>>> searchLegalArticles(String query, {String? category, int maxResults = 30}) async {
    final result = await client.rpc('search_legal_articles', params: {
      'q': query,
      'category': category,
      'max_results': maxResults,
    });
    return (result as List).map((r) => Map<String, dynamic>.from(r)).toList();
  }

  static Future<List<Map<String, dynamic>>> browseLegalArticles({String? category, int limit = 50, int offset = 0}) async {
    final result = await client.rpc('browse_legal_articles', params: {
      'category': category,
      'page_size': limit,
      'page_offset': offset,
    });
    return (result as List).map((r) => Map<String, dynamic>.from(r)).toList();
  }

  static Future<String> uploadDocument(File file, String documentId) async {
    final ext = file.path.contains('.') ? file.path.split('.').last.toLowerCase() : 'bin';
    final path = '$uid/$documentId.$ext';
    await client.storage.from('legal-documents').upload(
      path,
      file,
      fileOptions: const FileOptions(upsert: true),
    );
    return path;
  }

  static Future<void> deleteStorageFile(String? path) async {
    if (path == null || path.trim().isEmpty) return;
    await client.storage.from('legal-documents').remove([path]);
  }

  static Future<String> createSignedDocumentUrl(String path, {int expiresIn = 3600}) =>
      client.storage.from('legal-documents').createSignedUrl(path, expiresIn);

  static Future<void> signOut() => client.auth.signOut();
}
