import '../../../../core/helpers/arabic_text.dart';
import '../../../patient/domain/entities/category.dart';
import '../../domain/entities/medicine_catalog_item.dart';

/// Form data carried across every state so the screen never loses what the
/// user has already entered while a search, image upload, or submission is
/// in flight.
class AddMedicineFormData {
  /// The English trade name. Filled from [selectedMedicine] when one is picked
  /// from the search page, typed by hand otherwise.
  final String nameQuery;

  /// The Arabic trade name — optional.
  final String nameAr;

  /// Filled from [selectedMedicine] when a catalog match is picked, freely
  /// editable otherwise — also the value sent as `active_ingredient` when the
  /// medicine is added by name.
  final String activeIngredient;
  final String quantity;
  final String price;
  final bool isAvailable;
  final String? imageLocalPath;
  final String? imageUrl;
  final bool isUploadingImage;
  final String? imageError;

  /// What the search page found for its last query.
  final List<MedicineCatalogItem> suggestions;
  final bool isSearching;
  final String? searchError;

  /// False until the search page has run a query, so "no results" is not shown
  /// before anything was searched.
  final bool hasSearched;

  /// A medicine picked from the search page. Null means the medicine is added
  /// by name (`POST /pharmacy/medicines/by-name`) from the typed fields.
  final MedicineCatalogItem? selectedMedicine;

  final List<Category> categories;
  final bool isLoadingCategories;
  final String? categoriesError;
  final int? categoryId;

  const AddMedicineFormData({
    this.nameQuery = '',
    this.nameAr = '',
    this.activeIngredient = '',
    this.quantity = '',
    this.price = '',
    this.isAvailable = true,
    this.imageLocalPath,
    this.imageUrl,
    this.isUploadingImage = false,
    this.imageError,
    this.suggestions = const [],
    this.isSearching = false,
    this.searchError,
    this.hasSearched = false,
    this.selectedMedicine,
    this.categories = const [],
    this.isLoadingCategories = false,
    this.categoriesError,
    this.categoryId,
  });

  double? get priceValue => double.tryParse(price);

  int? get quantityValue => int.tryParse(quantity);

  /// True when nothing was picked from the catalog: the typed fields are sent
  /// to the by-name endpoint.
  bool get isManualEntry => selectedMedicine == null;

  /// The backend rejects `trade_name` if it contains Arabic characters.
  bool get nameHasArabicChars => containsArabicChars(nameQuery);

  bool get canSubmit =>
      (isManualEntry
          ? nameQuery.trim().isNotEmpty && !nameHasArabicChars && categoryId != null
          : true) &&
      (quantityValue ?? 0) > 0 &&
      (priceValue ?? 0) > 0 &&
      !isUploadingImage;

  AddMedicineFormData copyWith({
    String? nameQuery,
    String? nameAr,
    String? activeIngredient,
    String? quantity,
    String? price,
    bool? isAvailable,
    String? imageLocalPath,
    String? imageUrl,
    bool clearImageUrl = false,
    bool? isUploadingImage,
    String? imageError,
    bool clearImageError = false,
    List<MedicineCatalogItem>? suggestions,
    bool? isSearching,
    String? searchError,
    bool clearSearchError = false,
    bool? hasSearched,
    MedicineCatalogItem? selectedMedicine,
    bool clearSelectedMedicine = false,
    List<Category>? categories,
    bool? isLoadingCategories,
    String? categoriesError,
    bool clearCategoriesError = false,
    int? categoryId,
  }) {
    return AddMedicineFormData(
      nameQuery: nameQuery ?? this.nameQuery,
      nameAr: nameAr ?? this.nameAr,
      activeIngredient: activeIngredient ?? this.activeIngredient,
      quantity: quantity ?? this.quantity,
      price: price ?? this.price,
      isAvailable: isAvailable ?? this.isAvailable,
      imageLocalPath: imageLocalPath ?? this.imageLocalPath,
      imageUrl: clearImageUrl ? null : (imageUrl ?? this.imageUrl),
      isUploadingImage: isUploadingImage ?? this.isUploadingImage,
      imageError: clearImageError ? null : (imageError ?? this.imageError),
      suggestions: suggestions ?? this.suggestions,
      isSearching: isSearching ?? this.isSearching,
      searchError: clearSearchError ? null : (searchError ?? this.searchError),
      hasSearched: hasSearched ?? this.hasSearched,
      selectedMedicine:
          clearSelectedMedicine ? null : (selectedMedicine ?? this.selectedMedicine),
      categories: categories ?? this.categories,
      isLoadingCategories: isLoadingCategories ?? this.isLoadingCategories,
      categoriesError: clearCategoriesError ? null : (categoriesError ?? this.categoriesError),
      categoryId: categoryId ?? this.categoryId,
    );
  }
}

sealed class AddMedicineState {
  final AddMedicineFormData formData;

  const AddMedicineState(this.formData);
}

class AddMedicineEditing extends AddMedicineState {
  const AddMedicineEditing(super.formData);
}

class AddMedicineSaving extends AddMedicineState {
  const AddMedicineSaving(super.formData);
}

class AddMedicineSuccess extends AddMedicineState {
  const AddMedicineSuccess(super.formData);
}

class AddMedicineFailure extends AddMedicineState {
  final String message;

  const AddMedicineFailure(super.formData, this.message);
}
