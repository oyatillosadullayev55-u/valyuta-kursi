import 'dart:math' as math;

import 'package:flutter/material.dart';

class LinePainter extends CustomPainter {
  final List<double> values;
  final Color color;
  LinePainter(this.values, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    if (values.length < 2) return;
    final minV = values.reduce(math.min);
    final maxV = values.reduce(math.max);
    final range = (maxV - minV) == 0 ? 1.0 : (maxV - minV);
    const pad = 10.0;
    final w = size.width - pad * 2;
    final h = size.height - pad * 2;

    Offset pt(int i) => Offset(
      pad + w * i / (values.length - 1),
      pad + h * (1 - (values[i] - minV) / range),
    );

    final path = Path()..moveTo(pt(0).dx, pt(0).dy);
    for (var i = 1; i < values.length; i++) {
      path.lineTo(pt(i).dx, pt(i).dy);
    }

    final fill = Path.from(path)
      ..lineTo(pad + w, size.height)
      ..lineTo(pad, size.height)
      ..close();
    canvas.drawPath(fill, Paint()..color = color.withOpacity(0.12));

    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..strokeJoin = StrokeJoin.round,
    );
    canvas.drawCircle(pt(values.length - 1), 4.5, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant LinePainter old) => old.values != values;
}