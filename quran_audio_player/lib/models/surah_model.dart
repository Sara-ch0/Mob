class Surah {
  final int id;
  final String name;
  final String englishName;
  final int numberOfAyahs;
  final List<Reciter> reciters;

  const Surah({
    required this.id,
    required this.name,
    required this.englishName,
    required this.numberOfAyahs,
    required this.reciters,
  });

  factory Surah.fromJson(Map<String, dynamic> json) {
    // FIX: Look for 'number' OR 'id'
    final sId = json['number'] ?? json['id'] ?? 0;
    // FIX: Look for 'name' OR 'surahName'
    final sName = json['name'] ?? json['surahName'] ?? '';
    final sEng = json['englishName'] ?? '';

    return Surah(
      id: sId,
      name: sName,
      englishName: sEng,
      numberOfAyahs: json['numberOfAyahs'] ?? 0,
      // We manually create a Reciter for each surah to ensure audio works
      reciters: [
        Reciter(
          id: 1,
          name: "Mishary Rashid Alafasy",
          audioUrl:
              "https://cdn.islamic.network/quran/audio-surah/128/ar.alafasy/$sId.mp3",
          surahId: sId,
          surahName: sName,
          surahEnglishName: sEng,
        ),
      ],
    );
  }
}

class Reciter {
  final int id;
  final String name;
  final String audioUrl;
  final int surahId;
  final String surahName;
  final String surahEnglishName;

  const Reciter({
    required this.id,
    required this.name,
    required this.audioUrl,
    required this.surahId,
    required this.surahName,
    required this.surahEnglishName,
  });

  factory Reciter.fromJson(Map<String, dynamic> json) => Reciter(
        id: json['id'] ?? 0,
        name: json['name'] ?? '',
        audioUrl: json['audioUrl'] ?? '',
        surahId: 0,
        surahName: '',
        surahEnglishName: '',
      );

  Reciter copyWith(
          {int? surahId, String? surahName, String? surahEnglishName}) =>
      Reciter(
        id: id,
        name: name,
        audioUrl: audioUrl,
        surahId: surahId ?? this.surahId,
        surahName: surahName ?? this.surahName,
        surahEnglishName: surahEnglishName ?? this.surahEnglishName,
      );

  String get favouriteId => '${surahId}_$id';

  Map<String, dynamic> toFirestore() => {
        'reciterId': id,
        'reciterName': name,
        'audioUrl': audioUrl,
        'surahId': surahId,
        'surahName': surahName,
        'surahEnglishName': surahEnglishName,
        'addedAt': DateTime.now().toIso8601String(),
      };

  factory Reciter.fromFirestore(Map<String, dynamic> d) => Reciter(
        id: d['reciterId'],
        name: d['reciterName'],
        audioUrl: d['audioUrl'],
        surahId: d['surahId'],
        surahName: d['surahName'],
        surahEnglishName: d['surahEnglishName'],
      );
}
