import 'package:flutter/material.dart';

import '../models/currency.dart';
import '../utils/format.dart';

class ConverterView extends StatefulWidget {
  final List<Currency> all;
  const ConverterView({super.key, required this.all});

  @override
  State<ConverterView> createState() => _ConverterViewState();
}

class _ConverterViewState extends State<ConverterView> {
  final _ctrl = TextEditingController(text: '1');
  String _from = 'USD';
  String _to = 'UZS';

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  double _rate(String code) {
    if (code == 'UZS') return 1;
    for (final c in widget.all) {
      if (c.code == code) return c.perUnit;
    }
    return 1;
  }

  @override
  Widget build(BuildContext context) {
    final codes = ['UZS', ...widget.all.map((c) => c.code)];
    if (!codes.contains(_from)) _from = codes.length > 1 ? codes[1] : 'UZS';
    if (!codes.contains(_to)) _to = 'UZS';

    final amount =
        double.tryParse(_ctrl.text.replaceAll(' ', '').replaceAll(',', '.')) ??
            0;
    final unit = _rate(_from) / _rate(_to);
    final result = amount * unit;
    final cs = Theme.of(context).colorScheme;

    Widget dropdown(String value, ValueChanged<String> onChanged) {
      return DropdownButton<String>(
        value: value,
        isExpanded: true,
        items: codes
            .map((c) => DropdownMenuItem(value: c, child: Text(c)))
            .toList(),
        onChanged: (v) {
          if (v != null) onChanged(v);
        },
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        TextField(
          controller: _ctrl,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          onChanged: (_) => setState(() {}),
          style: const TextStyle(fontSize: 24),
          decoration: InputDecoration(
            labelText: 'Miqdor',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: dropdown(_from, (v) => setState(() => _from = v))),
            IconButton(
              onPressed: () => setState(() {
                final t = _from;
                _from = _to;
                _to = t;
              }),
              icon: const Icon(Icons.swap_horiz),
            ),
            Expanded(child: dropdown(_to, (v) => setState(() => _to = v))),
          ],
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: cs.primaryContainer,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            children: [
              Text('${fmt(amount, digits: 2)} $_from =',
                  style: Theme.of(context).textTheme.bodyLarge),
              const SizedBox(height: 8),
              Text(
                '${fmt(result)} $_to',
                textAlign: TextAlign.center,
                style: Theme.of(context)
                    .textTheme
                    .headlineMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text('1 $_from = ${fmt(unit)} $_to',
                  style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
      ],
    );
  }
}