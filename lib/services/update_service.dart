import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Holds information about a GitHub release.
class ReleaseInfo {
  final String tagName;
  final String version;
  final String name;
  final String body;
  final String apkDownloadUrl;
  final String htmlUrl;

  const ReleaseInfo({
    required this.tagName,
    required this.version,
    required this.name,
    required this.body,
    required this.apkDownloadUrl,
    required this.htmlUrl,
  });
}

/// Service responsible for checking, downloading, and installing OTA updates
/// from GitHub Releases.
class UpdateService {
  static const String _releasesUrl =
      'https://api.github.com/repos/Ivankali2020/offiline-pos/releases';

  static const String _prefKeyPendingVersion = 'ota_pending_version';
  static const String _prefKeyPendingApkPath = 'ota_pending_apk_path';
  static const String _prefKeyDismissedVersion = 'ota_dismissed_version';

  // ---------------------------------------------------------------------------
  // Version comparison
  // ---------------------------------------------------------------------------

  /// Strips a leading 'v' and returns the cleaned version string.
  static String _cleanVersion(String raw) {
    return raw.startsWith('v') ? raw.substring(1) : raw;
  }

  /// Returns `true` when [remote] is newer than [local].
  /// Both must be in semver format (e.g. `1.0.2`).
  static bool isNewer(String remote, String local) {
    final r = _cleanVersion(remote).split('.').map(int.tryParse).toList();
    final l = _cleanVersion(local).split('.').map(int.tryParse).toList();

    for (int i = 0; i < 3; i++) {
      final rv = i < r.length ? (r[i] ?? 0) : 0;
      final lv = i < l.length ? (l[i] ?? 0) : 0;
      if (rv > lv) return true;
      if (rv < lv) return false;
    }
    return false;
  }

  // ---------------------------------------------------------------------------
  // GitHub API
  // ---------------------------------------------------------------------------

  /// Fetches the latest release from GitHub. Returns `null` on failure.
  static Future<ReleaseInfo?> fetchLatestRelease() async {
    try {
      final response = await http.get(
        Uri.parse(_releasesUrl),
        headers: {'Accept': 'application/vnd.github.v3+json'},
      );

      if (response.statusCode != 200) return null;

      final List<dynamic> releases = json.decode(response.body);
      if (releases.isEmpty) return null;

      final latest = releases.first as Map<String, dynamic>;
      final assets = latest['assets'] as List<dynamic>? ?? [];

      // Find the APK asset
      String? apkUrl;
      for (final asset in assets) {
        final name = (asset['name'] as String? ?? '').toLowerCase();
        if (name.endsWith('.apk')) {
          apkUrl = asset['browser_download_url'] as String?;
          break;
        }
      }

      if (apkUrl == null) return null;

      final tagName = latest['tag_name'] as String? ?? '';
      return ReleaseInfo(
        tagName: tagName,
        version: _cleanVersion(tagName),
        name: latest['name'] as String? ?? tagName,
        body: latest['body'] as String? ?? '',
        apkDownloadUrl: apkUrl,
        htmlUrl: latest['html_url'] as String? ?? '',
      );
    } catch (_) {
      return null;
    }
  }

  // ---------------------------------------------------------------------------
  // Current app version
  // ---------------------------------------------------------------------------

  static Future<String> getCurrentVersion() async {
    final info = await PackageInfo.fromPlatform();
    return info.version; // e.g. "1.0.0"
  }

  // ---------------------------------------------------------------------------
  // Download
  // ---------------------------------------------------------------------------

  /// Downloads the APK from [url] into the app's external cache directory.
  /// Calls [onProgress] with values from 0.0 to 1.0.
  static Future<String?> downloadApk(
    String url, {
    void Function(double progress)? onProgress,
  }) async {
    try {
      final request = http.Request('GET', Uri.parse(url));
      final streamed = await http.Client().send(request);

      final contentLength = streamed.contentLength ?? 0;
      final dir = await getTemporaryDirectory();
      final filePath = '${dir.path}/abpos_update.apk';
      final file = File(filePath);
      final sink = file.openWrite();

      int received = 0;
      await for (final chunk in streamed.stream) {
        sink.add(chunk);
        received += chunk.length;
        if (contentLength > 0 && onProgress != null) {
          onProgress(received / contentLength);
        }
      }

      await sink.flush();
      await sink.close();

      return filePath;
    } catch (_) {
      return null;
    }
  }

  // ---------------------------------------------------------------------------
  // Install
  // ---------------------------------------------------------------------------

  /// Opens the downloaded APK for installation.
  static Future<bool> installApk(String filePath) async {
    try {
      final result = await OpenFilex.open(filePath);
      return result.type == ResultType.done;
    } catch (_) {
      return false;
    }
  }

  // ---------------------------------------------------------------------------
  // Persistence helpers  (for "remind on next launch")
  // ---------------------------------------------------------------------------

  /// Saves a pending update so the install prompt shows again on next launch.
  static Future<void> savePendingUpdate(
      String version, String apkPath) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKeyPendingVersion, version);
    await prefs.setString(_prefKeyPendingApkPath, apkPath);
  }

  /// Clears the pending update (user installed or we want to reset).
  static Future<void> clearPendingUpdate() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefKeyPendingVersion);
    await prefs.remove(_prefKeyPendingApkPath);
  }

  /// Returns the pending update info `(version, apkPath)` if one exists and
  /// the APK file is still on disk.
  static Future<(String?, String?)> getPendingUpdate() async {
    final prefs = await SharedPreferences.getInstance();
    final version = prefs.getString(_prefKeyPendingVersion);
    final path = prefs.getString(_prefKeyPendingApkPath);

    if (version != null && path != null && File(path).existsSync()) {
      return (version, path);
    }

    // Clean up stale entries
    await clearPendingUpdate();
    return (null, null);
  }

  /// Mark a version as dismissed so we don't auto-prompt for the same version
  /// again (still available manually from Settings).
  static Future<void> setDismissedVersion(String version) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKeyDismissedVersion, version);
  }

  static Future<String?> getDismissedVersion() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_prefKeyDismissedVersion);
  }
}
