# NOTICE — mushaf

This package is a Flutter reader for the Hafs (QCF4) and Warsh mushaf layouts.

## Bundled with the package

Small shared chrome used by both riwayat:

- `assets/quran/surahs/surahs.json` — surah index (names and counts).
- `assets/quran/chrome/surah_frame.svg` — ornamental surah header frame.
- `assets/quran/chrome/surah_name_glyphs.json` — glyph map for the surah-name font.
- `assets/fonts/chrome/` — surah-name and basmalah fonts.

These chrome files are attributed separately from the MIT engine. Confirm you
may redistribute them before shipping a product that includes this package.

## Not bundled

Hafs and Warsh ayah text and page fonts stay outside this package. A host
downloads or otherwise obtains a pack and registers it at runtime:

- Hafs QCF4: `registerMushafHafsQcf4(localRoot: …)`
- Warsh: `registerMushafWarsh(localRoot: …)`

QCF fonts and Quran text remain under the terms of their rights holders
(including the King Fahd Complex / Quranic Universal Library where applicable).
Do not commit those files to this repository.

## Engine

Layout, kashida justification, and the reader shell are original work unless
a source file says otherwise. The QCF4 line model notes its adaptation from
quran_library (MIT, Alheekmah Library).
