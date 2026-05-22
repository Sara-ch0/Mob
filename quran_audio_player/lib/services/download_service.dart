import 'dart:convert';
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

/// Manages offline download of Quran surah audio files (per user).
class DownloadService {
  static final _dio = Dio();
  static final _states = <String, DownloadState>{};
  static final _listeners = <String, List<void Function(DownloadState)>>{};

  static String get _uid =>
      FirebaseAuth.instance.currentUser?.uid ?? 'guest';

  static String get _prefKey => 'downloaded_urls_$_uid';
  static String get _metaKey => 'downloaded_meta_$_uid';

  static final ValueNotifier<Set<String>> downloadedUrls = ValueNotifier({});

  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    var list = List<String>.from(prefs.getStringList(_prefKey) ?? []);
    final meta = await _loadMetaMap(prefs);
    final valid = <String>[];

    for (final url in list) {
      if (await isDownloaded(url)) {
        valid.add(url);
      } else {
        meta.remove(url);
      }
    }

    // Recover files on disk not listed in prefs (e.g. after reinstall)
    final dir = await getApplicationDocumentsDirectory();
    final folder = Directory('${dir.path}/quran_downloads');
    if (await folder.exists()) {
      await for (final entity in folder.list()) {
        if (entity is! File || !entity.path.endsWith('.mp3')) continue;
        final id = entity.uri.pathSegments.last.replaceAll('.mp3', '');
        final url = _urlFromSurahId(int.tryParse(id) ?? 0);
        if (url.isEmpty) continue;
        if (!valid.contains(url)) {
          valid.add(url);
          meta.putIfAbsent(url, () => _defaultMetaForUrl(url));
        }
      }
    }

    await prefs.setStringList(_prefKey, valid);
    await _saveMetaMap(prefs, meta);
    downloadedUrls.value = valid.toSet();
  }

  static String _urlFromSurahId(int surahId) {
    if (surahId < 1 || surahId > 114) return '';
    return 'https://cdn.islamic.network/quran/audio-surah/128/ar.alafasy/$surahId.mp3';
  }

  static Map<String, dynamic> _defaultMetaForUrl(String url) {
    final id = _surahIdFromUrl(url);
    return {
      'reciterId': 1,
      'reciterName': 'Mishary Rashid Alafasy',
      'audioUrl': url,
      'surahId': id,
      'surahName': '',
      'surahEnglishName': id > 0 ? 'Surah $id' : 'Downloaded surah',
    };
  }

  static int _surahIdFromUrl(String url) {
    final match = RegExp(r'/(\d+)\.mp3').firstMatch(url);
    return int.tryParse(match?.group(1) ?? '') ?? 0;
  }

  static Future<Map<String, Map<String, dynamic>>> _loadMetaMap(
      SharedPreferences prefs) async {
    final raw = prefs.getString(_metaKey);
    if (raw == null || raw.isEmpty) return {};
    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      return decoded.map(
        (k, v) => MapEntry(k, Map<String, dynamic>.from(v as Map)),
      );
    } catch (_) {
      return {};
    }
  }

  static Future<void> _saveMetaMap(
      SharedPreferences prefs, Map<String, Map<String, dynamic>> meta) async {
    await prefs.setString(_metaKey, jsonEncode(meta));
  }

  static Future<void> _persistMeta(Reciter r) async {
    final prefs = await SharedPreferences.getInstance();
    final meta = await _loadMetaMap(prefs);
    meta[r.audioUrl] = r.toFirestore();
    await _saveMetaMap(prefs, meta);
  }

  static Future<void> _removeMeta(String url) async {
    final prefs = await SharedPreferences.getInstance();
    final meta = await _loadMetaMap(prefs);
    meta.remove(url);
    await _saveMetaMap(prefs, meta);
  }

  /// All downloaded tracks with metadata for the current user.
  static Future<List<Reciter>> getDownloadedReciters() async {
    await init();
    final prefs = await SharedPreferences.getInstance();
    final meta = await _loadMetaMap(prefs);
    final result = <Reciter>[];

    for (final url in downloadedUrls.value) {
      if (!await isDownloaded(url)) continue;
      final data = meta[url];
      if (data != null) {
        result.add(Reciter.fromFirestore(data));
      } else {
        result.add(Reciter.fromFirestore(_defaultMetaForUrl(url)));
      }
    }
    result.sort((a, b) => a.surahId.compareTo(b.surahId));
    return result;
  }

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

  static Future<String> _localPath(String url) async {
    final dir = await getApplicationDocumentsDirectory();
    final folder = Directory('${dir.path}/quran_downloads');
    if (!await folder.exists()) await folder.create(recursive: true);
    return '${folder.path}/${url.split('/').last}';
  }

  static Future<bool> isDownloaded(String url) async {
    final path = await _localPath(url);
    return File(path).exists();
  }

  static Future<String?> getLocalPath(String url) async {
    final path = await _localPath(url);
    return File(path).existsSync() ? path : null;
  }

  static Future<void> download(Reciter r) async {
    if (FirebaseAuth.instance.currentUser == null) return;
    final url = r.audioUrl;
    if (_states[url]?.status == DownloadStatus.downloading) return;
    _notify(
        url, const DownloadState(status: DownloadStatus.downloading, progress: 0));

    try {
      final path = await _localPath(url);
      await _dio.download(
        url,
        path,
        onReceiveProgress: (recv, total) {
          if (total > 0) {
            _notify(
                url,
                DownloadState(
                  status: DownloadStatus.downloading,
                  progress: recv / total,
                ));
          }
        },
      );
      final prefs = await SharedPreferences.getInstance();
      final list = prefs.getStringList(_prefKey) ?? [];
      if (!list.contains(url)) {
        list.add(url);
        await prefs.setStringList(_prefKey, list);
      }
      await _persistMeta(r);
      downloadedUrls.value = {...downloadedUrls.value, url};
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
    await _removeMeta(url);
    downloadedUrls.value = {...downloadedUrls.value}..remove(url);
    _notify(url, const DownloadState(status: DownloadStatus.idle));
  }

  static Future<List<Map<String, dynamic>>> getDownloadedFiles() async {
    final reciters = await getDownloadedReciters();
    final result = <Map<String, dynamic>>[];
    for (final r in reciters) {
      final path = await _localPath(r.audioUrl);
      final file = File(path);
      if (await file.exists()) {
        result.add({
          'url': r.audioUrl,
          'path': path,
          'size': await file.length(),
        });
        _states[r.audioUrl] =
            const DownloadState(status: DownloadStatus.done, progress: 1);
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
    await prefs.remove(_metaKey);
    downloadedUrls.value = <String>{};
  }

  /// Clears in-memory state on logout (prefs stay per uid).
  static Future<void> clear() async {
    downloadedUrls.value = <String>{};
    for (final url in _states.keys) {
      _notify(url, const DownloadState(status: DownloadStatus.idle));
    }
    _states.clear();
  }
}
