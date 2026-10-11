// ignore_for_file: unused_element

import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../fonts/qpc_page_fonts.dart';
import '../layout/warsh_mushaf_layout.dart';
import '../models/mushaf_ayah.dart';
import '../models/mushaf_ayah_ref.dart';
import '../models/mushaf_page.dart';
import '../models/mushaf_riwayah.dart';
import '../models/mushaf_riwayah_x.dart';
import '../mushaf_bootstrap.dart';
import '../repository/mushaf_repository.dart';
import '../store/mushaf_stores.dart';
import '../style/mushaf_style.dart';
import '../typography/mushaf_typography.dart';
import 'mushaf_ayah_marker.dart';
import 'mushaf_justified_text.dart';
import 'mushaf_surah_name_frame.dart';

/// Digital mushaf page from QPC V2 / Warsh layout JSON.
class MushafPageView extends StatefulWidget {
  const MushafPageView({
    super.key,
    required this.page,
    required this.ayahs,
    required this.riwayah,
    required this.fontScale,
    required this.surahNameAr,
    required this.surahNameEn,
    required this.juz,
    this.layoutPage,
    this.style,
    this.repository,
    this.onSurahHeaderLongPress,
    this.highlightedAyah,
    this.playingAyah,
    this.completedAyahs = const {},
    this.bookmarkedAyahs = const {},
    this.onAyahTap,
    this.onAyahLongPress,
  });

  final int page;
  final List<MushafAyah> ayahs;
  final MushafRiwayah riwayah;
  final double fontScale;
  final String surahNameAr;
  final String surahNameEn;
  final int juz;
  final MushafPage? layoutPage;
  final MushafStyle? style;
  final MushafRepository? repository;

  /// Long-press on the surah name frame / banner (surah id 1–114).
  final ValueChanged<int>? onSurahHeaderLongPress;

  /// Currently highlighted ayah (whole ayah across lines).
  final MushafAyahRef? highlightedAyah;

  /// Ayah currently being recited.
  final MushafAyahRef? playingAyah;

  /// Ayahs already recited in the active session.
  final Set<MushafAyahRef> completedAyahs;

  /// Persistent bookmark colors keyed by ayah.
  final Map<MushafAyahRef, MushafBookmarkColor> bookmarkedAyahs;

  /// Tap on any word/segment belonging to an ayah.
  final ValueChanged<MushafAyahRef>? onAyahTap;

  /// Long-press to select an ayah (highlight / actions).
  final ValueChanged<MushafAyahRef>? onAyahLongPress;

  @override
  State<MushafPageView> createState() => _MushafPageViewState();
}

class _MushafPageViewState extends State<MushafPageView> {
  bool _fontsReady = false;
  MushafPage? _resolvedLayout;
  int? _loadingPage;

  @override
  void initState() {
    super.initState();
    _resolvedLayout = widget.layoutPage;
    if (widget.riwayah == MushafRiwayah.hafs &&
        QpcPageFonts.isPageLoaded(widget.page)) {
      _fontsReady = true;
    }
    _loadFonts();
    _ensureLayout();
  }

  @override
  void didUpdateWidget(covariant MushafPageView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.layoutPage != null) {
      _resolvedLayout = widget.layoutPage;
    }
    if (oldWidget.riwayah != widget.riwayah) {
      _fontsReady = widget.riwayah == MushafRiwayah.hafs &&
          QpcPageFonts.isPageLoaded(widget.page);
      _resolvedLayout = widget.layoutPage;
      _loadFonts();
      _ensureLayout();
      return;
    }
    if (oldWidget.page != widget.page) {
      if (widget.layoutPage == null) {
        _resolvedLayout = null;
      }
      if (widget.riwayah == MushafRiwayah.hafs) {
        _fontsReady = QpcPageFonts.isPageLoaded(widget.page);
        _loadFonts();
      }
      _ensureLayout();
    } else if (widget.layoutPage == null && _resolvedLayout == null) {
      _ensureLayout();
    }
  }

  Future<void> _ensureLayout() async {
    if (_resolvedLayout != null || widget.layoutPage != null) {
      return;
    }
    if (!widget.riwayah.usesSplitMushafPages) {
      return;
    }
    final page = widget.page;
    if (_loadingPage == page) {
      return;
    }
    _loadingPage = page;
    final repo = widget.repository ?? Mushaf.repository;
    final result = await repo.getMushafPage(
      page,
      riwayah: widget.riwayah,
    );
    if (!mounted || widget.page != page) {
      return;
    }
    result.when(
      success: (mushaf) {
        setState(() {
          _resolvedLayout = mushaf;
          _loadingPage = null;
        });
      },
      failure: (_) {
        _loadingPage = null;
      },
    );
  }

  Future<void> _loadFonts() async {
    if (widget.riwayah == MushafRiwayah.hafs) {
      await QpcPageFonts.ensurePage(widget.page, neighbors: false);
    } else {
      await Mushaf.ensurePageFonts(
        widget.riwayah,
        widget.page,
        neighbors: false,
      );
    }
    if (!mounted) return;
    if (_fontsReady) return;
    setState(() => _fontsReady = true);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style = widget.style ??
        Theme.of(context).extension<MushafStyle>() ??
        MushafStyle.fromTheme(context);
    final colors = theme.colorScheme;
    final textTheme = theme.textTheme;
    final top = MediaQuery.paddingOf(context).top;
    final bottom = MediaQuery.paddingOf(context).bottom;

    final first = widget.ayahs.isNotEmpty ? widget.ayahs.first : null;
    final surahName = style.useArabicNames
        ? (first?.surahNameAr ?? widget.surahNameAr)
        : (first?.surahNameEn ?? widget.surahNameEn);
    final pageJuz = first?.juz ?? widget.juz;
    final juzLabel = style.juzLabel(pageJuz);

    final qpc = _resolvedLayout ?? widget.layoutPage;
    final useQpc = qpc != null && qpc.lines.isNotEmpty;
    // Warsh is always layout-JSON; never flash Unicode paragraph fallback
    // while the adjacent page is still loading during a swipe.
    final waitingWarshLayout = widget.riwayah.usesSplitMushafPages && !useQpc;
    final startsNewSurah = first != null && first.ayahNumber == 1;

    final pagePad = 8.0;
    final metaGap = 4.0;

    return RepaintBoundary(
      child: ColoredBox(
        color: theme.scaffoldBackgroundColor,
        child: MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.noScaling,
          ),
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              pagePad,
              top + 2,
              pagePad,
              bottom + 8,
            ),
            child: Column(
              children: [
                _PageMetaRow(
                  leading: surahName,
                  trailing: juzLabel,
                  colors: colors,
                  textTheme: textTheme,
                ),
                SizedBox(height: metaGap),
                Expanded(
                  child: waitingWarshLayout
                      ? const SizedBox.expand()
                      : !_fontsReady && useQpc
                          ? _MushafPageLoadingPlaceholder(
                              lineCount: qpc.lines.length,
                              colors: colors,
                            )
                          : LayoutBuilder(
                              builder: (context, constraints) {
                                if (useQpc) {
                                  return _MushafPageBody(
                                    maxWidth: constraints.maxWidth,
                                    maxHeight: constraints.maxHeight,
                                    page: widget.page,
                                    qpc: qpc,
                                    fontScale: widget.fontScale,
                                    colors: colors,
                                    riwayah: widget.riwayah,
                                    onSurahHeaderLongPress:
                                        widget.onSurahHeaderLongPress,
                                    highlightedAyah: widget.highlightedAyah,
                                    playingAyah: widget.playingAyah,
                                    completedAyahs: widget.completedAyahs,
                                    bookmarkedAyahs: widget.bookmarkedAyahs,
                                    onAyahTap: widget.onAyahTap,
                                    onAyahLongPress: widget.onAyahLongPress,
                                  );
                                }
                                return _UnicodeFallbackBody(
                                  maxWidth: constraints.maxWidth,
                                  maxHeight: constraints.maxHeight,
                                  ayahs: widget.ayahs,
                                  riwayah: widget.riwayah,
                                  fontScale: widget.fontScale,
                                  colors: colors,
                                  startsNewSurah: startsNewSurah,
                                  surahNameAr:
                                      first?.surahNameAr ?? widget.surahNameAr,
                                  showDecorativeBasmala: startsNewSurah &&
                                      first.surahId != 9 &&
                                      first.surahId != 1,
                                  onSurahHeaderLongPress:
                                      widget.onSurahHeaderLongPress,
                                );
                              },
                            ),
                ),
                SizedBox(height: metaGap),
                _PageNumberFrame(
                  page: widget.page,
                  colors: colors,
                  textTheme: textTheme,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Lightweight stand-in shown while a Hafs page's dedicated glyph font is
/// still loading (page entered the swipe faster than its warm-up finished).
///
/// Mirrors the eventual line rhythm instead of a bare centered spinner, so
/// the swap-in doesn't read as a jarring flash/reflow. Deliberately cheap —
/// no text measurement — so it never adds to the work competing with the
/// gesture for frame budget.
class _MushafPageLoadingPlaceholder extends StatelessWidget {
  const _MushafPageLoadingPlaceholder({
    required this.lineCount,
    required this.colors,
  });

  final int lineCount;
  final ColorScheme colors;

  @override
  Widget build(BuildContext context) {
    final barColor = colors.onSurface.withValues(alpha: 0.06);
    final lines = lineCount.clamp(6, 16);

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < lines; i++)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: FractionallySizedBox(
              widthFactor: i.isOdd ? 0.62 : 0.86,
              child: Container(
                height: 14,
                decoration: BoxDecoration(
                  color: barColor,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _MushafPageBody extends StatelessWidget {
  const _MushafPageBody({
    required this.maxWidth,
    required this.maxHeight,
    required this.page,
    required this.qpc,
    required this.fontScale,
    required this.colors,
    required this.riwayah,
    this.onSurahHeaderLongPress,
    this.highlightedAyah,
    this.playingAyah,
    this.completedAyahs = const {},
    this.bookmarkedAyahs = const {},
    this.onAyahTap,
    this.onAyahLongPress,
  });

  final double maxWidth;
  final double maxHeight;
  final int page;
  final MushafPage qpc;
  final double fontScale;
  final ColorScheme colors;
  final MushafRiwayah riwayah;
  final ValueChanged<int>? onSurahHeaderLongPress;
  final MushafAyahRef? highlightedAyah;
  final MushafAyahRef? playingAyah;
  final Set<MushafAyahRef> completedAyahs;
  final Map<MushafAyahRef, MushafBookmarkColor> bookmarkedAyahs;
  final ValueChanged<MushafAyahRef>? onAyahTap;
  final ValueChanged<MushafAyahRef>? onAyahLongPress;

  /// Soft continuous gold wash — readable over mushaf ink in both themes.
  static Color ayahHighlightColor(ColorScheme colors) {
    final isDark = colors.brightness == Brightness.dark;
    return Color.alphaBlend(
      colors.primary.withValues(alpha: isDark ? 0.34 : 0.25),
      colors.surface,
    );
  }

  /// Stronger wash while an ayah is actively recited.
  static Color ayahPlayingColor(ColorScheme colors) {
    final isDark = colors.brightness == Brightness.dark;
    return Color.alphaBlend(
      colors.primary.withValues(alpha: isDark ? 0.48 : 0.38),
      colors.surface,
    );
  }

  /// Soft wash for ayahs already completed in the session.
  static Color ayahCompletedColor(ColorScheme colors) {
    final isDark = colors.brightness == Brightness.dark;
    return Color.alphaBlend(
      colors.primary.withValues(alpha: isDark ? 0.20 : 0.14),
      colors.surface,
    );
  }

  static Color bookmarkInk(MushafBookmarkColor color) {
    return switch (color) {
      MushafBookmarkColor.red => const Color(0xFFC45C5C),
      MushafBookmarkColor.yellow => const Color(0xFFC9A227),
      MushafBookmarkColor.green => const Color(0xFF6A8F4E),
      MushafBookmarkColor.blue => const Color(0xFF4E7FA3),
    };
  }

  static Color bookmarkWash(ColorScheme colors, MushafBookmarkColor color) {
    final isDark = colors.brightness == Brightness.dark;
    return Color.alphaBlend(
      bookmarkInk(color).withValues(alpha: isDark ? 0.40 : 0.24),
      colors.surface,
    );
  }

  Color? fillForAyah(MushafAyahRef? ref) {
    if (ref == null) {
      return null;
    }
    final bookmark = bookmarkedAyahs[ref];
    if (bookmark != null) {
      return bookmarkWash(colors, bookmark);
    }
    if (playingAyah == ref) {
      return ayahPlayingColor(colors);
    }
    if (completedAyahs.contains(ref)) {
      return ayahCompletedColor(colors);
    }
    if (highlightedAyah == ref) {
      return ayahHighlightColor(colors);
    }
    return null;
  }

  // static Color ayahHighlightBorder(ColorScheme colors) {
  //   return colors.primary.withValues(
  //     alpha: colors.brightness == Brightness.dark ? 0.35 : 0.22,
  //   );
  // }

  bool get _isSparsePage => page <= 2;

  /// Zero-width split between Warsh words. Kashida fills the line, so a
  /// visible word space would reopen the gaps removed to match Hafs.
  static const _warshWordSeparator = '\u200B';

  bool get _injectAyahEndMarks => riwayah == MushafRiwayah.warsh;

  String _layoutWordText(String raw) {
    if (riwayah == MushafRiwayah.warsh) {
      return MushafTypography.normalizeWarshMushafText(raw);
    }
    return raw;
  }

  double _ayahLetterSpacing(double fontSize) {
    if (riwayah == MushafRiwayah.warsh) {
      return fontSize * WarshMushafLayout.letterSpacingRatio;
    }
    return 0;
  }

  /// Visual ayah rows as the renderer joins them (words + optional end marks).
  List<String> _warshVisualRowTexts() {
    const wordSeparator = _warshWordSeparator;
    final byVisualRow = <int, List<String>>{};
    var legacyKey = -1;

    for (final block in qpc.lines) {
      if (block.type != MushafLineType.ayah) {
        continue;
      }
      if (!block.isAyahBlock) {
        byVisualRow[legacyKey--] = [
          for (final word in block.words) _layoutWordText(word.text),
        ];
        continue;
      }
      for (final sub in block.ayahLines) {
        final tokens = byVisualRow.putIfAbsent(sub.visualRow, () => <String>[]);
        tokens.addAll(sub.words.map((w) => _layoutWordText(w.text)));
        final endsAyah = _injectAyahEndMarks &&
            block.complete &&
            block.lineCount != null &&
            sub.lineIndex == block.lineCount;
        if (endsAyah) {
          tokens.add(MushafAyahMarker.warshEndMark(block.ayah ?? 0));
        }
      }
    }

    final keys = byVisualRow.keys.toList()..sort();
    return [
      for (final key in keys)
        _GlyphLine.glueArticleParts(byVisualRow[key]!).join(wordSeparator),
    ];
  }

  double _measureWarshTextWidth(String text, TextStyle style) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: ui.TextDirection.rtl,
      maxLines: 1,
      textScaler: TextScaler.noScaling,
    )..layout();
    final width = painter.width;
    painter.dispose();
    return width;
  }

  /// Cache for [_warshUniformFontSize] — the full-page measurement pass
  /// (one [TextPainter] layout per visual row) is expensive and was
  /// previously recomputed on *every* build, including rebuilds triggered by
  /// unrelated global state (highlight/bookmark/playback) on far-away pages
  /// kept alive in the reader's [ListView]. Critical for smooth swipes.
  static const int _uniformFontSizeCacheLimit = 256;
  static final Map<String, double> _uniformFontSizeCache = {};

  /// One font size for the whole page: shrink once if any line would overflow.
  ///
  /// Per-line [FittedBox.scaleDown] alone makes short rows look larger than
  /// dense ones. Measuring first keeps glyph size uniform and still prevents
  /// clipped words.
  double _warshUniformFontSize({
    required double baseFontSize,
    required double lineWidth,
    required String fontFamily,
    List<String>? fontFamilyFallback,
  }) {
    if (lineWidth <= 0 || baseFontSize <= 0) {
      return baseFontSize;
    }

    // Page content + geometry fully determine the result — safe to memoize
    // across rebuilds (page JSON is immutable/cached in the repository).
    final cacheKey =
        'tight|$page|${lineWidth.toStringAsFixed(1)}|$fontFamily|${baseFontSize.toStringAsFixed(2)}';
    final cached = _uniformFontSizeCache[cacheKey];
    if (cached != null) {
      return cached;
    }

    final lines = _warshVisualRowTexts();
    if (lines.isEmpty) {
      return baseFontSize;
    }

    TextStyle styleAt(double size) => TextStyle(
          inherit: false,
          fontFamily: fontFamily,
          fontFamilyFallback: fontFamilyFallback,
          fontSize: size,
          height: 1,
          letterSpacing: size * WarshMushafLayout.letterSpacingRatio,
          wordSpacing: 0,
          decoration: TextDecoration.none,
        );

    var maxWidth = 0.0;
    final probe = styleAt(baseFontSize);
    for (final line in lines) {
      if (line.isEmpty) continue;
      final w = _measureWarshTextWidth(line, probe);
      if (w > maxWidth) maxWidth = w;
    }

    // Tiny margin so Skia rounding / ink does not clip after layout.
    final result = (maxWidth <= lineWidth || maxWidth <= 0)
        ? baseFontSize
        : baseFontSize * (lineWidth / maxWidth) * 0.995;

    if (_uniformFontSizeCache.length >= _uniformFontSizeCacheLimit) {
      _uniformFontSizeCache.clear();
    }
    _uniformFontSizeCache[cacheKey] = result;
    return result;
  }

  @override
  Widget build(BuildContext context) {
    if (riwayah == MushafRiwayah.hafs) {
      return _buildHafsQcfPage();
    }

    final ayahFontFamily = riwayah.fontFamily;
    final isFirstPages = page == 1 || page == 2;
    final isUnicodeMushaf = riwayah.usesSplitMushafPages;
    final fontSize = (isFirstPages ? 28.0 : 24.0) * fontScale;
    final height = isFirstPages ? 1.85 : 1.72;

    if (isUnicodeMushaf && !isFirstPages) {
      return _buildWarshFittedPage(ayahFontFamily);
    }

    // Pages 1–2 are sparse and fully centered.
    final edgeSafeProbe = (31.5 * fontScale * 0.55).clamp(12.0, 20.0);
    final lineWidth = isUnicodeMushaf ? maxWidth - edgeSafeProbe * 2 : maxWidth;
    final warshFontSize = isUnicodeMushaf
        ? _warshUniformFontSize(
            baseFontSize: 31.5 * fontScale,
            lineWidth: lineWidth,
            fontFamily: ayahFontFamily,
            fontFamilyFallback: riwayah.fontFamilyFallback,
          )
        : 31.5 * fontScale;
    final warshHeight = 1.86;

    final ayahStyle = TextStyle(
      inherit: false,
      fontFamily: ayahFontFamily,
      fontFamilyFallback: isUnicodeMushaf ? riwayah.fontFamilyFallback : null,
      fontSize: isUnicodeMushaf ? warshFontSize : fontSize,
      height: isUnicodeMushaf ? warshHeight : height,
      color: colors.onSurface,
      fontWeight: FontWeight.normal,
      letterSpacing: isUnicodeMushaf ? _ayahLetterSpacing(warshFontSize) : 0,
      wordSpacing: 0,
      decoration: TextDecoration.none,
    );

    final children = isUnicodeMushaf
        ? _buildWarshChildren(
            ayahStyle,
            lineWidth: lineWidth,
            chromeScale: 1,
          )
        : _buildFlatChildren(ayahStyle);

    final column = SizedBox(
      width: isUnicodeMushaf ? lineWidth : maxWidth,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      ),
    );

    return SizedBox(
      width: maxWidth,
      height: maxHeight,
      child: ClipRect(
        child: FittedBox(
          fit: _isSparsePage ? BoxFit.scaleDown : BoxFit.contain,
          alignment: Alignment.center,
          child: SizedBox(
            width: maxWidth,
            child: Center(child: column),
          ),
        ),
      ),
    );
  }

  /// QPC V2: each Madinah row stays one line. Scale the page as a unit so
  /// glyphs never wrap mid-verse.
  Widget _buildHafsQcfPage() {
    final isFirstPages = page <= 2;
    final fontSize = (isFirstPages ? 28.0 : 24.0) * fontScale;
    final height = isFirstPages ? 1.85 : 1.72;
    final ayahStyle = TextStyle(
      inherit: false,
      fontFamily: QpcPageFonts.familyForPage(page),
      fontSize: fontSize,
      height: height,
      color: colors.onSurface,
      fontWeight: FontWeight.normal,
      letterSpacing: 0,
      wordSpacing: 0,
      decoration: TextDecoration.none,
    );

    final column = SizedBox(
      width: maxWidth,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: _buildFlatChildren(ayahStyle),
      ),
    );

    return SizedBox(
      width: maxWidth,
      height: maxHeight,
      child: ClipRect(
        child: FittedBox(
          fit: isFirstPages ? BoxFit.scaleDown : BoxFit.contain,
          alignment: Alignment.center,
          child: SizedBox(
            width: maxWidth,
            child: Center(child: column),
          ),
        ),
      ),
    );
  }

  /// Warsh pages 3+: fixed column width + body size on every page.
  ///
  /// Chrome-heavy pages (e.g. 622) used to go through [FittedBox.contain],
  /// which shrank the whole page — including the text width — and left huge
  /// side margins. Vertical overflow is absorbed by compressing chrome and
  /// leading only, so page 50 and page 51 keep the same ayah size.
  Widget _buildWarshFittedPage(String ayahFontFamily) {
    // Full content width. The old 444.3/474 inset left a margin inside the
    // page; Hafs fills the same box, and Warsh should too.
    final lineWidth = maxWidth;
    final warshFontSize = _warshUniformFontSize(
      baseFontSize: WarshMushafLayout.fontSizeForFrame(maxWidth),
      lineWidth: lineWidth,
      fontFamily: ayahFontFamily,
      fontFamilyFallback: riwayah.fontFamilyFallback,
    );

    var ayahRows = <int>{};
    var surahHeaders = 0;
    var basmalas = 0;
    var legacyAyahLines = 0;
    for (final line in qpc.lines) {
      switch (line.type) {
        case MushafLineType.surahName:
          surahHeaders++;
        case MushafLineType.basmallah:
          basmalas++;
        case MushafLineType.ayah:
          if (line.isAyahBlock) {
            for (final sub in line.ayahLines) {
              ayahRows.add(sub.visualRow);
            }
          } else {
            legacyAyahLines++;
          }
      }
    }
    final ayahLines =
        (ayahRows.isEmpty ? legacyAyahLines : ayahRows.length).clamp(1, 999);

    final fit = WarshMushafLayout.verticalFit(
      maxHeight: maxHeight,
      lineWidth: lineWidth,
      fontSize: warshFontSize,
      ayahLines: ayahLines,
      surahHeaders: surahHeaders,
      basmalas: basmalas,
    );

    final ayahStyle = TextStyle(
      inherit: false,
      fontFamily: ayahFontFamily,
      fontFamilyFallback: riwayah.fontFamilyFallback,
      fontSize: warshFontSize,
      height: fit.lineHeight,
      color: colors.onSurface,
      fontWeight: FontWeight.normal,
      letterSpacing: _ayahLetterSpacing(warshFontSize),
      wordSpacing: 0,
      decoration: TextDecoration.none,
    );

    final children = _buildWarshChildren(
      ayahStyle,
      lineWidth: lineWidth,
      chromeScale: fit.chromeScale,
    );

    return SizedBox(
      width: maxWidth,
      height: maxHeight,
      child: ClipRect(
        // Sit under the surah/juz row. Leftover height stays below the text
        // so the top gap does not split the page in half.
        child: Align(
          alignment: Alignment.topCenter,
          child: SizedBox(
            width: lineWidth,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: children,
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildFlatChildren(TextStyle ayahStyle) {
    final children = <Widget>[];
    for (final line in qpc.lines) {
      switch (line.type) {
        case MushafLineType.surahName:
          children.add(
            MushafSurahNameFrame(
              surah: line.surah ?? 0,
              nameAr: line.nameAr ?? '${line.surah}',
              riwayah: riwayah,
              colors: colors,
              width: maxWidth,
              onLongPress: onSurahHeaderLongPress,
            ),
          );
        case MushafLineType.basmallah:
          children.add(
            _BasmalahLine(
              width: maxWidth,
              colors: colors,
            ),
          );
        case MushafLineType.ayah:
          children.add(
            _GlyphLine(
              words: line.words,
              style: ayahStyle,
              centered: line.centered || _isSparsePage,
              width: maxWidth,
              highlightedAyah: highlightedAyah,
              playingAyah: playingAyah,
              completedAyahs: completedAyahs,
              bookmarkedAyahs: bookmarkedAyahs,
              onAyahTap: onAyahTap,
              onAyahLongPress: onAyahLongPress,
              highlightColor: ayahHighlightColor(colors),
              playingColor: ayahPlayingColor(colors),
              completedColor: ayahCompletedColor(colors),
            ),
          );
      }
    }
    return children;
  }

  List<Widget> _buildWarshChildren(
    TextStyle ayahStyle, {
    required double lineWidth,
    required double chromeScale,
  }) {
    // Six-per-em space — closer to KFQC SVG inter-word gaps than U+0020.
    const wordSeparator = _warshWordSeparator;
    final children = <Widget>[];
    var index = 0;

    while (index < qpc.lines.length) {
      final line = qpc.lines[index];
      switch (line.type) {
        case MushafLineType.surahName:
          children.add(
            MushafSurahNameFrame(
              surah: line.surah ?? 0,
              nameAr: line.nameAr ?? '${line.surah}',
              riwayah: riwayah,
              colors: colors,
              width: lineWidth,
              chromeScale: chromeScale,
              onLongPress: onSurahHeaderLongPress,
            ),
          );
          index++;
        case MushafLineType.basmallah:
          children.add(
            _BasmalahLine(
              width: lineWidth,
              colors: colors,
              chromeScale: chromeScale,
            ),
          );
          index++;
        case MushafLineType.ayah:
          final ayahBlocks = <MushafLine>[];
          while (index < qpc.lines.length &&
              qpc.lines[index].type == MushafLineType.ayah) {
            ayahBlocks.add(qpc.lines[index]);
            index++;
          }
          children.addAll(
            _buildWarshAyahSection(
              ayahBlocks: ayahBlocks,
              ayahStyle: ayahStyle,
              wordSeparator: wordSeparator,
              lineWidth: lineWidth,
            ),
          );
      }
    }

    return children;
  }

  /// Sparse pages (1–2) always centered. Elsewhere trust layout JSON:
  /// short-surah pages (e.g. 600) mark lines centered on purpose — do not
  /// stretch them to full width (that creates unnatural word gaps).
  bool _warshLineCentered({required bool flaggedCentered}) {
    if (_isSparsePage) return true;
    return flaggedCentered;
  }

  List<Widget> _buildWarshAyahSection({
    required List<MushafLine> ayahBlocks,
    required TextStyle ayahStyle,
    required String wordSeparator,
    required double lineWidth,
  }) {
    final byVisualRow = <int, List<_WarshAyahLinePart>>{};
    for (final block in ayahBlocks) {
      if (block.isAyahBlock) {
        for (final subLine in block.ayahLines) {
          byVisualRow.putIfAbsent(subLine.visualRow, () => []).add(
                _WarshAyahLinePart(
                  surah: block.surah ?? 0,
                  ayah: block.ayah ?? 0,
                  lineCount: block.lineCount,
                  ayahComplete: block.complete,
                  subLine: subLine,
                ),
              );
        }
        continue;
      }

      byVisualRow.putIfAbsent(-byVisualRow.length - 1, () => []).add(
            _WarshAyahLinePart(
              surah: block.surah ?? 0,
              ayah: block.ayah ?? 0,
              legacyLine: block,
            ),
          );
    }

    final widgets = <Widget>[];
    for (final visualRow in byVisualRow.keys.toList()..sort()) {
      final parts = _orderWarshRowParts(ayahBlocks, byVisualRow[visualRow]!);
      if (parts.length == 1) {
        final part = parts.first;
        final partRef = part.surah >= 1 && part.ayah >= 1
            ? MushafAyahRef(surahId: part.surah, ayahNumber: part.ayah)
            : null;
        final fill = fillForAyah(partRef);
        widgets.add(
          _WarshAyahLineShell(
            surah: part.surah,
            ayah: part.ayah,
            lineKey: part.lineKey,
            highlighted: fill != null,
            highlightColor: fill,
            onTap: onAyahTap == null || part.surah < 1 || part.ayah < 1
                ? null
                : () => onAyahTap!(
                      MushafAyahRef(
                        surahId: part.surah,
                        ayahNumber: part.ayah,
                      ),
                    ),
            onLongPress:
                onAyahLongPress == null || part.surah < 1 || part.ayah < 1
                    ? null
                    : () => onAyahLongPress!(
                          MushafAyahRef(
                            surahId: part.surah,
                            ayahNumber: part.ayah,
                          ),
                        ),
            child: _glyphLineForWarshPart(
              part: part,
              ayahStyle: ayahStyle,
              width: lineWidth,
              wordSeparator: wordSeparator,
            ),
          ),
        );
        continue;
      }

      widgets.add(
        _buildMergedWarshVisualRow(
          parts: parts,
          ayahStyle: ayahStyle,
          width: lineWidth,
          wordSeparator: wordSeparator,
        ),
      );
    }

    return widgets;
  }

  Widget _buildMergedWarshVisualRow({
    required List<_WarshAyahLinePart> parts,
    required TextStyle ayahStyle,
    required double width,
    required String wordSeparator,
  }) {
    final tokens = <MushafWordToken>[];
    for (final part in parts) {
      final ref = part.surah >= 1 && part.ayah >= 1
          ? MushafAyahRef(surahId: part.surah, ayahNumber: part.ayah)
          : null;
      for (final word in part.wordTokens) {
        tokens.add(
          MushafWordToken(
            text: _layoutWordText(word.text),
            surah: ref?.surahId ?? word.surah,
            ayah: ref?.ayahNumber ?? word.ayah,
          ),
        );
      }
      if (_injectAyahEndMarks && part.isAyahEnd) {
        tokens.add(
          MushafWordToken(
            text: MushafAyahMarker.warshEndMark(part.ayah),
            surah: ref?.surahId,
            ayah: ref?.ayahNumber,
          ),
        );
      }
    }

    final flaggedCentered = parts.every((part) => part.isCentered);
    final centered = _warshLineCentered(flaggedCentered: flaggedCentered);

    return _GlyphLine(
      words: tokens,
      style: ayahStyle,
      centered: centered,
      width: width,
      wordSeparator: wordSeparator,
      softJustify: true,
      highlightedAyah: highlightedAyah,
      playingAyah: playingAyah,
      completedAyahs: completedAyahs,
      bookmarkedAyahs: bookmarkedAyahs,
      onAyahTap: onAyahTap,
      onAyahLongPress: onAyahLongPress,
      highlightColor: ayahHighlightColor(colors),
      playingColor: ayahPlayingColor(colors),
      completedColor: ayahCompletedColor(colors),
    );
  }

  List<_WarshAyahLinePart> _orderWarshRowParts(
    List<MushafLine> ayahBlocks,
    List<_WarshAyahLinePart> parts,
  ) {
    if (parts.length <= 1) {
      return parts;
    }

    final visualRow = parts.first.subLine?.visualRow;
    if (visualRow == null) {
      return parts;
    }

    final ordered = <_WarshAyahLinePart>[];
    for (final block in ayahBlocks) {
      for (final subLine in block.ayahLines) {
        if (subLine.visualRow != visualRow) {
          continue;
        }
        ordered.add(
          _WarshAyahLinePart(
            surah: block.surah ?? 0,
            ayah: block.ayah ?? 0,
            lineCount: block.lineCount,
            ayahComplete: block.complete,
            subLine: subLine,
          ),
        );
      }
    }
    return ordered.isEmpty ? parts : ordered;
  }

  Widget _glyphLineForWarshPart({
    required _WarshAyahLinePart part,
    required TextStyle ayahStyle,
    required double width,
    required String wordSeparator,
  }) {
    final tokens = [
      for (final word in part.wordTokens)
        MushafWordToken(
          text: _layoutWordText(word.text),
          surah: word.surah ?? (part.surah >= 1 ? part.surah : null),
          ayah: word.ayah ?? (part.ayah >= 1 ? part.ayah : null),
        ),
    ];

    if (part.legacyLine != null) {
      final legacy = part.legacyLine!;
      return _GlyphLine(
        words: tokens,
        style: ayahStyle,
        centered: _warshLineCentered(flaggedCentered: legacy.centered),
        width: width,
        wordSeparator: wordSeparator,
        softJustify: true,
      );
    }

    final subLine = part.subLine!;
    return _GlyphLine(
      words: tokens,
      style: ayahStyle,
      centered: _warshLineCentered(flaggedCentered: subLine.centered),
      width: width,
      wordSeparator: wordSeparator,
      ayahEndMark: _injectAyahEndMarks && part.isAyahEnd
          ? MushafAyahMarker.warshEndMark(part.ayah)
          : null,
      softJustify: true,
    );
  }
}

class _WarshAyahLinePart {
  const _WarshAyahLinePart({
    required this.surah,
    required this.ayah,
    this.lineCount,
    this.ayahComplete = true,
    this.subLine,
    this.legacyLine,
  });

  final int surah;
  final int ayah;
  final int? lineCount;
  final bool ayahComplete;
  final MushafAyahSubLine? subLine;
  final MushafLine? legacyLine;

  bool get isAyahEnd =>
      ayahComplete &&
      subLine != null &&
      lineCount != null &&
      subLine!.lineIndex == lineCount;

  bool get isCentered => subLine?.centered ?? legacyLine?.centered ?? false;

  List<MushafWordToken> get wordTokens =>
      subLine?.words ?? legacyLine?.words ?? const [];

  List<String> get words => [for (final w in wordTokens) w.text];

  int get wordCount => wordTokens.length;

  String get lineKey {
    if (subLine != null) {
      return '${subLine!.visualRow}-${subLine!.lineIndex}';
    }
    return 'legacy';
  }
}

/// Groups one ayah sub-line for whole-ayah selection / highlight.
class _WarshAyahLineShell extends StatelessWidget {
  const _WarshAyahLineShell({
    required this.surah,
    required this.ayah,
    required this.lineKey,
    required this.child,
    this.highlighted = false,
    this.highlightColor,
    this.onTap,
    this.onLongPress,
  });

  final int surah;
  final int ayah;
  final String lineKey;
  final Widget child;
  final bool highlighted;
  final Color? highlightColor;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    Widget content = KeyedSubtree(
      key: ValueKey('warsh-ayah-$surah-$ayah-$lineKey'),
      child: child,
    );

    if (highlighted && highlightColor != null) {
      content = DecoratedBox(
        decoration: BoxDecoration(color: highlightColor),
        child: content,
      );
    }

    if (onTap == null && onLongPress == null) {
      return content;
    }

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: onTap,
      onLongPress: onLongPress,
      child: content,
    );
  }
}

/// Elongated decorative basmala from official KFGQPC [QCF2BSML] (`U+FC21`).
class _BasmalahLine extends StatelessWidget {
  const _BasmalahLine({
    required this.width,
    required this.colors,
    this.chromeScale = 1,
  });

  final double width;
  final ColorScheme colors;

  /// Vertical compression for chrome-heavy Warsh pages (width stays fixed).
  final double chromeScale;

  @override
  Widget build(BuildContext context) {
    final scale = chromeScale.clamp(0.38, 1.0);
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4 * scale),
      child: Center(
        child: SizedBox(
          // Natural width, capped — do not stretch/kashida the basmala glyph.
          width: width * 0.72,
          height: 28 * scale,
          child: FittedBox(
            fit: BoxFit.contain,
            child: Text(
              QpcPageFonts.basmalahGlyph,
              textAlign: TextAlign.center,
              textDirection: ui.TextDirection.rtl,
              softWrap: false,
              maxLines: 1,
              style: TextStyle(
                inherit: false,
                fontFamily: QpcPageFonts.basmalahFamily,
                fontSize: 72,
                height: 1,
                color: colors.onSurface,
                fontWeight: FontWeight.normal,
                decoration: TextDecoration.none,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// One mushaf line of QPC glyphs (Hafs) or Unicode words (Warsh).
///
/// Centered lines stay natural width (scaled down if needed).
/// Warsh full lines fill [width] with tatweel (كشيدة) — not wide word gaps.
/// Hafs glyph lines distribute extra space between glyphs as before.
class _GlyphLine extends StatelessWidget {
  const _GlyphLine({
    required this.words,
    required this.style,
    required this.centered,
    required this.width,
    this.wordSeparator = '',
    this.ayahEndMark,
    this.softJustify = false,
    this.highlightedAyah,
    this.playingAyah,
    this.completedAyahs = const {},
    this.bookmarkedAyahs = const {},
    this.onAyahTap,
    this.onAyahLongPress,
    this.highlightColor,
    this.playingColor,
    this.completedColor,
  });

  final List<MushafWordToken> words;
  final TextStyle style;
  final bool centered;
  final double width;
  final String wordSeparator;
  final String? ayahEndMark;
  final bool softJustify;
  final MushafAyahRef? highlightedAyah;
  final MushafAyahRef? playingAyah;
  final Set<MushafAyahRef> completedAyahs;
  final Map<MushafAyahRef, MushafBookmarkColor> bookmarkedAyahs;
  final ValueChanged<MushafAyahRef>? onAyahTap;
  final ValueChanged<MushafAyahRef>? onAyahLongPress;
  final Color? highlightColor;
  final Color? playingColor;
  final Color? completedColor;

  List<String> get _texts => [for (final w in words) w.text];

  double _measureWord(String word) {
    final key =
        '${style.fontFamily}|${style.fontSize?.toStringAsFixed(2)}|$word';
    final cached = _glyphWidthCache[key];
    if (cached != null) {
      return cached;
    }
    final painter = TextPainter(
      text: TextSpan(text: word, style: style),
      textDirection: ui.TextDirection.rtl,
      maxLines: 1,
      textScaler: TextScaler.noScaling,
    )..layout();
    final w = painter.width;
    painter.dispose();
    if (_glyphWidthCache.length >= _glyphWidthCacheLimit) {
      _glyphWidthCache.clear();
    }
    _glyphWidthCache[key] = w;
    return w;
  }

  static const int _glyphWidthCacheLimit = 2048;
  static final Map<String, double> _glyphWidthCache = {};

  double _naturalWidth({
    required double baseGap,
  }) {
    var wordsWidth = 0.0;
    for (final word in _texts) {
      wordsWidth += _measureWord(word);
    }
    if (ayahEndMark != null) {
      wordsWidth += _measureWord(ayahEndMark!);
    }
    final segmentCount = words.length + (ayahEndMark != null ? 1 : 0);
    final gaps = segmentCount - 1;
    if (gaps > 0 && baseGap > 0) {
      wordsWidth += baseGap * gaps;
    }
    return wordsWidth;
  }

  Color? _bandColor(ColorScheme colors, MushafAyahRef? ref) {
    if (ref == null) {
      return null;
    }
    final bookmark = bookmarkedAyahs[ref];
    if (bookmark != null) {
      return _MushafPageBody.bookmarkWash(colors, bookmark);
    }
    if (playingAyah != null && playingAyah == ref) {
      return playingColor ?? _MushafPageBody.ayahPlayingColor(colors);
    }
    if (completedAyahs.contains(ref)) {
      return completedColor ?? _MushafPageBody.ayahCompletedColor(colors);
    }
    if (highlightedAyah != null && highlightedAyah == ref) {
      return highlightColor ?? _MushafPageBody.ayahHighlightColor(colors);
    }
    return null;
  }

  Widget _tapTarget({
    required MushafAyahRef? ref,
    required Widget child,
  }) {
    if (ref == null || (onAyahTap == null && onAyahLongPress == null)) {
      return child;
    }
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: onAyahTap == null ? null : () => onAyahTap!(ref),
      onLongPress: onAyahLongPress == null ? null : () => onAyahLongPress!(ref),
      child: child,
    );
  }

  Widget _highlightBand({required Color color, required Widget child}) {
    return DecoratedBox(
      decoration: BoxDecoration(color: color),
      child: child,
    );
  }

  /// Builds an RTL row where highlighted tokens form unbroken bands
  /// (gaps between words stay inside the band).
  Widget _continuousHighlightRow(
    BuildContext context, {
    required List<({MushafAyahRef? ref, Widget child})> segments,
    required double gapWidth,
  }) {
    final colors = Theme.of(context).colorScheme;
    final children = <Widget>[];
    var i = 0;
    while (i < segments.length) {
      final start = i;
      final bandColor = _bandColor(colors, segments[i].ref);
      final bandRef = segments[i].ref;
      i++;
      while (i < segments.length) {
        final nextColor = _bandColor(colors, segments[i].ref);
        if (nextColor != bandColor) {
          break;
        }
        if (bandColor != null && segments[i].ref != bandRef) {
          break;
        }
        i++;
      }

      final run = segments.sublist(start, i);
      final runChildren = <Widget>[];
      for (var j = 0; j < run.length; j++) {
        if (j > 0 && gapWidth > 0) {
          runChildren.add(SizedBox(width: gapWidth));
        }
        Widget token = _tapTarget(ref: run[j].ref, child: run[j].child);
        runChildren.add(token);
      }

      Widget group = Row(
        textDirection: ui.TextDirection.rtl,
        mainAxisSize: MainAxisSize.min,
        children: runChildren,
      );
      if (bandColor != null) {
        group = _highlightBand(color: bandColor, child: group);
      }

      if (children.isNotEmpty && gapWidth > 0) {
        children.add(SizedBox(width: gapWidth));
      }
      children.add(group);
    }

    return Row(
      textDirection: ui.TextDirection.rtl,
      mainAxisSize: MainAxisSize.min,
      children: children,
    );
  }

  Widget _centeredLine(BuildContext context, String text) {
    // Warsh: paint each token as its own [Text]. A single long RTL run that
    // crosses an ayah-end digit cluster has dropped the trailing word on
    // device (page 409 row 5: كَأَحَدٖ present in the string, absent on screen).
    if (softJustify) {
      return _warshTokenRowLine(context, text, fillKashida: false);
    }

    return _hafsLine(context, joined: text, gapWidth: 0);
  }

  Widget _kashidaFilledLine(BuildContext context, String text) {
    return _warshTokenRowLine(context, text, fillKashida: true);
  }

  /// Warsh line as a [Row] of per-token [Text]s (optional kashida on the joined
  /// string first). Keeps every word in its own paragraph so trailing tokens
  /// cannot vanish inside one shaped RTL run.
  Widget _warshTokenRowLine(
    BuildContext context,
    String text, {
    required bool fillKashida,
  }) {
    final sep = wordSeparator.isEmpty ? '\u2006' : wordSeparator;
    // Zero-width splits are not painted. If the font still advances them,
    // kashida covers that advance so the visible line reaches [width].
    final tight = sep == '\u200B';
    final sepAdvance = tight ? _measureWord(sep) : 0.0;
    final gapCount = tight ? sep.allMatches(text).length : 0;
    final fillWidth = tight ? width + sepAdvance * gapCount : width;
    final filled = fillKashida
        ? MushafKashidaJustifier.fillToWidth(
            text: text,
            style: style,
            maxWidth: fillWidth,
            minFillRatio: 0.50,
            maxKashida: 36,
          )
        : text;

    final segments =
        filled.split(sep).where((s) => s.isNotEmpty).toList(growable: false);
    final sepWidth =
        tight || wordSeparator.isEmpty ? 0.0 : _measureWord(wordSeparator);

    // Glued «ال» tokens match the joined string, so highlight refs stay aligned.
    final tokenWords = softJustify
        ? glueArticleTokens([
            for (final word in words)
              MushafWordToken(
                text: MushafTypography.normalizeWarshMushafText(word.text),
                surah: word.surah,
                ayah: word.ayah,
              ),
          ])
        : words;
    final refs = <MushafAyahRef?>[
      for (final w in tokenWords) w.ayahRef,
      if (ayahEndMark != null) tokenWords.lastOrNull?.ayahRef,
    ];

    final rowSegments = <({MushafAyahRef? ref, Widget child})>[
      for (var i = 0; i < segments.length; i++)
        (
          ref: i < refs.length ? refs[i] : refs.lastOrNull,
          child: _warshTokenText(segments[i]),
        ),
    ];

    final row = _continuousHighlightRow(
      context,
      segments: rowSegments,
      gapWidth: sepWidth,
    );

    return SizedBox(
      width: width,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.center,
        child: row,
      ),
    );
  }

  /// Ayah-end digit clusters need LTR so Eastern digits keep a non-zero advance
  /// when they sit alone in a [Row] child (RTL-only digits painted blank).
  Widget _warshTokenText(String token) {
    final isEndMark = _isWarshEndMarkToken(token);
    return Text(
      token,
      textDirection: isEndMark ? ui.TextDirection.ltr : ui.TextDirection.rtl,
      softWrap: false,
      maxLines: 1,
      style: style,
    );
  }

  static final RegExp _warshEndMarkPattern =
      RegExp(r'^[\u2009\u00A0\s]*[٠-٩]+[\u2009\u00A0\s]*$');

  static bool _isWarshEndMarkToken(String token) =>
      _warshEndMarkPattern.hasMatch(token);

  static final RegExp _articleMarks = RegExp(
    r'[\u064B-\u065F\u0670\u0640\u06D6-\u06ED\u200C\u200D]',
  );

  /// Standalone definite article. Joined to the next word so lam connects
  /// and the gap between «ال» and the noun disappears.
  static bool isLoneArticle(String token) {
    final bare = token.replaceAll(_articleMarks, '');
    return bare == 'ال' ||
        bare == 'ٱل' ||
        bare == 'أل' ||
        bare == 'إل' ||
        bare == 'آل';
  }

  static List<String> glueArticleParts(List<String> parts) {
    if (parts.length < 2) return parts;
    final out = <String>[];
    for (final part in parts) {
      if (out.isNotEmpty &&
          isLoneArticle(out.last) &&
          !_isWarshEndMarkToken(part)) {
        out[out.length - 1] = out.last + part;
      } else {
        out.add(part);
      }
    }
    return out;
  }

  static List<MushafWordToken> glueArticleTokens(List<MushafWordToken> words) {
    if (words.length < 2) return words;
    final out = <MushafWordToken>[];
    for (final word in words) {
      if (out.isNotEmpty &&
          isLoneArticle(out.last.text) &&
          !_isWarshEndMarkToken(word.text)) {
        final prev = out.removeLast();
        out.add(
          MushafWordToken(
            text: prev.text + word.text,
            surah: word.surah ?? prev.surah,
            ayah: word.ayah ?? prev.ayah,
          ),
        );
      } else {
        out.add(word);
      }
    }
    return out;
  }

  /// True when this line must paint per-token so ayah wash stays continuous.
  bool get _hafsLineNeedsOverlay {
    if (highlightedAyah == null &&
        playingAyah == null &&
        completedAyahs.isEmpty &&
        bookmarkedAyahs.isEmpty) {
      return false;
    }
    for (final word in words) {
      final ref = word.ayahRef;
      if (ref == null) {
        continue;
      }
      if (highlightedAyah == ref ||
          playingAyah == ref ||
          completedAyahs.contains(ref) ||
          bookmarkedAyahs.containsKey(ref)) {
        return true;
      }
    }
    return false;
  }

  /// One paragraph per Hafs line — cheap enough to paint *during* a swipe.
  ///
  /// The interactive [Row] of per-glyph [Text]s is ~15× the layout cost and
  /// was first-painting the incoming page in the middle of the fling, so the
  /// slide dropped frames and read as a hard cut.
  Widget _hafsPlainLine(String text) {
    Widget line = Text(
      text,
      textDirection: ui.TextDirection.rtl,
      softWrap: false,
      maxLines: 1,
      style: style,
    );

    if (onAyahLongPress != null) {
      line = GestureDetector(
        behavior: HitTestBehavior.translucent,
        onLongPressStart: (details) {
          final ref = _hafsAyahAtDx(
            details.localPosition.dx,
            textWidth: _measureWord(text),
          );
          if (ref != null) {
            onAyahLongPress!(ref);
          }
        },
        child: line,
      );
    }

    return SizedBox(
      width: width,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.center,
        child: line,
      ),
    );
  }

  MushafAyahRef? _hafsAyahAtDx(double dx, {required double textWidth}) {
    if (words.isEmpty) {
      return null;
    }
    // FittedBox child coords: 0 is the left of the laid-out run; QPC glyphs
    // are RTL so the first word sits on the right.
    var cursor = textWidth;
    for (final word in words) {
      final w = _measureWord(word.text);
      cursor -= w;
      if (dx >= cursor) {
        return word.ayahRef;
      }
    }
    return words.last.ayahRef;
  }

  Widget _hafsLine(
    BuildContext context, {
    required String joined,
    required double gapWidth,
  }) {
    if (!_hafsLineNeedsOverlay) {
      return _hafsPlainLine(joined);
    }
    return _hafsInteractiveRow(context, gapWidth: gapWidth);
  }

  Widget _hafsInteractiveRow(BuildContext context, {required double gapWidth}) {
    final segments = <({MushafAyahRef? ref, Widget child})>[
      for (final word in words)
        (
          ref: word.ayahRef,
          child: Text(
            word.text,
            textDirection: ui.TextDirection.rtl,
            softWrap: false,
            maxLines: 1,
            style: style,
          ),
        ),
      if (ayahEndMark != null)
        (
          ref: words.lastOrNull?.ayahRef,
          child: Text(
            ayahEndMark!,
            textDirection: ui.TextDirection.rtl,
            softWrap: false,
            maxLines: 1,
            style: style,
          ),
        ),
    ];

    final row = _continuousHighlightRow(
      context,
      segments: segments,
      gapWidth: gapWidth,
    );

    return SizedBox(
      width: width,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.center,
        child: row,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (words.isEmpty && ayahEndMark == null) return const SizedBox.shrink();

    final rawParts = <String>[
      for (final word in words)
        softJustify
            ? MushafTypography.normalizeWarshMushafText(word.text)
            : word.text,
      if (ayahEndMark != null) ayahEndMark!,
    ];
    final parts = softJustify ? glueArticleParts(rawParts) : rawParts;
    final joined = parts.join(wordSeparator);
    final segmentCount = parts.length;
    final gaps = segmentCount - 1;

    // Short / flagged-centered lines stay natural. Nearly-full "centered"
    // estimated rows still get kashida fill so edges align.
    var useCentered = centered || (words.length == 1 && ayahEndMark == null);
    if (softJustify && useCentered && gaps > 0) {
      if (_measureWord(joined) >= width * 0.90) {
        useCentered = false;
      }
    }

    if (useCentered) {
      return _centeredLine(context, joined);
    }

    // Warsh Unicode: stretch with tatweel (rule: never after ذءؤرةوزدا).
    // Skip per-word measuring — fillToWidth handles width itself (cached).
    if (softJustify) {
      return _kashidaFilledLine(context, joined);
    }

    // Hafs: one-paragraph paint unless this line needs ayah wash.
    // Skip the per-line TextPainter + per-glyph Row during swipes.
    if (!_hafsLineNeedsOverlay) {
      return _hafsPlainLine(joined);
    }

    final natural = _measureWord(joined);
    final extra = width - natural;
    final fontSize = style.fontSize ?? 24;
    final maxAdded = wordSeparator.isEmpty ? double.infinity : fontSize * 0.22;
    final added =
        gaps > 0 && extra > 0 ? (extra / gaps).clamp(0.0, maxAdded) : 0.0;
    final baseGap = wordSeparator.isEmpty ? 0.0 : _measureWord(wordSeparator);
    final gapWidth = baseGap + added;

    return _hafsInteractiveRow(context, gapWidth: gapWidth);
  }
}

class _UnicodeFallbackBody extends StatelessWidget {
  const _UnicodeFallbackBody({
    required this.maxWidth,
    required this.maxHeight,
    required this.ayahs,
    required this.riwayah,
    required this.fontScale,
    required this.colors,
    required this.startsNewSurah,
    required this.surahNameAr,
    required this.showDecorativeBasmala,
    this.onSurahHeaderLongPress,
  });

  final double maxWidth;
  final double maxHeight;
  final List<MushafAyah> ayahs;
  final MushafRiwayah riwayah;
  final double fontScale;
  final ColorScheme colors;
  final bool startsNewSurah;
  final String surahNameAr;
  final bool showDecorativeBasmala;
  final ValueChanged<int>? onSurahHeaderLongPress;

  @override
  Widget build(BuildContext context) {
    final style = MushafTypography.ayah(
      riwayah: riwayah,
      color: colors.onSurface,
      fontScale: fontScale,
    );
    final text = ayahs.map((a) => a.text).join(' ');
    final surahId = ayahs.isNotEmpty ? ayahs.first.surahId : 0;

    final column = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (startsNewSurah) ...[
          MushafSurahTitleBanner(
            nameAr: surahNameAr,
            riwayah: riwayah,
            colors: colors,
            surahId: surahId,
            onLongPress: onSurahHeaderLongPress,
          ),
          const SizedBox(height: 12),
        ],
        if (showDecorativeBasmala) ...[
          _BasmalahLine(
            width: maxWidth,
            colors: colors,
          ),
          const SizedBox(height: 8),
        ],
        Text(
          MushafTypography.normalizeAyahText(text),
          textAlign: TextAlign.center,
          textDirection: ui.TextDirection.rtl,
          softWrap: true,
          style: style,
        ),
      ],
    );

    return SizedBox(
      width: maxWidth,
      height: maxHeight,
      child: FittedBox(
        fit: BoxFit.contain,
        alignment: Alignment.center,
        child: SizedBox(width: maxWidth, child: column),
      ),
    );
  }
}

class _PageMetaRow extends StatelessWidget {
  const _PageMetaRow({
    required this.leading,
    required this.trailing,
    required this.colors,
    required this.textTheme,
  });

  final String leading;
  final String trailing;
  final ColorScheme colors;
  final TextTheme textTheme;

  @override
  Widget build(BuildContext context) {
    final style = textTheme.labelMedium?.copyWith(
      color: colors.onSurfaceVariant,
      fontWeight: FontWeight.w500,
    );

    return Row(
      children: [
        Expanded(
          child: Text(
            leading,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.start,
            style: style,
          ),
        ),
        Text(trailing, style: style),
      ],
    );
  }
}

class _PageNumberFrame extends StatelessWidget {
  const _PageNumberFrame({
    required this.page,
    required this.colors,
    required this.textTheme,
  });

  final int page;
  final ColorScheme colors;
  final TextTheme textTheme;

  @override
  Widget build(BuildContext context) {
    final ink = colors.onSurface.withValues(alpha: 0.72);
    final rule = colors.primary.withValues(alpha: 0.38);

    return SizedBox(
      height: 32,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _FolioRule(color: rule, towardEnd: true),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              '$page',
              textAlign: TextAlign.center,
              style: textTheme.labelMedium?.copyWith(
                color: ink,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.4,
                height: 1,
              ),
            ),
          ),
          _FolioRule(color: rule, towardEnd: false),
        ],
      ),
    );
  }
}

class _FolioRule extends StatelessWidget {
  const _FolioRule({
    required this.color,
    required this.towardEnd,
  });

  final Color color;
  final bool towardEnd;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 32,
      height: 8,
      child: CustomPaint(
        painter: _FolioRulePainter(
          color: color,
          towardEnd: towardEnd,
        ),
      ),
    );
  }
}

class _FolioRulePainter extends CustomPainter {
  const _FolioRulePainter({
    required this.color,
    required this.towardEnd,
  });

  final Color color;
  final bool towardEnd;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final midY = size.height / 2;
    final diamondX = towardEnd ? size.width - 3.5 : 3.5;
    final lineStart = towardEnd ? 0.0 : 7.0;
    final lineEnd = towardEnd ? size.width - 7.0 : size.width;

    canvas.drawLine(Offset(lineStart, midY), Offset(lineEnd, midY), paint);

    final diamond = Path()
      ..moveTo(diamondX, 0.5)
      ..lineTo(diamondX + 3, midY)
      ..lineTo(diamondX, size.height - 0.5)
      ..lineTo(diamondX - 3, midY)
      ..close();
    canvas.drawPath(diamond, paint);
  }

  @override
  bool shouldRepaint(covariant _FolioRulePainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.towardEnd != towardEnd;
}
