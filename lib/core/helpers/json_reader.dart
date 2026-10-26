/// Tolerant readers for decoded JSON. The backend is Laravel: decimals such as
/// prices usually arrive as strings ("18.00"), ids may arrive as strings, and a
/// field can be null or of another shape than documented. A strict `as num?`
/// cast on such a field throws and fails the whole screen with the generic
/// error, so models read through these instead: a field of an unexpected type
/// reads as missing.
library;

Map<String, dynamic>? jsonMap(Object? value) =>
    value is Map ? Map<String, dynamic>.from(value) : null;

String? jsonString(Object? value) => value is String ? value : null;

int? jsonInt(Object? value) {
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value.trim()) ?? double.tryParse(value.trim())?.toInt();
  return null;
}

double? jsonDouble(Object? value) {
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value.trim());
  return null;
}
