import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/currency.dart';
import 'storage.dart';

const _api = 'https://cbu.uz/uz/arkhiv-kursov-valyut/json/';

class RatesResult {
  final List<Currency> list;
  final bool fromCache;
  RatesResult(this.list, this.fromCache);
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
    await prefs.setString('cache', body);
    return RatesResult(list, false);
  } catch (_) {
    final cached = prefs.getString('cache');
    if (cached != null) return RatesResult(_parse(cached), true);
    rethrow;
  }
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

Future<List<double>> loadHistory(String code, int days) async {
  final now = DateTime.now();
  final results = await Future.wait(List.generate(
    days,
        (i) => _rateOn(code, now.subtract(Duration(days: days - 1 - i))),
  ));
  return results.whereType<double>().toList();
}