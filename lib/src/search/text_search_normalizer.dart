/// Normalizes text for search: strips Arabic diacritics, expands Quranic
/// letter-like marks into base letters, unifies letter forms, and folds Latin
/// transliteration accents. Display text is never modified — use this layer
/// only when indexing or matching search queries.
abstract final class TextSearchNormalizer {
  /// Harakat / Quranic annotation marks that are not letters.
  ///
  /// Excludes U+0670 (superscript alef) and U+06E5–U+06E7 (small waw/yeh);
  /// those encode letters and are expanded in [_expandQuranicLetters] first.
  static final RegExp _arabicMarks = RegExp(
    r'[\u0610-\u061A\u064B-\u065F\u06D6-\u06E4\u06E8-\u06ED\u0640]',
  );

  static final RegExp _ignorablePunctuation = RegExp(r"[-'‘'ʼ`´]");
  static final RegExp _whitespace = RegExp(r'\s+');

  static String normalize(String input) {
    if (input.isEmpty) {
      return '';
    }

    var text = input.trim();
    text = _expandQuranicLetters(text);
    text = text.replaceAll(_arabicMarks, '');
    text = _foldLatinAccents(text);
    text = _unifyArabicLetters(text);
    text = text.replaceAll(_ignorablePunctuation, '');
    text = text.replaceAll(_whitespace, ' ').trim().toLowerCase();
    return text;
  }

  /// Map Uthmani letter-like marks to emlaey letters before stripping marks.
  ///
  /// Example: `وَٰحِدَة` → `واحِدَة` so "واحدة" matches after diacritic strip.
  static String _expandQuranicLetters(String text) {
    if (text.isEmpty) {
      return text;
    }
    return text
        .replaceAll('\u0670', 'ا') // superscript alef
        .replaceAll('\u06E5', 'و') // small waw
        .replaceAll('\u06E6', 'ي') // small yeh
        .replaceAll('\u06E7', 'ي'); // small high yeh
  }

  static bool contains(String haystack, String needle) {
    final normalizedNeedle = normalize(needle);
    if (normalizedNeedle.isEmpty) {
      return true;
    }
    return normalize(haystack).contains(normalizedNeedle);
  }

  static bool equals(String a, String b) => normalize(a) == normalize(b);

  static String _unifyArabicLetters(String text) {
    return text
        .replaceAll('أ', 'ا')
        .replaceAll('إ', 'ا')
        .replaceAll('آ', 'ا')
        .replaceAll('ٱ', 'ا')
        .replaceAll('ة', 'ه')
        .replaceAll('ى', 'ي')
        .replaceAll('ؤ', 'و')
        .replaceAll('ئ', 'ي');
  }

  static String _foldLatinAccents(String text) {
    final buffer = StringBuffer();

    for (final codeUnit in text.codeUnits) {
      buffer.write(_foldLatinCodeUnit(codeUnit));
    }

    return buffer.toString();
  }

  static String _foldLatinCodeUnit(int codeUnit) {
    switch (codeUnit) {
      case 0x00C0:
      case 0x00C1:
      case 0x00C2:
      case 0x00C3:
      case 0x00C4:
      case 0x00C5:
      case 0x0100:
      case 0x0102:
      case 0x0104:
        return 'a';
      case 0x00E0:
      case 0x00E1:
      case 0x00E2:
      case 0x00E3:
      case 0x00E4:
      case 0x00E5:
      case 0x0101:
      case 0x0103:
      case 0x0105:
        return 'a';
      case 0x00C8:
      case 0x00C9:
      case 0x00CA:
      case 0x00CB:
      case 0x0112:
      case 0x0114:
        return 'e';
      case 0x00E8:
      case 0x00E9:
      case 0x00EA:
      case 0x00EB:
      case 0x0113:
      case 0x0115:
        return 'e';
      case 0x00CC:
      case 0x00CD:
      case 0x00CE:
      case 0x00CF:
      case 0x0128:
      case 0x012A:
        return 'i';
      case 0x00EC:
      case 0x00ED:
      case 0x00EE:
      case 0x00EF:
      case 0x0129:
      case 0x012B:
        return 'i';
      case 0x00D2:
      case 0x00D3:
      case 0x00D4:
      case 0x00D5:
      case 0x00D6:
      case 0x014C:
        return 'o';
      case 0x00F2:
      case 0x00F3:
      case 0x00F4:
      case 0x00F5:
      case 0x00F6:
      case 0x014D:
        return 'o';
      case 0x00D9:
      case 0x00DA:
      case 0x00DB:
      case 0x00DC:
      case 0x0168:
      case 0x016A:
        return 'u';
      case 0x00F9:
      case 0x00FA:
      case 0x00FB:
      case 0x00FC:
      case 0x0169:
      case 0x016B:
        return 'u';
      case 0x1E24:
      case 0x1E25:
        return 'h';
      case 0x1E62:
      case 0x1E63:
        return 's';
      case 0x1E6C:
      case 0x1E6D:
        return 't';
      default:
        if (codeUnit >= 0x0300 && codeUnit <= 0x036F) {
          return '';
        }
        return String.fromCharCode(codeUnit);
    }
  }
}
