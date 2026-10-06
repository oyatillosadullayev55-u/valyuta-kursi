import 'package:flutter/material.dart';

import '../controllers/app_controller.dart';
import '../utils/flags.dart';

class _Opt {
  final String code, name;
  const _Opt(this.code, this.name);
}

/// Valyuta tanlash oynasi (qidiruv bilan). Tanlangan kodni qaytaradi.
Future<String?> pickCurrency(
    BuildContext context,
    AppController c,
    String selected,
    ) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => _PickerSheet(c: c, selected: selected),
  );
}

class _PickerSheet extends StatefulWidget {
  final AppController c;
  final String selected;
  const _PickerSheet({required this.c, required this.selected});

  @override
  State<_PickerSheet> createState() => _PickerSheetState();
}

class _PickerSheetState extends State<_PickerSheet> {
  String _q = '';

  @override
  Widget build(BuildContext context) {
    final all = <_Opt>[
      const _Opt('UZS', "O'zbek so'mi"),
      ...widget.c.all.map((x) => _Opt(x.code, x.name)),
    ];
    final q = _q.toLowerCase();
    final items = all
        .where((o) =>
    o.code.toLowerCase().contains(q) || o.name.toLowerCase().contains(q))
        .toList();

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.7,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: TextField(
                autofocus: false,
                onChanged: (v) => setState(() => _q = v),
                decoration: InputDecoration(
                  hintText: 'Valyutani qidiring',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: items.length,
                itemBuilder: (context, i) {
                  final o = items[i];
                  return ListTile(
                    leading: Text(flagOf(o.code), style: const TextStyle(fontSize: 26)),
                    title: Text(o.code,
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(o.name, maxLines: 1, overflow: TextOverflow.ellipsis),
                    trailing:
                    o.code == widget.selected ? const Icon(Icons.check) : null,
                    onTap: () => Navigator.pop(context, o.code),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}