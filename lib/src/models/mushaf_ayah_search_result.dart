import 'mushaf_ayah.dart';

/// Word-search hit list with a total match count (may exceed [ayahs].length).
class MushafAyahSearchResult {
  const MushafAyahSearchResult({
    required this.ayahs,
    required this.totalCount,
    required this.query,
  });

  /// Truncated match list (capped for UI performance).
  final List<MushafAyah> ayahs;

  /// Full number of matching ayahs in the corpus.
  final int totalCount;

  /// Normalized single-word query that was searched.
  final String query;

  bool get isEmpty => totalCount == 0;

  bool get isTruncated => ayahs.length < totalCount;
}
