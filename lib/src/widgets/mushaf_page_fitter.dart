import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../models/mushaf_ayah.dart';
import 'mushaf_ayah_marker.dart';
import '../typography/mushaf_typography.dart';

/// Shared mushaf page-fit constants and span builders.
abstract final class MushafPageFitter {
  /// Smallest allowed fraction of the user font scale when fitting a page.
  static const minScaleFactor = 0.55;
}

/// Rich ayah run (body + ayah-end marks) as pure [TextSpan]s so word spacing
/// stays natural and height can be measured without WidgetSpan gaps.
InlineSpan mushafPageSpan({
  required List<MushafAyah> ayahs,
  required Color ink,
  required double markerFontSize,
}) {
  final children = <InlineSpan>[];
  final trailing = RegExp(r'[\s\u00A0]*[٠-٩0-9]+$');

  for (final ayah in ayahs) {
    final body = MushafTypography.normalizeAyahText(
      ayah.text.replaceFirst(trailing, ''),
    );
    if (body.isNotEmpty) {
      children.add(TextSpan(text: body));
    }
    children.add(
      MushafAyahMarker.span(
        number: ayah.ayahNumber,
        color: ink,
        fontSize: markerFontSize,
      ),
    );
    children.add(const TextSpan(text: ' '));
  }

  return TextSpan(children: children);
}

/// Measures a span at [maxWidth] with centered RTL layout.
double measureMushafSpan({
  required InlineSpan span,
  required TextStyle style,
  required double maxWidth,
}) {
  final painter = TextPainter(
    text: TextSpan(style: style, children: [span]),
    textDirection: ui.TextDirection.rtl,
    textAlign: TextAlign.center,
    textScaler: TextScaler.noScaling,
  )..layout(maxWidth: maxWidth);
  return painter.height;
}
