# AL AKRAM V2.1 — Scanner, Arabic OCR and Legal Templates

## Document scanner
- Multi-page capture using the native document scanner.
- Automatic document boundary detection and perspective correction where the platform scanner engine supports it.
- Native image cleanup/cropping flow.
- Combines captured pages into one A4 PDF.
- Stores the PDF locally and uploads it to the user's private Supabase document bucket when signed in.
- Associates the PDF with the current case when launched from a case.

## Arabic OCR and search
- Runs Tesseract Arabic OCR on the device.
- Extracted text is saved to `documents.ocr_text` (the column already exists in migration 0001).
- Document search checks title, notes, tags, and extracted OCR text.
- The Arabic model is bundled in `assets/tessdata/ara.traineddata`.

## Legal forms
- Structured templates: lease, sale, special power of attorney, legal notice, statement of claim, and defense memorandum.
- Drafts can be edited and saved locally per signed-in user/device profile.
- Export to Arabic PDF, print/share through the platform share sheet.
- Generated forms are drafts and require review by a lawyer before use or signature.

## Build
1. Run `flutter pub get`.
2. Run `flutter analyze` and the project's tests.
3. Build a debug APK and test scanning/OCR on the target Android phone.

The current build environment did not have Flutter/Dart installed, so APK compilation and Flutter analyzer execution have not been verified here. Tesseract Arabic model was verified with a local OCR smoke test, but the Flutter plugin/native Android integration still needs an on-device build test.
