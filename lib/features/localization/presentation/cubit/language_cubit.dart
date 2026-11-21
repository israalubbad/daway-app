import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/localization/translations.dart';
import '../../domain/entities/app_language.dart';
import '../../domain/usecases/get_app_language_usecase.dart';
import '../../domain/usecases/save_app_language_usecase.dart';

/// The language the app is shown in. The state is the language; changing it
/// also switches [Translations], which every `.tr` reads.
class LanguageCubit extends Cubit<AppLanguage> {
  final GetAppLanguageUseCase _getLanguage;
  final SaveAppLanguageUseCase _saveLanguage;

  LanguageCubit(this._getLanguage, this._saveLanguage) : super(AppLanguage.arabic);

  /// Reads the saved language; call it before the first screen is built.
  Future<void> load() async {
    final language = await _getLanguage();
    Translations.use(language.code);
    if (!isClosed) emit(language);
  }

  Future<void> select(AppLanguage language) async {
    if (language == state) return;
    Translations.use(language.code);
    emit(language);
    await _saveLanguage(language);
  }
}
