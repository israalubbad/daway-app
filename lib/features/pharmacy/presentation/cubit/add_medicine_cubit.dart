import 'dart:io';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/helpers/api_result.dart';
import '../../../patient/domain/usecases/get_categories_usecase.dart';
import '../../../patient/domain/usecases/upload_avatar_usecase.dart';
import '../../domain/entities/medicine_catalog_item.dart';
import '../../domain/usecases/add_pharmacy_medicine_by_name_usecase.dart';
import '../../domain/usecases/add_pharmacy_medicine_usecase.dart';
import '../../domain/usecases/search_medicine_catalog_usecase.dart';
import 'add_medicine_state.dart';

import '../../../../core/localization/translations.dart';

/// Backs both pages of "إضافة منتج جديد": the form, and the search page that
/// fills it from the catalog.
class AddMedicineCubit extends Cubit<AddMedicineState> {
  /// The backend answers a 1-character query with an empty list, so a search
  /// shorter than this is refused here instead of looking like "no results".
  static const int minSearchLength = 2;

  final SearchMedicineCatalogUseCase _searchMedicineCatalogUseCase;
  final AddPharmacyMedicineUseCase _addPharmacyMedicineUseCase;
  final AddPharmacyMedicineByNameUseCase _addPharmacyMedicineByNameUseCase;
  final UploadAvatarUseCase _uploadImageUseCase;
  final GetCategoriesUseCase _getCategoriesUseCase;

  AddMedicineCubit(
    this._searchMedicineCatalogUseCase,
    this._addPharmacyMedicineUseCase,
    this._addPharmacyMedicineByNameUseCase,
    this._uploadImageUseCase,
    this._getCategoriesUseCase,
  ) : super(const AddMedicineEditing(AddMedicineFormData()));

  // Bumped whenever the results are reset or a medicine is picked, so a
  // search that was already in flight can tell its result is stale and
  // discard it instead of resurrecting results the user no longer wants.
  int _searchSession = 0;

  // Bumped on every image pick, so an earlier upload that's still in flight
  // can tell its result is stale and won't overwrite a newer pick.
  int _imageSession = 0;

  Future<void> loadCategories() async {
    emit(AddMedicineEditing(state.formData.copyWith(
      isLoadingCategories: true,
      clearCategoriesError: true,
    )));

    final result = await _getCategoriesUseCase();

    switch (result) {
      case Success(:final data):
        emit(AddMedicineEditing(
          state.formData.copyWith(isLoadingCategories: false, categories: data),
        ));
      case ApiError(:final failure):
        emit(AddMedicineEditing(
          state.formData.copyWith(isLoadingCategories: false, categoriesError: failure.message),
        ));
    }
  }

  void categorySelected(int categoryId) {
    emit(AddMedicineEditing(state.formData.copyWith(categoryId: categoryId)));
  }

  void nameChanged(String value) {
    emit(AddMedicineEditing(state.formData.copyWith(nameQuery: value)));
  }

  void nameArChanged(String value) {
    emit(AddMedicineEditing(state.formData.copyWith(nameAr: value)));
  }

  void activeIngredientChanged(String value) {
    emit(AddMedicineEditing(state.formData.copyWith(activeIngredient: value)));
  }

  void quantityChanged(String value) {
    emit(AddMedicineEditing(state.formData.copyWith(quantity: value)));
  }

  void priceChanged(String value) {
    emit(AddMedicineEditing(state.formData.copyWith(price: value)));
  }

  void isAvailableChanged(bool value) {
    emit(AddMedicineEditing(state.formData.copyWith(isAvailable: value)));
  }

  /// Forgets the last search, for when the search page is opened again.
  void searchReset() {
    _searchSession++;
    emit(AddMedicineEditing(state.formData.copyWith(
      suggestions: const [],
      isSearching: false,
      hasSearched: false,
      clearSearchError: true,
    )));
  }

  Future<void> search(String query) async {
    final trimmed = query.trim();
    final session = ++_searchSession;

    if (trimmed.length < minSearchLength) {
      emit(AddMedicineEditing(state.formData.copyWith(
        suggestions: const [],
        isSearching: false,
        hasSearched: false,
        searchError: 'اكتب حرفين على الأقل للبحث'.tr,
      )));
      return;
    }

    emit(AddMedicineEditing(state.formData.copyWith(
      isSearching: true,
      suggestions: const [],
      clearSearchError: true,
    )));

    final result = await _searchMedicineCatalogUseCase(trimmed);
    if (session != _searchSession) return;

    switch (result) {
      case Success(:final data):
        emit(AddMedicineEditing(
          state.formData.copyWith(isSearching: false, hasSearched: true, suggestions: data),
        ));
      case ApiError(:final failure):
        emit(AddMedicineEditing(state.formData.copyWith(
          isSearching: false,
          hasSearched: true,
          suggestions: const [],
          searchError: failure.message,
        )));
    }
  }

  void medicineSelected(MedicineCatalogItem medicine) {
    _searchSession++;
    emit(AddMedicineEditing(state.formData.copyWith(
      nameQuery: medicine.name,
      nameAr: medicine.nameAr ?? '',
      activeIngredient: medicine.activeIngredient ?? '',
      selectedMedicine: medicine,
      suggestions: const [],
      isSearching: false,
      clearSearchError: true,
    )));
  }

  /// Drops the picked catalog medicine and empties the fields it filled, so
  /// the form goes back to adding a new medicine by name.
  void selectionCleared() {
    emit(AddMedicineEditing(state.formData.copyWith(
      clearSelectedMedicine: true,
      nameQuery: '',
      nameAr: '',
      activeIngredient: '',
    )));
  }

  Future<void> imageSelected(File imageFile) async {
    final session = ++_imageSession;

    emit(AddMedicineEditing(state.formData.copyWith(
      imageLocalPath: imageFile.path,
      isUploadingImage: true,
      clearImageError: true,
      clearImageUrl: true,
    )));

    final result = await _uploadImageUseCase(imageFile);
    if (session != _imageSession) return;

    switch (result) {
      case Success(:final data):
        emit(AddMedicineEditing(state.formData.copyWith(imageUrl: data, isUploadingImage: false)));
      case ApiError(:final failure):
        emit(AddMedicineEditing(
          state.formData.copyWith(isUploadingImage: false, imageError: failure.message),
        ));
    }
  }

  Future<void> save() async {
    final formData = state.formData;
    if (!formData.canSubmit) return;

    emit(AddMedicineSaving(formData));

    final result = formData.isManualEntry
        ? await _addPharmacyMedicineByNameUseCase(
            tradeName: formData.nameQuery.trim(),
            tradeNameAr: formData.nameAr.trim().isEmpty ? null : formData.nameAr.trim(),
            activeIngredient:
                formData.activeIngredient.trim().isEmpty ? null : formData.activeIngredient.trim(),
            categoryId: formData.categoryId,
            price: formData.priceValue!,
            quantity: formData.quantityValue!,
            isAvailable: formData.isAvailable,
            imageUrl: formData.imageUrl,
          )
        : await _addByCatalogSelection(formData);

    switch (result) {
      case Success():
        emit(AddMedicineSuccess(formData));
      case ApiError(:final failure):
        emit(AddMedicineFailure(formData, failure.message));
    }
  }

  Future<ApiResult<void>> _addByCatalogSelection(AddMedicineFormData formData) {
    // The backend requires either medicine_id (the pharmacy's own general
    // catalog) or moh_medicine_id (a Ministry of Health entry) — which one
    // depends on where the selected suggestion came from.
    final selected = formData.selectedMedicine!;
    final isFromMoh = selected.type == 'moh';

    return _addPharmacyMedicineUseCase(
      medicineId: isFromMoh ? null : selected.id,
      mohMedicineId: isFromMoh ? selected.id : null,
      price: formData.priceValue!,
      quantity: formData.quantityValue!,
      isAvailable: formData.isAvailable,
      imageUrl: formData.imageUrl,
    );
  }
}
