import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/currency_provider.dart';
import '../models/currency.dart';
import '../utils/formatter.dart';
import '../utils/app_theme.dart';

class TopRatesCard extends StatelessWidget {
  const TopRatesCard({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.watch<CurrencyProvider>();
    final popular = p.popularCurrencies;

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.star, color: Color(0xFFFBBF24), size: 20),
                const SizedBox(width: 8),
                const Text('Bugungi asosiy kurslar',
                    style:
                        TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
              ],
            ),
            const SizedBox(height: 12),
            if (p.isLoading)
              const Center(
                  child: CircularProgressIndicator(
                      color: AppTheme.primary, strokeWidth: 2))
            else
              ...popular.map((c) => _TopRateRow(currency: c)),
          ],
        ),
      ),
    );
  }
}

class _TopRateRow extends StatelessWidget {
  final Currency currency;
  const _TopRateRow({required this.currency});

  @override
  Widget build(BuildContext context) {
    final isUp = currency.isUp;
    final color = isUp ? AppTheme.primary : AppTheme.red;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Text(currency.flag, style: const TextStyle(fontSize: 22)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(currency.code,
                style: const TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w600)),
          ),
          Text(
            '${Formatter.rate(currency.rate)} UZS',
            style:
                const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
          ),
          const SizedBox(width: 10),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
            decoration: BoxDecoration(
              color: isUp ? AppTheme.greenLight : AppTheme.redLight,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                    isUp ? Icons.arrow_upward : Icons.arrow_downward,
                    size: 11,
                    color: color),
                const SizedBox(width: 2),
                Text(
                  Formatter.percent(currency.changePercent),
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: color),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
