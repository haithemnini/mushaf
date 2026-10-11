import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../fonts/qpc_page_fonts.dart';
import '../models/mushaf_ayah_ref.dart';
import '../models/mushaf_riwayah.dart';
import '../store/mushaf_stores.dart';
import '../style/mushaf_style.dart';
import '../widgets/mushaf_page_number_frame.dart';
import '../widgets/mushaf_surah_name_frame.dart';
import 'hafs_qcf4_fonts.dart';
import 'hafs_qcf4_models.dart';
import 'hafs_qcf4_store.dart';

/// Madinah Hafs page: one QCF4 font per page, one precomposed glyph per word.
///
/// Surah openings keep [MushafSurahNameFrame] and [HafsQcfBasmalah].
class HafsQcf4PageView extends StatefulWidget {
  const HafsQcf4PageView({
    super.key,
    required this.page,
    required this.fontScale,
    required this.style,
    this.highlightedAyah,
    this.playingAyah,
    this.completedAyahs = const {},
    this.bookmarkedAyahs = const {},
    this.onAyahLongPress,
    this.onSurahHeaderLongPress,
    this.tajweed = false,
    this.surahNames = const {},
  });

  final int page;
  final double fontScale;
  final MushafStyle style;
  final MushafAyahRef? highlightedAyah;
  final MushafAyahRef? playingAyah;
  final Set<MushafAyahRef> completedAyahs;
  final Map<MushafAyahRef, MushafBookmarkColor> bookmarkedAyahs;
  final ValueChanged<MushafAyahRef>? onAyahLongPress;
  final ValueChanged<int>? onSurahHeaderLongPress;
  final bool tajweed;

  /// Arabic surah names keyed by surah id (1–114).
  final Map<int, String> surahNames;

  @override
  State<HafsQcf4PageView> createState() => _HafsQcf4PageViewState();
}

class _HafsQcf4PageViewState extends State<HafsQcf4PageView> {
  var _ready = false;
  var _loadGeneration = 0;
  double? _measuredWidth;
  int? _measuredPage;
  double? _measuredScale;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant HafsQcf4PageView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.page != widget.page) {
      final dark = Theme.of(context).brightness == Brightness.dark;
      _ready = HafsQcf4Fonts.isPageLoaded(widget.page, dark: dark, tajweed: widget.tajweed) && HafsQcf4Store.isReady;
      _load();
    }
  }

  Future<void> _load() async {
    final generation = ++_loadGeneration;
    await Future.wait([
      HafsQcf4Store.ensureReady(),
      HafsQcf4Fonts.ensurePage(widget.page, neighbors: false),
      QpcPageFonts.loadSurahNameFont(),
      QpcPageFonts.loadBasmalahFont(),
    ]);
    if (!mounted || generation != _loadGeneration) {
      return;
    }
    setState(() => _ready = true);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style = widget.style;
    final colors = theme.colorScheme;
    final top = MediaQuery.paddingOf(context).top;
    final bottom = MediaQuery.paddingOf(context).bottom;
    final dark = theme.brightness == Brightness.dark;

    return ColoredBox(
      color: style.background,
      child: MediaQuery(
        data: MediaQuery.of(context).copyWith(textScaler: TextScaler.noScaling),
        child: Padding(
          padding: EdgeInsets.fromLTRB(8, top + 6, 8, bottom + 8),
          child: Column(
            children: [
              Expanded(
                child: !_ready
                    ? Center(child: CircularProgressIndicator(color: style.accent))
                    : FittedBox(
                        fit: BoxFit.contain,
                        alignment: Alignment.center,
                        child: SizedBox(
                          width: _pageWidth(),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              for (final block in HafsQcf4Store.blocksForPage(widget.page)) _block(block, colors, dark, _pageWidth()),
                            ],
                          ),
                        ),
                      ),
              ),
              const SizedBox(height: 8),
              MushafPageNumberFrame(
                page: widget.page,
                colors: colors,
                textTheme: theme.textTheme,
              ),
            ],
          ),
        ),
      ),
    );
  }

  double _pageWidth() {
    final scale = widget.fontScale <= 0 ? 1.0 : widget.fontScale;
    if (_measuredWidth != null && _measuredPage == widget.page && _measuredScale == scale) {
      return _measuredWidth!;
    }
    final width = measureHafsQcf4PageWidth(widget.page, scale);
    _measuredWidth = width;
    _measuredPage = widget.page;
    _measuredScale = scale;
    return width;
  }

  Widget _block(HafsQcf4Block block, ColorScheme colors, bool dark, double lineWidth) {
    switch (block) {
      case HafsQcf4SurahHeaderBlock(:final surahNumber):
        final name = _surahName(surahNumber);
        return MushafSurahNameFrame(
          surah: surahNumber,
          nameAr: name,
          riwayah: MushafRiwayah.hafs,
          colors: colors,
          width: lineWidth,
          onLongPress: widget.onSurahHeaderLongPress,
        );
      case HafsQcf4BasmallahBlock():
        return HafsQcfBasmalah(colors: colors);
      case HafsQcf4AyahLineBlock():
        return _Qcf4Line(
          page: widget.page,
          block: block,
          lineWidth: lineWidth,
          fontScale: widget.fontScale,
          dark: dark,
          tajweed: widget.tajweed,
          colors: colors,
          highlightedAyah: widget.highlightedAyah,
          playingAyah: widget.playingAyah,
          completedAyahs: widget.completedAyahs,
          bookmarkedAyahs: widget.bookmarkedAyahs,
          onAyahLongPress: widget.onAyahLongPress,
        );
    }
  }

  String _surahName(int surah) => widget.surahNames[surah] ?? '';
}

class _Qcf4Line extends StatefulWidget {
  const _Qcf4Line({
    required this.page,
    required this.block,
    required this.lineWidth,
    required this.fontScale,
    required this.dark,
    required this.tajweed,
    required this.colors,
    required this.highlightedAyah,
    required this.playingAyah,
    required this.completedAyahs,
    required this.bookmarkedAyahs,
    required this.onAyahLongPress,
  });

  final int page;
  final HafsQcf4AyahLineBlock block;
  final double lineWidth;
  final double fontScale;
  final bool dark;
  final bool tajweed;
  final ColorScheme colors;
  final MushafAyahRef? highlightedAyah;
  final MushafAyahRef? playingAyah;
  final Set<MushafAyahRef> completedAyahs;
  final Map<MushafAyahRef, MushafBookmarkColor> bookmarkedAyahs;
  final ValueChanged<MushafAyahRef>? onAyahLongPress;

  @override
  State<_Qcf4Line> createState() => _Qcf4LineState();
}

class _Qcf4LineState extends State<_Qcf4Line> {
  String? _cacheKey;
  Widget? _cached;

  @override
  Widget build(BuildContext context) {
    final key = _fingerprint();
    if (_cached != null && _cacheKey == key) {
      return _cached!;
    }
    _cacheKey = key;
    _cached = _buildLine();
    return _cached!;
  }

  String _fingerprint() {
    final buffer = StringBuffer(
      '${widget.page}|${widget.dark}|${widget.tajweed}|${widget.fontScale}|${widget.lineWidth}|',
    );
    final seen = <MushafAyahRef>{};
    for (final segment in widget.block.segments) {
      final ref = MushafAyahRef(surahId: segment.surahNumber, ayahNumber: segment.ayahNumber);
      if (!seen.add(ref)) {
        continue;
      }
      buffer
        ..write(ref.surahId)
        ..write(':')
        ..write(ref.ayahNumber)
        ..write(_wash(ref).toARGB32());
    }
    return buffer.toString();
  }

  Widget _buildLine() {
    final fontSize = hafsQcf4FontSize(widget.page) * (widget.fontScale <= 0 ? 1 : widget.fontScale);
    final family = HafsQcf4Fonts.familyForPage(widget.page, dark: widget.dark, tajweed: widget.tajweed);
    final centered = widget.block.isCentered;
    final children = <Widget>[];
    Color? previousWash;
    for (var index = 0; index < widget.block.segments.length; index++) {
      final segment = widget.block.segments[index];
      final ref = MushafAyahRef(surahId: segment.surahNumber, ayahNumber: segment.ayahNumber);
      final wash = _wash(ref);
      final shown = wash.a > 0;
      if (index > 0 && !centered) {
        children.add(_lineGap(shown && previousWash == wash ? wash : null, fontSize * 2));
      }
      children.add(
        GestureDetector(
          onLongPress: () => widget.onAyahLongPress?.call(ref),
          child: _washed(
            shown ? wash : null,
            Text(
              segment.glyphs,
              textDirection: ui.TextDirection.rtl,
              style: hafsQcf4GlyphStyle(family: family, fontSize: fontSize, color: widget.colors.onSurface),
            ),
          ),
        ),
      );
      if (segment.isAyahEnd) {
        if (!centered) {
          children.add(_lineGap(shown ? wash : null, fontSize * 2));
        }
        children.add(
          GestureDetector(
            onLongPress: () => widget.onAyahLongPress?.call(ref),
            child: _washed(
              shown ? wash : null,
              SizedBox(
                height: fontSize * 2,
                child: Align(
                  alignment: Alignment.center,
                  child: Text(
                    '${HafsQcf4Fonts.arabicIndic(segment.ayahNumber)}\u202F\u202F',
                    textDirection: ui.TextDirection.rtl,
                    style: hafsQcf4AyahNumberStyle(
                      fontSize: fontSize,
                      dark: widget.dark,
                      color: widget.colors.onSurface,
                    ).copyWith(height: 1),
                  ),
                ),
              ),
            ),
          ),
        );
      }
      previousWash = shown ? wash : null;
    }

    return RepaintBoundary(
      child: SizedBox(
        width: widget.lineWidth,
        child: Row(
          textDirection: ui.TextDirection.rtl,
          mainAxisAlignment: centered ? MainAxisAlignment.center : MainAxisAlignment.start,
          children: children,
        ),
      ),
    );
  }

  /// Fills the justify gap when both sides belong to the same highlighted ayah.
  Widget _lineGap(Color? wash, double height) {
    if (wash == null) {
      return const Expanded(child: SizedBox.shrink());
    }
    return Expanded(
      child: SizedBox(
        height: height,
        child: ColoredBox(color: wash),
      ),
    );
  }

  /// Paints the wash across the full line box, including the space between lines.
  Widget _washed(Color? wash, Widget child) {
    if (wash == null) {
      return child;
    }
    return ColoredBox(color: wash, child: child);
  }

  Color _wash(MushafAyahRef ref) {
    final bookmark = widget.bookmarkedAyahs[ref];
    if (bookmark != null) {
      return Color.alphaBlend(
        hafsBookmarkInk(bookmark).withValues(alpha: widget.colors.brightness == Brightness.dark ? 0.40 : 0.24),
        widget.colors.surface,
      );
    }
    if (widget.playingAyah == ref || widget.highlightedAyah == ref) {
      return widget.colors.primary.withValues(alpha: 0.22);
    }
    if (widget.completedAyahs.contains(ref)) {
      return widget.colors.primary.withValues(alpha: 0.10);
    }
    return const Color(0x00000000);
  }
}

/// Portrait sizes tuned so each Madinah line fills the same width.
double hafsQcf4FontSize(int page) {
  if (page == 1 || page == 2) {
    return 25;
  }
  if (page == 145 || page == 585) {
    return 22.7;
  }
  if (page == 532 || page == 533 || page == 523 || page == 577) {
    return 22.5;
  }
  if (page == 116 || page == 156) {
    return 23.4;
  }
  if (page == 70) {
    return 23.5;
  }
  if (page == 51 || page == 501) {
    return 23.7;
  }
  const size23 = {
    56,
    57,
    368,
    269,
    372,
    376,
    409,
    435,
    444,
    448,
    527,
    535,
    565,
    566,
    569,
    574,
    578,
    581,
    584,
    587,
    589,
    590,
    592,
    593,
    50,
    568,
    34,
    575,
  };
  if (size23.contains(page)) {
    return 23;
  }
  const size228 = {576, 567, 371, 446, 447};
  if (size228.contains(page)) {
    return 22.8;
  }
  return 23.1;
}

/// Width of the longest line on [page], so shorter lines can meet both edges.
double measureHafsQcf4PageWidth(int page, double fontScale) {
  final scale = fontScale <= 0 ? 1.0 : fontScale;
  final fontSize = hafsQcf4FontSize(page) * scale;
  final family = HafsQcf4Fonts.familyForPage(page, dark: false, tajweed: false);
  final glyphStyle = hafsQcf4GlyphStyle(family: family, fontSize: fontSize, color: const Color(0xFF000000));
  final numberStyle = hafsQcf4AyahNumberStyle(fontSize: fontSize, dark: false, color: const Color(0xFF000000));
  var maxWidth = 0.0;
  for (final block in HafsQcf4Store.blocksForPage(page)) {
    if (block is! HafsQcf4AyahLineBlock) {
      continue;
    }
    var width = 0.0;
    for (final segment in block.segments) {
      width += _textWidth(segment.glyphs, glyphStyle);
      if (segment.isAyahEnd) {
        width += _textWidth('${HafsQcf4Fonts.arabicIndic(segment.ayahNumber)}\u202F\u202F', numberStyle);
      }
    }
    if (width > maxWidth) {
      maxWidth = width;
    }
  }
  if (maxWidth <= 0) {
    return 360;
  }
  return maxWidth + 1;
}

double _textWidth(String text, TextStyle style) {
  final painter = TextPainter(
    text: TextSpan(text: text, style: style),
    textDirection: ui.TextDirection.rtl,
    textScaler: TextScaler.noScaling,
  )..layout();
  final width = painter.width;
  painter.dispose();
  return width;
}

TextStyle hafsQcf4GlyphStyle({
  required String family,
  required double fontSize,
  required Color color,
  Color? background,
}) {
  return TextStyle(
    inherit: false,
    fontFamily: family,
    fontSize: fontSize,
    height: 2,
    letterSpacing: 0,
    wordSpacing: 0,
    color: color,
    backgroundColor: background,
    decoration: TextDecoration.none,
  );
}

TextStyle hafsQcf4AyahNumberStyle({
  required double fontSize,
  required bool dark,
  required Color color,
  Color? background,
}) {
  return TextStyle(
    inherit: false,
    fontFamily: HafsQcf4Fonts.familyForAyah(dark: dark),
    fontSize: fontSize + 5,
    height: 1.5,
    color: color,
    backgroundColor: background,
    decoration: TextDecoration.none,
  );
}

/// Decorative QCF2 basmala drawn with the shared chrome font.
class HafsQcfBasmalah extends StatelessWidget {
  const HafsQcfBasmalah({super.key, required this.colors});

  final ColorScheme colors;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Center(
        child: SizedBox(
          height: 28,
          child: FittedBox(
            fit: BoxFit.contain,
            child: Text(
              QpcPageFonts.basmalahGlyph,
              textAlign: TextAlign.center,
              textDirection: ui.TextDirection.rtl,
              style: TextStyle(
                inherit: false,
                fontFamily: QpcPageFonts.basmalahFamily,
                fontSize: 72,
                height: 1,
                color: colors.onSurface,
                decoration: TextDecoration.none,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

Color hafsBookmarkInk(MushafBookmarkColor color) {
  return switch (color) {
    MushafBookmarkColor.red => const Color(0xFFC45C5C),
    MushafBookmarkColor.yellow => const Color(0xFFC9A227),
    MushafBookmarkColor.green => const Color(0xFF6A8F4E),
    MushafBookmarkColor.blue => const Color(0xFF4E7FA3),
  };
}
