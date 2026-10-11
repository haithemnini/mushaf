/// Geometry of the generated Warsh mushaf pages.
///
/// Page JSONs fix which words sit on which line, so the renderer must reproduce
/// the ratio the generator measured. Generator reference: 474px frame, 444.3px
/// safe text width, 27px body, 16 visual slots.
abstract final class WarshMushafLayout {
  static const int visualLinesPerPage = 16;
  static const int ayahLinesPerPage = visualLinesPerPage;
  static const double referenceFrameWidth = 474.0;
  static const double referenceTextWidth = 444.3;
  static const double referenceFontSize = 27.0;
  static const double lineHeight = 1.8;
  static const double letterSpacingRatio = -0.2 / referenceFontSize;

  /// Browser canvas measured this face up to ~9.6% narrower than Skia.
  static const double fitSafety = 0.91;

  /// Body boost once word gaps are removed. Uniform measurement still
  /// shrinks a page if any line would overflow.
  static const double displayScale = 1.20;

  static const double _textWidthRatio =
      referenceTextWidth / referenceFrameWidth;

  /// Surah-frame aspect from `surah_frame.svg` (16320×2000).
  static const double surahFrameAspect = 2000 / 16320;

  static double textWidthForFrame(double frameWidth) =>
      frameWidth * _textWidthRatio;

  static double fontSizeForFrame(double frameWidth) =>
      textWidthForFrame(frameWidth) /
      (referenceTextWidth / referenceFontSize) *
      fitSafety *
      displayScale;

  static WarshVerticalFit verticalFit({
    required double maxHeight,
    required double lineWidth,
    required double fontSize,
    required int ayahLines,
    required int surahHeaders,
    required int basmalas,
  }) {
    if (maxHeight <= 0 || ayahLines <= 0) {
      return const WarshVerticalFit(chromeScale: 1, lineHeight: lineHeight);
    }

    final budget = (maxHeight - 8).clamp(1.0, maxHeight);
    const surahPad = 16.0;
    const basmalaBody = 28.0;
    const basmalaPad = 8.0;
    final frameHeight = lineWidth * surahFrameAspect;
    var heightMult = lineHeight;

    double estimate() {
      final ayahH = fontSize * heightMult * ayahLines;
      final surahH = surahHeaders * (frameHeight + surahPad);
      final basmalaH = basmalas * (basmalaBody + basmalaPad);
      return ayahH + surahH + basmalaH;
    }

    for (var i = 0; i < 6; i++) {
      final h = estimate();
      if (h <= budget) break;
      heightMult = (heightMult * budget / h).clamp(1.20, lineHeight);
    }

    return WarshVerticalFit(chromeScale: 1, lineHeight: heightMult);
  }
}

/// Result of [WarshMushafLayout.verticalFit].
class WarshVerticalFit {
  const WarshVerticalFit({
    required this.chromeScale,
    required this.lineHeight,
  });

  final double chromeScale;
  final double lineHeight;
}
