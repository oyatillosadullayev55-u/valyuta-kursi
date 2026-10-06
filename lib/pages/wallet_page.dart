import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../controllers/app_controller.dart';
import '../utils/flags.dart';
import '../utils/format.dart';
import '../widgets/currency_picker.dart';
import '../widgets/currency_tile.dart';
import '../widgets/donut_chart.dart';

const _palette = <Color>[
  Colors.deepPurple,
  Colors.teal,
  Colors.orange,
  Colors.pink,
  Colors.blue,
  Colors.green,
];

class _Row {
  final String code;
  final double amount, value;
  const _Row(this.code, this.amount, this.value);
}

String _plain(double v) => v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toString();

class WalletPage extends StatelessWidget {
  const WalletPage({super.key});

  Future<void> _edit(BuildContext context, AppController c, {String? code}) async {
    var sel = code ?? 'USD';
    if (c.rateOf(sel) == null) sel = 'UZS';
    final tc = TextEditingController(
      text: code == null ? '' : _plain(c.holdings[code] ?? 0),
    );

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          title: Text(code == null ? "Valyuta qo'shish" : "Miqdorni o'zgartirish"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: code != null
                    ? null
                    : () async {
                  final r = await pickCurrency(ctx, c, sel);
                  if (r != null) setS(() => sel = r);
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      Text(flagOf(sel), style: const TextStyle(fontSize: 26)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(sel,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16)),
                      ),
                      if (code == null) const Icon(Icons.arrow_drop_down),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: tc,
                autofocus: true,
                keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                ],
                decoration: InputDecoration(
                  labelText: 'Miqdor',
                  suffixText: sel,
                  border: const OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Bekor qilish'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Saqlash'),
            ),
          ],
        ),
      ),
    );

    if (ok == true) {
      final v = double.tryParse(tc.text.replaceAll(',', '.'));
      if (v != null && v > 0) {
        final old = c.holdings[sel];
        c.setHolding(sel, (code == null && old != null) ? old + v : v);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = AppScope.of(context);
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    final rows = c.holdings.entries
        .map((e) => _Row(e.key, e.value, e.value * (c.rateOf(e.key) ?? 0)))
        .toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final total = c.walletTotal;
    final dayChange = c.walletDayChange;
    final prev = total - dayChange;
    final pct = prev == 0 ? 0.0 : dayChange / prev * 100;
    final usd = c.rateOf('USD');

    final slices = <_Row>[...rows.take(5)];
    if (rows.length > 5) {
      final rest = rows.skip(5).fold<double>(0, (s, r) => s + r.value);
      slices.add(_Row('Boshqa', 0, rest));
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Umumiy balans',
                  style: tt.bodyMedium?.copyWith(color: cs.onPrimary)),
              const SizedBox(height: 6),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  "${fmt(total, digits: 0)} so'm",
                  style: tt.headlineMedium?.copyWith(
                    color: cs.onPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (usd != null && usd != 0)
                Text(
                  '≈ ${fmt(total / usd, digits: 2)} USD',
                  style: tt.bodyMedium?.copyWith(color: cs.onPrimary),
                ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Icon(
                    dayChange > 0
                        ? Icons.trending_up
                        : (dayChange < 0 ? Icons.trending_down : Icons.trending_flat),
                    color: cs.onPrimary,
                    size: 20,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      "${dayChange > 0 ? '+' : ''}${fmt(dayChange, digits: 0)} so'm (${pct.toStringAsFixed(2)}%) kechagiga nisbatan",
                      style: tt.bodySmall?.copyWith(color: cs.onPrimary),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: () => _edit(context, c),
          icon: const Icon(Icons.add),
          label: const Text("Valyuta qo'shish"),
        ),
        const SizedBox(height: 16),
        if (rows.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 32),
            child: Text(
              "Hamyon bo'sh.\nQo'lingizdagi valyutalarni qo'shing, umumiy qiymat va "
                  "kunlik o'zgarish avtomatik hisoblanadi.",
              textAlign: TextAlign.center,
              style: TextStyle(color: cs.outline),
            ),
          )
        else ...[
          if (total > 0)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  DonutChart(
                    size: 130,
                    values: [for (final s in slices) s.value],
                    colors: _palette,
                    center: Icon(Icons.account_balance_wallet_outlined,
                        color: cs.outline),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      children: [
                        for (var i = 0; i < slices.length; i++)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              children: [
                                Container(
                                  width: 10,
                                  height: 10,
                                  decoration: BoxDecoration(
                                    color: _palette[i % _palette.length],
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(child: Text(slices[i].code)),
                                Text(
                                  '${(slices[i].value / total * 100).toStringAsFixed(1)}%',
                                  style: const TextStyle(fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 8),
          for (final r in rows)
            InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => _edit(context, c, code: r.code),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    FlagCircle(code: r.code),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(r.code,
                              style: tt.titleSmall
                                  ?.copyWith(fontWeight: FontWeight.bold)),
                          Text(
                            '${fmt(r.amount, digits: 2)} ${r.code}',
                            style: tt.bodySmall?.copyWith(color: cs.outline),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      "${fmt(r.value, digits: 0)} so'm",
                      style: tt.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                      tooltip: "O'chirish",
                      onPressed: () => c.removeHolding(r.code),
                      icon: Icon(Icons.delete_outline, color: cs.outline),
                    ),
                  ],
                ),
              ),
            ),
        ],
        const SizedBox(height: 16),
      ],
    );
  }
}