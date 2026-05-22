import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/surah_model.dart';

class QuranApiService {
  static const _base = 'https://api.alquran.cloud/v1/surah';

  static Future<List<Surah>> fetchSurahs() async {
    try {
      final response = await http.get(Uri.parse(_base));
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        final List list =
            data['data']; // AlQuran Cloud wraps data in a 'data' key
        return list.map((json) => Surah.fromJson(json)).toList();
      }
    } catch (e) {
      print("API Error: $e");
    }
    return [];
  }
}
