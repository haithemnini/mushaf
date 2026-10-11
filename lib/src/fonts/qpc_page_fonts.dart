import 'dart:convert';

import 'package:flutter/services.dart';

import '../assets/mushaf_assets.dart';
import '../models/mushaf_riwayah.dart';

/// Loads QPC V2 page fonts + shared surah-name / QCF2 basmalah chrome fonts.
abstract final class QpcPageFonts {
  static const surahNamesFamily = 'QPC_SurahNames';
  static const basmalahFamily = 'QCF2BSML';
  static const basmalahGlyph = '\uFC21';

  static const _coreSurahNames =
      'packages/mushaf/assets/fonts/chrome/surah_names.ttf';
  static const _coreBasmalah =
      'packages/mushaf/assets/fonts/chrome/QCF2BSML.ttf';
  static const _coreGlyphs =
      'packages/mushaf/assets/quran/chrome/surah_name_glyphs.json';
  static const surahFrameAsset =
      'packages/mushaf/assets/quran/chrome/surah_frame.svg';

  static final Set<String> _loaded = {};
  static final Map<String, Future<void>> _inflight = {};
  static Map<int, String>? _surahGlyphs;

  static String familyForPage(int page) {
    final n = page.clamp(1, 604);
    return 'p$n-v2';
  }

  static String? surahNameGlyph(int surah) => _surahGlyphs?[surah];

  static Future<void> ensurePage(
    int page, {
    bool neighbors = true,
    int radius = 1,
  }) async {
    final pages = <int>{page};
    if (neighbors) {
      final extent = radius < 1 ? 1 : radius;
      for (var i = 1; i <= extent; i++) {
        if (page - i >= 1) {
          pages.add(page - i);
        }
        if (page + i <= 604) {
          pages.add(page + i);
        }
      }
    }
    await Future.wait([
      ...pages.map(loadPageFont),
      loadSurahNameFont(),
      loadBasmalahFont(),
    ]);
  }

  static bool isPageLoaded(int page) {
    if (page < 1 || page > 604) return false;
    return _loaded.contains(familyForPage(page));
  }

  static Future<void> prefetchNeighbors(int page, {int radius = 1}) {
    final pages = <int>{};
    final extent = radius < 1 ? 1 : radius;
    for (var i = 1; i <= extent; i++) {
      if (page - i >= 1) {
        pages.add(page - i);
      }
      if (page + i <= 604) {
        pages.add(page + i);
      }
    }
    if (pages.isEmpty) return Future.value();
    return Future.wait(pages.map(loadPageFont));
  }

  static Future<void> loadPageFont(int page) async {
    if (page < 1 || page > 604) return;
    final assets = MushafAssets.maybe(MushafRiwayah.hafs);
    if (assets == null) return;
    final path = assets.resolvePageFont(page);
    if (path == null) return;
    await _loadFamily(familyForPage(page), path, assets.usesLocalFiles);
  }

  static Future<void> loadSurahNameFont() async {
    await Future.wait([
      _loadFamily(surahNamesFamily, _coreSurahNames, false),
      _loadSurahGlyphs(),
    ]);
  }

  static Future<void> loadBasmalahFont() async {
    await _loadFamily(basmalahFamily, _coreBasmalah, false);
  }

  static Future<void> _loadSurahGlyphs() async {
    if (_surahGlyphs != null) return;
    final raw = await rootBundle.loadString(_coreGlyphs);
    final decoded = json.decode(raw) as Map<String, dynamic>;
    _surahGlyphs = {
      for (final e in decoded.entries) int.parse(e.key): e.value as String,
    };
  }

  static Future<void> _loadFamily(String family, String asset, bool fromFile) async {
    if (_loaded.contains(family)) return;
    final existing = _inflight[family];
    if (existing != null) {
      await existing;
      return;
    }
    final task = () async {
      final data = fromFile
          ? MushafRiwayahAssets.bytesFromFile(asset)
          : rootBundle.load(asset);
      final loader = FontLoader(family)..addFont(data);
      await loader.load();
      _loaded.add(family);
    }();
    _inflight[family] = task;
    try {
      await task;
    } finally {
      _inflight.remove(family);
    }
  }

  static void resetForTest() {
    _loaded.clear();
    _inflight.clear();
    _surahGlyphs = null;
  }
}
