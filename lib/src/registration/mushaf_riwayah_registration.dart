import '../assets/mushaf_assets.dart';
import '../hafs/hafs_qcf4_pack.dart';
import '../models/mushaf_riwayah.dart';

/// Registers a downloaded Hafs QCF4 pack rooted at [localRoot]
/// (`…/mushaf_packs/hafs` with `assets/quran/hafs_qcf4` inside).
///
/// This is the Hafs renderer used by [MushafReader].
void registerMushafHafsQcf4({required String localRoot}) {
  final root = localRoot.trim();
  if (root.isEmpty) {
    throw ArgumentError.value(localRoot, 'localRoot', 'Downloaded Hafs pack root is required.');
  }
  if (!HafsQcf4Pack.looksLikePack(root)) {
    throw ArgumentError.value(
      localRoot,
      'localRoot',
      'Expected a Hafs QCF4 pack (assets/quran/hafs_qcf4).',
    );
  }
  HafsQcf4Pack.activate(root);
}

/// Registers a downloaded Hafs pack rooted at [localRoot]
/// (`…/mushaf_packs/hafs` with `assets/...` inside).
void registerMushafHafs({required String localRoot}) {
  final root = localRoot.trim();
  if (root.isEmpty) {
    throw ArgumentError.value(localRoot, 'localRoot', 'Downloaded Hafs pack root is required.');
  }
  MushafAssets.register(
    MushafRiwayah.hafs,
    MushafRiwayahAssets(
      packageName: 'mushaf',
      ayahsAsset: 'assets/quran/hafs/hafs.json',
      pagesAsset: 'assets/quran/qpc_v2/pages.json',
      pageCount: 604,
      usesSplitPages: false,
      fontFamily: 'DigitalMadina',
      fontFamilyFallback: const [
        'DigitalMadina-NON V1',
        'KFGQPC HAFS Uthmanic Script',
        'HafsQuran',
      ],
      pageFontAssetBuilder: (page) => 'assets/fonts/qpc_v2/pages/p$page.ttf',
      unicodeFontAssets: const {
        'DigitalMadina': 'assets/fonts/hafs/digital_madina.ttf',
        'DigitalMadina-NON V1': 'assets/fonts/hafs/digital_madina.ttf',
        'KFGQPC HAFS Uthmanic Script': 'assets/fonts/hafs/hafs.18.ttf',
        'HafsQuran': 'assets/fonts/hafs/hafs.18.ttf',
      },
      localRoot: root,
    ),
  );
}

/// Registers a downloaded Warsh pack rooted at [localRoot]
/// (`…/mushaf_packs/warsh` with `assets/...` inside).
void registerMushafWarsh({required String localRoot}) {
  final root = localRoot.trim();
  if (root.isEmpty) {
    throw ArgumentError.value(localRoot, 'localRoot', 'Downloaded Warsh pack root is required.');
  }
  MushafAssets.register(
    MushafRiwayah.warsh,
    MushafRiwayahAssets(
      packageName: 'mushaf',
      ayahsAsset: 'assets/quran/warsh/warsh.json',
      pagesAsset: 'assets/quran/warsh/pages/',
      pageCount: 599,
      usesSplitPages: true,
      // Trial: KFGQPC Warsh V2 Regular. Revert to KFGQPCWarshV2Bold to restore.
      fontFamily: 'KFGQPCWarshV2',
      fontFamilyFallback: const [
        'KFGQPCWarshV2Bold',
        'UthmanicWarshV21',
        'TEWarshTharwatEmara',
        'KFGQPC WARSH Uthmanic Script',
        'WarshQuran',
      ],
      unicodeFontAssets: const {
        'KFGQPCWarshV2': 'assets/fonts/warsh/kfgqpc-warsh-v2-regular.ttf',
        'KFGQPCWarshV2Bold': 'assets/fonts/warsh/kfgqpc-warsh-v2-bold.ttf',
        'UthmanicWarshV21': 'assets/fonts/warsh/uthmanic-warsh-v21.ttf',
        'TEWarshTharwatEmara': 'assets/fonts/warsh/te-warsh-tharwat-emara.ttf',
        'KFGQPC WARSH Uthmanic Script': 'assets/fonts/warsh/warsh.10.ttf',
        'WarshQuran': 'assets/fonts/warsh/warsh.10.ttf',
      },
      localRoot: root,
    ),
  );
}
