// Lenient readers for the values of a JSON response: a number may come as a
// number or as a decimal string ("25.00"), and a missing or wrong-typed field
// is null rather than a crash. Parsers that must reject a bad record check
// the null themselves.

double? jsonDouble(Object? value) {
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value.trim());
  return null;
}

int? jsonInt(Object? value) {
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value.trim()) ?? double.tryParse(value.trim())?.toInt();
  return null;
}

/// A JSON boolean, also accepted as 0/1 or "0"/"1"/"true"/"false", which is how
/// this backend sends flags from some endpoints.
bool? jsonBool(Object? value) {
  if (value is bool) return value;
  if (value is num) return value != 0;
  if (value is String) {
    final text = value.trim().toLowerCase();
    if (text == 'true' || text == '1') return true;
    if (text == 'false' || text == '0') return false;
  }
  return null;
}

/// The trimmed text of [value], or null when it is missing, blank, or not a
/// scalar. A number or a boolean reads as its text; a list or a map is not text.
String? jsonString(Object? value) {
  if (value is! String && value is! num && value is! bool) return null;
  final text = value.toString().trim();
  return text.isEmpty ? null : text;
}

Map<String, dynamic>? jsonMap(Object? value) =>
    value is Map ? Map<String, dynamic>.from(value) : null;
