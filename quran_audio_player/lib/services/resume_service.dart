import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Saves and restores the last playback position per Firebase user.
class ResumeService {
  static String get _uid =>
      FirebaseAuth.instance.currentUser?.uid ?? 'guest';

  static String _key(String base) => '${base}_$_uid';

  static const _kUrl = 'resume_url';
  static const _kPos = 'resume_pos_ms';
  static const _kSurahName = 'resume_surah_name';
  static const _kSurahEn = 'resume_surah_en';
  static const _kReciter = 'resume_reciter_name';
  static const _kSurahId = 'resume_surah_id';
  static const _kReciterId = 'resume_reciter_id';

  static Future<void> save({
    required String url,
    required int positionMs,
    required String surahName,
    required String surahEnglishName,
    required String reciterName,
    required int surahId,
    required int reciterId,
  }) async {
    if (FirebaseAuth.instance.currentUser == null) return;
    final p = await SharedPreferences.getInstance();
    await p.setString(_key(_kUrl), url);
    await p.setInt(_key(_kPos), positionMs);
    await p.setString(_key(_kSurahName), surahName);
    await p.setString(_key(_kSurahEn), surahEnglishName);
    await p.setString(_key(_kReciter), reciterName);
    await p.setInt(_key(_kSurahId), surahId);
    await p.setInt(_key(_kReciterId), reciterId);
  }

  static Future<Map<String, dynamic>?> load() async {
    if (FirebaseAuth.instance.currentUser == null) return null;
    final p = await SharedPreferences.getInstance();
    final url = p.getString(_key(_kUrl));
    if (url == null || url.isEmpty) return null;
    final pos = p.getInt(_key(_kPos)) ?? 0;
    if (pos <= 0) return null;
    return {
      'url': url,
      'positionMs': pos,
      'surahName': p.getString(_key(_kSurahName)) ?? '',
      'surahEnglishName': p.getString(_key(_kSurahEn)) ?? '',
      'reciterName': p.getString(_key(_kReciter)) ?? '',
      'surahId': p.getInt(_key(_kSurahId)) ?? 0,
      'reciterId': p.getInt(_key(_kReciterId)) ?? 0,
    };
  }

  static Future<void> clear() async {
    final p = await SharedPreferences.getInstance();
    for (final k in [
      _kUrl,
      _kPos,
      _kSurahName,
      _kSurahEn,
      _kReciter,
      _kSurahId,
      _kReciterId,
    ]) {
      await p.remove(_key(k));
    }
  }
}
