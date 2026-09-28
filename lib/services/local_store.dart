import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'supabase_service.dart';

class LocalStore {
  static const _casesKey = 'cases_v2';
  static const _documentsKey = 'documents_v2';
  static const _hearingsKey = 'hearings_v2';
  static const _notificationsKey = 'notifications_v2';
  static const _tasksKey = 'tasks_v1';
  static bool get _remote => SupabaseService.isConfigured && SupabaseService.user != null;
  static String? get _uid => SupabaseService.user?.id;
  static Future<SharedPreferences> _prefs() => SharedPreferences.getInstance();

  static Future<List<Map<String, dynamic>>> _readList(String key) async {
    final p = await _prefs(); final raw = p.getString(key);
    if (raw == null || raw.isEmpty) return [];
    try { final decoded = jsonDecode(raw); if (decoded is! List) return []; return decoded.map<Map<String, dynamic>>((e) => Map<String, dynamic>.from(e as Map)).toList(); } catch (_) { return []; }
  }
  static Future<void> _writeList(String key, List<Map<String, dynamic>> value) async => (await _prefs()).setString(key, jsonEncode(value));

  static Future<List<Map<String, dynamic>>> getCases() async {
    if (_remote) { final rows = await SupabaseService.client.from('cases').select().eq('user_id', _uid!).order('created_at', ascending: false); return rows.map((r) => _caseFromRemote(r)).toList(); }
    return _readList(_casesKey);
  }
  static Map<String, dynamic> _caseFromRemote(Map<String, dynamic> r) => {'id': r['id'], 'title': r['title'], 'caseNumber': r['case_number'], 'client': r['client_name'], 'court': r['court'], 'opponent': r['opponent'], 'summary': r['summary'], 'notes': r['notes'], 'type': r['case_type'], 'status': r['status'], 'createdAt': r['created_at'], 'updatedAt': r['updated_at']};
  static Future<void> saveCase(Map<String, dynamic> item) async {
    if (_remote) { await SupabaseService.client.from('cases').upsert({'id': item['id'], 'user_id': _uid, 'title': item['title'], 'case_number': item['caseNumber'], 'client_name': item['client'], 'court': item['court'], 'opponent': item['opponent'], 'summary': item['summary'], 'notes': item['notes'], 'case_type': item['type'], 'status': item['status'], 'created_at': item['createdAt'] ?? DateTime.now().toIso8601String(), 'updated_at': DateTime.now().toIso8601String()}); return; }
    final list = await getCases(); final id = item['id']; final i = list.indexWhere((e) => e['id'] == id); if (i >= 0) list[i] = item; else list.insert(0, item); await _writeList(_casesKey, list);
  }
  static Future<void> deleteCase(String id) async { if (_remote) { await SupabaseService.client.from('cases').delete().eq('id', id).eq('user_id', _uid!); return; } final list = await getCases(); list.removeWhere((e) => e['id'] == id); await _writeList(_casesKey, list); }

  static Future<List<Map<String, dynamic>>> getClients() async {
    if (_remote) return SupabaseService.getClients();
    return _readList('clients_v1');
  }
  static Future<void> saveClient(Map<String, dynamic> item) async {
    if (_remote) { await SupabaseService.saveClient(item); return; }
    final list = await getClients(); final id = item['id']; final i = list.indexWhere((e) => e['id'] == id); if (i >= 0) list[i] = item; else list.insert(0, item); await _writeList('clients_v1', list);
  }
  static Future<void> deleteClient(String id) async { if (_remote) { await SupabaseService.deleteClient(id); return; } final list = await getClients(); list.removeWhere((e) => e['id'].toString() == id); await _writeList('clients_v1', list); }

  static Future<List<Map<String, dynamic>>> getDocuments() async {
    if (_remote) { final rows = await SupabaseService.client.from('documents').select().eq('user_id', _uid!).order('created_at', ascending: false); return rows.map((r) => Map<String, dynamic>.from(r)).toList(); }
    return _readList(_documentsKey);
  }
  static Future<void> saveDocument(Map<String, dynamic> item) async {
    if (_remote) { await SupabaseService.client.from('documents').upsert({'id': item['id'], 'user_id': _uid, 'case_id': item['caseId'], 'title': item['title'], 'notes': item['notes'], 'tags': item['tags'], 'storage_path': item['storagePath'] ?? item['path'], 'created_at': item['createdAt'] ?? DateTime.now().toIso8601String(), 'updated_at': DateTime.now().toIso8601String()}); return; }
    final list = await getDocuments(); final id = item['id']; final i = list.indexWhere((e) => e['id'] == id); if (i >= 0) list[i] = item; else list.insert(0, item); await _writeList(_documentsKey, list);
  }
  static Future<void> deleteDocument(String id) async {
    if (_remote) {
      final row = await SupabaseService.client.from('documents').select('storage_path').eq('id', id).eq('user_id', _uid!).maybeSingle();
      final path = row?['storage_path']?.toString();
      await SupabaseService.client.from('documents').delete().eq('id', id).eq('user_id', _uid!);
      await SupabaseService.deleteStorageFile(path);
      return;
    }
    final list = await getDocuments(); list.removeWhere((e) => e['id'] == id); await _writeList(_documentsKey, list);
  }

  static Future<List<Map<String, dynamic>>> getHearings() async { if (_remote) { final rows = await SupabaseService.client.from('hearings').select().eq('user_id', _uid!).order('hearing_at', ascending: true); return rows.map((r) => Map<String, dynamic>.from(r)).toList(); } return _readList(_hearingsKey); }
  static Future<void> saveHearing(Map<String, dynamic> item) async { if (_remote) { await SupabaseService.client.from('hearings').upsert({'id': item['id'], 'user_id': _uid, 'case_id': item['caseId'], 'title': item['title'], 'court': item['court'], 'hearing_at': item['hearingAt'], 'notes': item['notes'], 'created_at': item['createdAt'] ?? DateTime.now().toIso8601String()}); return; } final list = await getHearings(); final id = item['id']; final i = list.indexWhere((e) => e['id'] == id); if (i >= 0) list[i] = item; else list.insert(0, item); await _writeList(_hearingsKey, list); }
  static Future<void> deleteHearing(String id) async { if (_remote) { await SupabaseService.client.from('hearings').delete().eq('id', id).eq('user_id', _uid!); return; } final list = await getHearings(); list.removeWhere((e) => e['id'] == id); await _writeList(_hearingsKey, list); }

  static Future<List<Map<String, dynamic>>> getTasks() async { if (_remote) return SupabaseService.getTasks(); return _readList(_tasksKey); }
  static Future<void> saveTask(Map<String, dynamic> item) async { if (_remote) { await SupabaseService.saveTask(item); return; } final list = await getTasks(); final id = item['id']; final i = list.indexWhere((e) => e['id'] == id); if (i >= 0) list[i] = item; else list.insert(0, item); await _writeList(_tasksKey, list); }
  static Future<void> deleteTask(String id) async { if (_remote) { await SupabaseService.deleteTask(id); return; } final list = await getTasks(); list.removeWhere((e) => e['id'].toString() == id); await _writeList(_tasksKey, list); }
  static Future<void> setTaskCompleted(String id, bool value) async { if (_remote) { await SupabaseService.setTaskCompleted(id, value); return; } final list = await getTasks(); final i = list.indexWhere((e) => e['id'].toString() == id); if (i >= 0) { list[i]['completed'] = value; await _writeList(_tasksKey, list); } }

  static Future<List<Map<String, dynamic>>> getNotifications() async { if (_remote) { final rows = await SupabaseService.client.from('notifications').select().eq('user_id', _uid!).order('created_at', ascending: false); return rows.map((r) => {'id': r['id'], 'title': r['title'], 'body': r['body'], 'date': r['created_at'], 'read': r['read']}).toList(); } return _readList(_notificationsKey); }
  static Future<void> addNotification(String title, String body) async { if (_remote) { await SupabaseService.client.from('notifications').insert({'user_id': _uid, 'title': title, 'body': body}); return; } final list = await getNotifications(); list.insert(0, {'id': DateTime.now().microsecondsSinceEpoch.toString(), 'title': title, 'body': body, 'date': DateTime.now().toIso8601String(), 'read': false}); await _writeList(_notificationsKey, list); }
  static Future<void> markAllNotificationsRead() async { if (_remote) { await SupabaseService.client.from('notifications').update({'read': true}).eq('user_id', _uid!); return; } final list = await getNotifications(); for (final n in list) n['read'] = true; await _writeList(_notificationsKey, list); }
  static Future<void> deleteNotification(String id) async { if (_remote) { await SupabaseService.client.from('notifications').delete().eq('id', id).eq('user_id', _uid!); return; } final list = await getNotifications(); list.removeWhere((e) => e['id'].toString() == id); await _writeList(_notificationsKey, list); }
}
