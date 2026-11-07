class Currency {
  final String id;
  final String code;
  final String nameUz;
  final String nameRu;
  final String nameEn;
  final int nominal;
  final double rate;
  final double diff;
  final String date;

  const Currency({
    required this.id,
    required this.code,
    required this.nameUz,
    required this.nameRu,
    required this.nameEn,
    required this.nominal,
    required this.rate,
    required this.diff,
    required this.date,
  });

  factory Currency.fromJson(Map<String, dynamic> json) {
    return Currency(
      id: json['id']?.toString() ?? '',
      code: json['Ccy']?.toString() ?? '',
      nameUz: json['CcyNm_UZ']?.toString() ?? '',
      nameRu: json['CcyNm_RU']?.toString() ?? '',
      nameEn: json['CcyNm_EN']?.toString() ?? '',
      nominal: int.tryParse(json['Nominal']?.toString() ?? '1') ?? 1,
      rate: double.tryParse(json['Rate']?.toString() ?? '0') ?? 0.0,
      diff: double.tryParse(json['Diff']?.toString() ?? '0') ?? 0.0,
      date: json['Date']?.toString() ?? '',
    );
  }

  /// Rate per 1 unit in UZS
  double get ratePerUnit => rate / nominal;

  /// Change percent
  double get changePercent {
    if (rate == 0) return 0;
    return (diff / (rate - diff)) * 100;
  }

  /// Is rate going up
  bool get isUp => diff > 0;
  bool get isDown => diff < 0;

  String get flag {
    const flags = {
      'USD': '🇺🇸', 'EUR': '🇪🇺', 'RUB': '🇷🇺', 'GBP': '🇬🇧',
      'JPY': '🇯🇵', 'CNY': '🇨🇳', 'KZT': '🇰🇿', 'KGS': '🇰🇬',
      'TJS': '🇹🇯', 'AZN': '🇦🇿', 'TRY': '🇹🇷', 'UAH': '🇺🇦',
      'CHF': '🇨🇭', 'SEK': '🇸🇪', 'NOK': '🇳🇴', 'DKK': '🇩🇰',
      'CAD': '🇨🇦', 'AUD': '🇦🇺', 'KWD': '🇰🇼', 'SAR': '🇸🇦',
      'AED': '🇦🇪', 'INR': '🇮🇳', 'BRL': '🇧🇷', 'GEL': '🇬🇪',
      'AMD': '🇦🇲', 'SGD': '🇸🇬', 'HKD': '🇭🇰', 'TMT': '🇹🇲',
      'MXN': '🇲🇽', 'PLN': '🇵🇱', 'CZK': '🇨🇿', 'HUF': '🇭🇺',
    };
    return flags[code] ?? '🏳️';
  }

  @override
  String toString() => 'Currency($code, $rate)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is Currency && code == other.code;

  @override
  int get hashCode => code.hashCode;
}
