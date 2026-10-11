import 'mushaf_surah.dart';

class MushafSurahSearchEntry {
  const MushafSurahSearchEntry({
    required this.surah,
    required this.normalizedNameAr,
    required this.normalizedNameEn,
  });

  final MushafSurah surah;
  final String normalizedNameAr;
  final String normalizedNameEn;
}
