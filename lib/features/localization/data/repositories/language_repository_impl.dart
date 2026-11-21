import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entities/app_language.dart';
import '../../domain/repositories/language_repository.dart';

class LanguageRepositoryImpl implements LanguageRepository {
  static const _key = 'app_language';

  const LanguageRepositoryImpl();

  @override
  Future<AppLanguage> getLanguage() async {
    try {
      final preferences = await SharedPreferences.getInstance();
      return AppLanguage.fromCode(preferences.getString(_key));
    } catch (_) {
      return AppLanguage.arabic;
    }
  }

  @override
  Future<void> saveLanguage(AppLanguage language) async {
    try {
      final preferences = await SharedPreferences.getInstance();
      await preferences.setString(_key, language.code);
    } catch (_) {
      // The language still applies for this run; it just is not remembered.
    }
  }
}
