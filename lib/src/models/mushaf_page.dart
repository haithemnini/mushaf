import 'mushaf_word_token.dart';

export 'mushaf_word_token.dart';

/// One mushaf page from QPC V2 / Warsh layout JSON.
class MushafPage {
  const MushafPage({
    required this.page,
    required this.lines,
  });

  final int page;
  final List<MushafLine> lines;

  factory MushafPage.fromJson(Map<String, dynamic> json) {
    return MushafPage(
      page: json['page'] as int,
      lines: (json['lines'] as List<dynamic>)
          .map((e) => MushafLine.fromJson(e as Map<String, dynamic>))
          .toList(growable: false),
    );
  }
}

enum MushafLineType { ayah, basmallah, surahName }

/// One visual row belonging to a Warsh ayah block (may share [visualRow]).
class MushafAyahSubLine {
  const MushafAyahSubLine({
    required this.visualRow,
    required this.lineIndex,
    required this.centered,
    required this.words,
  });

  final int visualRow;
  final int lineIndex;
  final bool centered;
  final List<MushafWordToken> words;

  factory MushafAyahSubLine.fromJson(Map<String, dynamic> json) {
    return MushafAyahSubLine(
      visualRow: json['visualRow'] as int? ?? 0,
      lineIndex: json['lineIndex'] as int? ?? 1,
      centered: json['centered'] as bool? ?? false,
      words: (json['words'] as List<dynamic>? ?? const [])
          .map(MushafWordToken.fromJson)
          .toList(growable: false),
    );
  }
}

class MushafLine {
  const MushafLine({
    required this.type,
    required this.centered,
    this.words = const [],
    this.surah,
    this.ayah,
    this.nameAr,
    this.lineCount,
    this.ayahLines = const [],
    this.complete = true,
  });

  final MushafLineType type;
  final bool centered;
  final List<MushafWordToken> words;
  final int? surah;
  final int? ayah;
  final String? nameAr;
  final int? lineCount;
  final List<MushafAyahSubLine> ayahLines;
  final bool complete;

  bool get isAyahBlock => type == MushafLineType.ayah && ayahLines.isNotEmpty;

  String get text => isAyahBlock
      ? ayahLines.map((line) => line.words.map((w) => w.text).join()).join()
      : words.map((w) => w.text).join();

  factory MushafLine.fromJson(Map<String, dynamic> json) {
    final rawType = json['type'] as String? ?? 'ayah';
    final type = switch (rawType) {
      'basmallah' => MushafLineType.basmallah,
      'surah_name' => MushafLineType.surahName,
      _ => MushafLineType.ayah,
    };
    final ayahLines = (json['lines'] as List<dynamic>? ?? const [])
        .map((e) => MushafAyahSubLine.fromJson(e as Map<String, dynamic>))
        .toList(growable: false);
    return MushafLine(
      type: type,
      centered: json['centered'] as bool? ?? false,
      words: (json['words'] as List<dynamic>? ?? const [])
          .map(MushafWordToken.fromJson)
          .toList(growable: false),
      surah: json['surah'] as int?,
      ayah: json['ayah'] as int?,
      nameAr: json['nameAr'] as String?,
      lineCount: json['lineCount'] as int?,
      ayahLines: ayahLines,
      complete: json['complete'] as bool? ?? true,
    );
  }
}

