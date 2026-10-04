# Arabic OCR (on-device)

The application uses `flutter_tesseract_ocr` and the Arabic Tesseract model.

- Required bundled asset: `assets/tessdata/ara.traineddata`
- Asset manifest: `assets/tessdata_config.json`
- OCR is executed on the device; scanned page images are not sent to an OCR cloud service.

The included `ara.traineddata` is from the local Tesseract 5 installation used while preparing this source package. Before release, verify recognition on representative Arabic legal documents on the target Android device. If the native Tesseract 4 Android engine rejects the model, replace it with the Arabic `ara.traineddata` from the official `tessdata_fast` repository and rebuild.
