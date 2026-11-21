import '../entities/app_language.dart';

/// Remembers which language the user picked.
abstract interface class LanguageRepository {
  /// The saved language; Arabic until one has been picked.
  Future<AppLanguage> getLanguage();

  Future<void> saveLanguage(AppLanguage language);
}
