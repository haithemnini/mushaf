import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../assets/mushaf_assets.dart';
import '../hafs/hafs_qcf4_fonts.dart';
import '../hafs/hafs_qcf4_pack.dart';
import '../hafs/hafs_qcf4_page_view.dart';
import '../hafs/hafs_qcf4_store.dart';
import '../models/mushaf_ayah.dart';
import '../models/mushaf_ayah_ref.dart';
import '../models/mushaf_riwayah.dart';
import '../models/mushaf_riwayah_x.dart';
import '../mushaf_bootstrap.dart';
import '../store/mushaf_stores.dart';
import '../style/mushaf_style.dart';
import '../widgets/mushaf_page_view.dart';
import 'mushaf_book_page_frame.dart';
import 'mushaf_page_strip.dart';
import 'mushaf_reader_chrome.dart';
import 'mushaf_reading_settings.dart';
import 'mushaf_settings_sheet.dart';

/// Drives [MushafReader] page turns and ayah highlight.
class MushafReaderController extends ChangeNotifier {
  MushafReaderController({
    this.riwayah = MushafRiwayah.hafs,
    int initialPage = 1,
  }) : page = initialPage < 1 ? 1 : initialPage;

  final MushafRiwayah riwayah;
  int page;
  MushafAyahRef? highlightedAyah;

  int get pageCount {
    if (riwayah == MushafRiwayah.hafs) {
      return HafsQcf4Store.pageCount;
    }
    return riwayah.mushafPageCount;
  }

  void goToPage(int target) {
    final next = target.clamp(1, pageCount);
    if (next == page) {
      return;
    }
    page = next;
    notifyListeners();
  }

  /// Opens the page that contains the ayah and highlights it.
  Future<bool> goToAyah({required int surahId, required int ayahNumber}) async {
    final target = await resolveMushafAyahPage(
      riwayah: riwayah,
      surahId: surahId,
      ayahNumber: ayahNumber,
    );
    if (target == null) {
      return false;
    }
    highlightedAyah = MushafAyahRef(surahId: surahId, ayahNumber: ayahNumber);
    page = target.clamp(1, pageCount);
    notifyListeners();
    return true;
  }

  void selectAyah(MushafAyahRef ref) {
    highlightedAyah = ref;
    notifyListeners();
  }

  void clearHighlight() {
    if (highlightedAyah == null) {
      return;
    }
    highlightedAyah = null;
    notifyListeners();
  }
}

/// Page of a Hafs QCF4 or Warsh ayah, after the matching pack is registered.
Future<int?> resolveMushafAyahPage({
  required MushafRiwayah riwayah,
  required int surahId,
  required int ayahNumber,
}) async {
  if (riwayah == MushafRiwayah.hafs) {
    await HafsQcf4Store.ensureReady();
    return HafsQcf4Store.pageForAyah(surahId, ayahNumber);
  }
  final result = await Mushaf.repository.getAyahsBySurah(surahId, riwayah: riwayah);
  return result.when(
    success: (ayahs) {
      for (final ayah in ayahs) {
        if (ayah.ayahNumber == ayahNumber) {
          return ayah.page;
        }
      }
      return null;
    },
    failure: (_) => null,
  );
}

/// First page of a surah for the active riwayah.
Future<int?> resolveMushafSurahPage({
  required MushafRiwayah riwayah,
  required int surahId,
}) async {
  if (riwayah == MushafRiwayah.hafs) {
    await HafsQcf4Store.ensureReady();
    return HafsQcf4Store.firstPageForSurah(surahId);
  }
  final result = await Mushaf.repository.firstPageForSurah(surahId, riwayah: riwayah);
  return result.when(success: (page) => page, failure: (_) => null);
}

/// Hafs QCF4 and Warsh reader: ayah selection, page navigation, fullscreen, and book layout.
class MushafReader extends StatefulWidget {
  const MushafReader({
    super.key,
    required this.riwayah,
    this.initialPage = 1,
    this.controller,
    this.settings = const MushafReadingSettings(),
    this.onSettingsChanged,
    this.onAyahLongPress,
    this.onPageChanged,
    this.bookmarkedAyahs = const {},
    this.playingAyah,
    this.completedAyahs = const {},
    this.onBack,
  });

  final MushafRiwayah riwayah;
  final int initialPage;
  final MushafReaderController? controller;
  final MushafReadingSettings settings;
  final ValueChanged<MushafReadingSettings>? onSettingsChanged;
  final ValueChanged<MushafAyahRef>? onAyahLongPress;
  final ValueChanged<int>? onPageChanged;
  final Map<MushafAyahRef, MushafBookmarkColor> bookmarkedAyahs;
  final MushafAyahRef? playingAyah;
  final Set<MushafAyahRef> completedAyahs;
  final VoidCallback? onBack;

  @override
  State<MushafReader> createState() => _MushafReaderState();
}

class _MushafReaderState extends State<MushafReader> {
  static const _mushafBlack = Color(0xFF0C0A08);
  static const _nearJump = 8;

  late final MushafReaderController _controller;
  late final bool _ownsController;
  late MushafReadingSettings _settings;
  PageController? _pageController;
  String? _layoutToken;
  var _ready = false;
  String? _error;
  var _chromeVisible = false;
  var _ignoreController = false;
  int? _previousPage;
  var _immersive = false;
  var _programmatic = false;
  int? _reportedPage;
  Map<int, String> _surahNames = const {};
  Map<int, String> _surahStarts = const {};

  @override
  void initState() {
    super.initState();
    _ownsController = widget.controller == null;
    _controller = widget.controller ??
        MushafReaderController(riwayah: widget.riwayah, initialPage: widget.initialPage);
    _settings = widget.settings;
    _controller.addListener(_onController);
    _prepare();
  }

  @override
  void didUpdateWidget(covariant MushafReader oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.settings != widget.settings) {
      _settings = widget.settings;
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onController);
    if (_ownsController) {
      _controller.dispose();
    }
    _pageController?.dispose();
    if (_immersive) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    }
    super.dispose();
  }

  Future<void> _prepare() async {
    try {
      if (!Mushaf.isInitialized) {
        await Mushaf.initialize();
      }
      final surahs = await Mushaf.repository.getSurahs();
      final names = surahs.when(
        success: (list) => {for (final surah in list) surah.id: surah.nameAr},
        failure: (message) => throw StateError(message),
      );
      if (widget.riwayah == MushafRiwayah.hafs) {
        if (!HafsQcf4Pack.isActive) {
          throw StateError('Call registerMushafHafsQcf4 before opening Hafs.');
        }
        await HafsQcf4Store.ensureReady();
        await HafsQcf4Fonts.ensurePage(_controller.page, neighbors: true);
      } else {
        if (MushafAssets.maybe(MushafRiwayah.warsh) == null) {
          throw StateError('Call registerMushafWarsh before opening Warsh.');
        }
        await Mushaf.ensureFontsLoaded();
        final loaded = await Mushaf.repository.getAyahsByPage(1, riwayah: widget.riwayah);
        loaded.when(success: (_) {}, failure: (message) => throw StateError(message));
      }
      if (!mounted) {
        return;
      }
      setState(() {
        _surahNames = names;
        _surahStarts = _indexSurahStarts(names);
        _ready = true;
        _error = null;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = error.toString();
        _ready = false;
      });
    }
  }

  Map<int, String> _indexSurahStarts(Map<int, String> names) {
    final starts = <int, String>{};
    if (widget.riwayah == MushafRiwayah.hafs) {
      for (final entry in names.entries) {
        final page = HafsQcf4Store.pageForAyah(entry.key, 1);
        if (page != null) {
          starts[page] = entry.value;
        }
      }
      return starts;
    }
    final count = _controller.pageCount;
    for (var page = 1; page <= count; page++) {
      final ayahs = Mushaf.repository.ayahsForPageSync(page, riwayah: widget.riwayah);
      if (ayahs.isEmpty || ayahs.first.ayahNumber != 1) {
        continue;
      }
      final name = ayahs.first.surahNameAr;
      if (name.isNotEmpty) {
        starts[page] = name;
      }
    }
    return starts;
  }

  void _onController() {
    if (!mounted || _ignoreController || _programmatic) {
      return;
    }
    final page = _controller.page;
    final controller = _pageController;
    final needsJump = controller != null && controller.hasClients && (controller.page?.round() ?? -1) != _indexForPage(page);
    setState(() {});
    if (_reportedPage != page) {
      _reportedPage = page;
      widget.onPageChanged?.call(page);
    }
    if (needsJump) {
      _jumpTo(page);
    }
  }

  void _syncStatusBar(bool fullscreen) {
    if (_immersive == fullscreen) {
      return;
    }
    _immersive = fullscreen;
    SystemChrome.setEnabledSystemUIMode(
      fullscreen ? SystemUiMode.immersiveSticky : SystemUiMode.edgeToEdge,
    );
  }

  bool _spreadFor(Size size) {
    return _settings.scrollDirection == MushafScrollDirection.horizontal &&
        _settings.landscapeLayout == MushafLandscapeLayout.doublePage &&
        mushafSpreadWindow(size);
  }

  int _indexForPage(int page) {
    final size = MediaQuery.sizeOf(context);
    if (_spreadFor(size)) {
      return (page - 1) ~/ 2;
    }
    return page - 1;
  }

  int _pageForIndex(int index) {
    final size = MediaQuery.sizeOf(context);
    if (_spreadFor(size)) {
      return index * 2 + 1;
    }
    return index + 1;
  }

  void _bindController(bool spread, bool horizontal) {
    final token = '$horizontal-$spread-${widget.riwayah.name}';
    if (_pageController != null && _layoutToken == token) {
      return;
    }
    final previous = _pageController;
    final index = spread ? (_controller.page - 1) ~/ 2 : _controller.page - 1;
    _pageController = PageController(initialPage: index < 0 ? 0 : index);
    _layoutToken = token;
    if (previous != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => previous.dispose());
    }
  }

  Future<void> _jumpTo(int target) async {
    final controller = _pageController;
    if (controller == null || !controller.hasClients) {
      return;
    }
    final from = _pageForIndex(controller.page?.round() ?? 0);
    if ((target - from).abs() > 1) {
      _previousPage = from;
    }
    final index = _indexForPage(target.clamp(1, _controller.pageCount));
    _programmatic = true;
    try {
      if ((target - from).abs() <= _nearJump) {
        await controller.animateToPage(
          index,
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOutCubic,
        );
      } else {
        controller.jumpToPage(index);
      }
    } finally {
      _programmatic = false;
    }
    _warm(target);
  }

  void _onPageChanged(int index) {
    if (_programmatic) {
      return;
    }
    final page = _pageForIndex(index);
    if (page == _controller.page) {
      return;
    }
    _ignoreController = true;
    _controller.page = page;
    _controller.highlightedAyah = null;
    _ignoreController = false;
    _chromeVisible = false;
    _reportedPage = page;
    widget.onPageChanged?.call(page);
    _warm(page);
    setState(() {});
  }

  void _warm(int page) {
    if (widget.riwayah == MushafRiwayah.hafs) {
      HafsQcf4Fonts.ensurePage(page, neighbors: true, radius: 2);
      return;
    }
    Mushaf.repository.prefetchMushafPages(page, riwayah: widget.riwayah, neighbors: true, radius: 2);
    Mushaf.ensurePageFonts(widget.riwayah, page, neighbors: true);
  }

  String _surahNameFor(int page) {
    var name = '';
    var best = 0;
    for (final entry in _surahStarts.entries) {
      if (entry.key <= page && entry.key >= best) {
        best = entry.key;
        name = entry.value;
      }
    }
    return name;
  }

  int _juzFor(int page) {
    if (widget.riwayah == MushafRiwayah.hafs) {
      return hafsJuzForPage(page);
    }
    final ayahs = Mushaf.repository.ayahsForPageSync(page, riwayah: widget.riwayah);
    if (ayahs.isEmpty) {
      return 1;
    }
    return ayahs.first.juz;
  }

  void _onLongPress(MushafAyahRef ref) {
    HapticFeedback.mediumImpact();
    _controller.selectAyah(ref);
    setState(() => _chromeVisible = false);
    widget.onAyahLongPress?.call(ref);
  }

  Future<void> _openSettings() async {
    await MushafSettingsSheet.show(
      context: context,
      settings: _settings,
      showTajweed: widget.riwayah == MushafRiwayah.hafs,
      onChanged: (next) {
        setState(() => _settings = next);
        widget.onSettingsChanged?.call(next);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final blackReading = _settings.blackBackground && theme.brightness == Brightness.dark;
    final canvas = blackReading ? _mushafBlack : theme.scaffoldBackgroundColor;
    final fullscreen = _settings.pageDesign == MushafPageDesign.fullscreen;
    _syncStatusBar(fullscreen);

    if (_error != null) {
      return ColoredBox(
        color: canvas,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(_error!, textAlign: TextAlign.center),
          ),
        ),
      );
    }
    if (!_ready) {
      return ColoredBox(
        color: canvas,
        child: Center(child: CircularProgressIndicator(color: colors.primary)),
      );
    }

    final size = MediaQuery.sizeOf(context);
    final horizontal = _settings.scrollDirection == MushafScrollDirection.horizontal;
    final spread = _spreadFor(size);
    _bindController(spread, horizontal);
    final pageCount = _controller.pageCount;
    final style = MushafStyle.fromTheme(context, useArabicNames: true).copyWith(
      background: blackReading ? _mushafBlack : null,
    );
    final currentPage = _controller.page;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: theme.brightness == Brightness.light ? Brightness.dark : Brightness.light,
      ),
      child: ColoredBox(
        color: canvas,
        child: Stack(
          children: [
            PageView.builder(
              controller: _pageController,
              scrollDirection: horizontal ? Axis.horizontal : Axis.vertical,
              allowImplicitScrolling: true,
              pageSnapping: horizontal,
              physics: horizontal
                  ? const _HafsPageScrollPhysics(parent: ClampingScrollPhysics())
                  : const ClampingScrollPhysics(),
              itemCount: spread ? (pageCount + 1) ~/ 2 : pageCount,
              onPageChanged: _onPageChanged,
              itemBuilder: (context, index) {
                final leading = spread ? index * 2 + 1 : index + 1;
                final facing = leading + 1;
                Widget framed(int pageNumber) {
                  return MushafBookPageFrame(
                    enabled: _settings.pageDesign == MushafPageDesign.book,
                    pageNumber: pageNumber,
                    sideEdges: horizontal,
                    joined: horizontal,
                    background: style.background,
                    child: _ReaderPage(
                      page: pageNumber,
                      riwayah: widget.riwayah,
                      style: style,
                      tajweed: _settings.tajweedEnabled && widget.riwayah == MushafRiwayah.hafs,
                      surahNames: _surahNames,
                      highlightedAyah: _controller.highlightedAyah,
                      playingAyah: widget.playingAyah,
                      completedAyahs: widget.completedAyahs,
                      bookmarkedAyahs: widget.bookmarkedAyahs,
                      onToggleChrome: () {
                        _controller.clearHighlight();
                        setState(() => _chromeVisible = !_chromeVisible);
                      },
                      onAyahLongPress: _onLongPress,
                    ),
                  );
                }

                if (!spread) {
                  return framed(leading);
                }
                return Row(
                  textDirection: TextDirection.rtl,
                  children: [
                    Expanded(child: framed(leading)),
                    Expanded(
                      child: facing <= pageCount
                          ? framed(facing)
                          : _settings.pageDesign == MushafPageDesign.book
                              ? ColoredBox(color: colors.primaryContainer)
                              : const SizedBox.expand(),
                    ),
                  ],
                );
              },
            ),
            MushafReaderChrome(
              visible: _chromeVisible,
              surahName: _surahNameFor(currentPage),
              juz: _juzFor(currentPage),
              page: currentPage,
              onBack: widget.onBack ?? () => Navigator.maybePop(context),
              onSettings: _openSettings,
            ),
            if (fullscreen && _settings.showClock && !_chromeVisible)
              Positioned(
                top: MediaQuery.viewPaddingOf(context).top,
                left: 0,
                right: 0,
                child: const IgnorePointer(child: Center(child: MushafReaderClock())),
              ),
            MushafPageStrip(
              visible: _chromeVisible,
              page: currentPage,
              pageCount: pageCount,
              mode: _settings.pageNavMode,
              previousPage: _previousPage,
              surahLabelForPage: (page) => _surahStarts[page],
              onPageSelected: (target) {
                if ((target - currentPage).abs() > 1) {
                  _previousPage = currentPage;
                }
                _controller.goToPage(target);
              },
              onReturnToPrevious: () {
                final previous = _previousPage;
                if (previous == null) {
                  return;
                }
                _previousPage = null;
                _controller.goToPage(previous);
              },
              onModeChanged: (mode) {
                final next = _settings.copyWith(pageNavMode: mode);
                setState(() => _settings = next);
                widget.onSettingsChanged?.call(next);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _ReaderPage extends StatelessWidget {
  const _ReaderPage({
    required this.page,
    required this.riwayah,
    required this.style,
    required this.tajweed,
    required this.surahNames,
    required this.highlightedAyah,
    required this.playingAyah,
    required this.completedAyahs,
    required this.bookmarkedAyahs,
    required this.onToggleChrome,
    required this.onAyahLongPress,
  });

  final int page;
  final MushafRiwayah riwayah;
  final MushafStyle style;
  final bool tajweed;
  final Map<int, String> surahNames;
  final MushafAyahRef? highlightedAyah;
  final MushafAyahRef? playingAyah;
  final Set<MushafAyahRef> completedAyahs;
  final Map<MushafAyahRef, MushafBookmarkColor> bookmarkedAyahs;
  final VoidCallback onToggleChrome;
  final ValueChanged<MushafAyahRef> onAyahLongPress;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onToggleChrome,
      child: riwayah == MushafRiwayah.hafs
          ? HafsQcf4PageView(
              page: page,
              fontScale: style.fontScale,
              tajweed: tajweed,
              style: style,
              surahNames: surahNames,
              highlightedAyah: highlightedAyah,
              playingAyah: playingAyah,
              completedAyahs: completedAyahs,
              bookmarkedAyahs: bookmarkedAyahs,
              onAyahLongPress: onAyahLongPress,
            )
          : _WarshPage(
              page: page,
              style: style,
              highlightedAyah: highlightedAyah,
              playingAyah: playingAyah,
              completedAyahs: completedAyahs,
              bookmarkedAyahs: bookmarkedAyahs,
              onToggleChrome: onToggleChrome,
              onAyahLongPress: onAyahLongPress,
            ),
    );
  }
}

class _WarshPage extends StatefulWidget {
  const _WarshPage({
    required this.page,
    required this.style,
    required this.highlightedAyah,
    required this.playingAyah,
    required this.completedAyahs,
    required this.bookmarkedAyahs,
    required this.onToggleChrome,
    required this.onAyahLongPress,
  });

  final int page;
  final MushafStyle style;
  final MushafAyahRef? highlightedAyah;
  final MushafAyahRef? playingAyah;
  final Set<MushafAyahRef> completedAyahs;
  final Map<MushafAyahRef, MushafBookmarkColor> bookmarkedAyahs;
  final VoidCallback onToggleChrome;
  final ValueChanged<MushafAyahRef> onAyahLongPress;

  @override
  State<_WarshPage> createState() => _WarshPageState();
}

class _WarshPageState extends State<_WarshPage> {
  List<MushafAyah>? _ayahs;
  var _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant _WarshPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.page != widget.page) {
      _load();
    }
  }

  Future<void> _load() async {
    final page = widget.page;
    await Future.wait([
      Mushaf.repository.getAyahsByPage(page, riwayah: MushafRiwayah.warsh),
      Mushaf.repository.getMushafPage(page, riwayah: MushafRiwayah.warsh),
      Mushaf.ensurePageFonts(MushafRiwayah.warsh, page),
    ]);
    if (!mounted || page != widget.page) {
      return;
    }
    setState(() {
      _ayahs = Mushaf.repository.ayahsForPageSync(page, riwayah: MushafRiwayah.warsh);
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading || _ayahs == null) {
      return ColoredBox(
        color: widget.style.background,
        child: Center(child: CircularProgressIndicator(color: widget.style.accent)),
      );
    }
    final ayahs = _ayahs!;
    final first = ayahs.isNotEmpty ? ayahs.first : null;
    return MushafPageView(
      page: widget.page,
      ayahs: ayahs,
      riwayah: MushafRiwayah.warsh,
      fontScale: widget.style.fontScale,
      surahNameAr: first?.surahNameAr ?? '',
      surahNameEn: first?.surahNameEn ?? '',
      juz: first?.juz ?? 1,
      layoutPage: Mushaf.repository.mushafPageSync(widget.page, riwayah: MushafRiwayah.warsh),
      style: widget.style,
      highlightedAyah: widget.highlightedAyah,
      playingAyah: widget.playingAyah,
      completedAyahs: widget.completedAyahs,
      bookmarkedAyahs: widget.bookmarkedAyahs,
      onAyahTap: (_) => widget.onToggleChrome(),
      onAyahLongPress: widget.onAyahLongPress,
    );
  }
}

class _HafsPageScrollPhysics extends PageScrollPhysics {
  const _HafsPageScrollPhysics({super.parent});

  static final SpringDescription _slide = SpringDescription.withDampingRatio(
    mass: 0.85,
    stiffness: 58,
    ratio: 1.05,
  );

  @override
  SpringDescription get spring => _slide;

  @override
  _HafsPageScrollPhysics applyTo(ScrollPhysics? ancestor) {
    return _HafsPageScrollPhysics(parent: buildParent(ancestor));
  }
}
