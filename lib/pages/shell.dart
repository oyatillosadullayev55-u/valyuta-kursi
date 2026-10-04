import 'package:flutter/material.dart';

import '../models/currency.dart';
import '../services/rates_service.dart';
import '../services/storage.dart';
import 'converter_view.dart';
import 'rates_view.dart';

class Shell extends StatefulWidget {
  final bool dark;
  final VoidCallback onToggleTheme;
  const Shell({super.key, required this.dark, required this.onToggleTheme});

  @override
  State<Shell> createState() => _ShellState();
}

class _ShellState extends State<Shell> {
  int _tab = 0;
  List<Currency> _all = [];
  bool _loading = true;
  bool _cached = false;
  String? _error;
  final Set<String> _fav = (prefs.getStringList('fav') ?? []).toSet();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (_all.isEmpty) setState(() => _loading = true);
    try {
      final r = await loadRates();
      _all = r.list;
      _cached = r.fromCache;
      _error = null;
    } catch (_) {
      _error = 'Ma\'lumotni yuklab bo\'lmadi.\nInternetni tekshiring.';
    }
    if (mounted) setState(() => _loading = false);
  }

  void _toggleFav(String code) {
    setState(() {
      if (_fav.contains(code)) {
        _fav.remove(code);
      } else {
        _fav.add(code);
      }
    });
    prefs.setStringList('fav', _fav.toList());
  }

  @override
  Widget build(BuildContext context) {
    Widget body;
    if (_loading) {
      body = const Center(child: CircularProgressIndicator());
    } else if (_all.isEmpty) {
      body = Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_error ?? 'Ma\'lumot yo\'q', textAlign: TextAlign.center),
            const SizedBox(height: 12),
            FilledButton(onPressed: _load, child: const Text('Qayta urinish')),
          ],
        ),
      );
    } else {
      body = Column(
        children: [
          if (_cached)
            Container(
              width: double.infinity,
              color: Theme.of(context).colorScheme.errorContainer,
              padding: const EdgeInsets.all(8),
              child: const Text(
                'Oflayn rejim: saqlangan kurslar ko\'rsatilmoqda',
                textAlign: TextAlign.center,
              ),
            ),
          Expanded(
            child: IndexedStack(
              index: _tab,
              children: [
                RatesView(
                  all: _all,
                  fav: _fav,
                  onFav: _toggleFav,
                  onRefresh: _load,
                ),
                ConverterView(all: _all),
              ],
            ),
          ),
        ],
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_tab == 0 ? 'Valyuta kursi' : 'Konvertor'),
        actions: [
          IconButton(
            onPressed: widget.onToggleTheme,
            icon: Icon(widget.dark ? Icons.light_mode : Icons.dark_mode),
          ),
          IconButton(onPressed: _load, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: body,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (i) => setState(() => _tab = i),
        destinations: const [
          NavigationDestination(
              icon: Icon(Icons.currency_exchange), label: 'Kurslar'),
          NavigationDestination(
              icon: Icon(Icons.calculate_outlined), label: 'Konvertor'),
        ],
      ),
    );
  }
}