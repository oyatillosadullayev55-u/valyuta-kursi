import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:valyuta_kursi_app/services/api_service.dart';
import 'package:valyuta_kursi_app/models/currency.dart';

void main() {
  group('ApiService', () {
    test('fetchRates returns list of currencies on success', () async {
      final mockJson = [
        {
          'id': '69',
          'Ccy': 'USD',
          'CcyNm_UZ': 'AQSh dollari',
          'CcyNm_RU': 'Доллар США',
          'CcyNm_EN': 'US Dollar',
          'Nominal': '1',
          'Rate': '12850.00',
          'Diff': '100.00',
          'Date': '07.11.2026',
        },
        {
          'id': '78',
          'Ccy': 'EUR',
          'CcyNm_UZ': 'Yevro',
          'CcyNm_RU': 'Евро',
          'CcyNm_EN': 'Euro',
          'Nominal': '1',
          'Rate': '14520.00',
          'Diff': '-50.00',
          'Date': '07.11.2026',
        },
      ];

      final mockClient = MockClient((_) async => http.Response(
            jsonEncode(mockJson),
            200,
            headers: {'content-type': 'application/json'},
          ));

      final service = ApiService(client: mockClient);
      final result = await service.fetchRates();

      expect(result, isA<List<Currency>>());
      expect(result.length, 2);
      expect(result.first.code, 'USD');
      expect(result.first.rate, 12850.0);
    });

    test('fetchRates sorts popular currencies first', () async {
      final mockJson = [
        {
          'id': '1', 'Ccy': 'PLN', 'CcyNm_UZ': 'Polsha zlotiyi',
          'CcyNm_RU': 'Польский злотый', 'CcyNm_EN': 'Polish Zloty',
          'Nominal': '1', 'Rate': '3200.00', 'Diff': '0', 'Date': '07.11.2026',
        },
        {
          'id': '69', 'Ccy': 'USD', 'CcyNm_UZ': 'AQSh dollari',
          'CcyNm_RU': 'Доллар США', 'CcyNm_EN': 'US Dollar',
          'Nominal': '1', 'Rate': '12850.00', 'Diff': '100', 'Date': '07.11.2026',
        },
      ];

      final mockClient = MockClient((_) async => http.Response(
            jsonEncode(mockJson),
            200,
            headers: {'content-type': 'application/json'},
          ));

      final service = ApiService(client: mockClient);
      final result = await service.fetchRates();

      expect(result.first.code, 'USD');
    });

    test('fetchRates throws ApiException on HTTP error', () async {
      final mockClient =
          MockClient((_) async => http.Response('Not Found', 404));

      final service = ApiService(client: mockClient);

      expect(
        () => service.fetchRates(),
        throwsA(isA<ApiException>()),
      );
    });

    test('fetchRates throws ApiException on network error', () async {
      final mockClient = MockClient((_) async => throw Exception('No network'));

      final service = ApiService(client: mockClient);

      expect(
        () => service.fetchRates(),
        throwsA(isA<ApiException>()),
      );
    });

    test('fetchRates filters out currencies with zero rate', () async {
      final mockJson = [
        {
          'id': '69', 'Ccy': 'USD', 'CcyNm_UZ': 'AQSh dollari',
          'CcyNm_RU': 'Доллар США', 'CcyNm_EN': 'US Dollar',
          'Nominal': '1', 'Rate': '0', 'Diff': '0', 'Date': '07.11.2026',
        },
        {
          'id': '78', 'Ccy': 'EUR', 'CcyNm_UZ': 'Yevro',
          'CcyNm_RU': 'Евро', 'CcyNm_EN': 'Euro',
          'Nominal': '1', 'Rate': '14520.00', 'Diff': '0', 'Date': '07.11.2026',
        },
      ];

      final mockClient = MockClient((_) async => http.Response(
            jsonEncode(mockJson),
            200,
            headers: {'content-type': 'application/json'},
          ));

      final service = ApiService(client: mockClient);
      final result = await service.fetchRates();

      expect(result.length, 1);
      expect(result.first.code, 'EUR');
    });
  });
}
