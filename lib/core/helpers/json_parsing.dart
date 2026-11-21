// Lenient readers for the values of a JSON response: a number may come as a
// number or as a decimal string ("25.00"), and a missing or wrong-typed field
// is null rather than a crash. Parsers that must reject a bad record check
// the null themselves.

double? jsonDouble(Object? value) {
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value);
  return null;
}

int? jsonInt(Object? value) {
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value);
  return null;
}

/// The trimmed text of [value], or null when it is missing or blank.
String? jsonString(Object? value) {
  if (value == null) return null;
  final text = value.toString().trim();
  return text.isEmpty ? null : text;
}

Map<String, dynamic>? jsonMap(Object? value) => value is Map<String, dynamic> ? value : null;
