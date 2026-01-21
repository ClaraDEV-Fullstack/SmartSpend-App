// lib/services/export_service_mobile.dart

import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:cross_file/cross_file.dart';  // XFile is from this package

/// Mobile implementation for file export
Future<String> exportFile(Uint8List bytes, String fileName, String mimeType) async {
  try {
    // Get app documents directory
    final directory = await getApplicationDocumentsDirectory();

    // Create exports subdirectory
    final exportDir = Directory('${directory.path}/exports');
    if (!await exportDir.exists()) {
      await exportDir.create(recursive: true);
    }

    // Write file
    final filePath = '${exportDir.path}/$fileName';
    final file = File(filePath);
    await file.writeAsBytes(bytes);

    // Share the file - ✅ FIXED: Wrap filePath in XFile
    await Share.shareXFiles(
      [XFile(filePath)],  // ← Changed from [(filePath)] to [XFile(filePath)]
      subject: 'SmartSpend Export',
      text: 'Exported from SmartSpend',
    );

    return filePath;
  } catch (e) {
    throw Exception('Failed to export file: $e');
  }
}

/// Share an existing file
Future<void> shareFile(String filePath) async {
  try {
    await Share.shareXFiles(
      [XFile(filePath)],
      subject: 'SmartSpend Export',
      text: 'Exported from SmartSpend',
    );
  } catch (e) {
    throw Exception('Failed to share file: $e');
  }
}