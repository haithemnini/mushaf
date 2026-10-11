import 'package:flutter/material.dart';

/// Theme tokens for mushaf widgets — map from the host app [ColorScheme].
@immutable
class MushafStyle extends ThemeExtension<MushafStyle> {
  const MushafStyle({
    required this.ink,
    required this.muted,
    required this.accent,
    required this.accentContainer,
    required this.background,
    this.pagePadding = const EdgeInsets.symmetric(horizontal: 16),
    this.fontScale = 1.0,
    this.useArabicNames = true,
  });

  final Color ink;
  final Color muted;
  final Color accent;
  final Color accentContainer;
  final Color background;
  final EdgeInsets pagePadding;
  final double fontScale;
  final bool useArabicNames;

  factory MushafStyle.fromTheme(
    BuildContext context, {
    double fontScale = 1.0,
    bool useArabicNames = true,
  }) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return MushafStyle(
      ink: colors.onSurface,
      muted: colors.onSurfaceVariant,
      accent: colors.primary,
      accentContainer: colors.primaryContainer,
      background: theme.scaffoldBackgroundColor,
      fontScale: fontScale,
      useArabicNames: useArabicNames,
    );
  }

  String juzLabel(int juz) =>
      useArabicNames ? 'الجزء $juz' : 'Part $juz';

  @override
  MushafStyle copyWith({
    Color? ink,
    Color? muted,
    Color? accent,
    Color? accentContainer,
    Color? background,
    EdgeInsets? pagePadding,
    double? fontScale,
    bool? useArabicNames,
  }) {
    return MushafStyle(
      ink: ink ?? this.ink,
      muted: muted ?? this.muted,
      accent: accent ?? this.accent,
      accentContainer: accentContainer ?? this.accentContainer,
      background: background ?? this.background,
      pagePadding: pagePadding ?? this.pagePadding,
      fontScale: fontScale ?? this.fontScale,
      useArabicNames: useArabicNames ?? this.useArabicNames,
    );
  }

  @override
  MushafStyle lerp(ThemeExtension<MushafStyle>? other, double t) {
    if (other is! MushafStyle) return this;
    return MushafStyle(
      ink: Color.lerp(ink, other.ink, t)!,
      muted: Color.lerp(muted, other.muted, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      accentContainer: Color.lerp(accentContainer, other.accentContainer, t)!,
      background: Color.lerp(background, other.background, t)!,
      pagePadding: EdgeInsets.lerp(pagePadding, other.pagePadding, t)!,
      fontScale: fontScale + (other.fontScale - fontScale) * t,
      useArabicNames: t < 0.5 ? useArabicNames : other.useArabicNames,
    );
  }
}
