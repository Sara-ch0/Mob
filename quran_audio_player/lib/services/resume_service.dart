import 'package:shared_preferences/shared_preferences.dart';

/// Saves and restores the last playback position so the user can resume.
class ResumeService {
  static const _kUrl        = 'resume_url';
  static const _kPos        = 'resume_pos_ms';
  static const _kSurahName  = 'resume_surah_name';
  static const _kSurahEn    = 'resume_surah_en';
  static const _kReciter    = 'resume_reciter_name';
  static const _kSurahId    = 'resume_surah_id';
  static const _kReciterId  = 'resume_reciter_id';

  static Future<void> save({
    required String url,
    required int positionMs,
    required String surahName,
    required String surahEnglishName,
    required String reciterName,
    required int surahId,
    required int reciterId,
  }) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_kUrl,       url);
    await p.setInt   (_kPos,       positionMs);
    await p.setString(_kSurahName, surahName);
    await p.setString(_kSurahEn,   surahEnglishName);
    await p.setString(_kReciter,   reciterName);
    await p.setInt   (_kSurahId,   surahId);
    await p.setInt   (_kReciterId, reciterId);
  }

  static Future<Map<String, dynamic>?> load() async {
    final p = await SharedPreferences.getInstance();
    final url = p.getString(_kUrl);
    if (url == null || url.isEmpty) return null;
    return {
      'url':               url,
      'positionMs':        p.getInt(_kPos)       ?? 0,
      'surahName':         p.getString(_kSurahName) ?? '',
      'surahEnglishName':  p.getString(_kSurahEn)   ?? '',
      'reciterName':       p.getString(_kReciter)    ?? '',
      'surahId':           p.getInt(_kSurahId)    ?? 0,
      'reciterId':         p.getInt(_kReciterId)  ?? 0,
    };
  }

  static Future<void> clear() async {
    final p = await SharedPreferences.getInstance();
    for (final k in [_kUrl, _kPos, _kSurahName, _kSurahEn, _kReciter, _kSurahId, _kReciterId]) {
      await p.remove(k);
    }
  }
}
