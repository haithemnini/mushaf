import 'dart:io';

/// Local root of a QCF4 Hafs layout (`…/assets/quran/hafs_qcf4`).
///
/// The root is either the downloaded mushaf pack or the debug folder
/// `Documents/hafs_qcf4_dev` prepared by `tool/prepare_hafs_qcf4_local.sh`.
abstract final class HafsQcf4Pack {
  static const devFolderName = 'hafs_qcf4_dev';

  static String? _root;
  static var epoch = 0;

  static bool get isActive => _root != null && _root!.isNotEmpty;

  static String? get rootOrNull => _root;

  static String get root {
    final value = _root;
    if (value == null || value.isEmpty) {
      throw StateError('Hafs QCF4 pack is not active.');
    }
    return value;
  }

  static void activate(String localRoot) {
    final trimmed = localRoot.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError.value(localRoot, 'localRoot', 'QCF4 pack root is required.');
    }
    if (_root == trimmed) {
      return;
    }
    _root = trimmed;
    epoch++;
  }

  static void deactivate() {
    if (_root == null) {
      return;
    }
    _root = null;
    epoch++;
  }

  static String resolve(String relative) {
    final normalized = relative.startsWith('/') ? relative.substring(1) : relative;
    return '$root${Platform.pathSeparator}$normalized'.replaceAll('/', Platform.pathSeparator);
  }

  static String fontPath(int page) {
    final padded = page.clamp(1, 604).toString().padLeft(3, '0');
    return resolve('assets/quran/hafs_qcf4/fonts/QCF4${padded}_COLOR-Regular.ttf.gz');
  }

  static String get ayahFontPath => resolve('assets/quran/hafs_qcf4/fonts/ayah_number.ttf');

  static String get ayahInfoPath => resolve('assets/quran/hafs_qcf4/qpc_v4_ayah_info.json.gz');

  static String get wordsPath => resolve('assets/quran/hafs_qcf4/qpc-v4.json.gz');

  static String get manifestPath => resolve('assets/quran/hafs_qcf4/manifest.json');

  static bool looksLikePack(String localRoot) {
    final base = localRoot.trim();
    if (base.isEmpty) {
      return false;
    }
    final sep = Platform.pathSeparator;
    final data = '$base${sep}assets${sep}quran${sep}hafs_qcf4';
    return File('$data${sep}manifest.json').existsSync() &&
        File('$data${sep}qpc-v4.json.gz').existsSync() &&
        File('$data${sep}qpc_v4_ayah_info.json.gz').existsSync() &&
        File('$data${sep}fonts${sep}QCF4001_COLOR-Regular.ttf.gz').existsSync() &&
        File('$data${sep}fonts${sep}ayah_number.ttf').existsSync();
  }
}
