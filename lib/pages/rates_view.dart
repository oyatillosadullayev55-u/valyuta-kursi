import 'package:flutter/material.dart';

import '../models/currency.dart';
import '../utils/format.dart';
import 'detail_page.dart';

class RatesView extends StatefulWidget {
  final List<Currency> all;
  final Set<String> fav;
  final ValueChanged<String> onFav;
  final Future<void> Function() onRefresh;

  const RatesView({
    super.key,
    required this.all,
    required this.fav,
    required this.onFav,
    required this.onRefresh,
  });

  @override
  State<RatesView> createState() => _RatesViewState();
}

class _RatesViewState extends State<RatesView> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final q = _query.toLowerCase();
    final filtered = widget.all
        .where((c) =>
    c.code.toLowerCase().contains(q) ||
        c.name.toLowerCase().contains(q))
        .toList();
    final list = [
      ...filtered.where((c) => widget.fav.contains(c.code)),
      ...filtered.where((c) => !widget.fav.contains(c.code)),
    ];

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
          child: TextField(
            onChanged: (v) => setState(() => _query = v),
            decoration: InputDecoration(
              hintText: 'Qidirish (USD, EUR...)',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Text(
            'O\'zbekiston Markaziy banki • ${widget.all.first.date}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: widget.onRefresh,
            child: ListView.builder(
              itemCount: list.length,
              itemBuilder: (_, i) => _tile(list[i]),
            ),
          ),
        ),
      ],
    );
  }

  Widget _tile(Currency c) {
    final up = c.diff > 0;
    final down = c.diff < 0;
    final color = up ? Colors.green : (down ? Colors.red : Colors.grey);
    final isFav = widget.fav.contains(c.code);
    return ListTile(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => DetailPage(c: c)),
      ),
      leading: CircleAvatar(
        child: Text(c.code, style: const TextStyle(fontSize: 11)),
      ),
      title: Text(c.name, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text(c.nominal > 1 ? '${c.code} • ${c.nominal} birlik' : c.code),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('${fmt(c.perUnit)} so\'m',
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    up
                        ? Icons.arrow_drop_up
                        : (down ? Icons.arrow_drop_down : Icons.remove),
                    color: color,
                    size: 20,
                  ),
                  Text(fmt(c.diffPerUnit.abs()),
                      style: TextStyle(color: color, fontSize: 12)),
                ],
              ),
            ],
          ),
          IconButton(
            onPressed: () => widget.onFav(c.code),
            icon: Icon(isFav ? Icons.star : Icons.star_border,
                color: isFav ? Colors.amber : null),
          ),
        ],
      ),
    );
  }
}