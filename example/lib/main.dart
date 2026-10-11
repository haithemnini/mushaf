import 'package:flutter/material.dart';
import 'package:mushaf/mushaf.dart';

/// Example host. Pass extracted pack roots via dart-define:
///
/// ```bash
/// flutter run --dart-define=MUSHAF_HAFS_ROOT=/path/to/hafs \
///   --dart-define=MUSHAF_WARSH_ROOT=/path/to/warsh
/// ```
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  const hafsRoot = String.fromEnvironment('MUSHAF_HAFS_ROOT');
  const warshRoot = String.fromEnvironment('MUSHAF_WARSH_ROOT');
  if (hafsRoot.isNotEmpty) {
    registerMushafHafsQcf4(localRoot: hafsRoot);
  }
  if (warshRoot.isNotEmpty) {
    registerMushafWarsh(localRoot: warshRoot);
  }

  await Mushaf.initialize();
  if (warshRoot.isNotEmpty) {
    await Mushaf.ensureFontsLoaded();
  }
  runApp(const MushafExampleApp());
}

class MushafExampleApp extends StatefulWidget {
  const MushafExampleApp({super.key});

  @override
  State<MushafExampleApp> createState() => _MushafExampleAppState();
}

class _MushafExampleAppState extends State<MushafExampleApp> {
  ThemeMode _themeMode = ThemeMode.light;
  MushafReadingSettings _settings = const MushafReadingSettings();
  final Map<MushafAyahRef, MushafBookmarkColor> _bookmarks = {};

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      themeMode: _themeMode,
      theme: _theme(Brightness.light),
      darkTheme: _theme(Brightness.dark),
      builder: (context, child) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: child ?? const SizedBox.shrink(),
        );
      },
      home: _Home(
        themeMode: _themeMode,
        onThemeMode: (mode) => setState(() => _themeMode = mode),
        settings: _settings,
        onSettings: (next) => setState(() => _settings = next),
        bookmarks: _bookmarks,
        onBookmarks: () => setState(() {}),
      ),
    );
  }

  ThemeData _theme(Brightness brightness) {
    final dark = brightness == Brightness.dark;
    final scheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFFC9953E),
      brightness: brightness,
    ).copyWith(
      primary: dark ? const Color(0xFFD7A957) : const Color(0xFFC9953E),
      surface: dark ? const Color(0xFF241A13) : const Color(0xFFFFFFFF),
      onSurface: dark ? const Color(0xFFF5EEE5) : const Color(0xFF2B211B),
      onSurfaceVariant: dark ? const Color(0xFFC9B8A5) : const Color(0xFF806F60),
      outlineVariant: dark ? const Color(0xFF34261B) : const Color(0xFFE7D8C2),
    );
    return ThemeData(
      colorScheme: scheme,
      scaffoldBackgroundColor: dark ? const Color(0xFF1C140F) : const Color(0xFFFCFAF5),
      useMaterial3: true,
    );
  }
}

class _Home extends StatefulWidget {
  const _Home({
    required this.themeMode,
    required this.onThemeMode,
    required this.settings,
    required this.onSettings,
    required this.bookmarks,
    required this.onBookmarks,
  });

  final ThemeMode themeMode;
  final ValueChanged<ThemeMode> onThemeMode;
  final MushafReadingSettings settings;
  final ValueChanged<MushafReadingSettings> onSettings;
  final Map<MushafAyahRef, MushafBookmarkColor> bookmarks;
  final VoidCallback onBookmarks;

  @override
  State<_Home> createState() => _HomeState();
}

class _HomeState extends State<_Home> {
  late MushafRiwayah _riwayah;

  @override
  void initState() {
    super.initState();
    if (HafsQcf4Pack.isActive) {
      _riwayah = MushafRiwayah.hafs;
    } else if (MushafAssets.isRegistered(MushafRiwayah.warsh)) {
      _riwayah = MushafRiwayah.warsh;
    } else {
      _riwayah = MushafRiwayah.hafs;
    }
  }

  bool get _hafs => HafsQcf4Pack.isActive;
  bool get _warsh => MushafAssets.isRegistered(MushafRiwayah.warsh);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final textTheme = theme.textTheme;
    if (!_hafs && !_warsh) {
      return Scaffold(
        appBar: AppBar(title: const Text('المصحف')),
        body: const Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'لم تُسجَّل نسخة.\n'
            'فك ضغط حزمة حفص أو ورش ثم شغّل المثال مع\n'
            'MUSHAF_HAFS_ROOT و MUSHAF_WARSH_ROOT.',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('المصحف'),
        actions: [
          IconButton(
            tooltip: widget.themeMode == ThemeMode.dark ? 'الوضع النهاري' : 'الوضع الليلي',
            onPressed: () {
              widget.onThemeMode(
                widget.themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark,
              );
            },
            icon: Icon(widget.themeMode == ThemeMode.dark ? Icons.light_mode_outlined : Icons.dark_mode_outlined),
          ),
        ],
      ),
      body: Column(
        children: [
          if (_hafs && _warsh)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: SegmentedButton<MushafRiwayah>(
                segments: const [
                  ButtonSegment(value: MushafRiwayah.hafs, label: Text('حفص')),
                  ButtonSegment(value: MushafRiwayah.warsh, label: Text('ورش')),
                ],
                selected: {_riwayah},
                onSelectionChanged: (value) => setState(() => _riwayah = value.first),
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Text(
              _riwayah == MushafRiwayah.hafs ? 'حفص عن عاصم · ٦٠٤ صفحة' : 'ورش عن نافع · ٥٩٩ صفحة',
              style: textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant),
            ),
          ),
          Expanded(
            child: MushafSurahList(
              style: MushafStyle.fromTheme(context, useArabicNames: true),
              searchHint: 'ابحث عن سورة…',
              emptyLabel: 'لا نتائج',
              onSurahTap: (surah) => _open(surah),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _open(MushafSurah surah) async {
    final page = await resolveMushafSurahPage(riwayah: _riwayah, surahId: surah.id);
    if (!mounted) {
      return;
    }
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => _ReaderScreen(
          riwayah: _riwayah,
          initialPage: page ?? 1,
          settings: widget.settings,
          onSettings: widget.onSettings,
          bookmarks: widget.bookmarks,
          onBookmarks: widget.onBookmarks,
        ),
      ),
    );
  }
}

class _ReaderScreen extends StatefulWidget {
  const _ReaderScreen({
    required this.riwayah,
    required this.initialPage,
    required this.settings,
    required this.onSettings,
    required this.bookmarks,
    required this.onBookmarks,
  });

  final MushafRiwayah riwayah;
  final int initialPage;
  final MushafReadingSettings settings;
  final ValueChanged<MushafReadingSettings> onSettings;
  final Map<MushafAyahRef, MushafBookmarkColor> bookmarks;
  final VoidCallback onBookmarks;

  @override
  State<_ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends State<_ReaderScreen> {
  late final MushafReaderController _controller;

  @override
  void initState() {
    super.initState();
    _controller = MushafReaderController(
      riwayah: widget.riwayah,
      initialPage: widget.initialPage,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MushafReader(
      riwayah: widget.riwayah,
      initialPage: widget.initialPage,
      controller: _controller,
      settings: widget.settings,
      onSettingsChanged: widget.onSettings,
      bookmarkedAyahs: widget.bookmarks,
      onBack: () => Navigator.of(context).pop(),
      onAyahLongPress: (ref) {
        final messenger = ScaffoldMessenger.of(context);
        messenger.hideCurrentSnackBar();
        messenger.showSnackBar(
          SnackBar(
            content: Text('سورة ${ref.surahId} · آية ${ref.ayahNumber}'),
            action: SnackBarAction(
              label: widget.bookmarks.containsKey(ref) ? 'إزالة' : 'إشارة',
              onPressed: () {
                if (widget.bookmarks.containsKey(ref)) {
                  widget.bookmarks.remove(ref);
                } else {
                  widget.bookmarks[ref] = MushafBookmarkColor.yellow;
                }
                widget.onBookmarks();
              },
            ),
          ),
        );
      },
    );
  }
}
