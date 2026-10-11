import 'package:flutter/material.dart';

/// Centered mushaf folio: the page number between two short gold rules.
class MushafPageNumberFrame extends StatelessWidget {
  const MushafPageNumberFrame({
    super.key,
    required this.page,
    required this.colors,
    required this.textTheme,
  });

  final int page;
  final ColorScheme colors;
  final TextTheme textTheme;

  @override
  Widget build(BuildContext context) {
    final ink = colors.onSurface.withValues(alpha: 0.72);
    final rule = colors.primary.withValues(alpha: 0.38);

    return SizedBox(
      height: 32,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _FolioRule(color: rule, towardEnd: true),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              '$page',
              textAlign: TextAlign.center,
              style: textTheme.labelMedium?.copyWith(
                color: ink,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.4,
                height: 1,
              ),
            ),
          ),
          _FolioRule(color: rule, towardEnd: false),
        ],
      ),
    );
  }
}

class _FolioRule extends StatelessWidget {
  const _FolioRule({
    required this.color,
    required this.towardEnd,
  });

  final Color color;
  final bool towardEnd;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 32,
      height: 8,
      child: CustomPaint(
        painter: _FolioRulePainter(
          color: color,
          towardEnd: towardEnd,
        ),
      ),
    );
  }
}

class _FolioRulePainter extends CustomPainter {
  const _FolioRulePainter({
    required this.color,
    required this.towardEnd,
  });

  final Color color;
  final bool towardEnd;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final midY = size.height / 2;
    final diamondX = towardEnd ? size.width - 3.5 : 3.5;
    final lineStart = towardEnd ? 0.0 : 7.0;
    final lineEnd = towardEnd ? size.width - 7.0 : size.width;

    canvas.drawLine(Offset(lineStart, midY), Offset(lineEnd, midY), paint);

    final diamond = Path()
      ..moveTo(diamondX, 0.5)
      ..lineTo(diamondX + 3, midY)
      ..lineTo(diamondX, size.height - 0.5)
      ..lineTo(diamondX - 3, midY)
      ..close();
    canvas.drawPath(diamond, paint);
  }

  @override
  bool shouldRepaint(covariant _FolioRulePainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.towardEnd != towardEnd;
}
