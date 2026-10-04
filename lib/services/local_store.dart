import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
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

  // التخزين المحلي يجب ألا يكون مشتركًا بين حسابات مختلفة على نفس الجهاز.
  // نستخدم user_id الحالي عند توفر جلسة Supabase، وguest فقط للحالة المحلية
  // التي لا يوجد فيها مستخدم مسجل الدخول.
  static String _scopedKey(String key) {
    final uid = _uid;
    if (uid != null && uid.isNotEmpty) return '${key}_$uid';
    return '${key}_guest';
  }

  static Future<List<Map<String, dynamic>>> _readList(String key) async {
    final scopedKey = _scopedKey(key);
    final p = await _prefs(); final raw = p.getString(scopedKey);
    if (raw == null || raw.isEmpty) return [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return [];
      return decoded
          .whereType<Map>()
          .map<Map<String, dynamic>>(
              (e) => Map<String, dynamic>.from(e))
          .toList();
    } catch (_) {
      return [];
    }
  }
  static Future<void> _writeList(String key, List<Map<String, dynamic>> value) async =>
      (await _prefs()).setString(_scopedKey(key), jsonEncode(value));

  static Future<List<Map<String, dynamic>>> getCases() async {
    if (_remote) {
      final rows = await SupabaseService.getCases();
      return rows.map((r) => _caseFromRemote(r)).toList();
    }
    return _readList(_casesKey);
  }

  static Map<String, dynamic> _caseFromRemote(Map<String, dynamic> r) => {
    'id': r['id']?.toString(),
    'title': r['title'],
    'caseNumber': r['case_number'],
    'clientId': r['client_id']?.toString(),
    'client': r['client_name'],
    'court': r['court'],
    'opponent': r['opponent'],
    'summary': r['summary'],
    'notes': r['notes'],
    'type': r['case_type'],
    'status': r['status'] ?? 'جارية',
    'createdAt': r['created_at'],
    'updatedAt': r['updated_at'],
  };

  static Future<void> saveCase(Map<String, dynamic> item) async {
    if (_remote) {
      await SupabaseService.saveCase(item);
      return;
    }
    final list = await getCases();
    final id = item['id'];
    final i = list.indexWhere((e) => e['id'].toString() == id.toString());
    if (i >= 0) {
      list[i] = item;
    } else {
      list.insert(0, item);
    }
    await _writeList(_casesKey, list);
  }
  static Future<void> deleteCase(String id) async {
    if (_remote) {
      // مستندات القضية تُحذف من الجدول تلقائياً (cascade)، لذلك نحذف ملفاتها من Storage أيضاً.
      final docs = await SupabaseService.client.from('documents').select('storage_path').eq('case_id', id).eq('user_id', _uid!);
      await SupabaseService.client.from('cases').delete().eq('id', id).eq('user_id', _uid!);
      for (final d in docs) {
        try { await SupabaseService.deleteStorageFile(d['storage_path']?.toString()); } catch (_) {}
      }
      return;
    }
    final list = await getCases(); list.removeWhere((e) => e['id'] == id); await _writeList(_casesKey, list);
  }

  static Map<String, dynamic> _clientFromRemote(Map<String, dynamic> r) => {
    'id': r['id']?.toString(),
    'full_name': r['full_name'] ?? '',
    'national_id': r['national_id'] ?? '',
    'phone': r['phone'] ?? '',
    'email': r['email'] ?? '',
    'address': r['address'] ?? '',
    'notes': r['notes'] ?? '',
    'created_at': r['created_at'],
    'updated_at': r['updated_at'],
  };

  static Future<List<Map<String, dynamic>>> getClients() async {
    if (_remote) {
      final rows = await SupabaseService.getClients();
      return rows.map(_clientFromRemote).toList();
    }
    return _readList('clients_v1');
  }

  static Future<Map<String, dynamic>?> getProfile() async {
    if (_remote) return SupabaseService.getProfile();
    final p = await _prefs();
    return {
      'full_name': p.getString('userName') ?? 'المحامي',
      'email': p.getString('userEmail') ?? '',
      'phone': p.getString('userPhone') ?? '',
      'specialty': p.getString('userSpecialty') ?? '',
      'bar_number': p.getString('barNumber') ?? '',
    };
  }
  static Future<void> saveClient(Map<String, dynamic> item) async {
    if (_remote) { await SupabaseService.saveClient(item); return; }
    final list = await getClients(); final id = item['id']; final i = list.indexWhere((e) => e['id'] == id); if (i >= 0) list[i] = item; else list.insert(0, item); await _writeList('clients_v1', list);
  }
  static Future<void> deleteClient(String id) async { if (_remote) { await SupabaseService.deleteClient(id); return; } final list = await getClients(); list.removeWhere((e) => e['id'].toString() == id); await _writeList('clients_v1', list); }

  static Map<String, dynamic> _documentFromRemote(Map<String, dynamic> r) => {'id': r['id']?.toString(), 'caseId': r['case_id']?.toString(), 'title': r['title'], 'notes': r['notes'], 'tags': r['tags'], 'storagePath': r['storage_path'], 'mimeType': r['mime_type'], 'ocrText': r['ocr_text'], 'createdAt': r['created_at'], 'updatedAt': r['updated_at']};

  static Future<List<Map<String, dynamic>>> getDocuments() async {
    if (_remote) { final rows = await SupabaseService.client.from('documents').select().eq('user_id', _uid!).order('created_at', ascending: false); return rows.map((r) => _documentFromRemote(Map<String, dynamic>.from(r))).toList(); }
    return _readList(_documentsKey);
  }
  static Future<void> saveDocument(Map<String, dynamic> item) async {
    if (_remote) { await SupabaseService.client.from('documents').upsert({'id': item['id'], 'user_id': _uid, 'case_id': item['caseId'], 'title': item['title'], 'notes': item['notes'], 'tags': item['tags'], 'storage_path': item['storagePath'], 'mime_type': item['mimeType'] ?? 'application/pdf', 'ocr_text': item['ocrText'] ?? '', 'created_at': item['createdAt'] ?? DateTime.now().toUtc().toIso8601String(), 'updated_at': DateTime.now().toUtc().toIso8601String()}); return; }
    final list = await getDocuments(); final id = item['id']; final i = list.indexWhere((e) => e['id'] == id); if (i >= 0) list[i] = item; else list.insert(0, item); await _writeList(_documentsKey, list);
  }
  static Future<void> deleteDocument(String id) async {
    if (_remote) {
      final row = await SupabaseService.client.from('documents').select('storage_path').eq('id', id).eq('user_id', _uid!).maybeSingle();
      final path = row?['storage_path']?.toString();
      await SupabaseService.client.from('documents').delete().eq('id', id).eq('user_id', _uid!);
      try { await SupabaseService.deleteStorageFile(path); } catch (_) {}
      return;
    }
    final list = await getDocuments(); list.removeWhere((e) => e['id'].toString() == id); await _writeList(_documentsKey, list);
  }

  // مسار النسخة المحلية (كاش) لملف المستند على الجهاز.
  static Future<String> localDocumentPath(String id, String ext) async {
    final dir = await getApplicationDocumentsDirectory();
    return '${dir.path}/legal_doc_$id.$ext';
  }
  static String _extOf(String? p) => (p == null || !p.contains('.')) ? 'jpg' : p.split('.').last.toLowerCase();

  // يحدد لكل مستند مصدر الصورة: نسخة محلية ('path') أو رابط موقّع مؤقت من Storage ('signedUrl').
  static Future<List<Map<String, dynamic>>> resolveDocumentFiles(List<Map<String, dynamic>> docs) async {
    final dir = await getApplicationDocumentsDirectory();
    await Future.wait(docs.map((d) async {
      final local = d['path']?.toString();
      if (local != null && local.isNotEmpty && File(local).existsSync()) return;
      d.remove('path');
      final sp = d['storagePath']?.toString();
      final cached = '${dir.path}/legal_doc_${d['id']}.${_extOf(sp)}';
      if (File(cached).existsSync()) { d['path'] = cached; return; }
      if (_remote && sp != null && sp.isNotEmpty) {
        try { d['signedUrl'] = await SupabaseService.createSignedDocumentUrl(sp); } catch (_) {}
      }
    }));
    return docs;
  }

  static Map<String, dynamic> _hearingFromRemote(Map<String, dynamic> r) => {'id': r['id']?.toString(), 'caseId': r['case_id']?.toString(), 'title': r['title'], 'court': r['court'], 'client': r['client_name'], 'caseNumber': r['case_number'], 'hearingAt': r['hearing_at'], 'notes': r['notes'], 'status': r['status'], 'createdAt': r['created_at'], 'updatedAt': r['updated_at']};
  static Future<List<Map<String, dynamic>>> getHearings() async { if (_remote) { final rows = await SupabaseService.client.from('hearings').select().eq('user_id', _uid!).order('hearing_at', ascending: true); return rows.map((r) => _hearingFromRemote(Map<String, dynamic>.from(r))).toList(); } return _readList(_hearingsKey); }
  static Future<void> saveHearing(Map<String, dynamic> item) async { if (_remote) { await SupabaseService.client.from('hearings').upsert({'id': item['id'], 'user_id': _uid, 'case_id': item['caseId'], 'title': item['title'], 'court': item['court'], 'client_name': item['client'], 'case_number': item['caseNumber'], 'hearing_at': item['hearingAt'], 'notes': item['notes'], 'status': item['status'] ?? 'قادمة', 'created_at': item['createdAt'] ?? DateTime.now().toUtc().toIso8601String(), 'updated_at': DateTime.now().toUtc().toIso8601String()}); await SupabaseService.upsertHearingNotification(hearingId: item['id'].toString(), title: 'تذكير بجلسة', body: '${item['title'] ?? 'جلسة'} - ${item['hearingAt'] ?? ''}'); return; } final list = await getHearings(); final id = item['id']; final i = list.indexWhere((e) => e['id'] == id); if (i >= 0) list[i] = item; else list.insert(0, item); await _writeList(_hearingsKey, list); await _upsertLocalLinkedNotification('hearing', id.toString(), 'تذكير بجلسة', '${item['title'] ?? 'جلسة'} - ${item['hearingAt'] ?? ''}'); }
  static Future<void> deleteHearing(String id) async { if (_remote) { await SupabaseService.client.from('hearings').delete().eq('id', id).eq('user_id', _uid!); await SupabaseService.deleteLinkedNotifications('hearing', id); return; } final list = await getHearings(); list.removeWhere((e) => e['id'].toString() == id); await _writeList(_hearingsKey, list); final notifications = await getNotifications(); notifications.removeWhere((n) => n['relatedType'] == 'hearing' && n['relatedId'].toString() == id); await _writeList(_notificationsKey, notifications); }

  static Future<List<Map<String, dynamic>>> getTasks() async {
    if (_remote) {
      final rows = await SupabaseService.getTasks();
      return rows.map((r) => _taskFromRemote(r)).toList();
    }
    return _readList(_tasksKey);
  }

  static Map<String, dynamic> _taskFromRemote(Map<String, dynamic> r) => {
    'id': r['id']?.toString(),
    'caseId': r['case_id']?.toString(),
    'title': r['title'],
    'description': r['description'],
    'dueAt': r['due_at'],
    'priority': r['priority'] ?? 'normal',
    'completed': r['completed'] == true,
    'createdAt': r['created_at'],
    'updatedAt': r['updated_at'],
  };

  static Future<void> saveTask(Map<String, dynamic> item) async {
    if (_remote) {
      final saved = await SupabaseService.saveTask(item);
      final savedId = saved['id']?.toString();
      if (savedId != null) {
        await SupabaseService.upsertLinkedNotification(
          relatedType: 'task',
          relatedId: savedId,
          title: item['completed'] == true ? 'مهمة مكتملة' : 'تذكير بمهمة',
          body: _taskNotificationBody(item),
        );
      }
      return;
    }
    final list = await getTasks();
    final id = item['id']?.toString() ?? DateTime.now().microsecondsSinceEpoch.toString();
    final normalized = Map<String, dynamic>.from(item)..['id'] = id;
    final i = list.indexWhere((e) => e['id'].toString() == id);
    if (i >= 0) { list[i] = normalized; } else { list.insert(0, normalized); }
    await _writeList(_tasksKey, list);
    await _upsertLocalLinkedNotification('task', id, normalized['title']?.toString() ?? 'مهمة', _taskNotificationBody(normalized));
  }

  static String _taskNotificationBody(Map<String, dynamic> item) {
    final due = item['dueAt']?.toString();
    final caseId = item['caseId']?.toString();
    final parts = <String>[];
    if (due != null && due.isNotEmpty) parts.add('الاستحقاق: $due');
    if (caseId != null && caseId.isNotEmpty) parts.add('مرتبطة بقضية: $caseId');
    return parts.isEmpty ? (item['description']?.toString() ?? 'لديك مهمة مرتبطة بملفك القانوني.') : parts.join(' - ');
  }

  static Future<void> deleteTask(String id) async {
    if (_remote) {
      await SupabaseService.deleteTask(id);
      await SupabaseService.deleteLinkedNotifications('task', id);
      return;
    }
    final list = await getTasks();
    list.removeWhere((e) => e['id'].toString() == id);
    await _writeList(_tasksKey, list);
    final notifications = await getNotifications();
    notifications.removeWhere((n) => n['relatedType'] == 'task' && n['relatedId'].toString() == id);
    await _writeList(_notificationsKey, notifications);
  }

  static Future<void> setTaskCompleted(String id, bool value) async {
    if (_remote) {
      await SupabaseService.setTaskCompleted(id, value);
      final tasks = await getTasks();
      Map<String, dynamic>? task;
      for (final t in tasks) { if (t['id'].toString() == id) { task = t; break; } }
      if (task != null) {
        final updated = Map<String, dynamic>.from(task)..['completed'] = value;
        await SupabaseService.upsertLinkedNotification(
          relatedType: 'task', relatedId: id,
          title: value ? 'تم إنجاز المهمة' : 'تذكير بمهمة',
          body: _taskNotificationBody(updated),
        );
      }
      return;
    }
    final list = await getTasks();
    final i = list.indexWhere((e) => e['id'].toString() == id);
    if (i >= 0) {
      list[i]['completed'] = value;
      await _writeList(_tasksKey, list);
      final t = list[i];
      await _upsertLocalLinkedNotification('task', id, value ? 'تم إنجاز المهمة' : 'تذكير بمهمة', _taskNotificationBody(t));
    }
  }

  static Future<List<Map<String, dynamic>>> getNotifications() async {
    if (_remote) {
      final rows = await SupabaseService.getNotifications();
      return rows.map((r) => {
        'id': r['id'], 'title': r['title'], 'body': r['body'],
        'date': r['created_at'] ?? r['date'], 'read': r['read'],
        'relatedType': r['related_type'], 'relatedId': r['related_id'],
      }).toList();
    }
    return _readList(_notificationsKey);
  }

  static Future<void> addNotification(String title, String body, {String? relatedType, String? relatedId}) async {
    if (_remote) {
      await SupabaseService.addNotification(title, body, relatedType: relatedType, relatedId: relatedId);
      return;
    }
    final list = await getNotifications();
    list.insert(0, {
      'id': DateTime.now().microsecondsSinceEpoch.toString(), 'title': title, 'body': body,
      'date': DateTime.now().toIso8601String(), 'read': false,
      'relatedType': relatedType, 'relatedId': relatedId,
    });
    await _writeList(_notificationsKey, list);
  }

  static Future<void> _upsertLocalLinkedNotification(String type, String id, String title, String body) async {
    final list = await getNotifications();
    final index = list.indexWhere((n) => n['relatedType'] == type && n['relatedId'].toString() == id);
    final item = {
      'id': index >= 0 ? list[index]['id'] : DateTime.now().microsecondsSinceEpoch.toString(),
      'title': title, 'body': body, 'date': DateTime.now().toIso8601String(),
      'read': false, 'relatedType': type, 'relatedId': id,
    };
    if (index >= 0) { list[index] = item; } else { list.insert(0, item); }
    await _writeList(_notificationsKey, list);
  }

  static Future<void> markAllNotificationsRead() async {
    if (_remote) { await SupabaseService.markAllNotificationsRead(); return; }
    final list = await getNotifications();
    for (final n in list) n['read'] = true;
    await _writeList(_notificationsKey, list);
  }

  static Future<void> deleteNotification(String id) async {
    if (_remote) { await SupabaseService.deleteNotification(id); return; }
    final list = await getNotifications();
    list.removeWhere((e) => e['id'].toString() == id);
    await _writeList(_notificationsKey, list);
  }

  static Future<List<Map<String, dynamic>>> getLegalDrafts() => _readList('legal_drafts_v1');

  static Future<void> saveLegalDraft(Map<String, dynamic> draft) async {
    final list = await getLegalDrafts();
    final id = draft['id']?.toString() ?? DateTime.now().microsecondsSinceEpoch.toString();
    final normalized = Map<String, dynamic>.from(draft)..['id'] = id;
    final index = list.indexWhere((item) => item['id']?.toString() == id);
    if (index >= 0) { list[index] = normalized; } else { list.insert(0, normalized); }
    await _writeList('legal_drafts_v1', list);
  }


}
