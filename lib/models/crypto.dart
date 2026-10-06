class CryptoCoin {
  final String id, symbol, name;
  final double price; // USD
  final double change24h; // foiz
  final List<double> spark; // oxirgi 7 kun, soatlik

  const CryptoCoin({
    required this.id,
    required this.symbol,
    required this.name,
    required this.price,
    required this.change24h,
    required this.spark,
  });

  static double _d(dynamic v) =>
      v is num ? v.toDouble() : (double.tryParse('$v') ?? 0);

  factory CryptoCoin.fromJson(Map<String, dynamic> j) {
    final sp = j['sparkline_in_7d'];
    final prices = (sp is Map && sp['price'] is List)
        ? (sp['price'] as List).map((e) => _d(e)).toList()
        : <double>[];
    return CryptoCoin(
      id: '${j['id']}',
      symbol: '${j['symbol']}'.toUpperCase(),
      name: '${j['name']}',
      price: _d(j['current_price']),
      change24h: _d(j['price_change_percentage_24h']),
      spark: prices,
    );
  }
}