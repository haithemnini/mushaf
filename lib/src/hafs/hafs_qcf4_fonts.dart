import 'dart:io';
// import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:archive/archive.dart';
import 'package:flutter/services.dart';

import 'hafs_qcf4_pack.dart';

/// Lazy loader for QCF4 color page fonts.
///
/// Each page is registered four times from the same file: colored tajweed
/// (light and dark ink) and plain ink (every CPAL color flattened).
abstract final class HafsQcf4Fonts {
  static final Set<String> _loaded = {};
  static final Map<String, Future<void>> _inflight = {};
  static var _epoch = -1;

  static String familyForPage(
    int page, {
    required bool dark,
    required bool tajweed,
  }) {
    final n = page.clamp(1, 604);
    final base = 'QCF4_P${n.toString().padLeft(3, '0')}';
    if (tajweed) {
      return dark ? '${base}d' : base;
    }
    return dark ? '${base}nd' : '${base}n';
  }

  static bool isPageLoaded(
    int page, {
    required bool dark,
    required bool tajweed,
  }) {
    _syncEpoch();
    if (page < 1 || page > 604) {
      return false;
    }
    return _loaded.contains(familyForPage(page, dark: dark, tajweed: tajweed));
  }

  static void clear() {
    _loaded.clear();
    _inflight.clear();
    _epoch = HafsQcf4Pack.epoch;
  }

  static Future<void> ensurePage(
    int page, {
    bool neighbors = true,
    int radius = 1,
  }) async {
    _syncEpoch();
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
      loadAyahFont(),
    ]);
  }

  static const ayahFamily = 'QCF4AyahNumber';

  static String familyForAyah({required bool dark}) => dark ? '${ayahFamily}d' : ayahFamily;

  /// Light and dark text ink from [Themes], baked into the marker font.
  static const _ayahInkLight = ui.Color(0xFF2D2118);
  static const _ayahInkDark = ui.Color(0xFFF5EDE2);

  static String arabicIndic(int value) {
    const digits = '٠١٢٣٤٥٦٧٨٩';
    return value.toString().split('').map((digit) => digits[int.parse(digit)]).join();
  }

  static Future<void> loadAyahFont() async {
    _syncEpoch();
    if (_loaded.contains(ayahFamily)) {
      return;
    }
    final existing = _inflight[ayahFamily];
    if (existing != null) {
      await existing;
      return;
    }
    final task = () async {
      final bytes = await _readFont(File(HafsQcf4Pack.ayahFontPath));
      final light = familyForAyah(dark: false);
      final dark = familyForAyah(dark: true);
      await _register(light, _recolorAyahMark(Uint8List.fromList(bytes), _ayahInkLight));
      await _register(dark, _recolorAyahMark(Uint8List.fromList(bytes), _ayahInkDark));
      _loaded.add(light);
      _loaded.add(dark);
    }();
    _inflight[ayahFamily] = task;
    try {
      await task;
    } finally {
      _inflight.remove(ayahFamily);
    }
  }

  static Future<void> loadPageFont(int page) async {
    _syncEpoch();
    if (page < 1 || page > 604) {
      return;
    }
    final families = [
      familyForPage(page, dark: false, tajweed: true),
      familyForPage(page, dark: true, tajweed: true),
      familyForPage(page, dark: false, tajweed: false),
      familyForPage(page, dark: true, tajweed: false),
    ];
    if (families.every(_loaded.contains)) {
      return;
    }
    final existing = _inflight[families.first];
    if (existing != null) {
      await existing;
      return;
    }
    final task = () async {
      final bytes = await _readFont(File(HafsQcf4Pack.fontPath(page)));
      const white = ui.Color(0xFFFFFFFF);
      const black = ui.Color(0xFF000000);
      await _register(families[0], bytes);
      await _register(families[1], _recolorBlackInk(Uint8List.fromList(bytes), white));
      await _register(families[2], _recolorAllColors(Uint8List.fromList(bytes), black));
      await _register(families[3], _recolorAllColors(Uint8List.fromList(bytes), white));
      _loaded.addAll(families);
    }();
    _inflight[families.first] = task;
    try {
      await task;
    } finally {
      _inflight.remove(families.first);
    }
  }

  static void _syncEpoch() {
    if (_epoch == HafsQcf4Pack.epoch) {
      return;
    }
    _loaded.clear();
    _inflight.clear();
    _epoch = HafsQcf4Pack.epoch;
  }

  static Future<Uint8List> _readFont(File file) async {
    final bytes = await file.readAsBytes();
    if (bytes.length >= 2 && bytes[0] == 0x1f && bytes[1] == 0x8b) {
      return Uint8List.fromList(const GZipDecoder().decodeBytes(bytes));
    }
    return bytes;
  }

  static Future<void> _register(String family, Uint8List bytes) async {
    final loader = FontLoader(family)..addFont(Future.value(ByteData.sublistView(bytes)));
    await loader.load();
  }

  /// Paints the ayah stop in the theme text ink and clears paper-colored fills.
  static Uint8List _recolorAyahMark(Uint8List fontBytes, ui.Color ink) {
    final colors = _cpalColors(fontBytes);
    if (colors == null) {
      return fontBytes;
    }
    final red = (ink.r * 255).round();
    final green = (ink.g * 255).round();
    final blue = (ink.b * 255).round();
    for (final at in colors) {
      final b = fontBytes[at];
      final g = fontBytes[at + 1];
      final r = fontBytes[at + 2];
      final a = fontBytes[at + 3];
      final paper = r >= 190 && g >= 190 && b >= 190 && a >= 200;
      if (paper) {
        fontBytes[at + 3] = 0;
        continue;
      }
      fontBytes[at] = blue;
      fontBytes[at + 1] = green;
      fontBytes[at + 2] = red;
      fontBytes[at + 3] = 255;
    }
    return fontBytes;
  }

  /// Flattens every CPAL record to one ink so the page draws without tajweed.
  static Uint8List _recolorAllColors(Uint8List fontBytes, ui.Color ink) {
    final colors = _cpalColors(fontBytes);
    if (colors == null) {
      return fontBytes;
    }
    final red = (ink.r * 255).round();
    final green = (ink.g * 255).round();
    final blue = (ink.b * 255).round();
    final alpha = (ink.a * 255).round();
    for (final at in colors) {
      fontBytes[at] = blue;
      fontBytes[at + 1] = green;
      fontBytes[at + 2] = red;
      fontBytes[at + 3] = alpha;
    }
    return fontBytes;
  }

  /// Replaces near-black CPAL records so dark mode keeps tajweed hues.
  static Uint8List _recolorBlackInk(Uint8List fontBytes, ui.Color ink) {
    final colors = _cpalColors(fontBytes);
    if (colors == null) {
      return fontBytes;
    }
    final red = (ink.r * 255).round();
    final green = (ink.g * 255).round();
    final blue = (ink.b * 255).round();
    final alpha = (ink.a * 255).round();
    for (final at in colors) {
      final b = fontBytes[at];
      final g = fontBytes[at + 1];
      final r = fontBytes[at + 2];
      final a = fontBytes[at + 3];
      if (r <= 30 && g <= 30 && b <= 30 && a >= 200) {
        fontBytes[at] = blue;
        fontBytes[at + 1] = green;
        fontBytes[at + 2] = red;
        fontBytes[at + 3] = alpha;
      }
    }
    return fontBytes;
  }

  /// Byte offsets of BGRA color records inside the font's CPAL table.
  static List<int>? _cpalColors(Uint8List fontBytes) {
    if (fontBytes.length < 12) {
      return null;
    }
    final data = ByteData.view(fontBytes.buffer, fontBytes.offsetInBytes, fontBytes.lengthInBytes);
    final numTables = data.getUint16(4);
    const cpalTag = 0x4350414C;
    int? cpalOffset;
    int? cpalLength;
    for (var table = 0; table < numTables; table++) {
      final record = 12 + table * 16;
      if (record + 16 > fontBytes.length) {
        break;
      }
      if (data.getUint32(record) == cpalTag) {
        cpalOffset = data.getUint32(record + 8);
        cpalLength = data.getUint32(record + 12);
        break;
      }
    }
    if (cpalOffset == null || cpalLength == null) {
      return null;
    }
    if (cpalOffset + cpalLength > fontBytes.length || cpalOffset + 12 > fontBytes.length) {
      return null;
    }
    final numColors = data.getUint16(cpalOffset + 6);
    final colorsAt = cpalOffset + data.getUint32(cpalOffset + 8);
    final offsets = <int>[];
    for (var color = 0; color < numColors; color++) {
      final at = colorsAt + color * 4;
      if (at + 4 > fontBytes.length) {
        break;
      }
      offsets.add(at);
    }
    return offsets;
  }
}
