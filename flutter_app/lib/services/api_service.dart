import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/currency.dart';

class ApiException implements Exception {
  final String message;
  const ApiException(this.message);
  @override
  String toString() => message;
}

class ApiService {
  static const String _baseUrl =
      'https://cbu.uz/uz/arkhiv-kursov-valyut/json/';
  static const Duration _timeout = Duration(seconds: 15);

  final http.Client _client;

  ApiService({http.Client? client}) : _client = client ?? http.Client();

  Future<List<Currency>> fetchRates() async {
    try {
      final response = await _client
          .get(Uri.parse(_baseUrl))
          .timeout(_timeout);

      if (response.statusCode != 200) {
        throw ApiException('Server xatosi: ${response.statusCode}');
      }

      final List<dynamic> json = jsonDecode(response.body);
      final currencies = json
          .map((e) => Currency.fromJson(e as Map<String, dynamic>))
          .where((c) => c.code.isNotEmpty && c.rate > 0)
          .toList();

      currencies.sort((a, b) {
        const popular = [
          'USD', 'EUR', 'RUB', 'GBP', 'JPY', 'CNY',
          'KZT', 'AZN', 'TRY', 'AED', 'CHF', 'AUD'
        ];
        final ia = popular.indexOf(a.code);
        final ib = popular.indexOf(b.code);
        if (ia != -1 && ib != -1) return ia.compareTo(ib);
        if (ia != -1) return -1;
        if (ib != -1) return 1;
        return a.code.compareTo(b.code);
      });

      return currencies;
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Internet aloqasini tekshiring: $e');
    }
  }

  void dispose() => _client.close();
}
