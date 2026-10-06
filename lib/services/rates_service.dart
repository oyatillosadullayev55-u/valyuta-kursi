import 'dart:convert';
import 'dart:math' as math;

import 'package:http/http.dart' as http;

import '../models/currency.dart';
import 'storage.dart';

const _api = 'https://cbu.uz/uz/arkhiv-kursov-valyut/json/';

class RatesResult {
  final List<Currency> list;
  final bool fromCache;
  final DateTime? savedAt;
  RatesResult(this.list, this.fromCache, this.savedAt);
}

List<Currency> _parse(String body) => (jsonDecode(body) as List)
    .map((e) => Currency.fromJson(e as Map<String, dynamic>))
    .toList();

Future<RatesResult> loadRates() async {
  try {
    final res =
    await http.get(Uri.parse(_api)).timeout(const Duration(seconds: 15));
    if (res.statusCode != 200) throw Exception('HTTP ${res.statusCode}');
    final body = utf8.decode(res.bodyBytes);
    final list = _parse(body);
    if (list.isEmpty) throw Exception('empty');
    final now = DateTime.now();
    await prefs.setString('cache', body);
    await prefs.setInt('cache_time', now.millisecondsSinceEpoch);
    return RatesResult(list, false, now);
  } catch (_) {
    final cached = prefs.getString('cache');
    if (cached != null) {
      final t = prefs.getInt('cache_time');
      return RatesResult(
        _parse(cached),
        true,
        t == null ? null : DateTime.fromMillisecondsSinceEpoch(t),
      );
    }
    rethrow;
  }
}

Future<void> clearRatesCache() async {
  await prefs.remove('cache');
  await prefs.remove('cache_time');
}

String _d(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

Future<double?> _rateOn(String code, DateTime day) async {
  try {
    final res = await http
        .get(Uri.parse('$_api$code/${_d(day)}/'))
        .timeout(const Duration(seconds: 15));
    final data = jsonDecode(utf8.decode(res.bodyBytes)) as List;
    if (data.isEmpty) return null;
    return Currency.fromJson(data.first as Map<String, dynamic>).perUnit;
  } catch (_) {
    return null;
  }
}

/// Oxirgi [days] kunlik tarix. Uzun davrlarda so'rovlar soni
/// ~30 tagacha kamaytiriladi (har n-kun).
Future<List<HistoryPoint>> loadHistory(String code, int days) async {
  final step = days > 30 ? (days / 30).ceil() : 1;
  final backs = <int>[];
  for (var b = days - 1; b > 0; b -= step) {
    backs.add(b);
  }
  backs.add(0);

  final now = DateTime.now();
  final out = <HistoryPoint>[];
  for (var i = 0; i < backs.length; i += 10) {
    final chunk = backs.sublist(i, math.min(i + 10, backs.length));
    final dates = chunk.map((b) => now.subtract(Duration(days: b))).toList();
    final res = await Future.wait(dates.map((d) => _rateOn(code, d)));
    for (var j = 0; j < dates.length; j++) {
      final v = res[j];
      if (v != null) out.add(HistoryPoint(dates[j], v));
    }
  }
  return out;
}