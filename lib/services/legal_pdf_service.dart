import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class LegalPdfService {
  static Future<Uint8List> imagesToPdf(List<String> imagePaths) async {
    final doc = pw.Document();
    for (final path in imagePaths) {
      final bytes = await File(path).readAsBytes();
      final image = pw.MemoryImage(bytes);
      doc.addPage(pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(18),
        build: (_) => pw.Center(child: pw.Image(image, fit: pw.BoxFit.contain)),
      ));
    }
    return doc.save();
  }

  static Future<Uint8List> textToPdf(String title, String body) async {
    final fontData = await rootBundle.load('assets/fonts/NotoSansArabic-Regular.ttf');
    final font = pw.Font.ttf(fontData);
    final doc = pw.Document();
    final paragraphs = body.split('\n').map((line) => pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 5),
      child: pw.Directionality(
        textDirection: pw.TextDirection.rtl,
        child: pw.Text(line.isEmpty ? ' ' : line,
          textAlign: pw.TextAlign.right,
          style: pw.TextStyle(font: font, fontSize: 12, lineSpacing: 4)),
      ),
    )).toList();
    doc.addPage(pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(42),
      theme: pw.ThemeData.withFont(base: font, bold: font),
      build: (_) => [
        pw.Directionality(textDirection: pw.TextDirection.rtl,
          child: pw.Text(title, textAlign: pw.TextAlign.center,
            style: pw.TextStyle(font: font, fontSize: 18))),
        pw.SizedBox(height: 24),
        ...paragraphs,
      ],
    ));
    return doc.save();
  }

  static Future<void> printOrShare(Uint8List bytes, {String name = 'legal_document.pdf'}) =>
      Printing.sharePdf(bytes: bytes, filename: name);
}
