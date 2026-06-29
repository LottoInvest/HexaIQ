import 'dart:math';

import 'package:flutter/material.dart';

class HexagonChart extends StatelessWidget {
  const HexagonChart({
    required this.values,
    this.labels = const [],
    this.size = 260,
    super.key,
  });

  final List<double> values;
  final List<String> labels;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child: CustomPaint(
        painter: _HexagonChartPainter(
          values: values,
          labels: labels,
          color: Theme.of(context).colorScheme.primary,
          labelStyle:
              Theme.of(context).textTheme.labelSmall ??
              const TextStyle(fontSize: 11),
        ),
      ),
    );
  }
}

class _HexagonChartPainter extends CustomPainter {
  _HexagonChartPainter({
    required this.values,
    required this.labels,
    required this.color,
    required this.labelStyle,
  });

  final List<double> values;
  final List<String> labels;
  final Color color;
  final TextStyle labelStyle;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) * 0.34;
    final gridPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.10)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    final fillPaint = Paint()
      ..color = color.withValues(alpha: 0.18)
      ..style = PaintingStyle.fill;
    final strokePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    for (var ring = 1; ring <= 4; ring++) {
      canvas.drawPath(_polygonPath(center, radius * ring / 4), gridPaint);
    }

    for (var i = 0; i < 6; i++) {
      canvas.drawLine(center, _point(center, radius, i), gridPaint);
    }

    final dataPath = Path();
    for (var i = 0; i < 6; i++) {
      final value = values.length > i ? values[i].clamp(0, 100) / 100 : 0.0;
      final point = _point(center, radius * value, i);
      if (i == 0) {
        dataPath.moveTo(point.dx, point.dy);
      } else {
        dataPath.lineTo(point.dx, point.dy);
      }
    }
    dataPath.close();
    canvas
      ..drawPath(dataPath, fillPaint)
      ..drawPath(dataPath, strokePaint);

    for (var i = 0; i < min(labels.length, 6); i++) {
      final point = _point(center, radius + 28, i);
      final textPainter = TextPainter(
        text: TextSpan(text: labels[i], style: labelStyle),
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: 64);
      textPainter.paint(
        canvas,
        Offset(point.dx - textPainter.width / 2, point.dy - 8),
      );
    }
  }

  Path _polygonPath(Offset center, double radius) {
    final path = Path();
    for (var i = 0; i < 6; i++) {
      final point = _point(center, radius, i);
      if (i == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }
    return path..close();
  }

  Offset _point(Offset center, double radius, int index) {
    final angle = -pi / 2 + index * pi / 3;
    return Offset(
      center.dx + cos(angle) * radius,
      center.dy + sin(angle) * radius,
    );
  }

  @override
  bool shouldRepaint(covariant _HexagonChartPainter oldDelegate) {
    return oldDelegate.values != values || oldDelegate.labels != labels;
  }
}
