import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

/// Arabic mushaf justification via tatweel (كشيدة / `U+0640`).
///
/// Rule (user): never insert tatweel **after** these letters:
/// `ذ ء ؤ ر ة و ز د ا` (plus common alef variants).
abstract final class MushafKashidaJustifier {
  static const kashida = '\u0640';

  /// Do not elongate after these base letters (non-connectors + user rule).
  static const _noKashidaAfter = {
    'ذ',
    'ء',
    'ؤ',
    'ر',
    'ة',
    'و',
    'ز',
    'د',
    'ا',
    // Alef / hamza-on-alef variants treated like ا
    'أ',
    'إ',
    'آ',
    'ٱ',
  };

  static final _allah = RegExp(r'ٱ?لل[َّٰ]*ه');

  /// Soft wrap + light stretch for continuous paragraph text.
  static List<String> justify({
    required String text,
    required TextStyle style,
    required double maxWidth,
    bool justifyLastLine = false,
  }) {
    if (text.isEmpty || maxWidth <= 0) {
      return const [];
    }

    final words = text.split(' ').where((w) => w.isNotEmpty).toList();
    if (words.isEmpty) {
      return const [];
    }

    final packed = <List<String>>[];
    var current = <String>[];

    for (final word in words) {
      final trial = current.isEmpty ? word : '${current.join(' ')} $word';
      if (_width(trial, style) <= maxWidth || current.isEmpty) {
        current.add(word);
      } else {
        packed.add(current);
        current = [word];
      }
    }
    if (current.isNotEmpty) {
      packed.add(current);
    }

    final out = <String>[];
    for (var i = 0; i < packed.length; i++) {
      final isLast = i == packed.length - 1;
      final joined = packed[i].join(' ');
      final shouldJustify =
          (!isLast || justifyLastLine) && packed[i].length > 1;
      if (!shouldJustify) {
        out.add(joined);
        continue;
      }
      out.add(
        fillToWidth(
          text: joined,
          style: style,
          maxWidth: maxWidth,
          minFillRatio: 0.84,
          maxKashida: 6,
        ),
      );
    }
    return out;
  }

  /// Fill one already-broken mushaf line to [maxWidth] using kashida.
  ///
  /// Used by Warsh page renderer so lines share the same end edge without
  /// widening inter-word gaps.
  ///
  /// Inserts tatweel in one bulk pass (few [TextPainter] layouts) and caches
  /// results — critical for smooth PageView swipes.
  static String fillToWidth({
    required String text,
    required TextStyle style,
    required double maxWidth,
    double minFillRatio = 0.55,
    int maxKashida = 28,
  }) {
    if (text.isEmpty || maxWidth <= 0) {
      return text;
    }

    final cacheKey =
        '${style.fontFamily}|${style.fontSize}|${maxWidth.toStringAsFixed(1)}|$maxKashida|$minFillRatio|$text';
    final cached = _fillCache[cacheKey];
    if (cached != null) {
      return cached;
    }

    final width = _width(text, style);
    if (width >= maxWidth - 0.5) {
      return _remember(cacheKey, text);
    }

    // Extremely short fragments stay natural (caller may center them).
    if (width / maxWidth < minFillRatio) {
      return _remember(cacheKey, text);
    }

    final slots = _kashidaSlots(text);
    if (slots.isEmpty) {
      return _remember(cacheKey, text);
    }

    final kashidaWidth = math.max(0.4, _width(kashida, style));
    var needed = ((maxWidth - width) / kashidaWidth).floor();
    needed = needed.clamp(0, maxKashida);
    if (needed <= 0) {
      return _remember(cacheKey, text);
    }

    var filled = _bulkInsertKashida(text, slots, needed);
    var filledWidth = _width(filled, style);

    // Overshoot: binary-search down the count (1–2 extra measures).
    if (filledWidth > maxWidth + 0.75) {
      var lo = 0;
      var hi = needed;
      var best = text;
      while (lo <= hi) {
        final mid = (lo + hi) ~/ 2;
        if (mid == 0) {
          best = text;
          hi = -1;
          break;
        }
        final trial = _bulkInsertKashida(text, slots, mid);
        final trialWidth = _width(trial, style);
        if (trialWidth <= maxWidth + 0.75) {
          best = trial;
          lo = mid + 1;
        } else {
          hi = mid - 1;
        }
      }
      filled = best;
    } else if (filledWidth < maxWidth - kashidaWidth * 1.25 &&
        needed < maxKashida) {
      // Slight undershoot: try one more tatweel if it still fits.
      final extra = math.min(maxKashida, needed + 1);
      final trial = _bulkInsertKashida(text, slots, extra);
      if (_width(trial, style) <= maxWidth + 0.75) {
        filled = trial;
      }
    }

    return _remember(cacheKey, filled);
  }

  static const int _fillCacheLimit = 512;
  static final Map<String, String> _fillCache = {};

  static String _remember(String key, String value) {
    if (_fillCache.length >= _fillCacheLimit) {
      _fillCache.clear();
    }
    _fillCache[key] = value;
    return value;
  }

  /// Distribute [count] tatweel glyphs across [slots] (round-robin), inserting
  /// from the end so earlier indexes stay valid.
  static String _bulkInsertKashida(
    String text,
    List<int> slots,
    int count,
  ) {
    if (count <= 0 || slots.isEmpty) {
      return text;
    }

    final amounts = List<int>.filled(slots.length, 0);
    for (var i = 0; i < count; i++) {
      amounts[(i * 3) % slots.length]++;
    }

    final buffer = StringBuffer();
    var cursor = 0;
    for (var s = 0; s < slots.length; s++) {
      final at = slots[s];
      buffer.write(text.substring(cursor, at));
      for (var k = 0; k < amounts[s]; k++) {
        buffer.write(kashida);
      }
      cursor = at;
    }
    buffer.write(text.substring(cursor));
    return buffer.toString();
  }

  /// Insertion indexes: after a connecting letter (+ its marks), before the
  /// next base letter — never after [\_noKashidaAfter].
  static List<int> _kashidaSlots(String line) {
    final slots = <int>[];
    final forbidden = List<bool>.filled(line.length, false);
    for (final match in _allah.allMatches(line)) {
      for (var i = match.start; i < match.end; i++) {
        forbidden[i] = true;
      }
    }

    for (var i = 0; i < line.length; i++) {
      final ch = line[i];
      if (_isMark(ch.codeUnitAt(0)) ||
          ch == kashida ||
          ch == ' ' ||
          ch == '\u00A0' ||
          ch == '\u2006' ||
          ch == '\u2009' ||
          ch == '\u200A' ||
          ch == '\u200B') {
        continue;
      }
      if (_noKashidaAfter.contains(ch) || forbidden[i]) {
        continue;
      }

      var j = i + 1;
      while (j < line.length && _isMark(line.codeUnitAt(j))) {
        j++;
      }
      if (j >= line.length) {
        continue;
      }

      final next = line[j];
      // Never between words / at ayah markers.
      if (next == ' ' ||
          next == '\u00A0' ||
          next == '\u2006' ||
          next == '\u2009' ||
          next == '\u200A' ||
          next == '\u200B' ||
          _isEasternDigit(next)) {
        continue;
      }

      // Insert after existing tatweel stack (allows further elongation).
      while (j < line.length && line[j] == kashida) {
        j++;
      }
      if (j >= line.length) {
        continue;
      }
      if (line[j] == ' ' || _isEasternDigit(line[j])) {
        continue;
      }

      slots.add(j);
    }
    return slots;
  }

  static bool _isEasternDigit(String ch) {
    if (ch.isEmpty) return false;
    final c = ch.codeUnitAt(0);
    return (c >= 0x0660 && c <= 0x0669) || (c >= 0x06F0 && c <= 0x06F9);
  }

  static bool _isMark(int code) {
    return (code >= 0x064B && code <= 0x065F) ||
        (code >= 0x0610 && code <= 0x061A) ||
        (code >= 0x06D6 && code <= 0x06ED) ||
        code == 0x0670 ||
        (code >= 0x08D3 && code <= 0x08FF) ||
        (code >= 0x0300 && code <= 0x036F);
  }

  static double _width(String text, TextStyle style) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: ui.TextDirection.rtl,
      maxLines: 1,
      textScaler: TextScaler.noScaling,
    )..layout();
    final w = painter.width;
    painter.dispose();
    return w;
  }
}

/// Mushaf body: proportional lines — soft kashida, no extreme stretch.
class MushafJustifiedText extends StatelessWidget {
  const MushafJustifiedText({
    super.key,
    required this.text,
    required this.style,
    this.justifyLastLine = false,
  });

  final String text;
  final TextStyle style;
  final bool justifyLastLine;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final lines = MushafKashidaJustifier.justify(
          text: text,
          style: style,
          maxWidth: constraints.maxWidth,
          justifyLastLine: justifyLastLine,
        );

        if (lines.isEmpty) {
          return const SizedBox.shrink();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final line in lines)
              Text(
                line,
                textAlign: TextAlign.center,
                textDirection: ui.TextDirection.rtl,
                softWrap: false,
                style: style,
              ),
          ],
        );
      },
    );
  }
}
