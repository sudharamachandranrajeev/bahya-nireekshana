import 'dart:convert';

/// Lenient readers for JSON from GitHub and the platform channels:
/// a missing or wrongly typed field reads as empty, never as a crash.
typedef Json = Map<String, Object?>;

String str(Object? v) => switch (v) {
  String s => s.trim(),
  num n => '$n',
  _ => '',
};

int? intOf(Object? v) => switch (v) {
  num n when n.isFinite => n.round(),
  String s => num.tryParse(s.replaceAll(RegExp(r'[^0-9.\-]'), ''))?.round(),
  _ => null,
};

double? numOf(Object? v) => switch (v) {
  num n when n.isFinite => n.toDouble(),
  String s => double.tryParse(s),
  _ => null,
};

Json obj(Object? v) => v is Map ? v.cast<String, Object?>() : const {};

List<Json> objs(Object? v) => v is List ? [for (final e in v) obj(e)] : const [];

List<String> strs(Object? v) =>
    v is List ? [for (final e in v) str(e)].where((s) => s.isNotEmpty).toList() : const [];

/// Decodes a JSON object stored as text; empty or broken text reads as {}.
Json decodeObject(String text) {
  if (text.trim().isEmpty) return const {};
  try {
    return obj(jsonDecode(text));
  } on FormatException {
    return const {};
  }
}

List<Object?> decodeList(String text) {
  if (text.trim().isEmpty) return const [];
  try {
    final v = jsonDecode(text);
    return v is List ? v : const [];
  } on FormatException {
    return const [];
  }
}

/// Plain text from an HTML job description: tags dropped, entities decoded,
/// paragraphs and list items kept as lines.
String htmlToText(String html) {
  var s = html
      .replaceAll(RegExp(r'<(script|style)[^>]*>.*?</\1>', caseSensitive: false, dotAll: true), '')
      .replaceAll(RegExp(r'<li[^>]*>', caseSensitive: false), '\n• ')
      .replaceAll(RegExp(r'<(br|/p|/div|/h[1-6]|/li|/ul|/ol|/tr)[^>]*>', caseSensitive: false), '\n')
      .replaceAll(RegExp(r'<[^>]+>'), '');
  const entities = {
    '&amp;': '&',
    '&lt;': '<',
    '&gt;': '>',
    '&quot;': '"',
    '&#39;': "'",
    '&apos;': "'",
    '&nbsp;': ' ',
    '&hellip;': '…',
    '&ndash;': '–',
    '&mdash;': '—',
    '&pound;': '£',
    '&euro;': '€',
    '&rsquo;': '’',
    '&lsquo;': '‘',
    '&rdquo;': '”',
    '&ldquo;': '“',
    '&bull;': '•',
  };
  s = s.replaceAllMapped(RegExp(r'&(#x?[0-9a-fA-F]+|[a-z]+);'), (m) {
    final e = m[0]!;
    if (entities.containsKey(e)) return entities[e]!;
    final code = m[1]!;
    if (code.startsWith('#')) {
      final n = code.startsWith('#x')
          ? int.tryParse(code.substring(2), radix: 16)
          : int.tryParse(code.substring(1));
      if (n != null && n > 0 && n < 0x110000) return String.fromCharCode(n);
    }
    return e;
  });
  return s
      .split('\n')
      .map((l) => l.replaceAll(RegExp(r'[ \t]+'), ' ').trim())
      .join('\n')
      .replaceAll(RegExp(r'\n{3,}'), '\n\n')
      .trim();
}
