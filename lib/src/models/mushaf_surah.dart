class MushafSurah {
  const MushafSurah({
    required this.id,
    required this.nameAr,
    required this.nameEn,
    required this.ayahs,
    required this.revelationPlaceAr,
    required this.revelationPlaceEn,
    required this.ayahStart,
    required this.ayahEnd,
    required this.juz,
  });

  final int id;
  final String nameAr;
  final String nameEn;
  final int ayahs;
  final String revelationPlaceAr;
  final String revelationPlaceEn;
  final int ayahStart;
  final int ayahEnd;
  final List<int> juz;

  factory MushafSurah.fromJson(Map<String, dynamic> json) {
    return MushafSurah(
      id: json['id'] as int,
      nameAr: json['name_ar'] as String,
      nameEn: json['name_en'] as String,
      ayahs: json['ayahs'] as int,
      revelationPlaceAr: json['revelation_place_ar'] as String,
      revelationPlaceEn: json['revelation_place_en'] as String,
      ayahStart: json['ayah_start'] as int,
      ayahEnd: json['ayah_end'] as int,
      juz: _parseJuz(json['juz']),
    );
  }

  static List<int> _parseJuz(dynamic value) {
    if (value is int) {
      return [value];
    }
    if (value is List) {
      return value.map((item) => item as int).toList(growable: false);
    }
    throw FormatException('Unexpected juz value: $value');
  }
}
