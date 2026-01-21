// lib/services/export_service_web.dart

import 'dart:convert';
import 'dart:typed_data';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

import '../models/transaction.dart';
import '../models/category.dart';

/// Platform-specific export function for conditional imports
Future<String> exportFile(Uint8List bytes, String fileName, String mimeType) async {
  try {
    final blob = html.Blob([bytes], mimeType);
    final url = html.Url.createObjectUrlFromBlob(blob);

    final anchor = html.AnchorElement(href: url)
      ..setAttribute('download', fileName)
      ..style.display = 'none';

    html.document.body?.children.add(anchor);
    anchor.click();

    html.document.body?.children.remove(anchor);
    html.Url.revokeObjectUrl(url);

    return fileName;
  } catch (e) {
    throw Exception('Failed to download file: $e');
  }
}

/// Share file on web (just informs user)
Future<void> shareFile(String filePath) async {
  // On web, file was already downloaded
}

