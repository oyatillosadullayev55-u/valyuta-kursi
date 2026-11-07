import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/currency.dart';
import '../services/api_service.dart';

enum LoadState { idle, loading, success, error }

class CurrencyProvider extends ChangeNotifier {
  final ApiService _api;

  CurrencyProvider({ApiService? api}) : _api = api ?? ApiService();

  List<Currency> _currencies = [];
  LoadState _state = LoadState.idle;
  String _errorMessage = '';
  DateTime? _lastUpdated;
  String _searchQuery = '';
  String _filterCode = 'all';
  bool _isDark = false;

  // Converter
  Currency? _fromCurrency;
  Currency? _toCurrency;
  double _fromAmount = 1000000;
  double _toAmount = 0;

  // Getters
  List<Currency> get currencies => _currencies;
  LoadState get state => _state;
  String get errorMessage => _errorMessage;
  DateTime? get lastUpdated => _lastUpdated;
  String get searchQuery => _searchQuery;
  String get filterCode => _filterCode;
  bool get isDark => _isDark;
  Currency? get fromCurrency => _fromCurrency;
  Currency? get toCurrency => _toCurrency;
  double get fromAmount => _fromAmount;
  double get toAmount => _toAmount;
  bool get isLoading => _state == LoadState.loading;
  bool get hasError => _state == LoadState.error;

  List<Currency> get popularCurrencies => _currencies
      .where((c) => ['USD', 'EUR', 'RUB', 'GBP'].contains(c.code))
      .toList();

  List<Currency> get filteredCurrencies {
    var list = _currencies;
    if (_filterCode != 'all') {
      list = list.where((c) => c.code == _filterCode).toList();
    }
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      list = list.where((c) =>
          c.code.toLowerCase().contains(q) ||
          c.nameUz.toLowerCase().contains(q) ||
          c.nameEn.toLowerCase().contains(q)).toList();
    }
    return list;
  }

  Currency? findByCode(String code) {
    try {
      return _currencies.firstWhere((c) => c.code == code);
    } catch (_) {
      return null;
    }
  }

  Future<void> fetchRates() async {
    _state = LoadState.loading;
    _errorMessage = '';
    notifyListeners();

    try {
      _currencies = await _api.fetchRates();
      _state = LoadState.success;
      _lastUpdated = DateTime.now();

      // Init converter defaults
      if (_fromCurrency == null) {
        _fromCurrency = findByCode('USD');
        _toCurrency = null; // null = UZS
        _calcToAmount();
      }

      // Cache last update time
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('last_update', _lastUpdated!.toIso8601String());
    } catch (e) {
      _state = LoadState.error;
      _errorMessage = e.toString();

      // Try load cached data
      await _loadCached();
    }
    notifyListeners();
  }

  Future<void> _loadCached() async {
    final prefs = await SharedPreferences.getInstance();
    final ts = prefs.getString('last_update');
    if (ts != null) {
      _lastUpdated = DateTime.tryParse(ts);
    }
  }

  void setSearch(String q) {
    _searchQuery = q;
    notifyListeners();
  }

  void setFilter(String code) {
    _filterCode = code;
    notifyListeners();
  }

  void toggleTheme() {
    _isDark = !_isDark;
    notifyListeners();
  }

  // Converter
  void setFromCurrency(Currency? c) {
    _fromCurrency = c;
    _calcToAmount();
    notifyListeners();
  }

  void setToCurrency(Currency? c) {
    _toCurrency = c;
    _calcToAmount();
    notifyListeners();
  }

  void setFromAmount(double amount) {
    _fromAmount = amount;
    _calcToAmount();
    notifyListeners();
  }

  void swapCurrencies() {
    final temp = _fromCurrency;
    _fromCurrency = _toCurrency;
    _toCurrency = temp;
    _calcToAmount();
    notifyListeners();
  }

  void _calcToAmount() {
    final fromRate = _fromCurrency?.ratePerUnit ?? 1.0;
    final toRate = _toCurrency?.ratePerUnit ?? 1.0;
    if (toRate == 0) {
      _toAmount = 0;
      return;
    }
    _toAmount = (_fromAmount * fromRate) / toRate;
  }

  /// Simulated chart data (7 days trend based on diff)
  List<double> chartData(String code) {
    final c = findByCode(code);
    if (c == null) return List.filled(8, 0);
    final base = c.rate;
    final step = c.diff / 8;
    return List.generate(
        8, (i) => base - (step * (8 - i)) + (i % 2 == 0 ? 0 : step * 0.3));
  }

  @override
  void dispose() {
    _api.dispose();
    super.dispose();
  }
}
