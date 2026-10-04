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

  factory Currency.fromJson(Map<String, dynamic> j) => Currency(
    code: '${j['Ccy'] ?? ''}',
    name: '${j['CcyNm_UZ'] ?? ''}',
    date: '${j['Date'] ?? ''}',
    rate: double.tryParse('${j['Rate']}') ?? 0,
    diff: double.tryParse('${j['Diff']}') ?? 0,
    nominal: int.tryParse('${j['Nominal']}') ?? 1,
  );
}