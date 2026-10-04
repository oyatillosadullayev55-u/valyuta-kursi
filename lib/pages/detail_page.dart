import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/currency.dart';
import '../services/rates_service.dart';
import '../utils/format.dart';
import '../widgets/line_painter.dart';

class DetailPage extends StatefulWidget {
  final Currency c;
  const DetailPage({super.key, required this.c});

  @override
  State<DetailPage> createState() => _DetailPageState();
}

class _DetailPageState extends State<DetailPage> {
  int _days = 7;
  List<double> _hist = [];
  bool _busy = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _busy = true);
    final h = await loadHistory(widget.c.code, _days);
    if (!mounted) return;
    setState(() {
      _hist = h;
      _busy = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.c;
    final cs = Theme.of(context).colorScheme;
    final up = c.diff > 0;
    final down = c.diff < 0;
    final color = up ? Colors.green : (down ? Colors.red : Colors.grey);

    Widget chart;
    if (_busy) {
      chart = const Center(child: CircularProgressIndicator());
    } else if (_hist.length < 2) {
      chart = const Center(child: Text('Grafik uchun ma\'lumot yetarli emas'));
    } else {
      chart = CustomPaint(
        size: Size.infinite,
        painter: LinePainter(_hist, cs.primary),
      );
    }

    Widget stat(String label, String value) => Expanded(
      child: Column(
        children: [
          Text(label, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );

    return Scaffold(
      appBar: AppBar(title: Text(c.name)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: cs.primaryContainer,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                Text('1 ${c.code} =',
                    style: Theme.of(context).textTheme.bodyLarge),
                Text(
                  '${fmt(c.perUnit)} so\'m',
                  style: Theme.of(context)
                      .textTheme
                      .headlineMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  '${up ? '+' : ''}${fmt(c.diffPerUnit)} (kechagiga nisbatan)',
                  style: TextStyle(color: color),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              for (final d in [7, 30])
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text('$d kun'),
                    selected: _days == d,
                    onSelected: (_) {
                      if (_days != d) {
                        _days = d;
                        _load();
                      }
                    },
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(height: 220, child: chart),
          const SizedBox(height: 16),
          if (_hist.length >= 2)
            Row(
              children: [
                stat('Eng past', fmt(_hist.reduce(math.min))),
                stat('O\'rtacha',
                    fmt(_hist.reduce((a, b) => a + b) / _hist.length)),
                stat('Eng yuqori', fmt(_hist.reduce(math.max))),
              ],
            ),
        ],
      ),
    );
  }
}