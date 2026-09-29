import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:path_provider/path_provider.dart';
import '../../core/colors.dart';
import '../../services/local_store.dart';
import '../../services/supabase_service.dart';

class DocumentEditorScreen extends StatefulWidget {
  final String? initialPath;
  final Map<String, dynamic>? existing;
  final String? caseId;
  const DocumentEditorScreen({super.key, this.initialPath, this.existing, this.caseId});
  @override
  State<DocumentEditorScreen> createState() => _DocumentEditorScreenState();
}

class _DocumentEditorScreenState extends State<DocumentEditorScreen> {
  late String? _path;
  late final TextEditingController _title;
  late final TextEditingController _notes;
  late final TextEditingController _tags;
  bool _saving = false;
  bool _loadingRemote = false;

  @override
  void initState() {
    super.initState();
    _path = widget.existing?['path']?.toString() ?? widget.initialPath;
    _title = TextEditingController(text: widget.existing?['title'] ?? 'مستند قانوني');
    _notes = TextEditingController(text: widget.existing?['notes'] ?? '');
    _tags = TextEditingController(text: widget.existing?['tags'] ?? '');
    _prepareRemote();
  }

  bool get _remote => SupabaseService.isConfigured && SupabaseService.user != null;

  // إذا كان المستند محفوظاً في السحابة ولا توجد نسخة محلية منه على هذا الجهاز، ننزّله من Storage.
  Future<void> _prepareRemote() async {
    final e = widget.existing;
    if (e == null || !_remote) return;
    final local = _path;
    if (local != null && local.isNotEmpty && File(local).existsSync()) return;
    final sp = e['storagePath']?.toString();
    if (sp == null || sp.isEmpty) return;
    _loadingRemote = true;
    try {
      final bytes = await SupabaseService.downloadDocument(sp);
      final ext = sp.contains('.') ? sp.split('.').last.toLowerCase() : 'jpg';
      final target = await LocalStore.localDocumentPath(e['id'].toString(), ext);
      await File(target).writeAsBytes(bytes, flush: true);
      if (mounted) setState(() => _path = target);
    } catch (err) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تعذر تحميل صورة المستند: $err')));
    } finally {
      if (mounted) setState(() => _loadingRemote = false);
    }
  }

  @override
  void dispose() {
    _title.dispose();
    _notes.dispose();
    _tags.dispose();
    super.dispose();
  }

  Future<void> _crop() async {
    if (_path == null) return;
    try {
      final cropped = await ImageCropper().cropImage(
        sourcePath: _path!,
        compressQuality: 92,
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'تعديل المستند',
            toolbarColor: AppColors.primary,
            toolbarWidgetColor: Colors.white,
            lockAspectRatio: false,
          ),
          IOSUiSettings(title: 'تعديل المستند'),
        ],
      );
      if (cropped != null && mounted) setState(() => _path = cropped.path);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تعذر تعديل الصورة: $e')));
    }
  }

  Future<void> _save() async {
    if (_path == null || _path!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('أضف صورة للمستند أولاً.')));
      return;
    }
    setState(() => _saving = true);
    final oldStoragePath = widget.existing?['storagePath']?.toString();
    String? uploadedPath;
    try {
      final id = widget.existing?['id']?.toString() ?? DateTime.now().microsecondsSinceEpoch.toString();
      final source = File(_path!);
      final extension = _path!.contains('.') ? _path!.split('.').last.toLowerCase() : 'jpg';
      final permanentPath = await LocalStore.localDocumentPath(id, extension);
      if (source.path != permanentPath) {
        await source.copy(permanentPath);
      }
      String? storagePath = oldStoragePath;
      if (_remote) {
        storagePath = await SupabaseService.uploadDocument(File(permanentPath), id);
        uploadedPath = storagePath;
      }
      final title = _title.text.trim().isEmpty ? 'مستند قانوني' : _title.text.trim();
      await LocalStore.saveDocument({
        'id': id,
        'caseId': widget.existing?['caseId'] ?? widget.caseId,
        'path': permanentPath,
        'storagePath': storagePath,
        'title': title,
        'notes': _notes.text.trim(),
        'tags': _tags.text.trim(),
        'createdAt': widget.existing?['createdAt'] ?? DateTime.now().toUtc().toIso8601String(),
        'updatedAt': DateTime.now().toUtc().toIso8601String(),
      });
      // إذا تغيّر امتداد الصورة بعد التعديل، نحذف الملف القديم من Storage حتى لا يبقى يتيماً.
      if (_remote && oldStoragePath != null && oldStoragePath.isNotEmpty && oldStoragePath != storagePath) {
        try { await SupabaseService.deleteStorageFile(oldStoragePath); } catch (_) {}
      }
      await LocalStore.addNotification('تم حفظ مستند', title);
      if (mounted) {
        setState(() => _saving = false);
        Navigator.pop(context, true);
      }
    } catch (e) {
      // فشل الحفظ: لا نترك ملفاً مرفوعاً بلا سجل في قاعدة البيانات.
      if (uploadedPath != null && uploadedPath != oldStoragePath) {
        try { await SupabaseService.deleteStorageFile(uploadedPath); } catch (_) {}
      }
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تعذر حفظ المستند: $e'), backgroundColor: Colors.red));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final exists = _path != null && File(_path!).existsSync();
    return Scaffold(
      appBar: AppBar(
        title: const Text('تعديل المستند'),
        actions: [
          IconButton(onPressed: _crop, icon: const Icon(Icons.crop_rotate), tooltip: 'قص وتدوير'),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            height: 330,
            decoration: BoxDecoration(
              color: Colors.black12,
              borderRadius: BorderRadius.circular(16),
            ),
            alignment: Alignment.center,
            child: exists
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.file(File(_path!), fit: BoxFit.contain),
                  )
                : _loadingRemote
                    ? const CircularProgressIndicator()
                    : const Text('لا توجد صورة'),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _crop,
            icon: const Icon(Icons.crop),
            label: const Text('قص / تدوير / ضبط إطار المستند'),
          ),
          const SizedBox(height: 18),
          _field(_title, 'اسم المستند', Icons.title),
          _field(_tags, 'الوسوم (مثال: عقد، وكالة، حكم)', Icons.sell_outlined),
          _field(_notes, 'ملاحظات المحامي على المستند', Icons.notes, maxLines: 5),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Text(
                _remote
                    ? 'يتم حفظ المستند والصورة المعدّلة في حسابك على السحابة، ويبقى متاحاً على أجهزتك بعد إغلاق التطبيق.'
                    : 'ملاحظة: النسخة الحالية تحفظ المستند والصورة المعدّلة وبياناتها على الجهاز. للمزامنة السحابية والنسخ الاحتياطي بين الأجهزة يلزم ربط قاعدة بيانات وحساب مستخدم.',
                style: const TextStyle(color: Colors.black54),
              ),
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: (_saving || _loadingRemote) ? null : _save,
            style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(54), backgroundColor: AppColors.primary),
            icon: _saving ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Icon(Icons.save),
            label: Text(_saving ? 'جاري الحفظ...' : 'حفظ المستند'),
          ),
        ],
      ),
    );
  }

  Widget _field(TextEditingController c, String label, IconData icon, {int maxLines = 1}) => Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: TextField(
      controller: c,
      maxLines: maxLines,
      textDirection: TextDirection.rtl,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppColors.primary),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
  );
}
