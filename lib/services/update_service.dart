// lib/services/update_service.dart
// ─────────────────────────────────────────────────────
// Paste this file into your services/ folder
// ─────────────────────────────────────────────────────

import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class UpdateService {
  // ── CHANGE THIS to your actual GitHub repo ──────────────────
  static const String _versionJsonUrl =
      'https://raw.githubusercontent.com/Mans610/supperclubApp/main/version.json';
  // ────────────────────────────────────────────────────────────

  /// Call this once in your HomeController or main screen initState
  static Future<void> checkForUpdate(BuildContext context) async {
    try {
      final response = await http
          .get(Uri.parse(_versionJsonUrl))
          .timeout(const Duration(seconds: 5));
print("response==${response.body}");
      if (response.statusCode != 200) return;

      final Map<String, dynamic> data = jsonDecode(response.body);
      final String latestVersion = data['latest_version'];
      final String apkUrl = data['apk_url'];
      final bool forceUpdate = data['force_update'] ?? false;
      final String releaseNotes =
          data['release_notes'] ?? 'A new version is available.';

      // Get current app version from pubspec
      final PackageInfo info = await PackageInfo.fromPlatform();
      final String currentVersion = info.version;

      if (_isNewer(latestVersion, currentVersion)) {
        if (context.mounted) {
          _showUpdateDialog(
            context,
            currentVersion: currentVersion,
            latestVersion: latestVersion,
            apkUrl: apkUrl,
            forceUpdate: forceUpdate,
            releaseNotes: releaseNotes,
          );
        }
      }
    } catch (e) {
      // Silently fail — no internet or server issue
      debugPrint('Update check failed: $e');
    }
  }

  /// Returns true if [latest] is newer than [current]
  static bool _isNewer(String latest, String current) {
    final List<int> l = latest.split('.').map(int.parse).toList();
    final List<int> c = current.split('.').map(int.parse).toList();

    for (int i = 0; i < 3; i++) {
      final int lv = i < l.length ? l[i] : 0;
      final int cv = i < c.length ? c[i] : 0;
      if (lv > cv) return true;
      if (lv < cv) return false;
    }
    return false;
  }

  static void _showUpdateDialog(
    BuildContext context, {
    required String currentVersion,
    required String latestVersion,
    required String apkUrl,
    required bool forceUpdate,
    required String releaseNotes,
  }) {
    showDialog(
      context: context,
      barrierDismissible: !forceUpdate, // can't dismiss if force update
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.system_update, color: Colors.blue),
            SizedBox(width: 8),
            Text('Update Available'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Current version: $currentVersion'),
            Text('New version: $latestVersion',
                style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Text(releaseNotes),
          ],
        ),
        actions: [
          if (!forceUpdate)
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Later'),
            ),
          ElevatedButton.icon(
            onPressed: () => _downloadApk(apkUrl),
            icon: const Icon(Icons.download),
            label: const Text('Update Now'),
          ),
        ],
      ),
    );
  }

  static Future<void> _downloadApk(String apkUrl) async {
    final uri = Uri.parse(apkUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}
