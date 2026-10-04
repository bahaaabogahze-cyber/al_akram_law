import 'dart:io';
import 'package:cunning_document_scanner/cunning_document_scanner.dart';
import 'package:flutter/material.dart';
import '../../core/colors.dart';
import '../../services/legal_ocr_service.dart';
import '../../services/legal_pdf_service.dart';
import '../../services/local_store.dart';
import '../../services/supabase_service.dart';

class DocumentScannerScreen extends StatefulWidget {
  final String? caseId;
  const DocumentScannerScreen({super.key, this.caseId});
  @override
  State<DocumentScannerScreen> createState() => _DocumentScannerScreenState();
}

class _DocumentScannerScreenState extends State<DocumentScannerScreen> {
  bool _busy = false;
  String _status = 'افتح الماسح لالتقاط صفحات المستند.';
  int _done = 0;
  int _total = 0;
  final _title = TextEditingController(text: 'مستند قانوني');
  final _notes = TextEditingController();

  @override
  void dispose() { _title.dispose(); _notes.dispose(); super.dispose(); }

  Future<void> _scan() async {
    setState(() { _busy = true; _status = 'جارٍ فتح الماسح...'; });
    try {
      final paths = await CunningDocumentScanner.getPictures(noOfPages: 40);
      if (!mounted) return;
      if (paths == null || paths.isEmpty) {
        setState(() { _busy = false; _status = 'تم إلغاء المسح.'; });
        return;
      }
      final pages = paths.whereType<String>().toList();
      if (pages.isEmpty) throw Exception('لم يتم استلام صفحات من الماسح.');
      setState(() { _total = pages.length; _done = 0; _status = 'جارٍ استخراج النص العربي...'; });
      String ocrText = '';
      try {
        ocrText = await LegalOcrService.extractPages(pages, onProgress: (d, t) {
          if (mounted) setState(() { _done = d; _total = t; _status = 'استخراج النص من الصفحة $d من $t'; });
        });
      } catch (e) {
        if (!mounted) return;
        final proceed = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
          title: const Text('تعذر OCR العربي'),
          content: Text('$e\n\nيمكنك حفظ ملف PDF الآن وإعادة استخراج النص بعد إضافة ملف اللغة العربية.'),
          actions: [TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('إلغاء')), FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('حفظ PDF فقط'))],
        ));
        if (proceed != true) { setState(() => _busy = false); return; }
      }
      setState(() => _status = 'جارٍ إنشاء ملف PDF متعدد الصفحات...');
      final pdfBytes = await LegalPdfService.imagesToPdf(pages);
      final id = DateTime.now().microsecondsSinceEpoch.toString();
      final target = await LocalStore.localDocumentPath(id, 'pdf');
      await File(target).writeAsBytes(pdfBytes, flush: true);
      String? storagePath;
      if (SupabaseService.isConfigured && SupabaseService.user != null) {
        storagePath = await SupabaseService.uploadDocument(File(target), id);
      }
      await LocalStore.saveDocument({
        'id': id,
        'caseId': widget.caseId,
        'path': target,
        'storagePath': storagePath,
        'mimeType': 'application/pdf',
        'title': _title.text.trim().isEmpty ? 'مستند ممسوح' : _title.text.trim(),
        'notes': _notes.text.trim(),
        'tags': 'مسح ضوئي,OCR عربي',
        'ocrText': ocrText,
        'pageCount': pages.length,
        'createdAt': DateTime.now().toUtc().toIso8601String(),
        'updatedAt': DateTime.now().toUtc().toIso8601String(),
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تم حفظ ${pages.length} صفحة في PDF${ocrText.isNotEmpty ? ' مع النص المستخرج' : ''}.')));
      Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        setState(() { _busy = false; _status = 'تعذر إكمال المسح.'; });
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطأ في الماسح: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('الماسح القانوني')),
    body: ListView(padding: const EdgeInsets.all(16), children: [
      Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(children: [
        Icon(Icons.document_scanner_outlined, size: 64, color: AppColors.primary),
        const SizedBox(height: 12),
        const Text('ماسح متعدد الصفحات', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        const Text('اكتشاف حدود الورقة وتصحيح المنظور وتحسين الصورة، ثم تجميع الصفحات في PDF واحد.', textAlign: TextAlign.center),
      ]))),
      const SizedBox(height: 14),
      TextField(controller: _title, textDirection: TextDirection.rtl, decoration: const InputDecoration(labelText: 'عنوان المستند', border: OutlineInputBorder())),
      const SizedBox(height: 12),
      TextField(controller: _notes, textDirection: TextDirection.rtl, maxLines: 3, decoration: const InputDecoration(labelText: 'ملاحظات (اختياري)', border: OutlineInputBorder())),
      const SizedBox(height: 18),
      if (_busy) ...[
        LinearProgressIndicator(value: _total == 0 ? null : _done / _total),
        const SizedBox(height: 10),
      ],
      Text(_status, textAlign: TextAlign.center),
      const SizedBox(height: 16),
      FilledButton.icon(onPressed: _busy ? null : _scan, style: FilledButton.styleFrom(backgroundColor: AppColors.primary, minimumSize: const Size.fromHeight(54)), icon: const Icon(Icons.camera_alt), label: Text(_busy ? 'يرجى الانتظار...' : 'بدء مسح المستند')),
      const SizedBox(height: 10),
      const Text('ملاحظة: استخراج النص يعمل محلياً على الهاتف. يتطلب تضمين ملف اللغة العربية ara.traineddata داخل التطبيق.', textAlign: TextAlign.center, style: TextStyle(color: Colors.black54)),
    ]),
  );
}
