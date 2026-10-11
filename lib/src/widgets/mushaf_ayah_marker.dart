import 'package:flutter/material.dart';

import '../fonts/mushaf_fonts.dart';

/// End-of-ayah mark: widget circle, or [TextSpan] glyphs (`۝` + digits).
class MushafAyahMarker extends StatelessWidget {
  const MushafAyahMarker({
    super.key,
    required this.number,
    required this.fontSize,
    required this.colors,
  });

  final int number;
  final double fontSize;
  final ColorScheme colors;

  static const _eastern = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];

  static String easternDigits(int number) {
    return number.toString().split('').map((d) => _eastern[int.parse(d)]).join();
  }

  /// Unicode Arabic End of Ayah + verse number (Hafs / fallback UI).
  static String mark(int number) => '\u06DD${easternDigits(number)}';

  /// Warsh mushaf ends ayahs with Arabic-Indic digits only (no U+06DD).
  static String warshEndMark(int number) => '\u2009${easternDigits(number)}';

  static TextStyle spanStyle({
    required Color color,
    required double fontSize,
  }) {
    return TextStyle(
      inherit: false,
      fontFamily: MushafFonts.digitalMadina,
      fontFamilyFallback: const [
        MushafFonts.digitalMadinaExact,
        MushafFonts.hafsAlias,
      ],
      fontSize: fontSize * 1.05,
      height: 1,
      color: color,
      fontWeight: FontWeight.normal,
      fontStyle: FontStyle.normal,
      letterSpacing: 0,
      wordSpacing: 0,
      decoration: TextDecoration.none,
    );
  }

  /// Inline mark for [Text.rich] / page fitters (no [WidgetSpan]).
  static InlineSpan span({
    required int number,
    required Color color,
    required double fontSize,
  }) {
    return TextSpan(
      text: mark(number),
      style: spanStyle(color: color, fontSize: fontSize),
    );
  }

  String get _label => easternDigits(number);

  @override
  Widget build(BuildContext context) {
    final size = (fontSize * 0.88).clamp(16.0, 28.0);
    final ink = colors.onSurface;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: SizedBox(
        width: size,
        height: size,
        child: DecoratedBox(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: colors.primaryContainer.withValues(alpha: 0.55),
            border: Border.all(
              color: colors.primary.withValues(alpha: 0.75),
              width: 1.2,
            ),
          ),
          child: Center(
            child: Text(
              _label,
              textAlign: TextAlign.center,
              style: TextStyle(
                inherit: false,
                fontFamily: MushafFonts.digitalMadina,
                fontFamilyFallback: const [
                  MushafFonts.digitalMadinaExact,
                  MushafFonts.hafsAlias,
                ],
                fontSize:
                    size *
                    (number >= 100
                        ? 0.38
                        : number >= 10
                        ? 0.42
                        : 0.48),
                height: 1,
                color: ink,
                fontWeight: FontWeight.w600,
                decoration: TextDecoration.none,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
