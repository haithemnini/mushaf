import 'dart:async';

import 'package:flutter/foundation.dart';

// import '../fonts/mushaf_fonts.dart';
import '../models/mushaf_ayah.dart';
import '../models/mushaf_page.dart';
import '../models/mushaf_riwayah.dart';
import '../models/mushaf_riwayah_x.dart';
import '../models/mushaf_surah.dart';
import '../mushaf_bootstrap.dart';
import '../repository/mushaf_repository.dart';
import '../store/mushaf_stores.dart';

/// ChangeNotifier-based reader controller (no flutter_bloc dependency).
class MushafController extends ChangeNotifier {
  MushafController({
    MushafRepository? repository,
    MushafRiwayah riwayah = MushafRiwayah.hafs,
    MushafProgressStore? progressStore,
  })  : _repository = repository,
        _riwayah = riwayah,
        _progressStore = progressStore;

  final MushafRepository? _repository;
  MushafRiwayah _riwayah;
  final MushafProgressStore? _progressStore;

  MushafSurah? _openedSurah;
  int _page = 1;
  bool _loading = false;
  String? _error;
  List<MushafAyah> _ayahs = const [];

  MushafRepository get repository => _repository ?? Mushaf.repository;
  MushafRiwayah get riwayah => _riwayah;
  MushafSurah? get openedSurah => _openedSurah;
  int get page => _page;
  int get pageCount => _riwayah.mushafPageCount;
  bool get isLoading => _loading;
  String? get error => _error;
  List<MushafAyah> get ayahs => _ayahs;

  String get pageSurahNameAr => _ayahs.isNotEmpty
      ? _ayahs.first.surahNameAr
      : (_openedSurah?.nameAr ?? '');
  String get pageSurahNameEn => _ayahs.isNotEmpty
      ? _ayahs.first.surahNameEn
      : (_openedSurah?.nameEn ?? '');
  int get juz =>
      _ayahs.isNotEmpty ? _ayahs.first.juz : (_openedSurah?.juz.first ?? 1);

  Future<void> openSurah(MushafSurah surah, {MushafRiwayah? riwayah}) async {
    _openedSurah = surah;
    if (riwayah != null) _riwayah = riwayah;
    _loading = true;
    _error = null;
    notifyListeners();

    final pageResult =
        await repository.firstPageForSurah(surah.id, riwayah: _riwayah);
    final page = pageResult.maybeWhen(
      success: (value) => value,
      failure: (message) {
        _error = message;
        return null;
      },
    );
    if (page == null) {
      _loading = false;
      notifyListeners();
      return;
    }

    await Future.wait([
      repository.getAyahsByPage(page, riwayah: _riwayah),
      repository.prefetchMushafPages(page, riwayah: _riwayah, neighbors: true),
      _ensureFonts(page),
    ]);

    await goToPage(page);
  }

  Future<void> goToPage(int page) async {
    if (page < 1 || page > pageCount) return;

    unawaited(_ensureFonts(page));

    await repository.getMushafPage(page, riwayah: _riwayah);
    final result = await repository.getAyahsByPage(page, riwayah: _riwayah);

    result.when(
      success: (ayahs) {
        _page = page;
        _ayahs = ayahs;
        _loading = false;
        _error = null;
        notifyListeners();
        unawaited(
          _progressStore?.save(
            MushafProgress(
              riwayah: _riwayah,
              page: page,
              surahId:
                  ayahs.isNotEmpty ? ayahs.first.surahId : _openedSurah?.id,
            ),
          ),
        );
      },
      failure: (message) {
        _error = message;
        _loading = false;
        notifyListeners();
      },
    );

    unawaited(
      repository.prefetchMushafPages(page, riwayah: _riwayah, neighbors: true),
    );
  }

  Future<void> nextPage() => goToPage(_page + 1);
  Future<void> previousPage() => goToPage(_page - 1);

  List<MushafAyah> ayahsForPage(int page) =>
      repository.ayahsForPageSync(page, riwayah: _riwayah);

  MushafPage? layoutForPage(int page) =>
      repository.mushafPageSync(page, riwayah: _riwayah);

  Future<void> _ensureFonts(int page) {
    return Mushaf.ensurePageFonts(_riwayah, page, neighbors: true);
  }
}
