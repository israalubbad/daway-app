import '../entities/app_language.dart';
import '../repositories/language_repository.dart';

class GetAppLanguageUseCase {
  final LanguageRepository _repository;

  const GetAppLanguageUseCase(this._repository);

  Future<AppLanguage> call() => _repository.getLanguage();
}
