String fmt(double v, {int? digits}) {
  final d = digits ?? (v.abs() < 10 ? 4 : 2);
  final s = v.toStringAsFixed(d);
  final parts = s.split('.');
  final ip = parts[0]
      .replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => ' ');
  return d == 0 ? ip : '$ip.${parts[1]}';
}