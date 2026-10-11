import 'mushaf_riwayah.dart';

/// Unified ayah model normalized from Hafs / Warsh JSON schemas.
class MushafAyah {
  const MushafAyah({
    required this.id,
    required this.surahId,
    required this.ayahNumber,
    required this.text,
    required this.juz,
    required this.page,
    required this.surahNameAr,
    required this.surahNameEn,
    this.textEmlaey,
    this.lineStart,
    this.lineEnd,
  });

  final int id;
  final int surahId;
  final int ayahNumber;
  final String text;
  final int juz;
  final int page;
  final String surahNameAr;
  final String surahNameEn;
  final String? textEmlaey;

  /// 1-based inclusive line index on [page] (Hafs corpus).
  final int? lineStart;

  /// 1-based inclusive line index on [page] (Hafs corpus).
  final int? lineEnd;

  factory MushafAyah.fromHafsJson(Map<String, dynamic> json) {
    return MushafAyah(
      id: json['id'] as int,
      surahId: json['sora'] as int,
      ayahNumber: json['aya_no'] as int,
      text: json['aya_text'] as String,
      juz: json['jozz'] as int,
      page: _parsePage(json['page']),
      surahNameAr: (json['sora_name_ar'] as String).trim(),
      surahNameEn: (json['sora_name_en'] as String).trim(),
      textEmlaey: json['aya_text_emlaey'] as String?,
      lineStart: json['line_start'] as int?,
      lineEnd: json['line_end'] as int?,
    );
  }

  factory MushafAyah.fromWarshJson(Map<String, dynamic> json) {
    final pages = _parsePages(value: json['page']);
    return MushafAyah(
      id: json['id'] as int,
      surahId: json['sura_no'] as int,
      ayahNumber: json['aya_no'] as int,
      text: json['aya_text'] as String,
      juz: json['jozz'] as int,
      page: pages.first,
      surahNameAr: (json['sura_name_ar'] as String).trim(),
      surahNameEn: (json['sura_name_en'] as String).trim(),
      lineStart: json['line_start'] as int?,
      lineEnd: json['line_end'] as int?,
    );
  }

  factory MushafAyah.fromJson(
    Map<String, dynamic> json, {
    required MushafRiwayah riwayah,
  }) {
    return switch (riwayah) {
      MushafRiwayah.hafs => MushafAyah.fromHafsJson(json),
      MushafRiwayah.warsh => MushafAyah.fromWarshJson(json),
    };
  }

  /// All mushaf pages this ayah touches (handles values like `85-86`).
  static List<int> pagesForWarshJson(Map<String, dynamic> json) {
    return _parsePages(value: json['page']);
  }

  static List<int> pagesForJson(
    Map<String, dynamic> json, {
    required MushafRiwayah riwayah,
  }) {
    return switch (riwayah) {
      MushafRiwayah.hafs => [_parsePage(json['page'])],
      MushafRiwayah.warsh => pagesForWarshJson(json),
    };
  }

  static int _parsePage(dynamic value) => _parsePages(value: value).first;

  static List<int> _parsePages({required dynamic value}) {
    if (value is int) {
      return [value];
    }
    if (value is String) {
      if (value.contains('-')) {
        final parts = value.split('-');
        if (parts.length == 2) {
          final start = int.parse(parts[0]);
          final end = int.parse(parts[1]);
          return [for (var page = start; page <= end; page++) page];
        }
      }
      return [int.parse(value)];
    }
    throw FormatException('Unexpected page value: $value');
  }
}
