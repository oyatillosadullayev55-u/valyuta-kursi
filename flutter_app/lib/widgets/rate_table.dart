import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/currency_provider.dart';
import '../models/currency.dart';
import '../utils/formatter.dart';
import '../utils/app_theme.dart';

class RateTable extends StatelessWidget {
  const RateTable({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.watch<CurrencyProvider>();
    final currencies = p.filteredCurrencies;
    final isDark = p.isDark;

    return Card(
      margin: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryLight,
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: const Icon(Icons.bar_chart,
                      color: AppTheme.primary, size: 20),
                ),
                const SizedBox(width: 10),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Valyuta kurslari',
                        style: TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w700)),
                    Text('Markaziy bank rasmiy ma\'lumotlari',
                        style: TextStyle(fontSize: 11, color: Colors.grey)),
                  ],
                ),
                const Spacer(),
                // Search
                SizedBox(
                  width: 200,
                  child: TextField(
                    onChanged: (v) =>
                        context.read<CurrencyProvider>().setSearch(v),
                    style: const TextStyle(fontSize: 13),
                    decoration: InputDecoration(
                      hintText: 'Valyuta nomini qidiring...',
                      hintStyle: const TextStyle(fontSize: 13),
                      prefixIcon:
                          const Icon(Icons.search, size: 18),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      isDense: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Filter chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _FilterChip(code: 'all', label: 'Barchasi', icon: Icons.grid_view),
                _FilterChip(code: 'USD', label: 'USD', flag: '🇺🇸'),
                _FilterChip(code: 'EUR', label: 'EUR', flag: '🇪🇺'),
                _FilterChip(code: 'RUB', label: 'RUB', flag: '🇷🇺'),
                _FilterChip(code: 'GBP', label: 'GBP', flag: '🇬🇧'),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Table header
          Container(
            color: isDark ? AppTheme.bgDark : const Color(0xFFF8FAFC),
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Text('Valyuta',
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? AppTheme.mutedDark
                              : AppTheme.mutedLight)),
                ),
                Expanded(
                  flex: 1,
                  child: Text('Kod',
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? AppTheme.mutedDark
                              : AppTheme.mutedLight)),
                ),
                Expanded(
                  flex: 2,
                  child: Text('Markaziy bank kursi',
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? AppTheme.mutedDark
                              : AppTheme.mutedLight)),
                ),
                Expanded(
                  flex: 2,
                  child: Text("O'zgarish",
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? AppTheme.mutedDark
                              : AppTheme.mutedLight)),
                ),
                Expanded(
                  flex: 2,
                  child: Text("So'nggi yangilanish",
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? AppTheme.mutedDark
                              : AppTheme.mutedLight)),
                ),
                const SizedBox(width: 80),
              ],
            ),
          ),
          const Divider(height: 1),

          // Rows
          if (p.isLoading)
            const _LoadingRows()
          else if (currencies.isEmpty)
            const Padding(
              padding: EdgeInsets.all(40),
              child: Center(
                child: Text("Hech narsa topilmadi",
                    style: TextStyle(color: Colors.grey)),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: currencies.length,
              separatorBuilder: (_, __) =>
                  const Divider(height: 1, indent: 16, endIndent: 16),
              itemBuilder: (context, i) => _RateRow(currency: currencies[i]),
            ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String code;
  final String label;
  final String? flag;
  final IconData? icon;

  const _FilterChip(
      {required this.code, required this.label, this.flag, this.icon});

  @override
  Widget build(BuildContext context) {
    final p = context.watch<CurrencyProvider>();
    final isActive = p.filterCode == code;

    return Padding(
      padding: const EdgeInsets.only(right: 8, bottom: 8),
      child: GestureDetector(
        onTap: () => context.read<CurrencyProvider>().setFilter(code),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
            color: isActive ? AppTheme.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color:
                  isActive ? AppTheme.primary : AppTheme.borderLight,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (flag != null)
                Text(flag!, style: const TextStyle(fontSize: 14))
              else if (icon != null)
                Icon(icon, size: 14,
                    color: isActive ? Colors.white : Colors.grey),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isActive ? Colors.white : Colors.grey,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RateRow extends StatelessWidget {
  final Currency currency;
  const _RateRow({required this.currency});

  @override
  Widget build(BuildContext context) {
    final changeColor =
        currency.isUp ? AppTheme.primary : AppTheme.red;
    final changeBg =
        currency.isUp ? AppTheme.greenLight : AppTheme.redLight;
    final changeIcon =
        currency.isUp ? Icons.arrow_upward : Icons.arrow_downward;

    return InkWell(
      onTap: () {
        context.read<CurrencyProvider>().setFromCurrency(currency);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            // Name
            Expanded(
              flex: 3,
              child: Row(
                children: [
                  Text(currency.flag,
                      style: const TextStyle(fontSize: 24)),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(currency.nameUz,
                          style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600)),
                      Text(currency.nameEn,
                          style: const TextStyle(
                              fontSize: 11, color: Colors.grey)),
                    ],
                  ),
                ],
              ),
            ),
            // Code
            Expanded(
              flex: 1,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(currency.code,
                    style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey)),
              ),
            ),
            // Rate
            Expanded(
              flex: 2,
              child: Text(
                '${Formatter.rate(currency.rate)} UZS',
                style: const TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w700),
              ),
            ),
            // Change
            Expanded(
              flex: 2,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: changeBg,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(changeIcon, size: 12, color: changeColor),
                    const SizedBox(width: 3),
                    Text(
                      Formatter.percent(currency.changePercent),
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: changeColor),
                    ),
                  ],
                ),
              ),
            ),
            // Date
            Expanded(
              flex: 2,
              child: Text(
                '${currency.date} 16:00',
                style: const TextStyle(fontSize: 11, color: Colors.grey),
              ),
            ),
            // Detail button
            SizedBox(
              width: 80,
              child: OutlinedButton(
                onPressed: () => _showDetail(context, currency),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.primary,
                  side: const BorderSide(color: AppTheme.primary),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 6),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Batafsil',
                        style: TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w600)),
                    SizedBox(width: 3),
                    Icon(Icons.arrow_forward, size: 12),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDetail(BuildContext context, Currency c) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _CurrencyDetailSheet(currency: c),
    );
  }
}

class _CurrencyDetailSheet extends StatelessWidget {
  final Currency currency;
  const _CurrencyDetailSheet({required this.currency});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          Text(currency.flag, style: const TextStyle(fontSize: 48)),
          const SizedBox(height: 8),
          Text(currency.nameUz,
              style: const TextStyle(
                  fontSize: 20, fontWeight: FontWeight.w700)),
          Text(currency.code,
              style: const TextStyle(fontSize: 14, color: Colors.grey)),
          const SizedBox(height: 20),
          _DetailRow("Rasmiy kurs",
              '${Formatter.rate(currency.rate)} UZS'),
          _DetailRow("Nominal", '${currency.nominal} ${currency.code}'),
          _DetailRow("1 birlik uchun",
              '${Formatter.rate(currency.ratePerUnit)} UZS'),
          _DetailRow(
              "O'zgarish",
              '${Formatter.diff(currency.diff)} UZS '
              '(${Formatter.percent(currency.changePercent)})',
              color: currency.isUp ? AppTheme.primary : AppTheme.red),
          _DetailRow("Sana", currency.date),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                context.read<CurrencyProvider>().setFromCurrency(currency);
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Konvertorga qo\'shish',
                  style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? color;
  const _DetailRow(this.label, this.value, {this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(value,
              style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: color ?? Colors.black87)),
        ],
      ),
    );
  }
}

class _LoadingRows extends StatelessWidget {
  const _LoadingRows();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(
        5,
        (i) => Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Row(
            children: [
              Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(16))),
              const SizedBox(width: 10),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Container(
                    width: 120,
                    height: 12,
                    color: Colors.grey[200]),
                const SizedBox(height: 6),
                Container(
                    width: 80, height: 10, color: Colors.grey[100]),
              ]),
              const Spacer(),
              Container(
                  width: 80, height: 14, color: Colors.grey[200]),
            ],
          ),
        ),
      ),
    );
  }
}
