import '../models/mushaf_riwayah.dart';

/// Global registry of riwayah asset packs + shared surahs path.
abstract final class MushafAssets {
  static final Map<MushafRiwayah, MushafRiwayahAssets> _riwayat = {};
  static String _surahsPackage = 'mushaf';
  static String _surahsAsset = 'assets/quran/surahs/surahs.json';

  static void configureSurahs({
    String packageName = 'mushaf',
    String asset = 'assets/quran/surahs/surahs.json',
  }) {
    _surahsPackage = packageName;
    _surahsAsset = asset;
  }

  static void register(MushafRiwayah riwayah, MushafRiwayahAssets assets) {
    _riwayat[riwayah] = assets;
  }

  static void unregister(MushafRiwayah riwayah) {
    _riwayat.remove(riwayah);
  }

  static bool isRegistered(MushafRiwayah riwayah) => _riwayat.containsKey(riwayah);

  static MushafRiwayahAssets require(MushafRiwayah riwayah) {
    final assets = _riwayat[riwayah];
    if (assets == null) {
      throw StateError(
        'Mushaf riwayah $riwayah is not registered. '
        'Download a pack and call registerMushafHafs/registerMushafWarsh.',
      );
    }
    return assets;
  }

  static MushafRiwayahAssets? maybe(MushafRiwayah riwayah) => _riwayat[riwayah];

  static Iterable<MushafRiwayah> get registered => _riwayat.keys;

  static String surahsPath() => 'packages/$_surahsPackage/$_surahsAsset';

  /// Test helper — clears registrations.
  static void resetForTest() {
    _riwayat.clear();
    _surahsPackage = 'mushaf';
    _surahsAsset = 'assets/quran/surahs/surahs.json';
  }
}
