/// [text] trimmed, or null when it is missing or blank — an optional field
/// the backend should either get filled in or not at all.
String? optionalText(String? text) {
  final trimmed = text?.trim();
  return (trimmed == null || trimmed.isEmpty) ? null : trimmed;
}
