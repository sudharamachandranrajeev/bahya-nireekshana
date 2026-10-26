/// Byte and speed formatting. Sizes use powers of 1000 (kB, MB, GB), as
/// operators bill and as Windows' and Android's data usage screens count;
/// speeds are shown in bits per second, as connections are sold.
library;

const _units = ['B', 'kB', 'MB', 'GB', 'TB', 'PB'];

/// 0 → "0 B", 1234 → "1.2 kB", 15_000_000_000 → "15 GB".
String bytes(num value, {int digits = 1}) {
  var v = value.toDouble().abs();
  var i = 0;
  while (v >= 1000 && i < _units.length - 1) {
    v /= 1000;
    i++;
  }
  final sign = value < 0 ? '-' : '';
  if (i == 0) return '$sign${v.round()} B';
  // Two significant digits at most below 10, none from 100 up.
  final d = v >= 100 ? 0 : (v >= 10 ? (digits > 0 ? 1 : 0) : digits);
  var text = v.toStringAsFixed(d);
  if (text.contains('.')) text = text.replaceFirst(RegExp(r'\.?0+$'), '');
  return '$sign$text ${_units[i]}';
}

/// Bytes per second as bits per second: 125000 → "1 Mbps".
String speed(num bytesPerSecond) {
  var v = bytesPerSecond * 8.0;
  const units = ['bps', 'kbps', 'Mbps', 'Gbps', 'Tbps'];
  var i = 0;
  while (v >= 1000 && i < units.length - 1) {
    v /= 1000;
    i++;
  }
  final d = i == 0 || v >= 100 ? 0 : (v >= 10 ? 1 : 2);
  var text = v.toStringAsFixed(d);
  if (text.contains('.')) text = text.replaceFirst(RegExp(r'\.?0+$'), '');
  return '$text ${units[i]}';
}

/// Reads "30 GB", "500MB", "1.5 tb" or a plain byte count; null when it
/// is not a size.
int? parseBytes(String text) {
  final m = RegExp(r'^\s*([0-9]+(?:\.[0-9]+)?)\s*([kmgtp]?)b?\s*$', caseSensitive: false).firstMatch(text);
  if (m == null) return null;
  final n = double.parse(m[1]!);
  // No prefix is plain bytes (indexOf('') would be 0, not -1).
  final power = m[2]!.isEmpty ? 0 : 'kmgtp'.indexOf(m[2]!.toLowerCase()) + 1;
  var v = n;
  for (var i = 0; i < power; i++) {
    v *= 1000;
  }
  return v.round();
}
