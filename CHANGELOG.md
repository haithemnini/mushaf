## 0.2.0

- Hafs (QCF4) and Warsh now ship inside the package. `Mushaf.initialize()`
  unpacks them on first launch, so both riwayat are ready without a separate
  download.

## 0.1.1

- Added reader screenshots to the package page: surah list, Warsh, Hafs
  tajweed, ayah highlight, fullscreen, book frame, and a two-page spread.
- Rewrote the README so the reading options and the local pack setup are
  easier to follow.

## 0.1.0

- First open-source release.
- Hafs reader uses the QCF4 page fonts (one font per page, optional tajweed).
- Warsh reader uses the generated 599-page layout with kashida justification.
- Shared reading options: horizontal or vertical scroll, fullscreen or book
  frame, single or double page on a wide landscape window, page strip or
  scrubber, clock, and black background in dark mode.
- Long-press an ayah to identify it and jump with `goToPage` / `goToAyah`.
- Page fonts and ayah corpora are loaded from a local pack, not from pub.dev.
