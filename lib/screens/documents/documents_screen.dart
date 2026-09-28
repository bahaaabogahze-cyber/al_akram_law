import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/colors.dart';
import '../../services/local_store.dart';
import 'document_editor_screen.dart';

class DocumentsScreen extends StatefulWidget {
  final String? caseId;
  const DocumentsScreen({super.key, this.caseId});
  @override
  State<DocumentsScreen> createState() => _DocumentsScreenState();
}

class _DocumentsScreenState extends State<DocumentsScreen> {
  final _picker = ImagePicker();
  List<Map<String, dynamic>> _documents = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final all = await LocalStore.getDocuments();
    if (!mounted) return;
    setState(() {
      _documents = widget.caseId == null
          ? all
          : all.where((d) => d['caseId']?.toString() == widget.caseId).toList();
    });
  }

  Future<void> _capture(ImageSource source) async {
    try {
      final image = await _picker.pickImage(
        source: source,
        imageQuality: 90,
        maxWidth: 3000,
      );
      if (image == null || !mounted) return;
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => DocumentEditorScreen(
            initialPath: image.path,
            caseId: widget.caseId,
          ),
        ),
      );
      if (result == true) _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تعذر فتح الكاميرا/المعرض: $e')),
      );
    }
  }

  Future<void> _delete(Map<String, dynamic> doc) async {
    await LocalStore.deleteDocument(doc['id'].toString());
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(widget.caseId == null ? 'المستندات' : 'مستندات القضية'),
        actions: [
          IconButton(onPressed: _load, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: _documents.isEmpty
          ? _empty()
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _documents.length,
                itemBuilder: (_, i) => _card(_documents[i]),
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        onPressed: _showSource,
        icon: const Icon(Icons.document_scanner_outlined),
        label: const Text('تصوير / إضافة مستند'),
      ),
    );
  }

  Widget _empty() => Center(
        child: Padding(
          padding: const EdgeInsets.all(30),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.document_scanner_outlined, size: 76, color: Colors.grey.shade400),
              const SizedBox(height: 14),
              const Text('لا توجد مستندات بعد', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const Text('صوّر المستند بالكاميرا أو اختر صورة من الجهاز ثم عدّلها واحفظ ملاحظاتك.'),
              const SizedBox(height: 20),
              FilledButton.icon(onPressed: _showSource, icon: const Icon(Icons.add_a_photo), label: const Text('إضافة مستند')),
            ],
          ),
        ),
      );

  Widget _card(Map<String, dynamic> d) {
    final path = d['path']?.toString() ?? '';
    final exists = path.isNotEmpty && File(path).existsSync();
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.all(10),
        leading: SizedBox(
          width: 64,
          height: 64,
          child: exists
              ? ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.file(File(path), fit: BoxFit.cover))
              : const Icon(Icons.insert_drive_file, size: 42),
        ),
        title: Text(d['title'] ?? 'مستند'),
        subtitle: Text('${d['notes'] ?? ''}\n${d['createdAt'] ?? ''}', maxLines: 2, overflow: TextOverflow.ellipsis),
        isThreeLine: true,
        onTap: () async {
          await Navigator.push(context, MaterialPageRoute(
            builder: (_) => DocumentEditorScreen(existing: d),
          ));
          _load();
        },
        trailing: PopupMenuButton<String>(
          onSelected: (v) {
            if (v == 'delete') _delete(d);
          },
          itemBuilder: (_) => const [
            PopupMenuItem(value: 'delete', child: Text('حذف')),
          ],
        ),
      ),
    );
  }

  void _showSource() {
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('تصوير بالكاميرا'),
              onTap: () {
                Navigator.pop(context);
                _capture(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('اختيار من المعرض'),
              onTap: () {
                Navigator.pop(context);
                _capture(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }
}
