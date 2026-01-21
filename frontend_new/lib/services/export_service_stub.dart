// lib/services/export_service_stub.dart

import 'dart:typed_data';

/// Stub implementation - should never be called directly
Future<String> exportFile(Uint8List bytes, String fileName, String mimeType) async {
  throw UnsupportedError('Cannot export on this platform');
}

Future<void> shareFile(String filePath) async {
  throw UnsupportedError('Cannot share on this platform');
}