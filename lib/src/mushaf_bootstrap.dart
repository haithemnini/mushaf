import 'package:flutter/services.dart';

import 'assets/mushaf_assets.dart';
import 'fonts/mushaf_fonts.dart';
import 'fonts/qpc_page_fonts.dart';
import 'hafs/hafs_qcf4_fonts.dart';
import 'hafs/hafs_qcf4_pack.dart';
import 'models/mushaf_riwayah.dart';
import 'repository/mushaf_repository.dart';

/// Entry point for the mushaf engine.
abstract final class Mushaf {
  static MushafRepository? _repository;
  static bool _initialized = false;

  static bool get isInitialized => _initialized;

  static MushafRepository get repository {
    final repo = _repository;
    if (repo == null) {
      throw StateError('Call Mushaf.initialize() before using the repository.');
    }
    return repo;
  }

  /// Registers shared paths and creates the default [MushafRepository].
  ///
  /// Register a downloaded riwayah with [registerMushafHafs] /
  /// [registerMushafWarsh] before the first page load.
  static Future<void> initialize({
    AssetBundle? bundle,
    MushafRepository? repository,
  }) async {
    MushafAssets.configureSurahs();
    _repository = repository ?? MushafRepository(bundle: bundle);
    _initialized = true;
  }

  /// Warm Unicode fonts for all registered riwayat (optional at app start).
  static Future<void> ensureFontsLoaded() => MushafFonts.ensureLoaded();

  static int pageCount(MushafRiwayah riwayah) =>
      MushafAssets.require(riwayah).pageCount;

  static void evictRiwayah(MushafRiwayah riwayah) {
    MushafAssets.unregister(riwayah);
    _repository?.evictRiwayah(riwayah);
  }

  static Future<void> ensurePageFonts(
    MushafRiwayah riwayah,
    int page, {
    bool neighbors = true,
  }) {
    if (page < 1) {
      return Future.value();
    }
    return switch (riwayah) {
      MushafRiwayah.hafs => HafsQcf4Pack.isActive
          ? HafsQcf4Fonts.ensurePage(
              page,
              neighbors: neighbors,
              radius: 1,
            )
          : QpcPageFonts.ensurePage(
              page,
              neighbors: neighbors,
              radius: 1,
            ),
      MushafRiwayah.warsh => Future.wait([
          MushafFonts.ensureLoaded(),
          QpcPageFonts.loadSurahNameFont(),
          QpcPageFonts.loadBasmalahFont(),
        ]),
    };
  }
}
