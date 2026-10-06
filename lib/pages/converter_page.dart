import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../controllers/app_controller.dart';
import '../services/storage.dart';
import '../utils/flags.dart';
import '../utils/format.dart';
import '../widgets/currency_picker.dart';

class ConverterPage extends StatefulWidget {
  const ConverterPage({super.key});

  @override
  State<ConverterPage> createState() => _ConverterPageState();
}

class _ConverterPageState extends State<ConverterPage> {
  final _ctrl = TextEditingController(text: '1');
  String _from = prefs.getString('conv_from') ?? 'USD';
  String _to = prefs.getString('conv_to') ?? 'UZS';

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  double get _amount =>
      double.tryParse(_ctrl.text.replaceAll(' ', '').replaceAll(',', '.')) ?? 0;

  void _save() {
    prefs.setString('conv_from', _from);
    prefs.setString('conv_to', _to);
  }

  Future<void> _pick(AppController c, bool isFrom) async {
    final r = await pickCurrency(context, c, isFrom ? _from : _to);
    if (r == null) return;
    setState(() {
      if (isFrom) {
        _from = r;
      } else {
        _to = r;
      }
    });
    _save();
  }

  @override
  Widget build(BuildContext context) {
    final c = AppScope.of(context);
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    if (c.rateOf(_from) == null) _from = c.all.first.code;
    if (c.rateOf(_to) == null) _to = 'UZS';

    final amount = _amount;
    final result = c.convert(amount, _from, _to) ?? 0;
    final unit = c.convert(1, _from, _to) ?? 0;
    final favs = c.favorites.where((x) => x != _from && c.rateOf(x) != null).toList()
      ..sort();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        TextField(
          controller: _ctrl,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9., ]'))],
          onChanged: (_) => setState(() {}),
          style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w600),
          decoration: InputDecoration(
            labelText: 'Miqdor',
            suffixText: _from,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          children: [
            for (final v in [1, 10, 100, 1000, 10000])
              ActionChip(
                label: Text(fmt(v.toDouble(), digits: 0)),
                onPressed: () => setState(() => _ctrl.text = '$v'),
              ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _SelectorCard(
                label: 'Beriladi',
                code: _from,
                onTap: () => _pick(c, true),
              ),
            ),
            IconButton(
              tooltip: 'Almashtirish',
              onPressed: () {
                setState(() {
                  final t = _from;
                  _from = _to;
                  _to = t;
                });
                _save();
              },
              icon: const Icon(Icons.swap_horiz),
            ),
            Expanded(
              child: _SelectorCard(
                label: 'Olinadi',
                code: _to,
                onTap: () => _pick(c, false),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
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
              Text(
                '${fmt(amount, digits: 2)} $_from =',
                style: tt.bodyLarge?.copyWith(color: cs.onPrimary),
              ),
              const SizedBox(height: 6),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  '${fmt(result)} $_to',
                  style: tt.headlineLarge?.copyWith(
                    color: cs.onPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '1 $_from = ${fmt(unit)} $_to',
                      style: tt.bodySmall?.copyWith(color: cs.onPrimary),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Nusxalash',
                    color: cs.onPrimary,
                    icon: const Icon(Icons.copy),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: fmt(result)));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Nusxalandi'),
                          duration: Duration(seconds: 1),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Text('Sevimli valyutalarda',
            style: tt.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        if (favs.isEmpty)
          Text(
            "Kurslar sahifasida yulduzcha bosib sevimli valyutalar qo'shing, "
                'natija bu yerda hammasida birdan ko\'rinadi.',
            style: tt.bodySmall?.copyWith(color: cs.outline),
          )
        else
          for (final code in favs)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Text(flagOf(code), style: const TextStyle(fontSize: 26)),
              title: Text(code, style: const TextStyle(fontWeight: FontWeight.bold)),
              trailing: Text(
                fmt(c.convert(amount, _from, code) ?? 0),
                style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
            ),
      ],
    );
  }
}

class _SelectorCard extends StatelessWidget {
  final String label, code;
  final VoidCallback onTap;
  const _SelectorCard({
    required this.label,
    required this.code,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Material(
      color: cs.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: cs.outline)),
              const SizedBox(height: 4),
              Row(
                children: [
                  Text(flagOf(code), style: const TextStyle(fontSize: 22)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(code,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                  const Icon(Icons.arrow_drop_down),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}