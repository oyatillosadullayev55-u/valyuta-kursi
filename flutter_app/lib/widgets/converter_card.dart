import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/currency_provider.dart';
import '../models/currency.dart';
import '../utils/formatter.dart';
import '../utils/app_theme.dart';

class ConverterCard extends StatefulWidget {
  const ConverterCard({super.key});

  @override
  State<ConverterCard> createState() => _ConverterCardState();
}

class _ConverterCardState extends State<ConverterCard> {
  final _controller = TextEditingController();
  bool _editing = false;

  @override
  void initState() {
    super.initState();
    final p = context.read<CurrencyProvider>();
    _controller.text = Formatter.amount(p.fromAmount);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<CurrencyProvider>();
    final isDark = p.isDark;

    if (!_editing) {
      _controller.text = Formatter.amount(p.fromAmount);
    }

    final from = p.fromCurrency;
    final to = p.toCurrency;
    final toLabel = to?.code ?? 'UZS';
    final toFlag = to?.flag ?? '🇺🇿';

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryLight,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.calculate_outlined,
                      color: AppTheme.primary, size: 22),
                ),
                const SizedBox(width: 12),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Valyuta konvertori',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w700)),
                    Text('Real vaqt kurslari asosida',
                        style: TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
                ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppTheme.greenLight,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          color: AppTheme.primary,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Text('Jonli',
                          style: TextStyle(
                              fontSize: 12,
                              color: AppTheme.primary,
                              fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Input row
            Row(
              children: [
                // Amount
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Miqdor',
                          style: TextStyle(
                              fontSize: 12,
                              color: isDark
                                  ? AppTheme.mutedDark
                                  : AppTheme.mutedLight)),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _controller,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                              RegExp(r'[0-9\.]'))
                        ],
                        style: const TextStyle(
                            fontSize: 20, fontWeight: FontWeight.w700),
                        decoration: const InputDecoration(
                          hintText: '0',
                          suffixIcon: Icon(Icons.close, size: 18),
                        ),
                        onTap: () => setState(() => _editing = true),
                        onChanged: (v) {
                          final d = double.tryParse(
                                  v.replaceAll(',', '').replaceAll(' ', '')) ??
                              0;
                          context.read<CurrencyProvider>().setFromAmount(d);
                        },
                        onEditingComplete: () {
                          setState(() => _editing = false);
                          FocusScope.of(context).unfocus();
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),

                // From currency
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Asosiy valyuta',
                          style: TextStyle(
                              fontSize: 12,
                              color: isDark
                                  ? AppTheme.mutedDark
                                  : AppTheme.mutedLight)),
                      const SizedBox(height: 6),
                      _CurrencyDropdown(
                        selected: from,
                        currencies: p.currencies,
                        includeUzs: false,
                        onChanged: (c) =>
                            context.read<CurrencyProvider>().setFromCurrency(c),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),

                // Swap
                Padding(
                  padding: const EdgeInsets.only(top: 22),
                  child: GestureDetector(
                    onTap: () =>
                        context.read<CurrencyProvider>().swapCurrencies(),
                    child: Container(
                      width: 40,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppTheme.primary,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.swap_horiz,
                          color: Colors.white, size: 22),
                    ),
                  ),
                ),
                const SizedBox(width: 10),

                // To currency
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Qaytish valyuta',
                          style: TextStyle(
                              fontSize: 12,
                              color: isDark
                                  ? AppTheme.mutedDark
                                  : AppTheme.mutedLight)),
                      const SizedBox(height: 6),
                      _CurrencyDropdown(
                        selected: to,
                        currencies: p.currencies,
                        includeUzs: true,
                        onChanged: (c) =>
                            context.read<CurrencyProvider>().setToCurrency(c),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Result
            Container(
              width: double.infinity,
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: AppTheme.primary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${Formatter.amount(p.toAmount)} $toLabel',
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                      if (from != null)
                        Text(
                          '1 ${from.code} = ${Formatter.rate(from.ratePerUnit)} UZS  '
                          '${from.diff >= 0 ? '+' : ''}${Formatter.rate(from.diff)} '
                          '(${Formatter.percent(from.changePercent)})',
                          style: const TextStyle(
                              fontSize: 12,
                              color: Colors.white70,
                              fontWeight: FontWeight.w500),
                        ),
                    ],
                  ),
                  Column(
                    children: [
                      Text(toFlag, style: const TextStyle(fontSize: 28)),
                      Text(toLabel,
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 12)),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Hisoblash button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  setState(() => _editing = false);
                  FocusScope.of(context).unfocus();
                },
                icon: const Icon(Icons.calculate, size: 18),
                label: const Text('Hisoblash',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.primary,
                  side: const BorderSide(color: AppTheme.primary),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CurrencyDropdown extends StatelessWidget {
  final Currency? selected;
  final List<Currency> currencies;
  final bool includeUzs;
  final ValueChanged<Currency?> onChanged;

  const _CurrencyDropdown({
    required this.selected,
    required this.currencies,
    required this.includeUzs,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final items = <DropdownMenuItem<Currency?>>[];
    if (includeUzs) {
      items.add(const DropdownMenuItem(
        value: null,
        child: Row(children: [
          Text('🇺🇿', style: TextStyle(fontSize: 20)),
          SizedBox(width: 8),
          Text('UZS', style: TextStyle(fontWeight: FontWeight.w700)),
        ]),
      ));
    }
    for (final c in currencies) {
      items.add(DropdownMenuItem(
        value: c,
        child: Row(children: [
          Text(c.flag, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 8),
          Text(c.code,
              style: const TextStyle(fontWeight: FontWeight.w700)),
        ]),
      ));
    }

    return DropdownButtonFormField<Currency?>(
      value: selected,
      items: items,
      onChanged: onChanged,
      decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10)),
      isExpanded: true,
    );
  }
}
