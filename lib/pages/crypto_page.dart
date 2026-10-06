import 'package:flutter/material.dart';

import '../controllers/app_controller.dart';
import '../models/crypto.dart';
import '../models/currency.dart';
import '../utils/format.dart';
import '../widgets/currency_tile.dart';
import '../widgets/history_chart.dart';
import '../widgets/sparkline.dart';
import '../widgets/states.dart';

const _coinColors = <Color>[
  Colors.orange,
  Colors.indigo,
  Colors.teal,
  Colors.pink,
  Colors.blue,
  Colors.green,
  Colors.purple,
  Colors.brown,
];

class CryptoPage extends StatelessWidget {
  const CryptoPage({super.key});

  @override
  Widget build(BuildContext context) {
    final c = AppScope.of(context);
    final cs = Theme.of(context).colorScheme;

    if (c.cryptoLoading && c.crypto.isEmpty) return const SkeletonList();
    if (c.crypto.isEmpty) {
      return ErrorView(
        message: c.cryptoError ?? "Ma'lumot yo'q",
        onRetry: c.refreshCrypto,
      );
    }

    final usd = c.rateOf('USD');
    return RefreshIndicator(
      onRefresh: c.refreshCrypto,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Text(
              c.cryptoFromCache
                  ? "Oflayn: saqlangan narxlar. Yangilash uchun pastga torting."
                  : "Narxlar CoinGecko'dan (USD). So'mdagi qiymat MB kursi bo'yicha hisoblangan.",
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: cs.outline),
            ),
          ),
          for (final x in c.crypto)
            _CoinTile(
              coin: x,
              usd: usd,
              onTap: () => _showCoin(context, x, usd),
            ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  void _showCoin(BuildContext context, CryptoCoin coin, double? usd) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) {
        final cs = Theme.of(ctx).colorScheme;
        final tt = Theme.of(ctx).textTheme;
        final n = coin.spark.length;
        final now = DateTime.now();
        final pts = [
          for (var i = 0; i < n; i++)
            HistoryPoint(now.subtract(Duration(hours: n - 1 - i)), coin.spark[i]),
        ];
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '${coin.name} (${coin.symbol})',
                      style: tt.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ),
                  PctBadge(pct: coin.change24h),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '\$${fmt(coin.price)}',
                style: tt.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              if (usd != null)
                Text(
                  "≈ ${fmt(coin.price * usd, digits: 0)} so'm",
                  style: tt.bodyMedium?.copyWith(color: cs.outline),
                ),
              const SizedBox(height: 16),
              if (n >= 2)
                SizedBox(
                  height: 260,
                  child: HistoryChart(points: pts, color: cs.primary),
                )
              else
                const SizedBox(
                  height: 120,
                  child: Center(child: Text("Grafik uchun ma'lumot yo'q")),
                ),
              const SizedBox(height: 8),
              Text(
                'Oxirgi 7 kun (soatlik)',
                style: tt.bodySmall?.copyWith(color: cs.outline),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _CoinTile extends StatelessWidget {
  final CryptoCoin coin;
  final double? usd;
  final VoidCallback onTap;
  const _CoinTile({required this.coin, required this.usd, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final color = _coinColors[coin.symbol.codeUnitAt(0) % _coinColors.length];
    final up = coin.spark.length >= 2
        ? coin.spark.last >= coin.spark.first
        : coin.change24h >= 0;
    final letters =
    coin.symbol.length > 3 ? coin.symbol.substring(0, 3) : coin.symbol;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              alignment: Alignment.center,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              child: Text(
                letters,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    coin.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  Text(
                    coin.symbol,
                    style: tt.bodySmall?.copyWith(color: cs.outline),
                  ),
                ],
              ),
            ),
            Sparkline(
              values: coin.spark,
              color: up ? Colors.green : Colors.red,
            ),
            const SizedBox(width: 12),
            SizedBox(
              width: 104,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      '\$${fmt(coin.price)}',
                      style: tt.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ),
                  if (usd != null)
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        "${fmt(coin.price * usd!, digits: 0)} so'm",
                        style: tt.bodySmall?.copyWith(color: cs.outline),
                      ),
                    ),
                  const SizedBox(height: 4),
                  PctBadge(pct: coin.change24h),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}