// lib/services/url_launcher_service.dart

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class UrlLauncherService {
  /// Launch email app
  static Future<bool> launchEmail({
    required String email,
    String? subject,
    String? body,
  }) async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: email,
      query: _encodeQueryParameters({
        if (subject != null) 'subject': subject,
        if (body != null) 'body': body,
      }),
    );

    try {
      return await launchUrl(emailUri);
    } catch (e) {
      debugPrint('Could not launch email: $e');
      return false;
    }
  }

  /// Launch phone dialer
  static Future<bool> launchPhone(String phoneNumber) async {
    final Uri phoneUri = Uri(scheme: 'tel', path: phoneNumber);

    try {
      return await launchUrl(phoneUri);
    } catch (e) {
      debugPrint('Could not launch phone: $e');
      return false;
    }
  }

  /// Launch URL in browser
  static Future<bool> launchWebUrl(String url) async {
    final Uri uri = Uri.parse(url);

    try {
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      debugPrint('Could not launch URL: $e');
      return false;
    }
  }

  static String? _encodeQueryParameters(Map<String, String> params) {
    if (params.isEmpty) return null;
    return params.entries
        .map((e) => '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
        .join('&');
  }
}