import 'dart:io';
import 'package:flutter_tesseract_ocr/flutter_tesseract_ocr.dart';

/// Arabic OCR runs on-device. The Arabic traineddata file must be bundled at
/// assets/tessdata/ara.traineddata (see docs/ARABIC_OCR_SETUP.md).
class LegalOcrService {
  static Future<String> extractArabicText(String imagePath) async {
    final file = File(imagePath);
    if (!await file.exists()) throw Exception('صورة الصفحة غير موجودة.');
    try {
      return await FlutterTesseractOcr.extractText(
        imagePath,
        language: 'ara',
        args: const {
          'psm': '3',
          'preserve_interword_spaces': '1',
        },
      );
    } catch (e) {
      throw Exception('تعذر تشغيل OCR العربي. تأكد من إضافة ara.traineddata إلى assets/tessdata. التفاصيل: $e');
    }
  }

  static Future<String> extractPages(List<String> paths,
      {void Function(int done, int total)? onProgress}) async {
    final sections = <String>[];
    for (var i = 0; i < paths.length; i++) {
      final text = await extractArabicText(paths[i]);
      sections.add('--- الصفحة ${i + 1} ---\n${text.trim()}');
      onProgress?.call(i + 1, paths.length);
    }
    return sections.join('\n\n');
  }
}
