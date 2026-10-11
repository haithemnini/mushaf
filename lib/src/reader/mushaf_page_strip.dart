import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'mushaf_reading_settings.dart';

/// Bottom page picker: thumbnail strip or a scrubber that jumps on release.
class MushafPageStrip extends StatefulWidget {
  const MushafPageStrip({
    super.key,
    required this.visible,
    required this.page,
    required this.pageCount,
    required this.mode,
    required this.onPageSelected,
    required this.onModeChanged,
    this.surahLabelForPage,
    this.previousPage,
    this.onReturnToPrevious,
  });

  final bool visible;
  final int page;
  final int pageCount;
  final MushafPageNavMode mode;
  final ValueChanged<int> onPageSelected;
  final ValueChanged<MushafPageNavMode> onModeChanged;
  final String? Function(int page)? surahLabelForPage;
  final int? previousPage;
  final VoidCallback? onReturnToPrevious;

  static const double itemWidth = 48;
  static const double scrubThumbWidth = 48;

  @override
  State<MushafPageStrip> createState() => _MushafPageStripState();
}

class _MushafPageStripState extends State<MushafPageStrip> {
  final ScrollController _scrollController = ScrollController();
  late int _previewPage;
  bool _dragging = false;
  int? _pendingJumpPage;

  @override
  void initState() {
    super.initState();
    _previewPage = widget.page;
    WidgetsBinding.instance.addPostFrameCallback((_) => _centerOnPage(animate: false));
  }

  @override
  void didUpdateWidget(covariant MushafPageStrip oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_dragging && oldWidget.page != widget.page) {
      final pending = _pendingJumpPage;
      if (pending != null) {
        if (widget.page == pending) {
          _pendingJumpPage = null;
          _previewPage = widget.page;
        }
      } else {
        _previewPage = widget.page;
      }
    }
    if (oldWidget.page != widget.page || (!oldWidget.visible && widget.visible)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _centerOnPage(animate: oldWidget.page != widget.page);
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  int get _displayPage {
    if (_dragging || _pendingJumpPage != null) {
      return _previewPage;
    }
    return widget.page;
  }

  void _centerOnPage({required bool animate}) {
    if (!_scrollController.hasClients) {
      return;
    }
    final viewport = _scrollController.position.viewportDimension;
    final target = ((widget.page - 1) * MushafPageStrip.itemWidth) - (viewport - MushafPageStrip.itemWidth) / 2;
    final offset = target.clamp(
      _scrollController.position.minScrollExtent,
      _scrollController.position.maxScrollExtent,
    );
    if (animate) {
      _scrollController.animateTo(
        offset,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
      );
    } else {
      _scrollController.jumpTo(offset);
    }
  }

  int _clampPage(int page) {
    if (page < 1) {
      return 1;
    }
    if (page > widget.pageCount) {
      return widget.pageCount;
    }
    return page;
  }

  void _onScrubChanged(int page) {
    final next = _clampPage(page);
    if (next == _previewPage && _dragging) {
      return;
    }
    setState(() {
      _dragging = true;
      _pendingJumpPage = null;
      _previewPage = next;
    });
  }

  void _onScrubChangeEnd(int page) {
    final target = _clampPage(page);
    setState(() {
      _dragging = false;
      _previewPage = target;
      _pendingJumpPage = target != widget.page ? target : null;
    });
    if (target != widget.page) {
      widget.onPageSelected(target);
    }
  }

  void _toggleMode() {
    final next = widget.mode == MushafPageNavMode.scrub ? MushafPageNavMode.strip : MushafPageNavMode.scrub;
    HapticFeedback.mediumImpact();
    widget.onModeChanged(next);
    if (next == MushafPageNavMode.strip) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _centerOnPage(animate: false));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final textTheme = theme.textTheme;
    final bottom = MediaQuery.paddingOf(context).bottom;
    final previous = widget.previousPage;
    final displayPage = _displayPage;
    final mode = widget.mode;

    final navBody = mode == MushafPageNavMode.scrub
        ? _PageScrubber(
            page: displayPage,
            pageCount: widget.pageCount,
            surahLabel: widget.surahLabelForPage?.call(displayPage),
            colors: colors,
            textTheme: textTheme,
            onChanged: _onScrubChanged,
            onChangeEnd: _onScrubChangeEnd,
          )
        : ListView.builder(
            controller: _scrollController,
            scrollDirection: Axis.horizontal,
            itemExtent: MushafPageStrip.itemWidth,
            itemCount: widget.pageCount,
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemBuilder: (context, index) {
              final pageNumber = index + 1;
              final selected = pageNumber == widget.page;
              return _PageStripItem(
                pageNumber: pageNumber,
                selected: selected,
                surahLabel: widget.surahLabelForPage?.call(pageNumber),
                colors: colors,
                textTheme: textTheme,
                onTap: () {
                  if (selected) {
                    return;
                  }
                  HapticFeedback.selectionClick();
                  widget.onPageSelected(pageNumber);
                },
                onLongPress: _toggleMode,
              );
            },
          );

    final nav = SizedBox(
      height: 88,
      child: Row(
        children: [
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            alignment: AlignmentDirectional.centerStart,
            child: previous != null && widget.onReturnToPrevious != null
                ? _ReturnPageButton(
                    page: previous,
                    onTap: () {
                      HapticFeedback.selectionClick();
                      widget.onReturnToPrevious!();
                    },
                  )
                : const SizedBox.shrink(),
          ),
          Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onLongPress: _toggleMode,
              child: navBody,
            ),
          ),
        ],
      ),
    );

    return IgnorePointer(
      ignoring: !widget.visible,
      child: AnimatedSlide(
        offset: widget.visible ? Offset.zero : const Offset(0, 1),
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        child: AnimatedOpacity(
          opacity: widget.visible ? 1 : 0,
          duration: const Duration(milliseconds: 180),
          child: Align(
            alignment: Alignment.bottomCenter,
            child: Material(
              color: colors.surface.withValues(alpha: 0.96),
              elevation: 0,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Divider(height: 1, thickness: 1, color: colors.outlineVariant.withValues(alpha: 0.65)),
                  nav,
                  SizedBox(height: bottom > 0 ? bottom : 8),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PageScrubber extends StatefulWidget {
  const _PageScrubber({
    required this.page,
    required this.pageCount,
    required this.surahLabel,
    required this.colors,
    required this.textTheme,
    required this.onChanged,
    required this.onChangeEnd,
  });

  final int page;
  final int pageCount;
  final String? surahLabel;
  final ColorScheme colors;
  final TextTheme textTheme;
  final ValueChanged<int> onChanged;
  final ValueChanged<int> onChangeEnd;

  @override
  State<_PageScrubber> createState() => _PageScrubberState();
}

class _PageScrubberState extends State<_PageScrubber> {
  static const double _thumbWidth = MushafPageStrip.scrubThumbWidth;
  static const double _trackHeight = 4;
  int? _lastHapticPage;

  int _pageFromDx({
    required double dx,
    required double width,
    required bool isRtl,
  }) {
    if (width <= 0 || widget.pageCount <= 1) {
      return 1;
    }
    final usable = width - _thumbWidth;
    final local = (dx - _thumbWidth / 2).clamp(0.0, usable);
    final t = usable <= 0 ? 0.0 : local / usable;
    final fraction = isRtl ? (1.0 - t) : t;
    return (1 + fraction * (widget.pageCount - 1)).round().clamp(1, widget.pageCount);
  }

  void _handleDrag(Offset local, double width, bool isRtl, {required bool ended}) {
    final page = _pageFromDx(dx: local.dx, width: width, isRtl: isRtl);
    if (ended) {
      _lastHapticPage = null;
      widget.onChangeEnd(page);
      return;
    }
    if (page != _lastHapticPage) {
      _lastHapticPage = page;
      HapticFeedback.selectionClick();
    }
    widget.onChanged(page);
  }

  @override
  Widget build(BuildContext context) {
    final colors = widget.colors;
    final textTheme = widget.textTheme;
    final safePage = widget.page.clamp(1, widget.pageCount);
    final isRtl = Directionality.of(context) == TextDirection.rtl;
    final progress = widget.pageCount <= 1 ? 0.0 : (safePage - 1) / (widget.pageCount - 1);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            height: 16,
            child: Text(
              widget.surahLabel ?? '',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: textTheme.labelSmall?.copyWith(
                fontSize: 12,
                height: 1.1,
                fontWeight: FontWeight.w600,
                color: colors.onSurface.withValues(alpha: 0.75),
              ),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 36,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final width = constraints.maxWidth;
                final usable = width - _thumbWidth;
                final thumbT = isRtl ? (1.0 - progress) : progress;
                final thumbLeft = usable * thumbT;
                return GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onHorizontalDragStart: (details) => _handleDrag(details.localPosition, width, isRtl, ended: false),
                  onHorizontalDragUpdate: (details) => _handleDrag(details.localPosition, width, isRtl, ended: false),
                  onHorizontalDragEnd: (_) {
                    _lastHapticPage = null;
                    widget.onChangeEnd(widget.page.clamp(1, widget.pageCount));
                  },
                  onTapDown: (details) => _handleDrag(details.localPosition, width, isRtl, ended: false),
                  onTapUp: (details) => _handleDrag(details.localPosition, width, isRtl, ended: true),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Positioned(
                        left: _thumbWidth / 2,
                        right: _thumbWidth / 2,
                        child: SizedBox(
                          height: _trackHeight,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: colors.outlineVariant.withValues(alpha: 0.55),
                              borderRadius: BorderRadius.circular(2),
                            ),
                            child: Align(
                              alignment: isRtl ? Alignment.centerRight : Alignment.centerLeft,
                              child: FractionallySizedBox(
                                widthFactor: progress.clamp(0.0, 1.0),
                                child: DecoratedBox(
                                  decoration: BoxDecoration(
                                    color: colors.primary.withValues(alpha: 0.7),
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        left: thumbLeft,
                        child: Container(
                          width: _thumbWidth,
                          height: 28,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: colors.primary,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: colors.surface, width: 1.5),
                          ),
                          child: Text(
                            '$safePage',
                            style: textTheme.labelSmall?.copyWith(
                              fontSize: 12,
                              height: 1,
                              fontWeight: FontWeight.w700,
                              color: colors.onPrimary,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Text('1', style: textTheme.labelSmall?.copyWith(fontSize: 10, color: colors.onSurfaceVariant.withValues(alpha: 0.7))),
              Expanded(
                child: Text(
                  '$safePage / ${widget.pageCount}',
                  textAlign: TextAlign.center,
                  style: textTheme.labelSmall?.copyWith(
                    fontSize: 11,
                    height: 1.1,
                    fontWeight: FontWeight.w500,
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ),
              Text(
                '${widget.pageCount}',
                style: textTheme.labelSmall?.copyWith(fontSize: 10, color: colors.onSurfaceVariant.withValues(alpha: 0.7)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PageStripItem extends StatelessWidget {
  const _PageStripItem({
    required this.pageNumber,
    required this.selected,
    required this.surahLabel,
    required this.colors,
    required this.textTheme,
    required this.onTap,
    this.onLongPress,
  });

  final int pageNumber;
  final bool selected;
  final String? surahLabel;
  final ColorScheme colors;
  final TextTheme textTheme;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      onLongPress: onLongPress,
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      borderRadius: BorderRadius.circular(10),
      child: SizedBox(
        width: MushafPageStrip.itemWidth,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              height: 14,
              child: surahLabel == null
                  ? null
                  : Text(
                      surahLabel!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: textTheme.labelSmall?.copyWith(fontSize: 9, height: 1.1, color: colors.onSurfaceVariant),
                    ),
            ),
            const SizedBox(height: 4),
            Container(
              width: 32,
              height: 36,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: selected ? colors.primary : colors.outlineVariant.withValues(alpha: 0.7),
                  width: selected ? 1.5 : 1,
                ),
                color: selected ? colors.primary.withValues(alpha: 0.08) : colors.surface,
              ),
              alignment: Alignment.center,
              child: Icon(Icons.article_outlined, size: 18, color: selected ? colors.primary : colors.onSurfaceVariant),
            ),
            const SizedBox(height: 4),
            Text(
              '$pageNumber',
              style: textTheme.labelSmall?.copyWith(
                fontSize: 11,
                height: 1.1,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                color: selected ? colors.primary : colors.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReturnPageButton extends StatelessWidget {
  const _ReturnPageButton({required this.page, required this.onTap});

  final int page;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsetsDirectional.only(start: 8, end: 4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: MushafPageStrip.itemWidth,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 18),
                    Container(
                      width: 32,
                      height: 36,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        color: colors.primary.withValues(alpha: 0.12),
                        border: Border.all(color: colors.primary, width: 1.5),
                      ),
                      alignment: Alignment.center,
                      child: Icon(Icons.undo, size: 18, color: colors.primary),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$page',
                      style: textTheme.labelSmall?.copyWith(
                        fontSize: 11,
                        height: 1.1,
                        fontWeight: FontWeight.w600,
                        color: colors.primary,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 1,
                height: 40,
                margin: const EdgeInsetsDirectional.only(start: 4),
                color: colors.outlineVariant.withValues(alpha: 0.75),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
