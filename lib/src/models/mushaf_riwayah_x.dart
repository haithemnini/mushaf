import '../assets/mushaf_assets.dart';
import 'mushaf_riwayah.dart';

/// Convenience accessors for a registered riwayah pack.
extension MushafRiwayahX on MushafRiwayah {
  MushafRiwayahAssets get assets => MushafAssets.require(this);

  bool get usesSplitMushafPages =>
      MushafAssets.maybe(this)?.usesSplitPages ?? defaultUsesSplitPages;

  int get mushafPageCount =>
      MushafAssets.maybe(this)?.pageCount ?? defaultPageCount;

  /// Pack face when registered; otherwise [defaultFontFamily] (no throw).
  ///
  /// Hafs QCF apps may never call [registerMushafHafs] — list/search UI must
  /// not depend on registration for typography lookups.
  String get fontFamily =>
      MushafAssets.maybe(this)?.fontFamily ?? defaultFontFamily;

  List<String> get fontFamilyFallback =>
      MushafAssets.maybe(this)?.fontFamilyFallback ?? defaultFontFamilyFallback;
}
