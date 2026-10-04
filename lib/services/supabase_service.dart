import 'dart:io';
import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/supabase_config.dart';

class SupabaseService {
  // Production Supabase endpoint is fixed here intentionally so a stale
  // --dart-define from an old build cannot silently point the APK to another project.
  static const url = SupabaseConfig.url;
  static const publishableKey = SupabaseConfig.publishableKey;

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

  static Future<AuthResponse> signIn(String email, String password) async {
    final response = await _withNetworkRetry(
      () => client.auth.signInWithPassword(
        email: email.trim(),
        password: password,
      ),
    );
    // Ensure the profile exists even if the database trigger was not present
    // when this account was originally created.
    if (response.user != null) {
      final existing = await client
          .from('profiles')
          .select('id')
          .eq('id', response.user!.id)
          .maybeSingle();
      if (existing == null) {
        await upsertProfile(
          response.user!.id,
          response.user!.email ?? email.trim(),
          _profileFromAuthMetadata(response.user!),
        );
      }
    }
    return response;
  }

  static Future<AuthResponse> signUp({
    required String email,
    required String password,
    required Map<String, dynamic> profile,
  }) async {
    final response = await _withNetworkRetry(
      () => client.auth.signUp(
        email: email.trim(),
        password: password,
        data: profile,
      ),
    );
    // The database trigger creates the profile and copies Auth metadata.
    // Do not issue a client-side upsert here: migration 0011 intentionally
    // withholds UPDATE permission on profiles.id.
    return response;
  }

  static Future<T> _withNetworkRetry<T>(Future<T> Function() action) async {
    Object? lastError;
    // DNS/network failures can be transient on mobile networks and VPNs.
    // Retry only transport-level failures; Auth/API errors are returned immediately.
    for (var attempt = 0; attempt < 3; attempt++) {
      try {
        return await action();
      } catch (error) {
        lastError = error;
        final text = error.toString().toLowerCase();
        final retryable = text.contains('socket') ||
            text.contains('failed host lookup') ||
            text.contains('host lookup') ||
            text.contains('connection reset') ||
            text.contains('connection closed') ||
            text.contains('connection refused') ||
            text.contains('timed out') ||
            text.contains('timeout');
        if (!retryable || attempt == 2) rethrow;
        await Future<void>.delayed(Duration(milliseconds: 700 * (attempt + 1)));
      }
    }
    throw lastError ?? Exception('تعذر الاتصال بالخادم.');
  }

  static Future<Map<String, dynamic>?> getProfile() async {
    final current = user;
    if (current == null) return null;
    final row = await client
        .from('profiles')
        .select()
        .eq('id', current.id)
        .maybeSingle();
    if (row != null) return Map<String, dynamic>.from(row);

    // Recover a missing profile from Auth metadata.
    if (current.id.isNotEmpty) {
      final data = _profileFromAuthMetadata(current);
      try {
        await upsertProfile(
          current.id,
          current.email ?? '',
          data,
        );
        return {
          'id': current.id,
          'email': current.email ?? '',
          ...data,
        };
      } catch (_) {}
    }
    return null;
  }

  static Map<String, dynamic> _profileFromAuthMetadata(User current) => {
        'full_name':
            current.userMetadata?['full_name']?.toString().trim().isNotEmpty == true
                ? current.userMetadata!['full_name'].toString().trim()
                : 'المحامي',
        'phone': current.userMetadata?['phone']?.toString() ?? '',
        'specialty': current.userMetadata?['specialty']?.toString() ?? '',
        'bar_number': current.userMetadata?['bar_number']?.toString() ?? '',
      };

  static Future<void> updateCurrentProfile(Map<String, dynamic> data) async {
    final current = user;
    if (current == null) throw Exception('لا يوجد مستخدم مسجل الدخول.');

    const allowed = <String>{
      'full_name',
      'phone',
      'specialty',
      'bar_number',
      'avatar_path',
    };
    final safeData = <String, dynamic>{};
    for (final entry in data.entries) {
      if (allowed.contains(entry.key)) safeData[entry.key] = entry.value;
    }
    safeData['email'] = current.email;
    safeData['updated_at'] = DateTime.now().toUtc().toIso8601String();
    await client.from('profiles').update(safeData).eq('id', current.id);
  }

  static Future<void> upsertProfile(String id, String email, Map<String, dynamic> data) async {
    final current = user;
    if (current == null || id != current.id) {
      throw Exception('لا يمكن تعديل ملف مستخدم آخر.');
    }
    const allowed = <String>{
      'full_name',
      'phone',
      'specialty',
      'bar_number',
      'avatar_path',
    };
    final safeData = <String, dynamic>{};
    for (final entry in data.entries) {
      if (allowed.contains(entry.key)) safeData[entry.key] = entry.value;
    }
    final values = <String, dynamic>{
      'email': email.trim(),
      ...safeData,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    };

    // Use UPDATE for an existing row and INSERT only for legacy accounts
    // whose profile row is genuinely missing. This avoids ON CONFLICT UPDATE
    // attempting to update the protected primary-key column (profiles.id).
    final existing = await client
        .from('profiles')
        .select('id')
        .eq('id', id)
        .maybeSingle();
    if (existing != null) {
      await client.from('profiles').update(values).eq('id', id);
      return;
    }

    try {
      await client.from('profiles').insert({'id': id, ...values});
    } on PostgrestException catch (error) {
      // A concurrent trigger/recovery may have inserted the same row.
      if (error.code != '23505') rethrow;
      await client.from('profiles').update(values).eq('id', id);
    }
  }


  static Future<List<Map<String, dynamic>>> getCases() async {
    final rows = await client.from('cases').select().eq('user_id', uid).order('updated_at', ascending: false);
    return rows.map((r) => Map<String, dynamic>.from(r)).toList();
  }

  static Future<Map<String, dynamic>> saveCase(Map<String, dynamic> caseData) async {
    final payload = <String, dynamic>{
      'id': caseData['id']?.toString().isNotEmpty == true
          ? caseData['id'].toString()
          : DateTime.now().microsecondsSinceEpoch.toString(),
      'user_id': uid,
      'title': caseData['title'],
      'case_number': caseData['caseNumber'],
      'client_id': caseData['clientId'],
      'client_name': caseData['client'],
      'court': caseData['court'],
      'opponent': caseData['opponent'],
      'summary': caseData['summary'],
      'notes': caseData['notes'],
      'case_type': caseData['type'],
      'status': caseData['status'] ?? 'جارية',
      'created_at': caseData['createdAt'] ?? DateTime.now().toUtc().toIso8601String(),
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    };
    final row = await client.from('cases').upsert(payload).select().single();
    return Map<String, dynamic>.from(row);
  }

  static Future<void> deleteCase(String id) async {
    await client.from('cases').delete().eq('id', id).eq('user_id', uid);
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
      'updated_at': DateTime.now().toUtc().toIso8601String(),
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
      'case_id': task['caseId'] ?? task['case_id'],
      'title': task['title'],
      'description': task['description'],
      'due_at': task['dueAt'] ?? task['due_at'],
      'priority': task['priority'] ?? 'normal',
      'completed': task['completed'] ?? false,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    };
    final existingId = task['id']?.toString();
    if (existingId != null && RegExp(r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[1-5][0-9a-fA-F]{3}-[89abAB][0-9a-fA-F]{3}-[0-9a-fA-F]{12}$').hasMatch(existingId)) payload['id'] = existingId;
    final row = await client.from('tasks').upsert(payload).select().single();
    return Map<String, dynamic>.from(row);
  }

  static Future<void> deleteTask(String id) async {
    await client.from('tasks').delete().eq('id', id).eq('user_id', uid);
  }

  static Future<void> setTaskCompleted(String id, bool completed) async {
    await client.from('tasks').update({'completed': completed, 'updated_at': DateTime.now().toUtc().toIso8601String()}).eq('id', id).eq('user_id', uid);
  }

  static Future<List<Map<String, dynamic>>> getNotifications() async {
    final rows = await client.from('notifications').select().eq('user_id', uid).order('created_at', ascending: false);
    return rows.map((r) => Map<String, dynamic>.from(r)).toList();
  }

  static Future<void> addNotification(String title, String body, {String? relatedType, String? relatedId}) async {
    await client.from('notifications').insert({
      'user_id': uid, 'title': title, 'body': body,
      'related_type': relatedType, 'related_id': relatedId,
    });
  }

  static Future<void> upsertLinkedNotification({required String relatedType, required String relatedId, required String title, required String body}) async {
    final existing = await client.from('notifications').select('id').eq('user_id', uid).eq('related_type', relatedType).eq('related_id', relatedId).limit(1);
    if (existing.isNotEmpty) {
      await client.from('notifications').update({'title': title, 'body': body, 'read': false, 'created_at': DateTime.now().toUtc().toIso8601String()}).eq('id', existing.first['id']).eq('user_id', uid);
    } else {
      await addNotification(title, body, relatedType: relatedType, relatedId: relatedId);
    }
  }

  static Future<void> deleteLinkedNotifications(String relatedType, String relatedId) async {
    await client.from('notifications').delete().eq('user_id', uid).eq('related_type', relatedType).eq('related_id', relatedId);
  }

  static Future<void> markAllNotificationsRead() async {
    await client.from('notifications').update({'read': true}).eq('user_id', uid);
  }

  static Future<void> deleteNotification(String id) async {
    await client.from('notifications').delete().eq('id', id).eq('user_id', uid);
  }

  static Future<List<String>> getLegalCategories() async {
    final rows = await client.from('legal_sources').select('title').eq('is_current', true).order('title');
    return rows.map((r) => r['title']?.toString() ?? '').where((x) => x.isNotEmpty).toSet().toList();
  }

  static Future<List<Map<String, dynamic>>> searchLegalArticles(
    String query, {
    String? category,
    int maxResults = 30,
    int offset = 0,
  }) async {
    final result = await client.rpc('search_legal_articles', params: {
      'q': query.trim(),
      'category': category,
      'max_results': maxResults,
      'page_offset': offset,
    });
    return (result as List)
        .map((r) => Map<String, dynamic>.from(r))
        .toList();
  }

  static Future<List<Map<String, dynamic>>> browseLegalArticles({String? category, int limit = 50, int offset = 0}) async {
    final result = await client.rpc('browse_legal_articles', params: {
      'category': category,
      'page_size': limit,
      'page_offset': offset,
    });
    return (result as List).map((r) => Map<String, dynamic>.from(r)).toList();
  }

  static String _contentType(String ext) {
    switch (ext) {
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
      case 'gif':
        return 'image/gif';
      case 'pdf':
        return 'application/pdf';
      case 'heic':
        return 'image/heic';
      default:
        return 'image/jpeg';
    }
  }

  static Future<String> uploadDocument(File file, String documentId) async {
    final ext = file.path.contains('.') ? file.path.split('.').last.toLowerCase() : 'bin';
    final path = '$uid/$documentId.$ext';
    await client.storage.from('legal-documents').upload(
      path,
      file,
      fileOptions: FileOptions(upsert: true, contentType: _contentType(ext)),
    );
    return path;
  }

  static void _assertOwnedStoragePath(String path) {
    final clean = path.trim();
    final current = user;
    if (current == null || clean.isEmpty || !clean.startsWith('${current.id}/')) {
      throw Exception('مسار المستند غير صالح لهذا المستخدم.');
    }
  }

  static Future<Uint8List> downloadDocument(String path) {
    _assertOwnedStoragePath(path);
    return client.storage.from('legal-documents').download(path);
  }

  static Future<void> deleteStorageFile(String? path) async {
    if (path == null || path.trim().isEmpty) return;
    _assertOwnedStoragePath(path);
    await client.storage.from('legal-documents').remove([path]);
  }

  static Future<String> createSignedDocumentUrl(String path, {int expiresIn = 3600}) {
    _assertOwnedStoragePath(path);
    return client.storage.from('legal-documents').createSignedUrl(path, expiresIn);
  }

  static Future<void> upsertHearingNotification({required String hearingId, required String title, required String body}) =>
      upsertLinkedNotification(relatedType: 'hearing', relatedId: hearingId, title: title, body: body);

  static Future<void> signOut() => client.auth.signOut();
}
