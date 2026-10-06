String fmt(double v, {int? digits}) {
  if (v.isNaN || v.isInfinite) return '—';
  final d = digits ?? (v.abs() < 10 ? 4 : 2);
  final s = v.toStringAsFixed(d);
  final parts = s.split('.');
  final ip = parts[0]
      .replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => ' ');
  return d == 0 ? ip : '$ip.${parts[1]}';
}

String _two(int n) => n.toString().padLeft(2, '0');

String fmtShortDate(DateTime d) => '${_two(d.day)}.${_two(d.month)}';

String fmtDate(DateTime d) => '${_two(d.day)}.${_two(d.month)}.${d.year}';

String fmtDateTime(DateTime d) =>
    '${fmtDate(d)} ${_two(d.hour)}:${_two(d.minute)}';