import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/currency.dart';
import '../utils/format.dart';

/// Bosib yoki surib qiymatni ko'rish mumkin bo'lgan chiziqli grafik.
class HistoryChart extends StatefulWidget {
  final List<HistoryPoint> points;
  final Color color;
  const HistoryChart({super.key, required this.points, required this.color});

  @override
  State<HistoryChart> createState() => _HistoryChartState();
}

class _HistoryChartState extends State<HistoryChart> {
  int? _sel;

  @override
  void didUpdateWidget(covariant HistoryChart old) {
    super.didUpdateWidget(old);
    if (old.points != widget.points) _sel = null;
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return LayoutBuilder(
      builder: (context, cons) {
        final w = cons.maxWidth;

        void pick(double dx) {
          final n = widget.points.length;
          if (n < 2) return;
          final plotW = w - _ChartPainter.left - _ChartPainter.right;
          final frac =
          math.min(math.max((dx - _ChartPainter.left) / plotW, 0.0), 1.0);
          setState(() => _sel = (frac * (n - 1)).round());
        }

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (d) => pick(d.localPosition.dx),
          onHorizontalDragStart: (d) => pick(d.localPosition.dx),
          onHorizontalDragUpdate: (d) => pick(d.localPosition.dx),
          child: CustomPaint(
            size: Size.infinite,
            painter: _ChartPainter(
              pts: widget.points,
              color: widget.color,
              grid: cs.outlineVariant,
              textColor: cs.outline,
              bg: cs.surface,
              onColor: cs.onPrimary,
              sel: _sel,
            ),
          ),
        );
      },
    );
  }
}

void _text(Canvas canvas, String s, Offset o,
    {double size = 11, Color color = Colors.grey, bool alignRight = false}) {
  final tp = TextPainter(
    text: TextSpan(text: s, style: TextStyle(fontSize: size, color: color)),
    textDirection: TextDirection.ltr,
  )..layout();
  tp.paint(canvas, Offset(alignRight ? o.dx - tp.width : o.dx, o.dy));
}

class _ChartPainter extends CustomPainter {
  static const double left = 8;
  static const double right = 8;
  static const double top = 36;
  static const double bottom = 24;

  final List<HistoryPoint> pts;
  final Color color, grid, textColor, bg, onColor;
  final int? sel;

  _ChartPainter({
    required this.pts,
    required this.color,
    required this.grid,
    required this.textColor,
    required this.bg,
    required this.onColor,
    required this.sel,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final n = pts.length;
    if (n < 2) return;

    final plotW = size.width - left - right;
    final plotH = size.height - top - bottom;

    var lo = pts.first.value;
    var hi = pts.first.value;
    for (final p in pts) {
      if (p.value < lo) lo = p.value;
      if (p.value > hi) hi = p.value;
    }
    var pad = (hi - lo) * 0.12;
    if (pad == 0) pad = hi.abs() * 0.01 + 1;
    lo -= pad;
    hi += pad;

    double xOf(int i) => left + plotW * i / (n - 1);
    double yOf(double v) => top + plotH * (1 - (v - lo) / (hi - lo));

    // Gorizontal chiziqlar va yozuvlar
    final gridPaint = Paint()
      ..color = grid
      ..strokeWidth = 1;
    for (var k = 0; k < 3; k++) {
      final y = top + plotH * k / 2;
      canvas.drawLine(Offset(left, y), Offset(size.width - right, y), gridPaint);
      final v = hi - (hi - lo) * k / 2;
      _text(canvas, fmt(v), Offset(left + 2, y - 14), size: 10, color: textColor);
    }

    // Chiziq
    final line = Path()..moveTo(xOf(0), yOf(pts[0].value));
    for (var i = 1; i < n; i++) {
      final x0 = xOf(i - 1), y0 = yOf(pts[i - 1].value);
      final x1 = xOf(i), y1 = yOf(pts[i].value);
      final mx = (x0 + x1) / 2;
      line.cubicTo(mx, y0, mx, y1, x1, y1);
    }

    final fill = Path.from(line)
      ..lineTo(xOf(n - 1), top + plotH)
      ..lineTo(xOf(0), top + plotH)
      ..close();
    canvas.drawPath(
      fill,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [color.withAlpha(80), color.withAlpha(0)],
        ).createShader(Rect.fromLTWH(0, top, size.width, plotH)),
    );
    canvas.drawPath(
      line,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    // Sana yozuvlari
    _text(canvas, fmtShortDate(pts.first.date),
        Offset(left, size.height - 18), color: textColor);
    _text(canvas, fmtShortDate(pts.last.date),
        Offset(size.width - right, size.height - 18),
        color: textColor, alignRight: true);

    // Tanlangan nuqta
    final s = math.max(0, math.min(sel ?? n - 1, n - 1));
    final sx = xOf(s);
    final sy = yOf(pts[s].value);
    canvas.drawLine(
      Offset(sx, top),
      Offset(sx, top + plotH),
      Paint()
        ..color = color.withAlpha(120)
        ..strokeWidth = 1,
    );
    canvas.drawCircle(Offset(sx, sy), 6.5, Paint()..color = bg);
    canvas.drawCircle(Offset(sx, sy), 4.5, Paint()..color = color);

    // Tooltip
    final label = '${fmtShortDate(pts[s].date)}  •  ${fmt(pts[s].value)}';
    final tp = TextPainter(
      text: TextSpan(
        text: label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: onColor,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    final bw = tp.width + 16;
    const bh = 24.0;
    final bx = math.max(2.0, math.min(sx - bw / 2, size.width - bw - 2));
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(bx, 4, bw, bh),
        const Radius.circular(8),
      ),
      Paint()..color = color,
    );
    tp.paint(canvas, Offset(bx + 8, 4 + (bh - tp.height) / 2));
  }

  @override
  bool shouldRepaint(covariant _ChartPainter old) =>
      old.pts != pts ||
          old.sel != sel ||
          old.color != color ||
          old.grid != grid ||
          old.bg != bg;
}