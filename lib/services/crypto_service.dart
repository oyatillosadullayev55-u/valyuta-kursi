import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/crypto.dart';
import 'storage.dart';

const _url = 'https://api.coingecko.com/api/v3/coins/markets'
    '?vs_currency=usd'
    '&ids=bitcoin,ethereum,tether,binancecoin,solana,ripple,the-open-network,dogecoin,tron,cardano'
    '&order=market_cap_desc&sparkline=true&price_change_percentage=24h';

class CryptoResult {
  final List<CryptoCoin> list;
  final bool fromCache;
  CryptoResult(this.list, this.fromCache);
}

List<CryptoCoin> _parse(String body) => (jsonDecode(body) as List)
    .map((e) => CryptoCoin.fromJson(e as Map<String, dynamic>))
    .toList();

Future<CryptoResult> loadCrypto() async {
  try {
    final res =
    await http.get(Uri.parse(_url)).timeout(const Duration(seconds: 15));
    if (res.statusCode != 200) throw Exception('HTTP ${res.statusCode}');
    final body = utf8.decode(res.bodyBytes);
    final list = _parse(body);
    if (list.isEmpty) throw Exception('empty');
    await prefs.setString('crypto_cache', body);
    return CryptoResult(list, false);
  } catch (_) {
    final cached = prefs.getString('crypto_cache');
    if (cached != null) return CryptoResult(_parse(cached), true);
    rethrow;
  }
}