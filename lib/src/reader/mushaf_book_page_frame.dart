import 'package:flutter/material.dart';

/// Physical-book chrome around one mushaf page.
///
/// Odd pages sit on the right of a real mushaf, so their edges are on the
/// right. Even pages sit on the left, so their edges are on the left.
class MushafBookPageFrame extends StatelessWidget {
  const MushafBookPageFrame({
    super.key,
    required this.enabled,
    required this.pageNumber,
    required this.background,
    required this.child,
    this.sideEdges = true,
    this.joined = false,
  });

  final bool enabled;
  final int pageNumber;

  /// Side stacks are for horizontal page turns. Vertical book mode keeps
  /// only the band between this page and the one above or below it.
  final bool sideEdges;

  /// This page sits against its pair in an open spread. The spine side is
  /// flush so only the divider line separates the two pages.
  final bool joined;
  final Color background;
  final Widget child;

  bool get _edgesOnRight => pageNumber.isOdd;

  /// Outer corners stay round. In a spread the spine corners are square so
  /// the page meets the divider line.
  static BorderRadius _cornerRadius({required bool onRight, required bool joined}) {
    if (!joined) return BorderRadius.circular(_pageRadius);
    final outer = const Radius.circular(_pageRadius);
    const spine = Radius.zero;
    return BorderRadius.only(
      topLeft: onRight ? spine : outer,
      bottomLeft: onRight ? spine : outer,
      topRight: onRight ? outer : spine,
      bottomRight: onRight ? outer : spine,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!enabled) {
      return child;
    }
    final colors = Theme.of(context).colorScheme;
    final onRight = _edgesOnRight;
    final radius = _cornerRadius(onRight: onRight, joined: joined);
    final page = DecoratedBox(
      decoration: BoxDecoration(
        color: background,
        borderRadius: radius,
        border: joined && onRight ? Border(left: BorderSide(color: colors.onSurfaceVariant, width: 1)) : null,
        boxShadow: [
          BoxShadow(
            color: colors.onSurface.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: child,
      ),
    );

    if (!sideEdges) {
      return ColoredBox(
        color: colors.primaryContainer,
        child: Padding(
          padding: const EdgeInsets.only(top: 40, bottom: 24),
          child: page,
        ),
      );
    }

    return ColoredBox(
      color: colors.primaryContainer,
      child: Padding(
        padding: EdgeInsets.fromLTRB(onRight ? (joined ? 0 : 8) : 20, 40, onRight ? 20 : (joined ? 0 : 8), 8),
        child: Padding(
          padding: EdgeInsets.only(
            left: onRight ? 0 : _pageEdgeWidth,
            right: onRight ? _pageEdgeWidth : 0,
          ),
          child: Stack(
            fit: StackFit.expand,
            clipBehavior: Clip.none,
            children: [
              Positioned(
                left: onRight ? null : -_edgeSpread,
                right: onRight ? -_edgeSpread : null,
                top: 0,
                bottom: 0,
                width: _pageRadius + _edgeSpread,
                child: CustomPaint(
                  painter: _BookEdgePainter(
                    pageColor: background,
                    ink: colors.onSurface,
                    onRight: onRight,
                  ),
                ),
              ),
              page,
            ],
          ),
        ),
      ),
    );
  }
}

const _pageEdgeWidth = 14.0;
const _pageRadius = 12.0;
const _edgeSpread = 8.0;

class _BookEdgePainter extends CustomPainter {
  const _BookEdgePainter({
    required this.pageColor,
    required this.ink,
    required this.onRight,
  });

  final Color pageColor;
  final Color ink;
  final bool onRight;

  @override
  void paint(Canvas canvas, Size size) {
    const gaps = <double>[4.0, 8.0];
    final pageEdge = onRight ? size.width - _edgeSpread : _edgeSpread;
    // Each sheet is the page's own rounded rect, simply slid sideways by
    // `gap`. Same radius, same top/bottom as the page, so the corner arc
    // is a full, uncut circle that flows straight down and ends exactly
    // where the page ends — never clipped, never past the page's edges.
    for (var i = gaps.length - 1; i >= 0; i--) {
      final gap = gaps[i];
      final rect = onRight ? Rect.fromLTRB(-64, 0, pageEdge + gap, size.height) : Rect.fromLTRB(pageEdge - gap, 0, size.width + 64, size.height);
      final sheet = RRect.fromRectAndRadius(rect, const Radius.circular(_pageRadius));
      canvas.drawRRect(
        sheet.shift(Offset(onRight ? 0.8 : -0.8, 0)),
        Paint()
          ..color = ink.withValues(alpha: 0.10)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1),
      );
      canvas.drawRRect(
        sheet,
        Paint()..color = Color.lerp(pageColor, ink, i == 0 ? 0.04 : 0.12)!,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _BookEdgePainter oldDelegate) {
    return oldDelegate.pageColor != pageColor || oldDelegate.ink != ink || oldDelegate.onRight != onRight;
  }
}
