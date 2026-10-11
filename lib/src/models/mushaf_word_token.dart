import 'mushaf_ayah_ref.dart';

/// One glyph/word token on a mushaf line (Hafs QPC or Warsh Unicode).
class MushafWordToken {
  const MushafWordToken({
    required this.text,
    this.surah,
    this.ayah,
  });

  final String text;
  final int? surah;
  final int? ayah;

  MushafAyahRef? get ayahRef {
    final s = surah;
    final a = ayah;
    if (s == null || a == null || s < 1 || a < 1) {
      return null;
    }
    return MushafAyahRef(surahId: s, ayahNumber: a);
  }

  factory MushafWordToken.fromJson(dynamic json) {
    if (json is String) {
      return MushafWordToken(text: json);
    }
    if (json is Map<String, dynamic>) {
      return MushafWordToken(
        text: json['t'] as String? ?? json['text'] as String? ?? '',
        surah: json['s'] as int? ?? json['surah'] as int?,
        ayah: json['a'] as int? ?? json['ayah'] as int?,
      );
    }
    throw FormatException('Unexpected mushaf word token: $json');
  }

  Map<String, dynamic> toJson() {
    if (surah == null && ayah == null) {
      return {'t': text};
    }
    return {
      't': text,
      if (surah != null) 's': surah,
      if (ayah != null) 'a': ayah,
    };
  }
}
