import 'package:flutter/material.dart';

import '../models/mushaf_riwayah.dart';
import '../models/mushaf_riwayah_x.dart';

/// Uthmani typography — breaks Theme/DefaultTextStyle inheritance (Poppins/IBM Plex).
abstract final class MushafTypography {
  /// Body ayah style. [inherit: false] is required so app-wide Arabic UI fonts
  /// (IBM Plex) cannot replace missing glyphs or override the Quran face.
  static TextStyle ayah({
    required MushafRiwayah riwayah,
    required Color color,
    required double fontScale,
    double baseSize = 24,
    double height = 2.1,
  }) {
    return TextStyle(
      inherit: false,
      fontFamily: riwayah.fontFamily,
      fontFamilyFallback: riwayah.fontFamilyFallback,
      fontSize: baseSize * fontScale,
      height: height,
      color: color,
      fontWeight: FontWeight.normal,
      fontStyle: FontStyle.normal,
      letterSpacing: 0,
      wordSpacing: 0,
      decoration: TextDecoration.none,
    );
  }

  static TextStyle surahTitle({
    required MushafRiwayah riwayah,
    required Color color,
    double fontSize = 18,
  }) {
    return TextStyle(
      inherit: false,
      fontFamily: riwayah.fontFamily,
      fontFamilyFallback: riwayah.fontFamilyFallback,
      fontSize: fontSize,
      height: 1.5,
      color: color,
      fontWeight: FontWeight.normal,
      fontStyle: FontStyle.normal,
      letterSpacing: 0,
      wordSpacing: 0,
      decoration: TextDecoration.none,
    );
  }

  /// Collapse whitespace; keep NBSP only before ayah-end digits.
  static String normalizeAyahText(String raw) {
    final collapsed = raw.replaceAll(RegExp(r'[\s\u00A0\u2000-\u200B\u202F\u205F]+'), ' ').trim();

    return collapsed.replaceAllMapped(
      RegExp(r' ([٠-٩0-9]+)'),
      (m) => '\u00A0${m[1]}',
    );
  }

  /// Fix Warsh sequences that KFGQPC Warsh V2 Bold cannot paint.
  ///
  /// Page JSON stores Yeh Barree + Hamza as U+06D2 U+0654 (or NFC U+06D3).
  /// In this face U+06D3 is wrongly mapped to uni0600 (Arabic Number Sign) and
  /// paints as a solid black circle — e.g. يَسْتَهْزِۓُ on page 3. Map both
  /// forms to Yeh-with-Hamza (U+0626), which this face shapes correctly.
  static String normalizeWarshMushafText(String raw) {
    if (raw.isEmpty) {
      return raw;
    }
    var out = raw;
    if (out.contains('\u06D2')) {
      out = out.replaceAll('\u06D2\u0654', '\u0626');
    }
    if (out.contains('\u06D3')) {
      out = out.replaceAll('\u06D3', '\u0626');
    }
    return out;
  }

  static String joinAyahs(Iterable<String> texts) {
    return normalizeAyahText(texts.map(normalizeAyahText).join(' '));
  }
}
