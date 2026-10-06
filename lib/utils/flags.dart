/// Valyuta kodidan bayroq emojisini yasaydi (USD -> 🇺🇸).
String flagOf(String code) {
  const special = {'EUR': '🇪🇺', 'XDR': '🌐', 'UZS': '🇺🇿'};
  final s = special[code];
  if (s != null) return s;
  if (code.length < 2) return '🏳️';
  final up = code.toUpperCase();
  final a = up.codeUnitAt(0);
  final b = up.codeUnitAt(1);
  if (a < 65 || a > 90 || b < 65 || b > 90) return '🏳️';
  return String.fromCharCode(0x1F1E6 + a - 65) +
      String.fromCharCode(0x1F1E6 + b - 65);
}