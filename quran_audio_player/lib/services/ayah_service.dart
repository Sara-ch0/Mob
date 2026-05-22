import 'dart:convert';
import 'package:http/http.dart' as http;

/// Fetches Arabic ayahs for a given surah from the AlQuran Cloud API.
/// Results are cached in memory to avoid repeated network calls.
class AyahService {
  static const _base = 'https://api.alquran.cloud/v1/surah';

  // In-memory cache: surahId → list of Arabic ayah texts
  static final _cache = <int, List<String>>{};

  static Future<List<String>> fetchAyahs(int surahId) async {
    if (_cache.containsKey(surahId)) return _cache[surahId]!;

    try {
      final resp = await http
          .get(Uri.parse('$_base/$surahId'))
          .timeout(const Duration(seconds: 10));

      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body) as Map<String, dynamic>;
        final ayahs = (data['data']['ayahs'] as List)
            .map((a) => a['text'] as String)
            .toList();
        _cache[surahId] = ayahs;
        return ayahs;
      }
    } catch (e) {
      // Return empty — UI will show "Verses unavailable"
    }
    return [];
  }
}
