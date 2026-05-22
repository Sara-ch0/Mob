import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/surah_model.dart';

enum DownloadStatus { idle, downloading, done, error }

class DownloadState {
  final DownloadStatus status;
  final double progress;
  const DownloadState({required this.status, this.progress = 0.0});
}

/// Manages offline download of Quran surah audio files.
class DownloadService {
  static final _dio = Dio();
  static final _states = <String, DownloadState>{};
  static final _listeners = <String, List<void Function(DownloadState)>>{};
  static String get _prefKey {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? 'guest';
    return 'downloaded_urls_$uid';
  }

  // Global reactive set of downloaded URLs
  static final ValueNotifier<Set<String>> downloadedUrls = ValueNotifier({});

  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_prefKey) ?? [];
    downloadedUrls.value = list.toSet();
  }

  // ── Listener pattern for UI updates ─────────────────────────────────────────
  static void addListener(String url, void Function(DownloadState) cb) =>
      _listeners.putIfAbsent(url, () => []).add(cb);

  static void removeListener(String url, void Function(DownloadState) cb) =>
      _listeners[url]?.remove(cb);

  static void _notify(String url, DownloadState state) {
    _states[url] = state;
    for (final cb in List.from(_listeners[url] ?? [])) {
      cb(state);
    }
  }

  static DownloadState getState(String url) =>
      _states[url] ?? const DownloadState(status: DownloadStatus.idle);

  // ── Paths ────────────────────────────────────────────────────────────────────
  static Future<String> _localPath(String url) async {
    final dir = await getApplicationDocumentsDirectory();
    final folder = Directory('${dir.path}/quran_downloads');
    if (!await folder.exists()) await folder.create(recursive: true);
    return '${folder.path}/${url.split('/').last}';
  }

  // ── Public API ───────────────────────────────────────────────────────────────
  static Future<bool> isDownloaded(String url) async {
    final path = await _localPath(url);
    return File(path).exists();
  }

  static Future<String?> getLocalPath(String url) async {
    final path = await _localPath(url);
    return await File(path).exists() ? path : null;
  }

  static Future<void> download(Reciter r) async {
    final url = r.audioUrl;
    if (_states[url]?.status == DownloadStatus.downloading) return;
    _notify(url, const DownloadState(status: DownloadStatus.downloading, progress: 0));

    try {
      final path = await _localPath(url);
      await _dio.download(
        url,
        path,
        onReceiveProgress: (recv, total) {
          if (total > 0) {
            _notify(url, DownloadState(
              status: DownloadStatus.downloading,
              progress: recv / total,
            ));
          }
        },
      );
      // Persist to prefs
      final prefs = await SharedPreferences.getInstance();
      final list = prefs.getStringList(_prefKey) ?? [];
      if (!list.contains(url)) {
        list.add(url);
        await prefs.setStringList(_prefKey, list);
        downloadedUrls.value = {...downloadedUrls.value, url};
      }
      _notify(url, const DownloadState(status: DownloadStatus.done, progress: 1));
    } catch (_) {
      _notify(url, const DownloadState(status: DownloadStatus.error));
    }
  }

  static Future<void> delete(String url) async {
    final path = await _localPath(url);
    final file = File(path);
    if (await file.exists()) await file.delete();
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_prefKey) ?? [];
    list.remove(url);
    await prefs.setStringList(_prefKey, list);
    downloadedUrls.value = {...downloadedUrls.value}..remove(url);
    _notify(url, const DownloadState(status: DownloadStatus.idle));
  }

  static Future<List<Map<String, dynamic>>> getDownloadedFiles() async {
    final prefs = await SharedPreferences.getInstance();
    final urls = prefs.getStringList(_prefKey) ?? [];
    final result = <Map<String, dynamic>>[];
    for (final url in urls) {
      final path = await _localPath(url);
      final file = File(path);
      if (await file.exists()) {
        result.add({'url': url, 'path': path, 'size': await file.length()});
        // Mark state as done
        _states[url] = const DownloadState(status: DownloadStatus.done, progress: 1);
      }
    }
    return result;
  }

  static Future<void> deleteAll() async {
    final prefs = await SharedPreferences.getInstance();
    final urls = prefs.getStringList(_prefKey) ?? [];
    for (final url in urls) {
      final path = await _localPath(url);
      final file = File(path);
      if (await file.exists()) await file.delete();
      _notify(url, const DownloadState(status: DownloadStatus.idle));
    }
    await prefs.remove(_prefKey);
    downloadedUrls.value = <String>{};
  }

  // ── Logout Cleanup ──────────────────────────────────────────────────────────
  static Future<void> clear() async {
    downloadedUrls.value = <String>{};
    for (final url in _states.keys) {
      _notify(url, const DownloadState(status: DownloadStatus.idle));
    }
    _states.clear();
  }
}
