class Currency {
  final String code, name, date;
  final double rate, diff;
  final int nominal;

  Currency({
    required this.code,
    required this.name,
    required this.date,
    required this.rate,
    required this.diff,
    required this.nominal,
  });

  /// 1 birlik valyutaning so'mdagi narxi (nominal hisobga olingan)
  double get perUnit => nominal == 0 ? rate : rate / nominal;
  double get diffPerUnit => nominal == 0 ? diff : diff / nominal;

  /// Kechagiga nisbatan o'zgarish, foizda
  double get changePercent {
    final prev = perUnit - diffPerUnit;
    return prev == 0 ? 0 : diffPerUnit / prev * 100;
  }

  factory Currency.fromJson(Map<String, dynamic> j) => Currency(
    code: '${j['Ccy'] ?? ''}',
    name: '${j['CcyNm_UZ'] ?? ''}',
    date: '${j['Date'] ?? ''}',
    rate: double.tryParse('${j['Rate']}') ?? 0,
    diff: double.tryParse('${j['Diff']}') ?? 0,
    nominal: int.tryParse('${j['Nominal']}') ?? 1,
  );
}

class HistoryPoint {
  final DateTime date;
  final double value;
  const HistoryPoint(this.date, this.value);
}

/// Narx signali: kurs maqsadga yetganda xabar beradi.
class PriceAlert {
  final String code;
  final double target;
  final bool above;
  const PriceAlert(this.code, this.target, this.above);

  String encode() => '$code|$target|${above ? 1 : 0}';

  static PriceAlert? decode(String s) {
    final p = s.split('|');
    if (p.length != 3) return null;
    final t = double.tryParse(p[1]);
    if (t == null) return null;
    return PriceAlert(p[0], t, p[2] == '1');
  }
}