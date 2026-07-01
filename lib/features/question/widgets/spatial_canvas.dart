import 'package:flutter/material.dart';

class SpatialCanvas extends StatelessWidget {
  const SpatialCanvas({super.key, required this.pattern, this.height = 120});

  final String pattern;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '공간지각 도형 캔버스',
      child: SizedBox(
        height: height,
        width: double.infinity,
        child: CustomPaint(
          painter: _SpatialPatternPainter(
            pattern: pattern,
            color: Theme.of(context).colorScheme.primary,
            guideColor: Theme.of(context).colorScheme.outlineVariant,
          ),
        ),
      ),
    );
  }
}

class _SpatialPatternPainter extends CustomPainter {
  const _SpatialPatternPainter({
    required this.pattern,
    required this.color,
    required this.guideColor,
  });

  final String pattern;
  final Color color;
  final Color guideColor;

  @override
  void paint(Canvas canvas, Size size) {
    final guidePaint = Paint()
      ..color = guideColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    final shapePaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    final columns = pattern.trim().isEmpty ? 1 : pattern.trim().length;
    final cell = size.width / columns.clamp(1, 8);
    for (var i = 0; i < columns; i++) {
      final left = i * cell;
      final rect = Rect.fromLTWH(left + 6, 10, cell - 12, size.height - 20);
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(8)),
        guidePaint,
      );
      final symbol = pattern[i];
      final center = rect.center;
      switch (symbol) {
        case '▲':
          _drawTriangle(canvas, center, rect.shortestSide * 0.28, shapePaint);
          break;
        case '▼':
          _drawTriangle(
            canvas,
            center,
            rect.shortestSide * 0.28,
            shapePaint,
            upsideDown: true,
          );
          break;
        case '■':
          canvas.drawRect(
            Rect.fromCenter(
              center: center,
              width: rect.shortestSide * 0.45,
              height: rect.shortestSide * 0.45,
            ),
            shapePaint,
          );
          break;
        case '◆':
          canvas.save();
          canvas.translate(center.dx, center.dy);
          canvas.rotate(0.785398);
          canvas.drawRect(
            Rect.fromCenter(
              center: Offset.zero,
              width: rect.shortestSide * 0.42,
              height: rect.shortestSide * 0.42,
            ),
            shapePaint,
          );
          canvas.restore();
          break;
        default:
          canvas.drawCircle(center, rect.shortestSide * 0.22, shapePaint);
      }
    }
  }

  void _drawTriangle(
    Canvas canvas,
    Offset center,
    double radius,
    Paint paint, {
    bool upsideDown = false,
  }) {
    final direction = upsideDown ? -1 : 1;
    final path = Path()
      ..moveTo(center.dx, center.dy - radius * direction)
      ..lineTo(center.dx - radius, center.dy + radius * direction)
      ..lineTo(center.dx + radius, center.dy + radius * direction)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _SpatialPatternPainter oldDelegate) {
    return oldDelegate.pattern != pattern ||
        oldDelegate.color != color ||
        oldDelegate.guideColor != guideColor;
  }
}
