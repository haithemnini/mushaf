/// QCF4 line layout adapted from quran_library (MIT, Alheekmah Library).
/// QCF fonts and QUL data remain under King Fahd Complex / QUL terms.
enum HafsQcf4LineType {
  surahName,
  basmallah,
  ayah;

  static HafsQcf4LineType fromJson(Object? value) {
    switch (value?.toString()) {
      case 'surah_name':
        return HafsQcf4LineType.surahName;
      case 'basmallah':
        return HafsQcf4LineType.basmallah;
      case 'ayah':
        return HafsQcf4LineType.ayah;
      default:
        throw FormatException('Unsupported line_type: $value');
    }
  }
}

int? hafsQcf4OptionalInt(Object? value) {
  if (value == null) {
    return null;
  }
  if (value is int) {
    return value;
  }
  final text = value.toString().trim();
  if (text.isEmpty) {
    return null;
  }
  return int.tryParse(text);
}

class HafsQcf4LineInfo {
  const HafsQcf4LineInfo({
    required this.pageNumber,
    required this.lineNumber,
    required this.lineType,
    required this.isCentered,
    required this.surahNumber,
    required this.firstWordId,
    required this.lastWordId,
  });

  final int pageNumber;
  final int lineNumber;
  final HafsQcf4LineType lineType;
  final bool isCentered;
  final int? surahNumber;
  final int? firstWordId;
  final int? lastWordId;

  factory HafsQcf4LineInfo.fromJson(Map<String, dynamic> json) {
    return HafsQcf4LineInfo(
      pageNumber: (json['page_number'] as num).toInt(),
      lineNumber: (json['line_number'] as num).toInt(),
      lineType: HafsQcf4LineType.fromJson(json['line_type']),
      isCentered: ((json['is_centered'] as num?)?.toInt() ?? 0) == 1,
      surahNumber: hafsQcf4OptionalInt(json['surah_number']),
      firstWordId: hafsQcf4OptionalInt(json['first_word_id']),
      lastWordId: hafsQcf4OptionalInt(json['last_word_id']),
    );
  }
}

class HafsQcf4Word {
  const HafsQcf4Word({
    required this.id,
    required this.surah,
    required this.ayah,
    required this.wordIndex,
    required this.text,
    required this.page,
  });

  final int id;
  final int surah;
  final int ayah;
  final int wordIndex;
  final String text;
  final int page;

  factory HafsQcf4Word.fromJson(Map<String, dynamic> json, {required int page}) {
    return HafsQcf4Word(
      id: (json['id'] as num).toInt(),
      surah: int.parse(json['surah'].toString()),
      ayah: int.parse(json['ayah'].toString()),
      wordIndex: int.parse(json['word'].toString()),
      text: (json['text'] ?? '').toString(),
      page: page,
    );
  }
}

sealed class HafsQcf4Block {
  const HafsQcf4Block();
}

class HafsQcf4SurahHeaderBlock extends HafsQcf4Block {
  const HafsQcf4SurahHeaderBlock(this.surahNumber);

  final int surahNumber;
}

class HafsQcf4BasmallahBlock extends HafsQcf4Block {
  const HafsQcf4BasmallahBlock(this.surahNumber);

  final int surahNumber;
}

class HafsQcf4WordSegment {
  const HafsQcf4WordSegment({
    required this.surahNumber,
    required this.ayahNumber,
    required this.glyphs,
    required this.isAyahEnd,
  });

  final int surahNumber;
  final int ayahNumber;
  final String glyphs;
  final bool isAyahEnd;
}

class HafsQcf4AyahLineBlock extends HafsQcf4Block {
  const HafsQcf4AyahLineBlock({
    required this.isCentered,
    required this.segments,
  });

  final bool isCentered;
  final List<HafsQcf4WordSegment> segments;
}

/// One run of an ayah that shares a single page font.
class HafsQcf4GlyphRun {
  const HafsQcf4GlyphRun({required this.page, required this.glyphs});

  final int page;
  final String glyphs;
}
