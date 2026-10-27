abstract class AppConstants {
  /// Map center shown before the user has picked (or been located to) a
  /// point — Gaza City, matching the sample address in the API docs.
  static const double defaultMapLatitude = 31.5017;
  static const double defaultMapLongitude = 34.4668;

  /// Palestinian/Israeli new shekel — this app's only market (see the map
  /// center above), so every displayed price uses this, not a Gulf riyal.
  static const String currencySuffix = '₪';

  /// The support line: dialled as written, and as an international number
  /// (970, no leading 0, no "+") for the wa.me WhatsApp link.
  static const String supportPhone = '0597601911';
  static const String supportWhatsAppNumber = '970597601911';
}
