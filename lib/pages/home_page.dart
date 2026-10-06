import 'package:flutter/material.dart';

import '../controllers/app_controller.dart';
import '../widgets/states.dart';
import 'converter_page.dart';
import 'crypto_page.dart';
import 'rates_page.dart';
import 'settings_page.dart';
import 'wallet_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _tab = 0;
  static const _titles = [
    'Valyuta kursi',
    'Konvertor',
    'Hamyon',
    'Kripto',
    'Sozlamalar',
  ];

  Widget _gate(AppController c, Widget child) {
    if (c.loading) return const SkeletonList();
    if (c.all.isEmpty) {
      return ErrorView(
        message: c.error ?? "Ma'lumot yo'q",
        onRetry: c.refresh,
      );
    }
    return child;
  }

  @override
  Widget build(BuildContext context) {
    final c = AppScope.of(context);

    // Narx signali ishga tushsa, xabar ko'rsatamiz
    if (c.hasPending) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final msgs = c.takePending();
        if (msgs.isEmpty) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('🔔 ${msgs.join('\n')}'),
            duration: const Duration(seconds: 6),
            behavior: SnackBarBehavior.floating,
          ),
        );
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_tab]),
        actions: [
          if (c.fromCache)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 4),
              child: Icon(Icons.cloud_off, size: 20),
            ),
          IconButton(
            tooltip: 'Yangilash',
            onPressed: _tab == 3 ? c.refreshCrypto : c.refresh,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Column(
        children: [
          if (c.fromCache && !c.loading)
            Container(
              width: double.infinity,
              color: Theme.of(context).colorScheme.errorContainer,
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
              child: Text(
                "Oflayn rejim: saqlangan kurslar ko'rsatilmoqda",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onErrorContainer,
                  fontSize: 12,
                ),
              ),
            ),
          Expanded(
            child: IndexedStack(
              index: _tab,
              children: [
                _gate(c, const RatesPage()),
                _gate(c, const ConverterPage()),
                _gate(c, const WalletPage()),
                const CryptoPage(),
                const SettingsPage(),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (i) => setState(() => _tab = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.currency_exchange),
            label: 'Kurslar',
          ),
          NavigationDestination(
            icon: Icon(Icons.calculate_outlined),
            label: 'Konvertor',
          ),
          NavigationDestination(
            icon: Icon(Icons.account_balance_wallet_outlined),
            label: 'Hamyon',
          ),
          NavigationDestination(
            icon: Icon(Icons.currency_bitcoin),
            label: 'Kripto',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            label: 'Sozlamalar',
          ),
        ],
      ),
    );
  }
}