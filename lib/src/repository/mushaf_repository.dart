import 'dart:convert';

import 'package:flutter/services.dart';

import '../assets/mushaf_assets.dart';
import '../models/mushaf_ayah.dart';
import '../models/mushaf_ayah_search_result.dart';
import '../models/mushaf_page.dart';
import '../models/mushaf_result.dart';
import '../models/mushaf_riwayah.dart';
import '../models/mushaf_surah.dart';
import '../models/mushaf_surah_search_entry.dart';
import '../search/text_search_normalizer.dart';

/// Loads ayah corpora and mushaf page layouts from registered asset packs.
class MushafRepository {
  MushafRepository({AssetBundle? bundle}) : _bundle = bundle ?? rootBundle;

  static const int ayahSearchLimit = 200;

  final AssetBundle _bundle;

  List<MushafSurah>? _surahs;
  List<MushafSurahSearchEntry>? _searchEntries;
  final Map<MushafRiwayah, List<MushafAyah>> _ayahsByRiwayah = {};
  final Map<MushafRiwayah, Map<int, List<MushafAyah>>> _ayahsByPage = {};
  final Map<MushafRiwayah, List<MushafPage>> _pagesByRiwayah = {};
  final Map<MushafRiwayah, Map<int, MushafPage>> _splitPagesByRiwayah = {};
  final Map<MushafRiwayah, List<String>> _normalizedAyahTextByRiwayah = {};
  Future<MushafResult<List<MushafSurah>>> getSurahs() async {
    try {
      await _ensureSurahsLoaded();
      return MushafSuccess(_surahs!);
    } catch (error) {
      return MushafFailure(error.toString());
    }
  }

  Future<MushafResult<List<MushafSurahSearchEntry>>>
  getSurahSearchEntries() async {
    try {
      await _ensureSurahsLoaded();
      return MushafSuccess(_searchEntries!);
    } catch (error) {
      return MushafFailure(error.toString());
    }
  }

  Future<MushafResult<List<MushafAyah>>> getAyahsBySurah(
    int surahId, {
    MushafRiwayah riwayah = MushafRiwayah.hafs,
  }) async {
    try {
      final all = await _ensureAyahsLoaded(riwayah);
      final ayahs = all
          .where((ayah) => ayah.surahId == surahId)
          .toList(growable: false);
      return MushafSuccess(ayahs);
    } catch (error) {
      return MushafFailure(error.toString());
    }
  }

  Future<MushafResult<List<MushafAyah>>> getAyahsByPage(
    int page, {
    MushafRiwayah riwayah = MushafRiwayah.hafs,
  }) async {
    try {
      final assets = MushafAssets.require(riwayah);
      if (page < 1 || page > assets.pageCount) {
        return MushafFailure('Invalid page: $page');
      }
      final byPage = await _ensureAyahsByPage(riwayah);
      return MushafSuccess(byPage[page] ?? const []);
    } catch (error) {
      return MushafFailure(error.toString());
    }
  }

  Future<MushafResult<List<MushafAyah>>> getAyahs({
    MushafRiwayah riwayah = MushafRiwayah.hafs,
  }) async {
    try {
      final all = await _ensureAyahsLoaded(riwayah);
      return MushafSuccess(all);
    } catch (error) {
      return MushafFailure(error.toString());
    }
  }

  Future<MushafResult<int>> firstPageForSurah(
    int surahId, {
    MushafRiwayah riwayah = MushafRiwayah.hafs,
  }) async {
    try {
      final all = await _ensureAyahsLoaded(riwayah);
      for (final ayah in all) {
        if (ayah.surahId == surahId) {
          return MushafSuccess(ayah.page);
        }
      }
      return MushafFailure('Surah not found: $surahId');
    } catch (error) {
      return MushafFailure(error.toString());
    }
  }

  /// Searches all ayahs for a phrase (normalized), using normalized text.
  ///
  /// Prefers [MushafAyah.textEmlaey] when available; otherwise falls back to
  /// [MushafAyah.text]. Results are capped at [ayahSearchLimit].
  Future<MushafResult<MushafAyahSearchResult>> searchAyahs(
    String query, {
    MushafRiwayah riwayah = MushafRiwayah.hafs,
    int limit = ayahSearchLimit,
  }) async {
    try {
      final normalizedQuery = TextSearchNormalizer.normalize(query);
      if (normalizedQuery.isEmpty) {
        return MushafSuccess(
          MushafAyahSearchResult(ayahs: const [], totalCount: 0, query: ''),
        );
      }

      final all = await _ensureAyahsLoaded(riwayah);
      final haystacks = await _ensureNormalizedAyahTexts(riwayah);
      final matches = <MushafAyah>[];
      var total = 0;

      for (var i = 0; i < all.length; i++) {
        if (!haystacks[i].contains(normalizedQuery)) {
          continue;
        }
        total++;
        if (matches.length < limit) {
          matches.add(all[i]);
        }
      }

      return MushafSuccess(
        MushafAyahSearchResult(
          ayahs: matches,
          totalCount: total,
          query: normalizedQuery,
        ),
      );
    } catch (error) {
      return MushafFailure(error.toString());
    }
  }

  List<MushafAyah> ayahsForPageSync(
    int page, {
    MushafRiwayah riwayah = MushafRiwayah.hafs,
  }) {
    return _ayahsByPage[riwayah]?[page] ?? const [];
  }

  Future<MushafResult<MushafPage>> getMushafPage(
    int page, {
    MushafRiwayah riwayah = MushafRiwayah.hafs,
  }) async {
    try {
      final assets = MushafAssets.require(riwayah);
      if (page < 1 || page > assets.pageCount) {
        return MushafFailure('Invalid page: $page');
      }
      final mushafPage = await _loadMushafPage(page, riwayah);
      return MushafSuccess(mushafPage);
    } catch (error) {
      return MushafFailure(error.toString());
    }
  }

  Future<void> prefetchMushafPages(
    int page, {
    MushafRiwayah riwayah = MushafRiwayah.hafs,
    bool neighbors = true,
    int radius = 1,
  }) async {
    final assets = MushafAssets.require(riwayah);
    final pages = <int>{page};
    if (neighbors) {
      final extent = radius < 1 ? 1 : radius;
      for (var i = 1; i <= extent; i++) {
        if (page - i >= 1) {
          pages.add(page - i);
        }
        if (page + i <= assets.pageCount) {
          pages.add(page + i);
        }
      }
    }
    await Future.wait([for (final p in pages) _loadMushafPage(p, riwayah)]);
  }

  MushafPage? mushafPageSync(
    int page, {
    MushafRiwayah riwayah = MushafRiwayah.hafs,
  }) {
    final assets = MushafAssets.maybe(riwayah);
    if (assets == null || page < 1 || page > assets.pageCount) return null;
    if (assets.usesSplitPages) {
      return _splitPagesByRiwayah[riwayah]?[page];
    }
    final pages = _pagesByRiwayah[riwayah];
    if (pages == null) return null;
    return pages[page - 1];
  }

  Future<MushafPage> _loadMushafPage(int page, MushafRiwayah riwayah) async {
    final assets = MushafAssets.require(riwayah);
    if (assets.usesSplitPages) {
      final byPage = _splitPagesByRiwayah.putIfAbsent(riwayah, () => {});
      final cached = byPage[page];
      if (cached != null) return cached;

      final raw = await assets.loadString(_bundle, assets.resolvePage(page));
      final mushafPage = MushafPage.fromJson(
        json.decode(raw) as Map<String, dynamic>,
      );
      byPage[page] = mushafPage;
      return mushafPage;
    }

    final pages = await _ensureMushafPages(riwayah);
    return pages[page - 1];
  }

  Future<List<MushafPage>> _ensureMushafPages(MushafRiwayah riwayah) async {
    final assets = MushafAssets.require(riwayah);
    if (assets.usesSplitPages) {
      final pages = <MushafPage>[];
      for (var page = 1; page <= assets.pageCount; page++) {
        pages.add(await _loadMushafPage(page, riwayah));
      }
      return pages;
    }

    final cached = _pagesByRiwayah[riwayah];
    if (cached != null) return cached;

    final raw = await assets.loadString(_bundle, assets.resolvePages());
    final list = json.decode(raw) as List<dynamic>;
    final pages = list
        .map((e) => MushafPage.fromJson(e as Map<String, dynamic>))
        .toList(growable: false);
    _pagesByRiwayah[riwayah] = pages;
    return pages;
  }

  Future<void> _ensureSurahsLoaded() async {
    if (_surahs != null && _searchEntries != null) {
      return;
    }

    final raw = await _bundle.loadString(MushafAssets.surahsPath());
    final list = json.decode(raw) as List<dynamic>;
    _surahs = list
        .map((item) => MushafSurah.fromJson(item as Map<String, dynamic>))
        .toList();

    _searchEntries = _surahs!
        .map(
          (surah) => MushafSurahSearchEntry(
            surah: surah,
            normalizedNameAr: TextSearchNormalizer.normalize(surah.nameAr),
            normalizedNameEn: TextSearchNormalizer.normalize(surah.nameEn),
          ),
        )
        .toList();
  }

  Future<List<MushafAyah>> _ensureAyahsLoaded(MushafRiwayah riwayah) async {
    final cached = _ayahsByRiwayah[riwayah];
    if (cached != null) {
      return cached;
    }

    final assets = MushafAssets.require(riwayah);
    final raw = await assets.loadString(_bundle, assets.resolveAyahs());
    final list = json.decode(raw) as List<dynamic>;
    final ayahs = <MushafAyah>[];
    for (final item in list) {
      ayahs.add(
        MushafAyah.fromJson(item as Map<String, dynamic>, riwayah: riwayah),
      );
    }

    _ayahsByRiwayah[riwayah] = ayahs;
    return ayahs;
  }

  Future<List<String>> _ensureNormalizedAyahTexts(MushafRiwayah riwayah) async {
    final cached = _normalizedAyahTextByRiwayah[riwayah];
    if (cached != null) {
      return cached;
    }

    final ayahs = await _ensureAyahsLoaded(riwayah);
    final normalized = List<String>.generate(ayahs.length, (index) {
      final ayah = ayahs[index];
      final source = ayah.textEmlaey?.trim().isNotEmpty == true
          ? ayah.textEmlaey!
          : ayah.text;
      return TextSearchNormalizer.normalize(source);
    }, growable: false);
    _normalizedAyahTextByRiwayah[riwayah] = normalized;
    return normalized;
  }

  Future<Map<int, List<MushafAyah>>> _ensureAyahsByPage(
    MushafRiwayah riwayah,
  ) async {
    final cached = _ayahsByPage[riwayah];
    if (cached != null) {
      return cached;
    }

    final assets = MushafAssets.require(riwayah);
    final raw = await assets.loadString(_bundle, assets.resolveAyahs());
    final list = json.decode(raw) as List<dynamic>;
    final map = <int, List<MushafAyah>>{};
    for (final item in list) {
      final mapJson = item as Map<String, dynamic>;
      final ayah = MushafAyah.fromJson(mapJson, riwayah: riwayah);
      final pages = MushafAyah.pagesForJson(mapJson, riwayah: riwayah);
      for (final page in pages) {
        (map[page] ??= <MushafAyah>[]).add(ayah);
      }
    }
    _ayahsByPage[riwayah] = map;
    return map;
  }

  void evictRiwayah(MushafRiwayah riwayah) {
    _ayahsByRiwayah.remove(riwayah);
    _ayahsByPage.remove(riwayah);
    _pagesByRiwayah.remove(riwayah);
    _splitPagesByRiwayah.remove(riwayah);
    _normalizedAyahTextByRiwayah.remove(riwayah);
  }
}
