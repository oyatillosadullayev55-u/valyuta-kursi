import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/currency_provider.dart';
import '../widgets/converter_card.dart';
import '../widgets/rate_table.dart';
import '../widgets/top_rates_card.dart';
import '../widgets/chart_card.dart';
import '../utils/app_theme.dart';
import '../utils/formatter.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _navIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CurrencyProvider>().fetchRates();
    });
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<CurrencyProvider>();
    final isDark = p.isDark;

    return Scaffold(
      appBar: _buildAppBar(context, p, isDark),
      body: _buildBody(context, p),
      bottomNavigationBar: _buildBottomNav(isDark),
    );
  }

  PreferredSizeWidget _buildAppBar(
      BuildContext context, CurrencyProvider p, bool isDark) {
    return AppBar(
      backgroundColor: AppTheme.primary,
      title: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.bar_chart, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 10),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Valyuta Kurslari',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.white)),
              Text('Markaziy bank rasmiy kurslari',
                  style: TextStyle(fontSize: 10, color: Colors.white70)),
            ],
          ),
        ],
      ),
      actions: [
        // Last update time
        if (p.lastUpdated != null)
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    Formatter.timeOnly(p.lastUpdated!),
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.white),
                  ),
                  Text(
                    Formatter.dateTime(p.lastUpdated!).split(' ')[0],
                    style: const TextStyle(
                        fontSize: 11, color: Colors.white70),
                  ),
                ],
              ),
            ),
          ),
        // Refresh
        if (p.isLoading)
          const Padding(
            padding: EdgeInsets.only(right: 8),
            child: Center(
                child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2))),
          )
        else
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () => p.fetchRates(),
            tooltip: 'Yangilash',
          ),
        // Language
        Container(
          margin: const EdgeInsets.only(right: 6),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15),
            borderRadius: BorderRadius.circular(8),
            border:
                Border.all(color: Colors.white.withOpacity(0.3)),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('🇺🇿', style: TextStyle(fontSize: 14)),
              SizedBox(width: 4),
              Text('UZ',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.white)),
              SizedBox(width: 2),
              Icon(Icons.keyboard_arrow_down,
                  size: 14, color: Colors.white),
            ],
          ),
        ),
        // Dark mode
        IconButton(
          icon: Icon(
            isDark ? Icons.light_mode : Icons.dark_mode,
            color: Colors.white,
          ),
          onPressed: () => p.toggleTheme(),
        ),
      ],
    );
  }

  Widget _buildBody(BuildContext context, CurrencyProvider p) {
    if (_navIndex == 0) return _buildHomeTab(context, p);
    if (_navIndex == 1) return _buildRatesTab(context, p);
    if (_navIndex == 2) return _buildChartTab(context, p);
    return _buildNewsTab(context);
  }

  Widget _buildHomeTab(BuildContext context, CurrencyProvider p) {
    return RefreshIndicator(
      onRefresh: () => p.fetchRates(),
      color: AppTheme.primary,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Hero banner
            _HeroBanner(),
            const SizedBox(height: 16),

            // Error bar
            if (p.hasError)
              _ErrorBar(message: p.errorMessage),

            // Main content: Converter + Top rates side by side on wide screens
            LayoutBuilder(builder: (context, constraints) {
              if (constraints.maxWidth > 700) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 3, child: ConverterCard()),
                    const SizedBox(width: 16),
                    Expanded(flex: 2, child: TopRatesCard()),
                  ],
                );
              }
              return Column(children: [
                const ConverterCard(),
                const SizedBox(height: 16),
                const TopRatesCard(),
              ]);
            }),
            const SizedBox(height: 16),

            // Rate table
            const RateTable(),
            const SizedBox(height: 16),

            // Chart
            const ChartCard(),
            const SizedBox(height: 16),

            // Footer
            _Footer(),
          ],
        ),
      ),
    );
  }

  Widget _buildRatesTab(BuildContext context, CurrencyProvider p) {
    return RefreshIndicator(
      onRefresh: () => p.fetchRates(),
      color: AppTheme.primary,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: const RateTable(),
      ),
    );
  }

  Widget _buildChartTab(BuildContext context, CurrencyProvider p) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: const ChartCard(),
    );
  }

  Widget _buildNewsTab(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.newspaper, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 12),
          const Text('Yangiliklar bo\'limi',
              style:
                  TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          const Text('Tez orada...',
              style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildBottomNav(bool isDark) {
    return NavigationBar(
      selectedIndex: _navIndex,
      onDestinationSelected: (i) => setState(() => _navIndex = i),
      backgroundColor:
          isDark ? AppTheme.cardDark : AppTheme.cardLight,
      indicatorColor: AppTheme.primaryLight,
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.home_outlined),
          selectedIcon: Icon(Icons.home, color: AppTheme.primary),
          label: 'Bosh sahifa',
        ),
        NavigationDestination(
          icon: Icon(Icons.bar_chart_outlined),
          selectedIcon:
              Icon(Icons.bar_chart, color: AppTheme.primary),
          label: 'Valyutalar',
        ),
        NavigationDestination(
          icon: Icon(Icons.show_chart_outlined),
          selectedIcon:
              Icon(Icons.show_chart, color: AppTheme.primary),
          label: 'Tarix',
        ),
        NavigationDestination(
          icon: Icon(Icons.newspaper_outlined),
          selectedIcon:
              Icon(Icons.newspaper, color: AppTheme.primary),
          label: 'Yangiliklar',
        ),
      ],
    );
  }
}

// ── Hero Banner ──
class _HeroBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1B8A4C), Color(0xFF0D5C33)],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Valyuta kurslarini\nkuzating',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            "O'zbekiston Markaziy bankining rasmiy kurslari — tez, aniq va qulay",
            style: TextStyle(fontSize: 13, color: Colors.white70),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 16,
            runSpacing: 8,
            children: [
              _BannerFeature(Icons.verified_outlined, 'Ishonchli\nma\'lumotlar'),
              _BannerFeature(Icons.bolt, 'Real vaqt\nrejimida'),
              _BannerFeature(Icons.devices, 'Qulay\ninterfeys'),
              _BannerFeature(Icons.phone_android, 'Barcha qurilmalarda\nmos'),
            ],
          ),
        ],
      ),
    );
  }
}

class _BannerFeature extends StatelessWidget {
  final IconData icon;
  final String label;
  const _BannerFeature(this.icon, this.label);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: Colors.white70, size: 16),
        const SizedBox(width: 5),
        Text(label,
            style: const TextStyle(fontSize: 11, color: Colors.white70)),
      ],
    );
  }
}

// ── Error Bar ──
class _ErrorBar extends StatelessWidget {
  final String message;
  const _ErrorBar({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.redLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.red.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded,
              color: AppTheme.red, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(message,
                style: const TextStyle(
                    fontSize: 13, color: AppTheme.red)),
          ),
          TextButton.icon(
            onPressed: () => context.read<CurrencyProvider>().fetchRates(),
            icon: const Icon(Icons.refresh, size: 16),
            label: const Text('Qayta'),
            style: TextButton.styleFrom(foregroundColor: AppTheme.red),
          ),
        ],
      ),
    );
  }
}

// ── Footer ──
class _Footer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Column(
        children: [
          Divider(),
          SizedBox(height: 8),
          Text(
            '© 2026 Valyuta Kurslari',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
          SizedBox(height: 4),
          Text(
            "Ma'lumot manbasi: O'zbekiston Respublikasi Markaziy banki",
            style: TextStyle(fontSize: 11, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
