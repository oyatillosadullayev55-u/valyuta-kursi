import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../controllers/app_controller.dart';
import '../models/currency.dart';
import '../utils/format.dart';
import '../widgets/currency_tile.dart';
import 'detail_page.dart';

class RatesPage extends StatefulWidget {
  const RatesPage({super.key});

  @override
  State<RatesPage> createState() => _RatesPageState();
}

class _RatesPageState extends State<RatesPage> {
  final _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _open(Currency c) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => DetailPage(c: c)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = AppScope.of(context);
    final cs = Theme.of(context).colorScheme;
    final list = c.visible;

    const labels = {
      RateFilter.all: 'Hammasi',
      RateFilter.favorites: 'Sevimli',
      RateFilter.rising: "O'sayotgan",
      RateFilter.falling: 'Tushayotgan',
    };
    const sortLabels = {
      SortMode.byName: 'Nomi bo\'yicha',
      SortMode.byRate: 'Kursi bo\'yicha',
      SortMode.byChange: "O'zgarishi bo'yicha",
    };

    final stamp = StringBuffer();
    if (c.updatedAt != null) {
      stamp.write('Yangilangan: ${fmtDateTime(c.updatedAt!)}  •  ');
    }
    stamp.write('MB kursi: ${c.all.first.date}');

    final showStrip = c.query.isEmpty && c.filter == RateFilter.all;
    final strip = <Currency>[];
    for (final code in ['USD', 'EUR', 'RUB']) {
      final x = c.byCode(code);
      if (x != null) strip.add(x);
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 4, 0),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _search,
                  onChanged: c.setQuery,
                  decoration: InputDecoration(
                    hintText: 'Qidirish (USD, Yevro...)',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: c.query.isEmpty
                        ? null
                        : IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () {
                        _search.clear();
                        c.setQuery('');
                      },
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 0),
                  ),
                ),
              ),
              PopupMenuButton<SortMode>(
                tooltip: 'Saralash',
                icon: const Icon(Icons.sort),
                onSelected: c.setSort,
                itemBuilder: (_) => [
                  for (final s in SortMode.values)
                    CheckedPopupMenuItem<SortMode>(
                      value: s,
                      checked: c.sort == s,
                      child: Text(sortLabels[s]!),
                    ),
                ],
              ),
              IconButton(
                tooltip: 'Kurslarni nusxalash',
                icon: const Icon(Icons.copy_all_outlined),
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: c.ratesText()));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Kurslar nusxalandi'),
                      duration: Duration(seconds: 1),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
        SizedBox(
          height: 48,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            children: [
              for (final f in RateFilter.values)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                  child: ChoiceChip(
                    label: Text(labels[f]!),
                    selected: c.filter == f,
                    onSelected: (_) => c.setFilter(f),
                  ),
                ),
            ],
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: c.refresh,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                if (showStrip && strip.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
                    child: Row(
                      children: [
                        for (var i = 0; i < strip.length; i++)
                          Expanded(
                            child: Padding(
                              padding: EdgeInsets.only(left: i == 0 ? 0 : 8),
                              child: _MainCard(cur: strip[i], onTap: () => _open(strip[i])),
                            ),
                          ),
                      ],
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Text(
                    stamp.toString(),
                    textAlign: TextAlign.center,
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: cs.outline),
                  ),
                ),
                if (list.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(48),
                    child: Center(
                      child: Text(
                        c.filter == RateFilter.favorites
                            ? "Hali sevimli valyuta yo'q.\nYulduzcha bosib qo'shing."
                            : 'Hech narsa topilmadi',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: cs.outline),
                      ),
                    ),
                  ),
                for (final x in list)
                  CurrencyTile(
                    c: x,
                    fav: c.favorites.contains(x.code),
                    onTap: () => _open(x),
                    onFav: () => c.toggleFavorite(x.code),
                  ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _MainCard extends StatelessWidget {
  final Currency cur;
  final VoidCallback onTap;
  const _MainCard({required this.cur, required this.onTap});

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
              Row(
                children: [
                  FlagCircle(code: cur.code, size: 26),
                  const SizedBox(width: 6),
                  Text(cur.code,
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 8),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  fmt(cur.perUnit),
                  style: const TextStyle(
                      fontSize: 17, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 6),
              ChangeBadge(c: cur),
            ],
          ),
        ),
      ),
    );
  }
}