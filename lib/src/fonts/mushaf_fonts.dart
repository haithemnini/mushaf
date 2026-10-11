import 'package:flutter/services.dart';

import '../assets/mushaf_assets.dart';
import '../models/mushaf_riwayah.dart';

/// Loads Unicode Quran font families registered with each riwayah pack.
abstract final class MushafFonts {
  static final Set<String> _loadedFamilies = {};
  static final Map<String, Future<void>> _inflight = {};

  static const digitalMadina = 'DigitalMadina';
  static const digitalMadinaExact = 'DigitalMadina-NON V1';
  static const hafsFamily = 'KFGQPC HAFS Uthmanic Script';
  static const hafsAlias = 'HafsQuran';
  static const warshV2Family = 'KFGQPCWarshV2';
  static const warshV2BoldFamily = 'KFGQPCWarshV2Bold';
  static const warshV21Family = 'UthmanicWarshV21';
  static const warshTeFamily = 'TEWarshTharwatEmara';
  static const warshFamily = 'KFGQPC WARSH Uthmanic Script';
  static const warshAlias = 'WarshQuran';

  static Future<void> ensureLoaded() async {
    for (final riwayah in MushafAssets.registered) {
      await ensureRiwayahLoaded(riwayah);
    }
  }

  static Future<void> ensureRiwayahLoaded(MushafRiwayah riwayah) async {
    final assets = MushafAssets.maybe(riwayah);
    if (assets == null) return;
    await Future.wait([
      for (final entry in assets.unicodeFontAssets.entries)
        _loadFamily(
          entry.key,
          assets.resolve(entry.value),
          fromFile: assets.usesLocalFiles,
        ),
    ]);
  }

  static Future<void> _loadFamily(
    String family,
    String path, {
    required bool fromFile,
  }) async {
    if (_loadedFamilies.contains(family)) return;
    final existing = _inflight[family];
    if (existing != null) {
      await existing;
      return;
    }
    final task = () async {
      final data = fromFile
          ? MushafRiwayahAssets.bytesFromFile(path)
          : rootBundle.load(path);
      final loader = FontLoader(family)..addFont(data);
      await loader.load();
      _loadedFamilies.add(family);
    }();
    _inflight[family] = task;
    try {
      await task;
    } finally {
      _inflight.remove(family);
    }
  }

  /// Test helper.
  static void resetForTest() {
    _loadedFamilies.clear();
    _inflight.clear();
  }
}
