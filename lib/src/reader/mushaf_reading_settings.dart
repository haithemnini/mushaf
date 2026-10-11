import 'package:flutter/material.dart';

/// Horizontal page turns, or a vertical stack of pages.
enum MushafScrollDirection { horizontal, vertical }

/// Full-bleed page, or a page set inside a book frame.
enum MushafPageDesign { fullscreen, book }

/// Landscape spread on a wide, short window.
enum MushafLandscapeLayout { single, doublePage }

/// Bottom page picker: thumbnails, or a scrubber that jumps on release.
enum MushafPageNavMode { strip, scrub }

/// Reading options shared by Hafs and Warsh.
@immutable
class MushafReadingSettings {
  const MushafReadingSettings({
    this.scrollDirection = MushafScrollDirection.horizontal,
    this.pageDesign = MushafPageDesign.fullscreen,
    this.landscapeLayout = MushafLandscapeLayout.doublePage,
    this.pageNavMode = MushafPageNavMode.strip,
    this.showClock = false,
    this.blackBackground = false,
    this.tajweedEnabled = false,
  });

  final MushafScrollDirection scrollDirection;
  final MushafPageDesign pageDesign;
  final MushafLandscapeLayout landscapeLayout;
  final MushafPageNavMode pageNavMode;
  final bool showClock;
  final bool blackBackground;

  /// Colored QCF4 glyphs. Ignored for Warsh.
  final bool tajweedEnabled;

  MushafReadingSettings copyWith({
    MushafScrollDirection? scrollDirection,
    MushafPageDesign? pageDesign,
    MushafLandscapeLayout? landscapeLayout,
    MushafPageNavMode? pageNavMode,
    bool? showClock,
    bool? blackBackground,
    bool? tajweedEnabled,
  }) {
    return MushafReadingSettings(
      scrollDirection: scrollDirection ?? this.scrollDirection,
      pageDesign: pageDesign ?? this.pageDesign,
      landscapeLayout: landscapeLayout ?? this.landscapeLayout,
      pageNavMode: pageNavMode ?? this.pageNavMode,
      showClock: showClock ?? this.showClock,
      blackBackground: blackBackground ?? this.blackBackground,
      tajweedEnabled: tajweedEnabled ?? this.tajweedEnabled,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is MushafReadingSettings &&
        other.scrollDirection == scrollDirection &&
        other.pageDesign == pageDesign &&
        other.landscapeLayout == landscapeLayout &&
        other.pageNavMode == pageNavMode &&
        other.showClock == showClock &&
        other.blackBackground == blackBackground &&
        other.tajweedEnabled == tajweedEnabled;
  }

  @override
  int get hashCode => Object.hash(
        scrollDirection,
        pageDesign,
        landscapeLayout,
        pageNavMode,
        showClock,
        blackBackground,
        tajweedEnabled,
      );
}

/// Madinah Hafs (604) juz start pages. Warsh uses the ayah corpus instead.
int hafsJuzForPage(int page) {
  const starts = <int>[
    1, 22, 42, 62, 82, 102, 121, 142, 162, 182,
    201, 222, 242, 262, 282, 302, 322, 342, 362, 382,
    402, 422, 442, 462, 482, 502, 522, 542, 562, 582,
  ];
  final safe = page < 1 ? 1 : page;
  var juz = 1;
  for (var i = 0; i < starts.length; i++) {
    if (safe >= starts[i]) {
      juz = i + 1;
    }
  }
  return juz;
}

/// Wide and short enough that two mushaf pages sit side by side.
bool mushafSpreadWindow(Size size) {
  return size.width >= 800 && size.width > size.height;
}
