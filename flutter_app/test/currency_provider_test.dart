import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:valyuta_kursi_app/providers/currency_provider.dart';
import 'package:valyuta_kursi_app/services/api_service.dart';
import 'package:valyuta_kursi_app/models/currency.dart';

List<Map<String, dynamic>> _mockData() => [
      {
        'id': '69', 'Ccy': 'USD', 'CcyNm_UZ': 'AQSh dollari',
        'CcyNm_RU': 'Доллар США', 'CcyNm_EN': 'US Dollar',
        'Nominal': '1', 'Rate': '12850.00', 'Diff': '100.00', 'Date': '07.11.2026',
      },
      {
        'id': '78', 'Ccy': 'EUR', 'CcyNm_UZ': 'Yevro',
        'CcyNm_RU': 'Евро', 'CcyNm_EN': 'Euro',
        'Nominal': '1', 'Rate': '14520.00', 'Diff': '-50.00', 'Date': '07.11.2026',
      },
      {
        'id': '90', 'Ccy': 'RUB', 'CcyNm_UZ': 'Rossiya rubli',
        'CcyNm_RU': 'Российский рубль', 'CcyNm_EN': 'Russian Ruble',
        'Nominal': '1', 'Rate': '162.00', 'Diff': '0.50', 'Date': '07.11.2026',
      },
    ];

CurrencyProvider _makeProvider({bool fail = false}) {
  SharedPreferences.setMockInitialValues({});
  final client = fail
      ? MockClient((_) async => throw Exception('Network error'))
      : MockClient((_) async => http.Response(
            jsonEncode(_mockData()),
            200,
            headers: {'content-type': 'application/json'},
          ));
  return CurrencyProvider(api: ApiService(client: client));
}

void main() {
  group('CurrencyProvider', () {
    test('initial state is idle', () {
      final p = _makeProvider();
      expect(p.state, LoadState.idle);
      expect(p.currencies, isEmpty);
    });

    test('fetchRates sets state to success', () async {
      final p = _makeProvider();
      await p.fetchRates();
      expect(p.state, LoadState.success);
      expect(p.currencies.length, 3);
    });

    test('fetchRates sets state to error on failure', () async {
      final p = _makeProvider(fail: true);
      await p.fetchRates();
      expect(p.state, LoadState.error);
      expect(p.errorMessage, isNotEmpty);
    });

    test('findByCode returns correct currency', () async {
      final p = _makeProvider();
      await p.fetchRates();
      final usd = p.findByCode('USD');
      expect(usd, isNotNull);
      expect(usd!.rate, 12850.0);
    });

    test('findByCode returns null for unknown code', () async {
      final p = _makeProvider();
      await p.fetchRates();
      expect(p.findByCode('XYZ'), isNull);
    });

    test('setSearch filters currencies', () async {
      final p = _makeProvider();
      await p.fetchRates();
      p.setSearch('usd');
      expect(p.filteredCurrencies.length, 1);
      expect(p.filteredCurrencies.first.code, 'USD');
    });

    test('setFilter by code', () async {
      final p = _makeProvider();
      await p.fetchRates();
      p.setFilter('EUR');
      expect(p.filteredCurrencies.length, 1);
      expect(p.filteredCurrencies.first.code, 'EUR');
    });

    test('setFilter all returns all currencies', () async {
      final p = _makeProvider();
      await p.fetchRates();
      p.setFilter('EUR');
      p.setFilter('all');
      expect(p.filteredCurrencies.length, 3);
    });

    test('converter calculates toAmount correctly', () async {
      final p = _makeProvider();
      await p.fetchRates();
      final usd = p.findByCode('USD')!;
      p.setFromCurrency(usd);
      p.setToCurrency(null); // UZS
      p.setFromAmount(1.0);
      expect(p.toAmount, closeTo(12850.0, 0.01));
    });

    test('converter USD to EUR calculation', () async {
      final p = _makeProvider();
      await p.fetchRates();
      final usd = p.findByCode('USD')!;
      final eur = p.findByCode('EUR')!;
      p.setFromCurrency(usd);
      p.setToCurrency(eur);
      p.setFromAmount(1.0);
      // 1 USD = 12850 UZS, 1 EUR = 14520 UZS → 1 USD ≈ 0.8849 EUR
      expect(p.toAmount, closeTo(12850.0 / 14520.0, 0.001));
    });

    test('swapCurrencies swaps from and to', () async {
      final p = _makeProvider();
      await p.fetchRates();
      final usd = p.findByCode('USD')!;
      final eur = p.findByCode('EUR')!;
      p.setFromCurrency(usd);
      p.setToCurrency(eur);
      p.swapCurrencies();
      expect(p.fromCurrency?.code, 'EUR');
      expect(p.toCurrency?.code, 'USD');
    });

    test('toggleTheme changes isDark', () {
      final p = _makeProvider();
      expect(p.isDark, isFalse);
      p.toggleTheme();
      expect(p.isDark, isTrue);
      p.toggleTheme();
      expect(p.isDark, isFalse);
    });

    test('popularCurrencies returns only USD EUR RUB GBP', () async {
      final p = _makeProvider();
      await p.fetchRates();
      final codes = p.popularCurrencies.map((c) => c.code).toList();
      expect(codes, containsAll(['USD', 'EUR', 'RUB']));
    });

    test('chartData returns 8 points', () async {
      final p = _makeProvider();
      await p.fetchRates();
      expect(p.chartData('USD').length, 8);
    });

    test('lastUpdated is set after fetchRates', () async {
      final p = _makeProvider();
      await p.fetchRates();
      expect(p.lastUpdated, isNotNull);
    });
  });
}
