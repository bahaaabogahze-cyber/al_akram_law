import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import '../../services/supabase_service.dart';

class DocumentPdfScreen extends StatelessWidget {
  final Map<String, dynamic> document;
  const DocumentPdfScreen({super.key, required this.document});

  Future<Uint8List> _bytes() async {
    final path = document['path']?.toString() ?? '';
    if (path.isNotEmpty && await File(path).exists()) return File(path).readAsBytes();
    final storagePath = document['storagePath']?.toString();
    if (storagePath != null && storagePath.isNotEmpty) return SupabaseService.downloadDocument(storagePath);
    throw Exception('ملف PDF غير متاح على هذا الجهاز أو في التخزين السحابي.');
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(document['title']?.toString() ?? 'معاينة PDF')),
    body: PdfPreview(
      canChangePageFormat: false,
      canChangeOrientation: false,
      allowPrinting: true,
      allowSharing: true,
      build: (_) => _bytes(),
    ),
  );
}
