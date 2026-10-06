import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../controllers/app_controller.dart';
import '../models/currency.dart';
import '../utils/format.dart';
import '../widgets/currency_tile.dart';
import '../widgets/history_chart.dart';

class DetailPage extends StatefulWidget {
  final Currency c;
  const DetailPage({super.key, required this.c});

  @override
  State<DetailPage> createState() => _DetailPageState();
}

class _DetailPageState extends State<DetailPage> {
  int _days = 7;
  List<HistoryPoint> _hist = [];
  bool _busy = true;
  final _amount = TextEditingController(text: '1');

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  Future<void> _fetch({bool force = false}) async {
    final days = _days;
    final h = await AppScope.read(context)
        .history(widget.c.code, days, force: force);
    if (!mounted || days != _days) return;
    setState(() {
      _hist = h;
      _busy = false;
    });
  }

  void _reload({bool force = false}) {
    setState(() => _busy = true);
    _fetch(force: force);
  }

  Future<void> _editAlert(AppController ctrl, Currency cur) async {
    final tc = TextEditingController(text: cur.perUnit.toStringAsFixed(2));
    var above = true;
    final res = await showDialog<PriceAlert>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          title: Text('${cur.code} signali'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SegmentedButton<bool>(
                showSelectedIcon: false,
                segments: const [
                  ButtonSegment(value: true, label: Text('Oshsa')),
                  ButtonSegment(value: false, label: Text('Tushsa')),
                ],
                selected: {above},
                onSelectionChanged: (s) => setS(() => above = s.first),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: tc,
                keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: "Maqsad kurs (so'm)",
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Bekor qilish'),
            ),
            FilledButton(
              onPressed: () {
                final t = double.tryParse(tc.text.replaceAll(',', '.'));
                if (t == null || t <= 0) return;
                Navigator.pop(ctx, PriceAlert(cur.code, t, above));
              },
              child: const Text('Saqlash'),
            ),
          ],
        ),
      ),
    );
    if (res != null) ctrl.setAlert(res);
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = AppScope.of(context);
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final cur = ctrl.byCode(widget.c.code) ?? widget.c;
    final fav = ctrl.favorites.contains(cur.code);
    final alert = ctrl.alerts[cur.code];
    final up = cur.diff > 0;
    final down = cur.diff < 0;
    final diffColor = up ? Colors.green : (down ? Colors.red : cs.outline);

    Widget chart;
    if (_busy) {
      chart = const Center(child: CircularProgressIndicator());
    } else if (_hist.length < 2) {
      chart = Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Grafik uchun ma'lumot topilmadi"),
            TextButton(
              onPressed: () => _reload(force: true),
              child: const Text('Qayta urinish'),
            ),
          ],
        ),
      );
    } else {
      chart = HistoryChart(points: _hist, color: cs.primary);
    }

    // Statistika
    String sMin = '—', sAvg = '—', sMax = '—', sChg = '—';
    Color chgColor = cs.outline;
    if (_hist.length >= 2) {
      var mn = _hist.first.value, mx = _hist.first.value, sum = 0.0;
      for (final p in _hist) {
        if (p.value < mn) mn = p.value;
        if (p.value > mx) mx = p.value;
        sum += p.value;
      }
      final first = _hist.first.value;
      final last = _hist.last.value;
      final chg = first == 0 ? 0.0 : (last - first) / first * 100;
      sMin = fmt(mn);
      sMax = fmt(mx);
      sAvg = fmt(sum / _hist.length);
      sChg = '${chg > 0 ? '+' : ''}${chg.toStringAsFixed(2)}%';
      chgColor = chg > 0 ? Colors.green : (chg < 0 ? Colors.red : cs.outline);
    }

    final amount =
        double.tryParse(_amount.text.replaceAll(' ', '').replaceAll(',', '.')) ??
            0;

    return Scaffold(
      appBar: AppBar(
        title: Text(cur.name, maxLines: 1, overflow: TextOverflow.ellipsis),
        actions: [
          IconButton(
            tooltip: 'Sevimli',
            onPressed: () => ctrl.toggleFavorite(cur.code),
            icon: Icon(fav ? Icons.star : Icons.star_border,
                color: fav ? Colors.amber : null),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Sarlavha kartasi
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [cs.primary, Color.lerp(cs.primary, cs.tertiary, 0.6)!],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Row(
              children: [
                FlagCircle(code: cur.code, size: 56),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('1 ${cur.code} =',
                          style: tt.bodyMedium?.copyWith(color: cs.onPrimary)),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          "${fmt(cur.perUnit)} so'm",
                          style: tt.headlineMedium?.copyWith(
                            color: cs.onPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'MB kursi: ${cur.date}',
                        style: tt.bodySmall?.copyWith(color: cs.onPrimary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              ChangeBadge(c: cur),
              const SizedBox(width: 8),
              Text(
                '${up ? '+' : ''}${fmt(cur.diffPerUnit)} kechagiga nisbatan',
                style: tt.bodySmall?.copyWith(color: diffColor),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Davr tanlash
          SizedBox(
            width: double.infinity,
            child: SegmentedButton<int>(
              showSelectedIcon: false,
              segments: const [
                ButtonSegment(value: 7, label: Text('7 kun')),
                ButtonSegment(value: 30, label: Text('30 kun')),
                ButtonSegment(value: 90, label: Text('90 kun')),
              ],
              selected: {_days},
              onSelectionChanged: (s) {
                _days = s.first;
                _reload();
              },
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(height: 240, child: chart),
          const SizedBox(height: 8),
          Row(
            children: [
              _Stat(label: 'Eng past', value: sMin),
              _Stat(label: "O'rtacha", value: sAvg),
              _Stat(label: 'Eng yuqori', value: sMax),
              _Stat(label: 'Davr', value: sChg, color: chgColor),
            ],
          ),
          const SizedBox(height: 24),

          if (_hist.length >= 4) ...[
            _Insights(pts: _hist),
            const SizedBox(height: 24),
          ],

          // Kalkulyator
          Text('Tezkor hisoblash',
              style: tt.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          TextField(
            controller: _amount,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9., ]'))],
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              labelText: 'Miqdor',
              suffixText: cur.code,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "= ${fmt(amount * cur.perUnit, digits: 2)} so'm",
            style: tt.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),

          // Signal
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                const Icon(Icons.notifications_active_outlined),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    alert == null
                        ? 'Kurs kerakli darajaga yetganda xabar oling'
                        : "Signal: ${alert.above ? '≥' : '≤'} ${fmt(alert.target)} so'm",
                  ),
                ),
                if (alert != null)
                  IconButton(
                    tooltip: "O'chirish",
                    onPressed: () => ctrl.removeAlert(cur.code),
                    icon: const Icon(Icons.delete_outline),
                  ),
                TextButton(
                  onPressed: () => _editAlert(ctrl, cur),
                  child: Text(alert == null ? "Qo'shish" : "O'zgartirish"),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String label, value;
  final Color? color;
  const _Stat({required this.label, required this.value, this.color});

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Expanded(
      child: Column(
        children: [
          Text(label,
              style: tt.bodySmall
                  ?.copyWith(color: Theme.of(context).colorScheme.outline)),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: TextStyle(fontWeight: FontWeight.bold, color: color),
            ),
          ),
        ],
      ),
    );
  }
}

/// Tarix asosida oddiy tahlil (maslahat emas, faqat statistika).
class _Insights extends StatelessWidget {
  final List<HistoryPoint> pts;
  const _Insights({required this.pts});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final vals = pts.map((p) => p.value).toList();
    final n = vals.length;
    final mean = vals.reduce((a, b) => a + b) / n;
    var varSum = 0.0;
    for (final v in vals) {
      varSum += (v - mean) * (v - mean);
    }
    final vol = mean == 0 ? 0.0 : math.sqrt(varSum / n) / mean * 100;
    final first = vals.first;
    final last = vals.last;
    final chg = first == 0 ? 0.0 : (last - first) / first * 100;
    final vsAvg = mean == 0 ? 0.0 : (last - mean) / mean * 100;

    var iMax = 0, iMin = 0;
    for (var i = 0; i < n; i++) {
      if (vals[i] > vals[iMax]) iMax = i;
      if (vals[i] < vals[iMin]) iMin = i;
    }

    final volLabel = vol < 0.4 ? 'past' : (vol < 1.2 ? "o'rtacha" : 'yuqori');
    final moveWord = chg > 0 ? 'oshdi' : (chg < 0 ? 'tushdi' : "o'zgarmadi");
    final avgWord = vsAvg >= 0 ? 'yuqori' : 'past';

    Widget line(IconData icon, String text) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: cs.primary),
          const SizedBox(width: 12),
          Expanded(child: Text(text)),
        ],
      ),
    );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tahlil',
            style: Theme.of(context)
                .textTheme
                .titleSmall
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          line(
            chg > 0
                ? Icons.trending_up
                : (chg < 0 ? Icons.trending_down : Icons.trending_flat),
            "Davr mobaynida kurs ${chg.abs().toStringAsFixed(2)}% $moveWord",
          ),
          line(
            Icons.straighten,
            "Joriy kurs davr o'rtachasidan ${vsAvg.abs().toStringAsFixed(2)}% $avgWord",
          ),
          line(
            Icons.show_chart,
            "O'zgaruvchanlik: $volLabel (${vol.toStringAsFixed(2)}%)",
          ),
          line(
            Icons.event,
            "Eng yuqori kurs: ${fmtDate(pts[iMax].date)}\nEng past kurs: ${fmtDate(pts[iMin].date)}",
          ),
        ],
      ),
    );
  }
}