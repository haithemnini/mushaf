import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Top bar for the mushaf reader. Hidden chrome does not block page swipes.
class MushafReaderChrome extends StatelessWidget {
  const MushafReaderChrome({
    super.key,
    required this.visible,
    required this.surahName,
    required this.juz,
    required this.page,
    required this.onBack,
    this.onSettings,
  });

  final bool visible;
  final String surahName;
  final int juz;
  final int page;
  final VoidCallback onBack;
  final VoidCallback? onSettings;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final textTheme = theme.textTheme;
    final top = MediaQuery.paddingOf(context).top;
    final isRtl = Directionality.of(context) == TextDirection.rtl;
    final meta = isRtl ? 'الجزء $juz' : 'Juz $juz';

    return IgnorePointer(
      ignoring: !visible,
      child: AnimatedSlide(
        offset: visible ? Offset.zero : const Offset(0, -1),
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        child: AnimatedOpacity(
          opacity: visible ? 1 : 0,
          duration: const Duration(milliseconds: 180),
          child: Align(
            alignment: Alignment.topCenter,
            child: Material(
              color: colors.surface.withValues(alpha: 0.96),
              elevation: 0,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(height: top),
                  SizedBox(
                    height: 48,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 96),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                surahName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                                style: textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: colors.onSurface,
                                  height: 1.2,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '$meta · $page',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                                style: textTheme.labelSmall?.copyWith(color: colors.onSurfaceVariant, height: 1.2),
                              ),
                            ],
                          ),
                        ),
                        Align(
                          alignment: AlignmentDirectional.centerStart,
                          child: IconButton(
                            tooltip: MaterialLocalizations.of(context).backButtonTooltip,
                            onPressed: () {
                              HapticFeedback.selectionClick();
                              onBack();
                            },
                            icon: Icon(
                              isRtl ? Icons.arrow_forward : Icons.arrow_back,
                              size: 22,
                              color: colors.primary,
                            ),
                          ),
                        ),
                        Align(
                          alignment: AlignmentDirectional.centerEnd,
                          child: IconButton(
                            tooltip: isRtl ? 'إعدادات القراءة' : 'Reading settings',
                            onPressed: onSettings == null
                                ? null
                                : () {
                                    HapticFeedback.selectionClick();
                                    onSettings!();
                                  },
                            icon: Icon(Icons.tune, size: 22, color: colors.primary),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Divider(height: 1, thickness: 1, color: colors.outlineVariant.withValues(alpha: 0.65)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class MushafReaderClock extends StatefulWidget {
  const MushafReaderClock({super.key});

  @override
  State<MushafReaderClock> createState() => _MushafReaderClockState();
}

class _MushafReaderClockState extends State<MushafReaderClock> {
  late DateTime _now;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _now = DateTime.now();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) {
        return;
      }
      setState(() => _now = DateTime.now());
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final hour = _now.hour.toString().padLeft(2, '0');
    final minute = _now.minute.toString().padLeft(2, '0');
    final second = _now.second.toString().padLeft(2, '0');
    return Text(
      '$hour:$minute:$second',
      style: textTheme.labelSmall?.copyWith(
        color: colors.primary,
        height: 1.2,
        fontFeatures: const [FontFeature.tabularFigures()],
      ),
    );
  }
}
