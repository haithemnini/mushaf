import 'dart:io';

import 'package:flutter/services.dart';

/// Supported mushaf riwayat.
enum MushafRiwayah {
  /// Madinah Hafs — canonical **604** pages (QPC V2 Uthmani page fonts).
  hafs,

  /// Warsh — **generated 599** pages (not printed Madinah 604).
  warsh,
}

extension MushafRiwayahDefaults on MushafRiwayah {
  int get defaultPageCount => switch (this) {
        MushafRiwayah.hafs => 604,
        MushafRiwayah.warsh => 599,
      };

  bool get defaultUsesSplitPages => switch (this) {
        MushafRiwayah.hafs => false,
        MushafRiwayah.warsh => true,
      };

  /// Logical Unicode face name when a pack has not called [MushafAssets.register].
  /// Prefer loading real pack fonts via registration before painting mushaf pages.
  String get defaultFontFamily => switch (this) {
        MushafRiwayah.hafs => 'DigitalMadina',
        MushafRiwayah.warsh => 'KFGQPCWarshV2',
      };

  List<String> get defaultFontFamilyFallback => switch (this) {
        MushafRiwayah.hafs => const [
            'DigitalMadina-NON V1',
            'KFGQPC HAFS Uthmanic Script',
            'HafsQuran',
          ],
        MushafRiwayah.warsh => const [
            'KFGQPCWarshV2Bold',
            'UthmanicWarshV21',
            'TEWarshTharwatEmara',
            'KFGQPC WARSH Uthmanic Script',
            'WarshQuran',
          ],
      };
}

/// Registration payload for a riwayah's asset locations.
class MushafRiwayahAssets {
  MushafRiwayahAssets({
    required this.packageName,
    required this.ayahsAsset,
    required this.pagesAsset,
    required this.pageCount,
    required this.usesSplitPages,
    required this.fontFamily,
    this.fontFamilyFallback = const [],
    this.surahFrameAsset,
    this.surahGlyphsAsset,
    this.pageFontAssetBuilder,
    this.surahNamesFontAsset,
    this.basmalahFontAsset,
    this.unicodeFontAssets = const {},
    this.localRoot,
  });

  /// Logical owner name (unused when [localRoot] is set).
  final String packageName;

  /// Relative path under the pack root, e.g. `assets/quran/hafs/hafs.json`.
  final String ayahsAsset;

  /// Single pages JSON (Hafs) or directory prefix ending with `/` (Warsh).
  final String pagesAsset;

  final int pageCount;
  final bool usesSplitPages;
  final String fontFamily;
  final List<String> fontFamilyFallback;

  final String? surahFrameAsset;
  final String? surahGlyphsAsset;
  final String Function(int page)? pageFontAssetBuilder;
  final String? surahNamesFontAsset;
  final String? basmalahFontAsset;

  /// Extra Unicode font families → relative asset paths for [FontLoader].
  final Map<String, String> unicodeFontAssets;

  /// Absolute extracted pack directory. When set, files are read from disk.
  final String? localRoot;

  bool get usesLocalFiles {
    final root = localRoot;
    return root != null && root.isNotEmpty;
  }

  String packagePath(String relative) => 'packages/$packageName/$relative';

  String resolve(String relative) {
    final root = localRoot;
    if (root != null && root.isNotEmpty) {
      final prefix = root.endsWith('/') ? root.substring(0, root.length - 1) : root;
      return '$prefix/$relative';
    }
    return packagePath(relative);
  }

  String resolveAyahs() => resolve(ayahsAsset);

  String resolvePages() => resolve(pagesAsset);

  String resolvePage(int page) {
    if (!usesSplitPages) {
      return resolvePages();
    }
    final padded = page.toString().padLeft(3, '0');
    return resolve('$pagesAsset$padded.json');
  }

  String? resolveSurahFrame() =>
      surahFrameAsset == null ? null : resolve(surahFrameAsset!);

  String? resolveSurahGlyphs() =>
      surahGlyphsAsset == null ? null : resolve(surahGlyphsAsset!);

  String? resolvePageFont(int page) {
    final builder = pageFontAssetBuilder;
    if (builder == null) return null;
    return resolve(builder(page));
  }

  String? resolveSurahNamesFont() =>
      surahNamesFontAsset == null ? null : resolve(surahNamesFontAsset!);

  String? resolveBasmalahFont() =>
      basmalahFontAsset == null ? null : resolve(basmalahFontAsset!);

  Future<String> loadString(AssetBundle bundle, String resolved) {
    if (usesLocalFiles) {
      return File(resolved).readAsString();
    }
    return bundle.loadString(resolved);
  }

  Future<ByteData> loadBytes(AssetBundle bundle, String resolved) async {
    if (usesLocalFiles) {
      return bytesFromFile(resolved);
    }
    return bundle.load(resolved);
  }

  static Future<ByteData> bytesFromFile(String path) async {
    final bytes = await File(path).readAsBytes();
    return ByteData.sublistView(bytes);
  }
}
