import 'package:flutter/material.dart';

import '../models/crypto.dart';
import '../models/currency.dart';
import '../services/crypto_service.dart';
import '../services/rates_service.dart';
import '../services/storage.dart';
import '../utils/flags.dart';
import '../utils/format.dart';

const kAccents = <Color>[
  Colors.deepPurple,
  Colors.blue,
  Colors.teal,
  Colors.green,
  Colors.orange,
  Colors.pink,
];

enum SortMode { byName, byRate, byChange }

enum RateFilter { all, favorites, rising, falling }

int _idx(int? v, int max) => (v == null || v < 0 || v > max) ? 0 : v;

class AppController extends ChangeNotifier {
  // Ma'lumotlar
  List<Currency> all = [];
  bool loading = true;
  bool fromCache = false;
  String? error;
  DateTime? updatedAt;

  // Foydalanuvchi sozlamalari
  Set<String> favorites = {};
  Map<String, PriceAlert> alerts = {};
  ThemeMode themeMode = ThemeMode.system;
  int accent = 0;
  SortMode sort = SortMode.byName;
  RateFilter filter = RateFilter.all;
  String query = '';

  // Hamyon: valyuta kodi -> miqdor
  Map<String, double> holdings = {};

  // Kripto
  List<CryptoCoin> crypto = [];
  bool cryptoLoading = true;
  bool cryptoFromCache = false;
  String? cryptoError;

  final List<String> _pending = [];
  final Map<String, List<HistoryPoint>> _history = {};

  void init() {
    favorites = (prefs.getStringList('fav') ?? []).toSet();
    for (final s in prefs.getStringList('alerts') ?? <String>[]) {
      final a = PriceAlert.decode(s);
      if (a != null) alerts[a.code] = a;
    }
    themeMode = ThemeMode.values[_idx(prefs.getInt('theme'), 2)];
    accent = _idx(prefs.getInt('accent'), kAccents.length - 1);
    sort = SortMode.values[_idx(prefs.getInt('sort'), SortMode.values.length - 1)];
    for (final s in prefs.getStringList('wallet') ?? <String>[]) {
      final p = s.split('|');
      if (p.length != 2) continue;
      final v = double.tryParse(p[1]);
      if (v != null && v > 0) holdings[p[0]] = v;
    }
    refresh();
    refreshCrypto();
  }

  // ------------------------------------------------------------ Kurslar

  Future<void> refresh() async {
    if (all.isEmpty) {
      loading = true;
      notifyListeners();
    }
    try {
      final r = await loadRates();
      all = r.list;
      fromCache = r.fromCache;
      updatedAt = r.savedAt;
      error = null;
      if (!fromCache) _checkAlerts();
    } catch (_) {
      error = "Ma'lumotni yuklab bo'lmadi.\nInternetni tekshirib, qayta urinib ko'ring.";
    }
    loading = false;
    notifyListeners();
  }

  /// 1 birlik valyutaning so'mdagi narxi (UZS uchun 1).
  double? rateOf(String code) {
    if (code == 'UZS') return 1;
    for (final c in all) {
      if (c.code == code) return c.perUnit;
    }
    return null;
  }

  double? convert(double amount, String from, String to) {
    final a = rateOf(from);
    final b = rateOf(to);
    if (a == null || b == null || b == 0) return null;
    return amount * a / b;
  }

  Currency? byCode(String code) {
    for (final c in all) {
      if (c.code == code) return c;
    }
    return null;
  }

  List<Currency> get visible {
    final q = query.trim().toLowerCase();
    final list = all.where((c) {
      if (q.isNotEmpty &&
          !c.code.toLowerCase().contains(q) &&
          !c.name.toLowerCase().contains(q)) {
        return false;
      }
      return switch (filter) {
        RateFilter.all => true,
        RateFilter.favorites => favorites.contains(c.code),
        RateFilter.rising => c.diff > 0,
        RateFilter.falling => c.diff < 0,
      };
    }).toList();

    list.sort((a, b) {
      final fa = favorites.contains(a.code) ? 0 : 1;
      final fb = favorites.contains(b.code) ? 0 : 1;
      if (fa != fb) return fa - fb;
      return switch (sort) {
        SortMode.byName => a.name.compareTo(b.name),
        SortMode.byRate => b.perUnit.compareTo(a.perUnit),
        SortMode.byChange =>
            b.changePercent.abs().compareTo(a.changePercent.abs()),
      };
    });
    return list;
  }

  // ------------------------------------------------------------ Tarix

  Future<List<HistoryPoint>> history(String code, int days,
      {bool force = false}) async {
    final key = '$code-$days';
    final cached = _history[key];
    if (cached != null && !force) return cached;
    final h = await loadHistory(code, days);
    if (h.length >= 2) _history[key] = h;
    return h;
  }

  // ------------------------------------------------------------ Sevimlilar

  void toggleFavorite(String code) {
    if (favorites.contains(code)) {
      favorites.remove(code);
    } else {
      favorites.add(code);
    }
    prefs.setStringList('fav', favorites.toList());
    notifyListeners();
  }

  // ------------------------------------------------------------ Signallar

  void setAlert(PriceAlert a) {
    alerts[a.code] = a;
    _saveAlerts();
    notifyListeners();
  }

  void removeAlert(String code) {
    alerts.remove(code);
    _saveAlerts();
    notifyListeners();
  }

  void _saveAlerts() {
    prefs.setStringList('alerts', alerts.values.map((a) => a.encode()).toList());
  }

  void _checkAlerts() {
    final done = <String>[];
    alerts.forEach((code, a) {
      final cur = rateOf(code);
      if (cur == null) return;
      final hit = a.above ? cur >= a.target : cur <= a.target;
      if (hit) {
        _pending.add("$code kursi maqsadga yetdi: ${fmt(cur)} so'm");
        done.add(code);
      }
    });
    for (final c in done) {
      alerts.remove(c);
    }
    if (done.isNotEmpty) _saveAlerts();
  }

  bool get hasPending => _pending.isNotEmpty;

  List<String> takePending() {
    final l = List<String>.from(_pending);
    _pending.clear();
    return l;
  }

  // ------------------------------------------------------------ Hamyon

  void setHolding(String code, double amount) {
    if (amount <= 0) {
      holdings.remove(code);
    } else {
      holdings[code] = amount;
    }
    _saveWallet();
    notifyListeners();
  }

  void removeHolding(String code) {
    holdings.remove(code);
    _saveWallet();
    notifyListeners();
  }

  void _saveWallet() {
    prefs.setStringList(
      'wallet',
      holdings.entries.map((e) => '${e.key}|${e.value}').toList(),
    );
  }

  /// Hamyonning so'mdagi umumiy qiymati.
  double get walletTotal {
    var t = 0.0;
    holdings.forEach((code, a) {
      final r = rateOf(code);
      if (r != null) t += a * r;
    });
    return t;
  }

  /// Hamyon qiymatining kechagiga nisbatan o'zgarishi (so'mda).
  double get walletDayChange {
    var t = 0.0;
    holdings.forEach((code, a) {
      final cur = byCode(code);
      if (cur != null) t += a * cur.diffPerUnit;
    });
    return t;
  }

  // ------------------------------------------------------------ Kripto

  Future<void> refreshCrypto() async {
    if (crypto.isEmpty) {
      cryptoLoading = true;
      notifyListeners();
    }
    try {
      final r = await loadCrypto();
      crypto = r.list;
      cryptoFromCache = r.fromCache;
      cryptoError = null;
    } catch (_) {
      cryptoError =
      "Kripto narxlarni yuklab bo'lmadi.\nBiroz keyin qayta urinib ko'ring.";
    }
    cryptoLoading = false;
    notifyListeners();
  }

  // ------------------------------------------------------------ Ulashish

  /// Kurslarni matn ko'rinishida (sevimlilar yoki USD/EUR/RUB).
  String ratesText() {
    final codes = favorites.isNotEmpty
        ? (favorites.toList()..sort())
        : <String>['USD', 'EUR', 'RUB'];
    final b = StringBuffer('📊 Valyuta kurslari (MB)');
    if (all.isNotEmpty) b.write(' — ${all.first.date}');
    b.writeln();
    for (final code in codes) {
      final c = byCode(code);
      if (c == null) continue;
      b.writeln("${flagOf(c.code)} 1 ${c.code} = ${fmt(c.perUnit)} so'm");
    }
    return b.toString().trim();
  }

  // ------------------------------------------------------------ Sozlamalar

  void setThemeMode(ThemeMode m) {
    themeMode = m;
    prefs.setInt('theme', m.index);
    notifyListeners();
  }

  void setAccent(int i) {
    accent = i;
    prefs.setInt('accent', i);
    notifyListeners();
  }

  void setSort(SortMode s) {
    sort = s;
    prefs.setInt('sort', s.index);
    notifyListeners();
  }

  void setFilter(RateFilter f) {
    filter = f;
    notifyListeners();
  }

  void setQuery(String q) {
    query = q;
    notifyListeners();
  }

  Future<void> clearCache() async {
    await clearRatesCache();
    _history.clear();
    updatedAt = null;
    notifyListeners();
  }
}

/// Controllerni butun ilova bo'ylab ulashadi.
class AppScope extends InheritedNotifier<AppController> {
  const AppScope({
    super.key,
    required AppController controller,
    required super.child,
  }) : super(notifier: controller);

  /// build() ichida ishlatiladi (o'zgarishda qayta chizadi).
  static AppController of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AppScope>()!.notifier!;

  /// initState va tugma bosilganda ishlatiladi (qayta chizmaydi).
  static AppController read(BuildContext context) =>
      context.getInheritedWidgetOfExactType<AppScope>()!.notifier!;
}