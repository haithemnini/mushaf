# mushaf

قارئ مصحف لـ Flutter يجمع **حفص (QCF4)** و**ورش** في حزمة واحدة: تحديد الآية، الانتقال إلى صفحة أو آية، ملء الشاشة، إطار الكتاب، صفحتان في الوضع الأفقي العريض، شريط الصفحات أو المنزلق، الساعة، والخلفية السوداء. التجويد متاح لحفص.

Flutter mushaf reader for **Hafs (QCF4)** and **Warsh**: ayah selection, page and ayah jumps, fullscreen, book frame, a two-page landscape spread, page strip or scrubber, clock, and a black canvas in dark mode. Tajweed coloring is available for Hafs.

نص الآيات وخطوط الصفحات **ليست** داخل الحزمة. المضيف يفك ضغط الحزمة محلياً ثم يسجّلها. انظر [NOTICE.md](NOTICE.md).

Ayah text and page fonts are **not** bundled. Register a local pack. See [NOTICE.md](NOTICE.md).

## Install

```yaml
dependencies:
  mushaf: ^0.1.0
```

## Quick start

```dart
import 'package:flutter/material.dart';
import 'package:mushaf/mushaf.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  registerMushafHafsQcf4(localRoot: hafsPackRoot);
  registerMushafWarsh(localRoot: warshPackRoot);
  await Mushaf.initialize();
  runApp(const MyApp());
}
```

```dart
MushafReader(
  riwayah: MushafRiwayah.hafs,
  initialPage: 1,
  settings: const MushafReadingSettings(),
  onSettingsChanged: (next) {},
  onAyahLongPress: (ref) {},
)
```

`MushafReaderController.goToPage` and `goToAyah` move the highlight and the page. Warsh is `MushafRiwayah.warsh` after `registerMushafWarsh`.

## Pack layout

`MUSHAF_HAFS_ROOT` is the extracted Hafs pack that contains `assets/quran/hafs_qcf4/` (QCF4 fonts, `qpc-v4.json.gz`, ayah info). `MUSHAF_WARSH_ROOT` is the extracted Warsh pack that contains `assets/quran/warsh/` and the Warsh fonts.

## Example

```bash
cd example
flutter run \
  --dart-define=MUSHAF_HAFS_ROOT=/path/to/extracted/hafs \
  --dart-define=MUSHAF_WARSH_ROOT=/path/to/extracted/warsh
```

Without those paths the example explains how to pass them.

## License

MIT for the Dart source. Fonts and Quran text keep their own terms. See [LICENSE](LICENSE) and [NOTICE.md](NOTICE.md).
