import 'package:flutter_test/flutter_test.dart';
import 'package:valyuta_kursi_app/models/currency.dart';

void main() {
  group('Currency model', () {
    late Currency usd;
    late Currency eur;

    setUp(() {
      usd = const Currency(
        id: '69',
        code: 'USD',
        nameUz: 'AQSh dollari',
        nameRu: 'Доллар США',
        nameEn: 'US Dollar',
        nominal: 1,
        rate: 12850.0,
        diff: 100.0,
        date: '07.11.2026',
      );
      eur = const Currency(
        id: '78',
        code: 'EUR',
        nameUz: 'Yevro',
        nameRu: 'Евро',
        nameEn: 'Euro',
        nominal: 1,
        rate: 14520.0,
        diff: -50.0,
        date: '07.11.2026',
      );
    });

    test('fromJson parses correctly', () {
      final json = {
        'id': '69',
        'Ccy': 'USD',
        'CcyNm_UZ': 'AQSh dollari',
        'CcyNm_RU': 'Доллар США',
        'CcyNm_EN': 'US Dollar',
        'Nominal': '1',
        'Rate': '12850.00',
        'Diff': '100.00',
        'Date': '07.11.2026',
      };
      final c = Currency.fromJson(json);
      expect(c.code, 'USD');
      expect(c.rate, 12850.0);
      expect(c.diff, 100.0);
      expect(c.nominal, 1);
    });

    test('ratePerUnit is rate/nominal', () {
      final c = const Currency(
        id: '1',
        code: 'JPY',
        nameUz: 'Yapon iyenasi',
        nameRu: 'Японская иена',
        nameEn: 'Japanese Yen',
        nominal: 100,
        rate: 8500.0,
        diff: 10.0,
        date: '07.11.2026',
      );
      expect(c.ratePerUnit, closeTo(85.0, 0.001));
    });

    test('changePercent is positive when diff > 0', () {
      expect(usd.changePercent, greaterThan(0));
    });

    test('changePercent is negative when diff < 0', () {
      expect(eur.changePercent, lessThan(0));
    });

    test('isUp is true when diff > 0', () {
      expect(usd.isUp, isTrue);
      expect(usd.isDown, isFalse);
    });

    test('isDown is true when diff < 0', () {
      expect(eur.isDown, isTrue);
      expect(eur.isUp, isFalse);
    });

    test('flag returns correct emoji', () {
      expect(usd.flag, '🇺🇸');
      expect(eur.flag, '🇪🇺');
    });

    test('flag returns default for unknown code', () {
      const unknown = Currency(
        id: '99',
        code: 'XYZ',
        nameUz: 'Unknown',
        nameRu: 'Unknown',
        nameEn: 'Unknown',
        nominal: 1,
        rate: 1.0,
        diff: 0.0,
        date: '',
      );
      expect(unknown.flag, '🏳️');
    });

    test('equality is based on code', () {
      const usd2 = Currency(
        id: '999',
        code: 'USD',
        nameUz: 'Dollar',
        nameRu: 'Dollar',
        nameEn: 'Dollar',
        nominal: 1,
        rate: 13000.0,
        diff: 0.0,
        date: '',
      );
      expect(usd, equals(usd2));
    });

    test('fromJson handles null/missing fields gracefully', () {
      final json = <String, dynamic>{};
      final c = Currency.fromJson(json);
      expect(c.code, '');
      expect(c.rate, 0.0);
      expect(c.nominal, 1);
    });

    test('toString returns code and rate', () {
      expect(usd.toString(), contains('USD'));
      expect(usd.toString(), contains('12850'));
    });
  });
}
