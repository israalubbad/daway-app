import 'package:daway_app/features/localization/domain/entities/app_language.dart';
import 'package:daway_app/features/localization/domain/repositories/language_repository.dart';
import 'package:daway_app/features/localization/domain/usecases/get_app_language_usecase.dart';
import 'package:daway_app/features/localization/domain/usecases/save_app_language_usecase.dart';
import 'package:daway_app/features/localization/presentation/cubit/language_cubit.dart';
import 'package:get_it/get_it.dart';

class FakeLanguageRepository implements LanguageRepository {
  AppLanguage saved;
  int saveCount = 0;

  FakeLanguageRepository([this.saved = AppLanguage.arabic]);

  @override
  Future<AppLanguage> getLanguage() async => saved;

  @override
  Future<void> saveLanguage(AppLanguage language) async {
    saveCount++;
    saved = language;
  }
}

LanguageCubit buildLanguageCubit([FakeLanguageRepository? repository]) {
  final repo = repository ?? FakeLanguageRepository();
  return LanguageCubit(GetAppLanguageUseCase(repo), SaveAppLanguageUseCase(repo));
}

/// Puts a [LanguageCubit] (Arabic, in memory) in [getIt], for a test that
/// opens a screen which reads the language or builds the app.
void registerLanguageCubit(GetIt getIt) {
  if (getIt.isRegistered<LanguageCubit>()) getIt.unregister<LanguageCubit>();
  getIt.registerSingleton<LanguageCubit>(buildLanguageCubit());
}
