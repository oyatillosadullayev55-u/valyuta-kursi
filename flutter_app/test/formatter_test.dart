import 'package:flutter_test/flutter_test.dart';
import 'package:valyuta_kursi_app/utils/formatter.dart';

void main() {
  group('Formatter', () {
    test('rate formats large numbers with separators', () {
      expect(Formatter.rate(12850.0), contains('12'));
      expect(Formatter.rate(12850.0), contains('850'));
    });

    test('rate formats small numbers with decimals', () {
      expect(Formatter.rate(0.50), contains('0'));
    });

    test('amount formats without decimals', () {
      final result = Formatter.amount(1000000.0);
      expect(result, isNotEmpty);
    });

    test('percent adds percent sign', () {
      expect(Formatter.percent(0.78), contains('%'));
    });

    test('percent positive adds plus', () {
      expect(Formatter.percent(0.78), contains('+'));
    });

    test('percent negative has minus', () {
      expect(Formatter.percent(-0.32), contains('-'));
    });

    test('diff positive adds plus sign', () {
      expect(Formatter.diff(100.0), startsWith('+'));
    });

    test('diff negative keeps minus', () {
      expect(Formatter.diff(-50.0), startsWith('-'));
    });

    test('dateTime formats correctly', () {
      final dt = DateTime(2026, 11, 7, 16, 0);
      final result = Formatter.dateTime(dt);
      expect(result, contains('07.11.2026'));
      expect(result, contains('16:00'));
    });

    test('timeOnly returns HH:mm', () {
      final dt = DateTime(2026, 11, 7, 9, 30);
      expect(Formatter.timeOnly(dt), '09:30');
    });
  });
}
