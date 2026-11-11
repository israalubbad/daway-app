import '../entities/app_language.dart';
import '../repositories/language_repository.dart';

class SaveAppLanguageUseCase {
  final LanguageRepository _repository;

  const SaveAppLanguageUseCase(this._repository);

  Future<void> call(AppLanguage language) => _repository.saveLanguage(language);
}
