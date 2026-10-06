import 'package:flutter/material.dart';

import '../models/currency.dart';
import '../utils/flags.dart';
import '../utils/format.dart';

/// Foiz nishonchasi (+0.25%).
class PctBadge extends StatelessWidget {
  final double pct;
  const PctBadge({super.key, required this.pct});

  @override
  Widget build(BuildContext context) {
    final up = pct > 0;
    final down = pct < 0;
    final color = up
        ? Colors.green
        : (down ? Colors.red : Theme.of(context).colorScheme.outline);
    final sign = up ? '+' : '';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withAlpha(30),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '$sign${pct.toStringAsFixed(2)}%',
        style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600),
      ),
    );
  }
}

/// Valyutaning kechagiga nisbatan o'zgarish foizi.
class ChangeBadge extends StatelessWidget {
  final Currency c;
  const ChangeBadge({super.key, required this.c});

  @override
  Widget build(BuildContext context) => PctBadge(pct: c.changePercent);
}

class FlagCircle extends StatelessWidget {
  final String code;
  final double size;
  const FlagCircle({super.key, required this.code, this.size = 44});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        shape: BoxShape.circle,
      ),
      child: Text(flagOf(code), style: TextStyle(fontSize: size * 0.5)),
    );
  }
}

class CurrencyTile extends StatelessWidget {
  final Currency c;
  final bool fav;
  final VoidCallback onTap;
  final VoidCallback onFav;

  const CurrencyTile({
    super.key,
    required this.c,
    required this.fav,
    required this.onTap,
    required this.onFav,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.only(left: 16, top: 8, bottom: 8),
        child: Row(
          children: [
            FlagCircle(code: c.code),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    c.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    c.nominal > 1 ? '${c.code} • ${c.nominal} birlik' : c.code,
                    style: tt.bodySmall?.copyWith(color: cs.outline),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  fmt(c.perUnit),
                  style: tt.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                ChangeBadge(c: c),
              ],
            ),
            IconButton(
              onPressed: onFav,
              icon: Icon(
                fav ? Icons.star : Icons.star_border,
                color: fav ? Colors.amber : cs.outline,
              ),
            ),
          ],
        ),
      ),
    );
  }
}