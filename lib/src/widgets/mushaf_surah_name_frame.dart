import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../fonts/qpc_page_fonts.dart';
import '../layout/warsh_mushaf_layout.dart';
import '../models/mushaf_riwayah.dart';
import '../typography/mushaf_typography.dart';

/// Surah name inside the Islamic SVG cartouche frame.
class MushafSurahNameFrame extends StatelessWidget {
  const MushafSurahNameFrame({
    super.key,
    required this.surah,
    required this.nameAr,
    required this.riwayah,
    required this.colors,
    required this.width,
    this.chromeScale = 1,
    this.onLongPress,
  });

  final int surah;
  final String nameAr;
  final MushafRiwayah riwayah;
  final ColorScheme colors;
  final double width;

  /// Vertical compression for chrome-heavy Warsh pages (width stays fixed).
  final double chromeScale;
  final ValueChanged<int>? onLongPress;

  String get _frameAsset => QpcPageFonts.surahFrameAsset;

  @override
  Widget build(BuildContext context) {
    if (surah < 1 || surah > 114) {
      return MushafSurahTitleBanner(
        nameAr: nameAr,
        riwayah: riwayah,
        colors: colors,
        surahId: surah,
        onLongPress: onLongPress,
      );
    }

    final scale = chromeScale.clamp(0.38, 1.0);
    final height = width * WarshMushafLayout.surahFrameAspect * scale;
    final glyph = QpcPageFonts.surahNameGlyph(surah);
    final sidePad = width * 0.28;
    final nameColor = colors.onSurface;
    final nameChild = glyph == null
        ? Text(
            nameAr.startsWith('سورة') || nameAr.startsWith('سُورَة')
                ? nameAr
                : 'سورة $nameAr',
            textAlign: TextAlign.center,
            textDirection: ui.TextDirection.rtl,
            softWrap: false,
            maxLines: 1,
            style: MushafTypography.surahTitle(
              riwayah: riwayah,
              color: nameColor,
              fontSize: 14,
            ),
          )
        : ColorFiltered(
            colorFilter: ColorFilter.mode(nameColor, BlendMode.srcIn),
            child: Text(
              glyph,
              textAlign: TextAlign.center,
              textDirection: ui.TextDirection.rtl,
              softWrap: false,
              maxLines: 1,
              style: const TextStyle(
                inherit: false,
                fontFamily: QpcPageFonts.surahNamesFamily,
                fontSize: 22,
                height: 1,
                color: Color(0xFFFFFFFF),
                fontWeight: FontWeight.normal,
                decoration: TextDecoration.none,
              ),
            ),
          );

    final frame = Padding(
      padding: EdgeInsets.symmetric(vertical: 8 * scale),
      child: SizedBox(
        width: width,
        height: height,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Positioned.fill(
              child: SvgPicture.asset(
                _frameAsset,
                fit: BoxFit.fill,
                colorFilter: ColorFilter.mode(
                  colors.onSurface,
                  BlendMode.srcIn,
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: sidePad,
                vertical: height * 0.30,
              ),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: nameChild,
              ),
            ),
          ],
        ),
      ),
    );

    if (onLongPress == null) {
      return frame;
    }

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onLongPress: () => onLongPress!(surah),
      child: frame,
    );
  }
}

/// Fallback plain banner (missing surah id / glyph).
class MushafSurahTitleBanner extends StatelessWidget {
  const MushafSurahTitleBanner({
    super.key,
    required this.nameAr,
    required this.riwayah,
    required this.colors,
    this.surahId = 0,
    this.onLongPress,
  });

  final String nameAr;
  final MushafRiwayah riwayah;
  final ColorScheme colors;
  final int surahId;
  final ValueChanged<int>? onLongPress;

  @override
  Widget build(BuildContext context) {
    final title = nameAr.startsWith('سورة') || nameAr.startsWith('سُورَة')
        ? nameAr
        : 'سُورَةُ $nameAr';

    final banner = Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Container(
        width: double.infinity,
        height: 44,
        decoration: BoxDecoration(
          color: colors.primaryContainer.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: colors.primary.withValues(alpha: 0.5),
            width: 1.4,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Positioned.fill(
              child: ColoredBox(
                color: colors.primary.withValues(alpha: 0.06),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                title,
                textAlign: TextAlign.center,
                textDirection: ui.TextDirection.rtl,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: MushafTypography.surahTitle(
                  riwayah: riwayah,
                  color: colors.onSurface,
                  fontSize: 17,
                ),
              ),
            ),
          ],
        ),
      ),
    );

    if (onLongPress == null || surahId < 1 || surahId > 114) {
      return banner;
    }

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onLongPress: () => onLongPress!(surahId),
      child: banner,
    );
  }
}
