/// A language the app can be shown in: its code, its name in its own language,
/// and a small line under it in the other one (what the language picker lists).
enum AppLanguage {
  arabic('ar', 'العربية', 'Arabic'),
  english('en', 'English', 'الإنجليزية');

  final String code;
  final String nativeName;
  final String subtitle;

  const AppLanguage(this.code, this.nativeName, this.subtitle);

  /// The language with [code], Arabic when it is not one the app has.
  static AppLanguage fromCode(String? code) =>
      values.firstWhere((language) => language.code == code, orElse: () => arabic);
}
