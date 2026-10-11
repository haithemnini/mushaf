import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';

import 'hafs_qcf4_models.dart';
import 'hafs_qcf4_pack.dart';

/// In-memory QCF4 words and Madinah line map.
abstract final class HafsQcf4Store {
  static const pageCount = 604;

  static var _ready = false;
  static var _epoch = -1;
  static Future<void>? _inflight;
  static Map<int, HafsQcf4Word> _wordsById = const {};
  static Map<int, List<HafsQcf4LineInfo>> _linesByPage = const {};
  static Map<int, int> _maxWordIndexByAyah = const {};
  static Map<int, int> _pageByAyah = const {};
  static Map<int, int> _firstPageBySurah = const {};
  static final Map<int, List<HafsQcf4Block>> _pages = {};

  static bool get isReady => _ready && _epoch == HafsQcf4Pack.epoch;

  static void reset() {
    _ready = false;
    _epoch = -1;
    _inflight = null;
    _wordsById = const {};
    _linesByPage = const {};
    _maxWordIndexByAyah = const {};
    _pageByAyah = const {};
    _firstPageBySurah = const {};
    _pages.clear();
  }

  static Future<void> ensureReady() async {
    if (isReady) {
      return;
    }
    final existing = _inflight;
    if (existing != null && _epoch == HafsQcf4Pack.epoch) {
      await existing;
      return;
    }
    final epoch = HafsQcf4Pack.epoch;
    final task = _load(epoch);
    _inflight = task;
    try {
      await task;
    } finally {
      if (identical(_inflight, task)) {
        _inflight = null;
      }
    }
  }

  /// First Madinah page that contains [surah]:[ayah], after [ensureReady].
  static int? pageForAyah(int surah, int ayah) {
    if (!isReady) {
      return null;
    }
    return _pageByAyah[_ayahKey(surah, ayah)];
  }

  /// First page of [surah], after [ensureReady].
  static int? firstPageForSurah(int surah) {
    if (!isReady) {
      return null;
    }
    return _firstPageBySurah[surah];
  }

  static List<HafsQcf4Block> blocksForPage(int page) {
    if (!isReady || page < 1 || page > pageCount) {
      return const [];
    }
    return _pages.putIfAbsent(page, () => _buildPage(page));
  }

  /// Glyph runs for one ayah, grouped by the page font that owns them.
  ///
  /// The verse-marker slot is omitted. The page draws it with the ayah-number font.
  static List<HafsQcf4GlyphRun> runsForAyah(int surah, int ayah) {
    if (!isReady) {
      return const [];
    }
    final words = _wordsById.values.where((word) => word.surah == surah && word.ayah == ayah).toList()..sort((a, b) => a.id.compareTo(b.id));
    if (words.isEmpty) {
      return const [];
    }
    final runs = <HafsQcf4GlyphRun>[];
    final buffer = StringBuffer();
    final maxIndex = _maxWordIndexByAyah[_ayahKey(surah, ayah)];
    var page = words.first.page;
    for (final word in words) {
      if (word.text.isEmpty) {
        continue;
      }
      if (maxIndex != null && word.wordIndex == maxIndex) {
        continue;
      }
      if (word.page != page && buffer.isNotEmpty) {
        runs.add(HafsQcf4GlyphRun(page: page, glyphs: buffer.toString()));
        buffer.clear();
        page = word.page;
      }
      buffer.write(word.text);
      page = word.page;
    }
    if (buffer.isNotEmpty) {
      runs.add(HafsQcf4GlyphRun(page: page, glyphs: buffer.toString()));
    }
    return runs;
  }

  static Future<void> _load(int epoch) async {
    final linesRaw = jsonDecode(utf8.decode(await _readGzip(File(HafsQcf4Pack.ayahInfoPath)))) as List<dynamic>;
    final linesByPage = <int, List<HafsQcf4LineInfo>>{};
    for (final item in linesRaw) {
      if (item is! Map) {
        continue;
      }
      final line = HafsQcf4LineInfo.fromJson(Map<String, dynamic>.from(item));
      (linesByPage[line.pageNumber] ??= <HafsQcf4LineInfo>[]).add(line);
    }
    for (final lines in linesByPage.values) {
      lines.sort((a, b) => a.lineNumber.compareTo(b.lineNumber));
    }

    final pageByWordId = <int, int>{};
    for (final lines in linesByPage.values) {
      for (final line in lines) {
        final start = line.firstWordId;
        final end = line.lastWordId;
        if (line.lineType != HafsQcf4LineType.ayah || start == null || end == null) {
          continue;
        }
        for (var id = start; id <= end; id++) {
          pageByWordId[id] = line.pageNumber;
        }
      }
    }

    final wordsRaw = jsonDecode(utf8.decode(await _readGzip(File(HafsQcf4Pack.wordsPath)))) as Map<String, dynamic>;
    final wordsById = <int, HafsQcf4Word>{};
    final maxWordIndex = <int, int>{};
    final pageByAyah = <int, int>{};
    final firstPageBySurah = <int, int>{};
    for (final value in wordsRaw.values) {
      if (value is! Map) {
        continue;
      }
      final json = Map<String, dynamic>.from(value);
      final id = (json['id'] as num).toInt();
      final word = HafsQcf4Word.fromJson(json, page: pageByWordId[id] ?? 1);
      wordsById[word.id] = word;
      final key = _ayahKey(word.surah, word.ayah);
      final previous = maxWordIndex[key];
      if (previous == null || word.wordIndex > previous) {
        maxWordIndex[key] = word.wordIndex;
      }
      final ayahPage = pageByAyah[key];
      if (ayahPage == null || word.page < ayahPage) {
        pageByAyah[key] = word.page;
      }
      final surahPage = firstPageBySurah[word.surah];
      if (surahPage == null || word.page < surahPage) {
        firstPageBySurah[word.surah] = word.page;
      }
    }

    if (epoch != HafsQcf4Pack.epoch) {
      return;
    }
    _wordsById = wordsById;
    _linesByPage = linesByPage;
    _maxWordIndexByAyah = maxWordIndex;
    _pageByAyah = pageByAyah;
    _firstPageBySurah = firstPageBySurah;
    _pages.clear();
    _epoch = epoch;
    _ready = true;
  }

  static List<HafsQcf4Block> _buildPage(int pageNumber) {
    final lines = _linesByPage[pageNumber];
    if (lines == null || lines.isEmpty) {
      return const [];
    }
    final endWordIdByAyah = _endWordIds(lines);
    final blocks = <HafsQcf4Block>[];
    var needsPageStartSpace = true;
    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];
      switch (line.lineType) {
        case HafsQcf4LineType.surahName:
          final surah = line.surahNumber;
          if (surah != null) {
            blocks.add(HafsQcf4SurahHeaderBlock(surah));
          }
        case HafsQcf4LineType.basmallah:
          final surah = _inferBasmallahSurah(lines, i);
          if (surah != null && surah != 1 && surah != 9) {
            blocks.add(HafsQcf4BasmallahBlock(surah));
          }
        case HafsQcf4LineType.ayah:
          final start = line.firstWordId;
          final end = line.lastWordId;
          if (start == null || end == null) {
            break;
          }
          final built = _segmentsForLine(
            rangeStart: start,
            rangeEnd: end,
            endWordIdByAyah: endWordIdByAyah,
            addPageStartSpace: needsPageStartSpace,
          );
          if (built.segments.isNotEmpty) {
            blocks.add(
              HafsQcf4AyahLineBlock(
                isCentered: line.isCentered,
                segments: built.segments,
              ),
            );
          }
          if (built.didInsertPageStartSpace) {
            needsPageStartSpace = false;
          }
      }
    }
    return blocks;
  }

  static Map<int, int> _endWordIds(List<HafsQcf4LineInfo> lines) {
    final lastWordId = <int, int>{};
    for (final line in lines) {
      if (line.lineType != HafsQcf4LineType.ayah) {
        continue;
      }
      final start = line.firstWordId;
      final end = line.lastWordId;
      if (start == null || end == null) {
        continue;
      }
      for (var id = start; id <= end; id++) {
        final word = _wordsById[id];
        if (word == null) {
          continue;
        }
        lastWordId[_ayahKey(word.surah, word.ayah)] = id;
      }
    }
    final ends = <int, int>{};
    for (final entry in lastWordId.entries) {
      final key = entry.key;
      final maxIndex = _maxWordIndexByAyah[key];
      var effective = entry.value;
      if (maxIndex != null) {
        while (effective > 0) {
          final word = _wordsById[effective];
          if (word == null || _ayahKey(word.surah, word.ayah) != key || word.wordIndex != maxIndex) {
            break;
          }
          effective--;
        }
      }
      ends[key] = effective > 0 ? effective : entry.value;
    }
    return ends;
  }

  static ({List<HafsQcf4WordSegment> segments, bool didInsertPageStartSpace}) _segmentsForLine({
    required int rangeStart,
    required int rangeEnd,
    required Map<int, int> endWordIdByAyah,
    required bool addPageStartSpace,
  }) {
    final segments = <HafsQcf4WordSegment>[];
    var didInsert = false;
    var realWords = 0;
    for (var id = rangeStart; id <= rangeEnd; id++) {
      final word = _wordsById[id];
      if (word == null || word.text.isEmpty) {
        continue;
      }
      final key = _ayahKey(word.surah, word.ayah);
      final maxIndex = _maxWordIndexByAyah[key];
      if (maxIndex != null && word.wordIndex == maxIndex) {
        continue;
      }
      final isAyahEnd = endWordIdByAyah[key] == id;
      final glyphs = word.text;
      if (addPageStartSpace && realWords == 0) {
        final runes = glyphs.runes.toList(growable: false);
        final opened = '${String.fromCharCode(runes.first)}\u202F${String.fromCharCodes(runes.skip(1))}';
        didInsert = true;
        segments.add(
          HafsQcf4WordSegment(
            surahNumber: word.surah,
            ayahNumber: word.ayah,
            glyphs: opened,
            isAyahEnd: isAyahEnd,
          ),
        );
        realWords += 2;
        continue;
      }
      var placed = glyphs;
      if (addPageStartSpace && realWords == 1) {
        placed = '\u202F$placed';
        didInsert = true;
      }
      segments.add(
        HafsQcf4WordSegment(
          surahNumber: word.surah,
          ayahNumber: word.ayah,
          glyphs: placed,
          isAyahEnd: isAyahEnd,
        ),
      );
      realWords++;
    }
    return (segments: segments, didInsertPageStartSpace: didInsert);
  }

  static int? _inferBasmallahSurah(List<HafsQcf4LineInfo> lines, int index) {
    for (var i = index + 1; i < lines.length; i++) {
      final next = lines[i];
      if (next.lineType != HafsQcf4LineType.ayah) {
        continue;
      }
      final start = next.firstWordId;
      if (start == null) {
        continue;
      }
      return _wordsById[start]?.surah;
    }
    return null;
  }

  static int _ayahKey(int surah, int ayah) => surah * 1000 + ayah;

  static Future<Uint8List> _readGzip(File file) async {
    final bytes = await file.readAsBytes();
    if (bytes.length >= 2 && bytes[0] == 0x1f && bytes[1] == 0x8b) {
      return Uint8List.fromList(const GZipDecoder().decodeBytes(bytes));
    }
    return bytes;
  }
}
