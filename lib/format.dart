/// Display helpers shared by the screens.
library;

/// money(399) -> "$3.99". Amounts from the API are in cents.
String money(int cents, [String currency = 'USD']) {
  final value = (cents / 100).toStringAsFixed(2);
  return currency == 'USD' ? '\$$value' : '$value $currency';
}

/// bytes(1610612736) -> "1.5 GB"
String bytes(int n) {
  final gb = n / (1 << 30);
  if (gb >= 1) {
    final s = gb.toStringAsFixed(gb < 10 ? 1 : 0);
    return '${s.endsWith('.0') ? s.substring(0, s.length - 2) : s} GB';
  }
  return '${(n / (1 << 20)).round()} MB';
}

const _months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

/// date(...) -> "24 Oct 2026"
String date(DateTime d) {
  final local = d.toLocal();
  return '${local.day} ${_months[local.month - 1]} ${local.year}';
}

String days(int n) => '$n ${n == 1 ? 'day' : 'days'}';

String flagUrl(String code) => 'https://flagcdn.com/w80/${code.toLowerCase()}.png';
