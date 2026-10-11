# mushaf

قارئ مصحف جاهز لـ Flutter، بروايتي **حفص عن عاصم** و**ورش عن نافع** في حزمة واحدة.

تفتح سورة، تقلب الصفحات، وتضغط ضغطاً مطوّلاً على الآية لتحديدها. من الإعدادات تختار ملء الشاشة أو شكل الكتاب، والتمرير الأفقي أو العمودي، وصفحة واحدة أو صفحتين عندما تكون النافذة عريضة وأفقية. حفص يُرسم بخطوط QCF4، ويمكن تلوين التجويد. ورش يُرسم بخط واحد مع ضبط السطور.

A Flutter mushaf reader for **Hafs (QCF4)** and **Warsh**: surah list, page turns, long-press ayah selection, fullscreen or book frame, and a two-page spread on a wide landscape window.

## المعاينة

من مثال الحزمة على macOS.

| قائمة السور | ورش — الفاتحة |
| --- | --- |
| ![قائمة السور والتبديل بين حفص وورش](screenshots/surah-list.png) | ![سورة الفاتحة برواية ورش](screenshots/warsh-fatiha.png) |

| حفص بالتجويد | تحديد الآية |
| --- | --- |
| ![صفحة حفص ملوّنة بالتجويد](screenshots/hafs-tajweed.png) | ![ضغط مطوّل يظلل الآية](screenshots/hafs-highlight.png) |

| ملء الشاشة | إطار الكتاب |
| --- | --- |
| ![صفحة حفص بملء الشاشة](screenshots/hafs-plain.png) | ![الصفحة داخل إطار الكتاب](screenshots/hafs-book.png) |

صفحتان متقابلتان في الوضع الأفقي العريض:

![حفص، الصفحتان ٤٣ و٤٤](screenshots/hafs-spread.png)

## ماذا ترى في القارئ

- قائمة السور مع البحث، والتبديل بين حفص (604 صفحة) وورش (599 صفحة).
- تحديد الآية بالضغط المطوّل، مع تمييزها، والانتقال إلى صفحة أو آية.
- ملء الشاشة، أو إطار كتاب بحواف الصفحات.
- تمرير أفقي أو عمودي.
- في النافذة العريضة الأفقية: صفحة واحدة أو صفحتان.
- شريط مصغّرات للصفحات، أو منزلق يقفز عند الإفلات.
- ساعة اختيارية، وخلفية سوداء في الوضع الليلي.
- تلوين التجويد لحفص فقط.

## التثبيت

```yaml
dependencies:
  mushaf: ^0.2.0
```

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
  onSettingsChanged: (settings) {},
  onAyahLongPress: (ref) {},
)
```

`MushafReaderController.goToPage` و`goToAyah` ينقلان الصفحة ويميزان الآية. لورش استخدم `MushafRiwayah.warsh` بعد `registerMushafWarsh`.

## حفص وورش داخل الحزمة

الملفان `assets/packs/hafs.zip` و`assets/packs/warsh.zip` جزء من الحزمة. أول استدعاء لـ `Mushaf.initialize()` يفكّهما على الجهاز، وبعدها حفص وورش جاهزان. لا يحتاج المستخدم إلى تنزيل منفصل.

```bash
cd example
flutter run
```

إن أردت استخدام مجلد خاص بدل الملفات المضمّنة، سجّله قبل `initialize`:

```dart
registerMushafHafsQcf4(localRoot: hafsPackRoot);
registerMushafWarsh(localRoot: warshPackRoot);
await Mushaf.initialize();
```

## الترخيص

كود Dart تحت رخصة MIT. الخطوط ونص القرآن لهما شروط أصحاب الحقوق. راجع [LICENSE](LICENSE) و[NOTICE.md](NOTICE.md).
