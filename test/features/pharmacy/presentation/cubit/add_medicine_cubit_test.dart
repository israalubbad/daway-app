import 'dart:async';
import 'dart:io';

import 'package:daway_app/core/erroring/failure.dart';
import 'package:daway_app/core/helpers/api_result.dart';
import 'package:daway_app/features/patient/domain/entities/category.dart';
import 'package:daway_app/features/patient/domain/entities/category_medicines_result.dart';
import 'package:daway_app/features/patient/domain/repositories/avatar_repository.dart';
import 'package:daway_app/features/patient/domain/repositories/category_repository.dart';
import 'package:daway_app/features/patient/domain/usecases/get_categories_usecase.dart';
import 'package:daway_app/features/patient/domain/usecases/upload_avatar_usecase.dart';
import 'package:daway_app/features/pharmacy/domain/entities/medicine.dart';
import 'package:daway_app/features/pharmacy/domain/entities/medicine_catalog_item.dart';
import 'package:daway_app/features/pharmacy/domain/repositories/pharmacy_medicine_repository.dart';
import 'package:daway_app/features/pharmacy/domain/usecases/add_pharmacy_medicine_by_name_usecase.dart';
import 'package:daway_app/features/pharmacy/domain/usecases/add_pharmacy_medicine_usecase.dart';
import 'package:daway_app/features/pharmacy/domain/usecases/search_medicine_catalog_usecase.dart';
import 'package:daway_app/features/pharmacy/presentation/cubit/add_medicine_cubit.dart';
import 'package:daway_app/features/pharmacy/presentation/cubit/add_medicine_state.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../../../helpers/in_memory_session_repository.dart';

const _catalogItem = MedicineCatalogItem(
  id: 5,
  name: 'Panadol',
  activeIngredient: 'Paracetamol 500mg',
  type: 'medicine',
);
const _mohCatalogItem = MedicineCatalogItem(
  id: 21,
  name: 'THE HOPPA. BETTER GLOW VIT C SERUM',
  activeIngredient: 'Orientco Limited/Turkey',
  type: 'moh',
);

class _FakePharmacyMedicineRepository implements PharmacyMedicineRepository {
  ApiResult<List<MedicineCatalogItem>> searchResult = const Success([_catalogItem]);
  ApiResult<void> addResult = const Success(null);
  ApiResult<void> addByNameResult = const Success(null);
  int? lastMedicineId;
  int? lastMohMedicineId;
  double? lastPrice;
  int? lastQuantity;
  bool? lastIsAvailable;
  String? lastImageUrl;
  String? lastTradeName;
  String? lastTradeNameAr;
  String? lastActiveIngredient;
  int? lastCategoryId;

  /// When set, searchCatalog() waits for this to complete instead of
  /// resolving immediately — lets a test pause mid-search to exercise races.
  Completer<void>? searchGate;

  @override
  Future<ApiResult<List<Medicine>>> getMedicines({required String token}) async {
    throw UnimplementedError();
  }

  @override
  Future<ApiResult<List<MedicineCatalogItem>>> searchCatalog({
    required String token,
    required String query,
  }) async {
    if (searchGate != null) await searchGate!.future;
    return searchResult;
  }

  @override
  Future<ApiResult<void>> addMedicine({
    required String token,
    int? medicineId,
    int? mohMedicineId,
    required double price,
    required int quantity,
    required bool isAvailable,
    String? imageUrl,
  }) async {
    lastMedicineId = medicineId;
    lastMohMedicineId = mohMedicineId;
    lastPrice = price;
    lastQuantity = quantity;
    lastIsAvailable = isAvailable;
    lastImageUrl = imageUrl;
    return addResult;
  }

  @override
  Future<ApiResult<void>> addMedicineByName({
    required String token,
    required String tradeName,
    String? tradeNameAr,
    String? activeIngredient,
    int? categoryId,
    required double price,
    required int quantity,
    required bool isAvailable,
    String? imageUrl,
  }) async {
    lastTradeName = tradeName;
    lastTradeNameAr = tradeNameAr;
    lastActiveIngredient = activeIngredient;
    lastCategoryId = categoryId;
    lastPrice = price;
    lastQuantity = quantity;
    lastIsAvailable = isAvailable;
    lastImageUrl = imageUrl;
    return addByNameResult;
  }

  @override
  Future<ApiResult<void>> deleteMedicine({
    required String token,
    required int pharmacyMedicineId,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<ApiResult<void>> updateMedicine({
    required String token,
    required int pharmacyMedicineId,
    required int medicineId,
    required String tradeName,
    String? tradeNameAr,
    String? activeIngredient,
    required double price,
    required int quantity,
    required bool isAvailable,
  }) async {
    throw UnimplementedError();
  }
}

class _FakeAvatarRepository implements AvatarRepository {
  ApiResult<String> result = const Success('https://res.cloudinary.com/demo/image/upload/a.jpg');

  /// When set, uploadAvatar() waits for this to complete instead of
  /// resolving immediately — lets a test pause mid-upload to exercise races.
  Completer<void>? uploadGate;

  @override
  Future<ApiResult<String>> uploadAvatar(File imageFile) async {
    if (uploadGate != null) await uploadGate!.future;
    return result;
  }
}


const _categories = [
  Category(id: 3, nameAr: 'مسكنات', slug: 'painkillers'),
  Category(id: 4, nameAr: 'فيتامينات', slug: 'vitamins'),
];

class _FakeCategoryRepository implements CategoryRepository {
  ApiResult<List<Category>> result = const Success(_categories);

  @override
  Future<ApiResult<List<Category>>> getCategories() async => result;

  @override
  Future<ApiResult<CategoryMedicinesResult>> getCategoryMedicines({
    required String categorySlug,
    String? subcategorySlug,
    String? dosageForm,
    String? query,
    int page = 1,
    int perPage = 20,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<ApiResult<List<String>>> getDosageForms() async {
    throw UnimplementedError();
  }
}

void main() {
  late _FakePharmacyMedicineRepository repository;
  late _FakeAvatarRepository imageRepository;
  late _FakeCategoryRepository categoryRepository;
  late AddMedicineCubit cubit;

  setUp(() {
    repository = _FakePharmacyMedicineRepository();
    imageRepository = _FakeAvatarRepository();
    categoryRepository = _FakeCategoryRepository();
    final sessionRepository = InMemorySessionRepository.pharmacy();
    cubit = AddMedicineCubit(
      SearchMedicineCatalogUseCase(repository, sessionRepository),
      AddPharmacyMedicineUseCase(repository, sessionRepository),
      AddPharmacyMedicineByNameUseCase(repository, sessionRepository),
      UploadAvatarUseCase(imageRepository),
      GetCategoriesUseCase(categoryRepository),
    );
  });

  tearDown(() => cubit.close());

  void fillStock() {
    cubit.quantityChanged('20');
    cubit.priceChanged('25.00');
  }

  test('starts empty, adding by name, and not submittable', () {
    final formData = cubit.state.formData;
    expect(formData.selectedMedicine, isNull);
    expect(formData.isManualEntry, isTrue);
    expect(formData.canSubmit, isFalse);
  });

  group('categories', () {
    test('loadCategories fills the list', () async {
      await cubit.loadCategories();

      final formData = cubit.state.formData;
      expect(formData.categories, _categories);
      expect(formData.isLoadingCategories, isFalse);
      expect(formData.categoriesError, isNull);
    });

    test('a failed load surfaces the message and a retry clears it', () async {
      categoryRepository.result = const ApiError(NetworkFailure('تعذر الاتصال بالخادم'));
      await cubit.loadCategories();
      expect(cubit.state.formData.categoriesError, 'تعذر الاتصال بالخادم');
      expect(cubit.state.formData.categories, isEmpty);

      categoryRepository.result = const Success(_categories);
      await cubit.loadCategories();
      expect(cubit.state.formData.categoriesError, isNull);
      expect(cubit.state.formData.categories, _categories);
    });

    test('categorySelected stores the id', () {
      cubit.categorySelected(4);

      expect(cubit.state.formData.categoryId, 4);
    });
  });

  group('search (the second page)', () {
    test('search returns the catalog matches', () async {
      await cubit.search('pan');

      final formData = cubit.state.formData;
      expect(formData.suggestions, [_catalogItem]);
      expect(formData.hasSearched, isTrue);
      expect(formData.isSearching, isFalse);
    });

    test('a query shorter than two characters is refused, not searched', () async {
      await cubit.search(' p ');

      final formData = cubit.state.formData;
      expect(formData.suggestions, isEmpty);
      expect(formData.hasSearched, isFalse);
      expect(formData.searchError, isNotNull);
    });

    test('a failed search surfaces the message instead of looking like no results', () async {
      repository.searchResult = const ApiError(NetworkFailure('تعذر الاتصال بالخادم'));

      await cubit.search('pan');

      final formData = cubit.state.formData;
      expect(formData.suggestions, isEmpty);
      expect(formData.searchError, 'تعذر الاتصال بالخادم');
    });

    test('a new search clears the previous error', () async {
      repository.searchResult = const ApiError(NetworkFailure('تعذر الاتصال بالخادم'));
      await cubit.search('pan');
      expect(cubit.state.formData.searchError, isNotNull);

      repository.searchResult = const Success([_catalogItem]);
      await cubit.search('pan');

      expect(cubit.state.formData.searchError, isNull);
    });

    test('searchReset forgets the last results', () async {
      await cubit.search('pan');

      cubit.searchReset();

      final formData = cubit.state.formData;
      expect(formData.suggestions, isEmpty);
      expect(formData.hasSearched, isFalse);
    });

    test('picking a medicine while a search is in flight discards its stale result', () async {
      final gate = Completer<void>();
      repository.searchGate = gate;

      final search = cubit.search('pan');
      cubit.medicineSelected(_catalogItem);
      gate.complete();
      await search;

      final formData = cubit.state.formData;
      expect(formData.selectedMedicine, _catalogItem);
      expect(formData.suggestions, isEmpty);
    });

    test('a reset while a search is in flight discards its stale result', () async {
      final gate = Completer<void>();
      repository.searchGate = gate;

      final search = cubit.search('pan');
      cubit.searchReset();
      gate.complete();
      await search;

      expect(cubit.state.formData.suggestions, isEmpty);
      expect(cubit.state.formData.isSearching, isFalse);
    });
  });

  group('picking from the catalog', () {
    test('medicineSelected fills the form and clears the results', () async {
      await cubit.search('pan');

      cubit.medicineSelected(_catalogItem);

      final formData = cubit.state.formData;
      expect(formData.selectedMedicine, _catalogItem);
      expect(formData.isManualEntry, isFalse);
      expect(formData.nameQuery, 'Panadol');
      expect(formData.activeIngredient, 'Paracetamol 500mg');
      expect(formData.suggestions, isEmpty);
    });

    test('selectionCleared empties what the pick filled and goes back to adding by name', () {
      cubit.medicineSelected(_catalogItem);

      cubit.selectionCleared();

      final formData = cubit.state.formData;
      expect(formData.selectedMedicine, isNull);
      expect(formData.isManualEntry, isTrue);
      expect(formData.nameQuery, isEmpty);
      expect(formData.activeIngredient, isEmpty);
    });

    test('a picked medicine needs no category to be submitted', () {
      cubit.medicineSelected(_catalogItem);
      expect(cubit.state.formData.canSubmit, isFalse);

      fillStock();

      expect(cubit.state.formData.canSubmit, isTrue);
    });

    test('canSubmit is false for a non-numeric or non-positive quantity', () {
      cubit.medicineSelected(_catalogItem);
      cubit.priceChanged('25.00');

      cubit.quantityChanged('abc');
      expect(cubit.state.formData.canSubmit, isFalse);

      cubit.quantityChanged('0');
      expect(cubit.state.formData.canSubmit, isFalse);

      cubit.quantityChanged('20');
      expect(cubit.state.formData.canSubmit, isTrue);
    });

    test('isAvailable defaults to true and is sent as entered', () async {
      expect(cubit.state.formData.isAvailable, isTrue);

      cubit.medicineSelected(_catalogItem);
      fillStock();
      cubit.isAvailableChanged(false);

      await cubit.save();

      expect(repository.lastIsAvailable, isFalse);
    });

    test('save sends medicine_id for a general-catalog selection', () async {
      cubit.medicineSelected(_catalogItem); // type: 'medicine' (general catalog)
      fillStock();

      await cubit.save();

      expect(cubit.state, isA<AddMedicineSuccess>());
      expect(repository.lastMedicineId, 5);
      expect(repository.lastMohMedicineId, isNull);
    });

    test('save sends moh_medicine_id for a Ministry of Health selection', () async {
      cubit.medicineSelected(_mohCatalogItem);
      fillStock();

      await cubit.save();

      expect(cubit.state, isA<AddMedicineSuccess>());
      expect(repository.lastMedicineId, isNull);
      expect(repository.lastMohMedicineId, 21);
    });

    test('save sends the stock and the uploaded image url and emits success', () async {
      cubit.medicineSelected(_catalogItem);
      fillStock();
      await cubit.imageSelected(File('medicine.jpg'));

      await cubit.save();

      expect(cubit.state, isA<AddMedicineSuccess>());
      expect(repository.lastPrice, 25.0);
      expect(repository.lastQuantity, 20);
      expect(repository.lastImageUrl, 'https://res.cloudinary.com/demo/image/upload/a.jpg');
    });

    test('save works without a photo — image is optional', () async {
      cubit.medicineSelected(_catalogItem);
      fillStock();

      await cubit.save();

      expect(cubit.state, isA<AddMedicineSuccess>());
      expect(repository.lastImageUrl, isNull);
    });

    test('save surfaces a repository failure', () async {
      cubit.medicineSelected(_catalogItem);
      fillStock();
      repository.addResult = const ApiError(ApiFailure(message: 'فشل الحفظ'));

      await cubit.save();

      final state = cubit.state as AddMedicineFailure;
      expect(state.message, 'فشل الحفظ');
    });
  });

  test('save does nothing when the form is incomplete', () async {
    await cubit.save();

    expect(repository.lastMedicineId, isNull);
    expect(repository.lastTradeName, isNull);
    expect(cubit.state, isA<AddMedicineEditing>());
  });

  group('image', () {
    test('imageSelected uploads to Cloudinary and stores the resulting url', () async {
      await cubit.imageSelected(File('medicine.jpg'));

      final formData = cubit.state.formData;
      expect(formData.imageUrl, 'https://res.cloudinary.com/demo/image/upload/a.jpg');
      expect(formData.isUploadingImage, isFalse);
    });

    test('imageSelected surfaces an upload failure', () async {
      imageRepository.result = const ApiError(UnknownFailure('تعذر رفع الصورة'));

      await cubit.imageSelected(File('medicine.jpg'));

      final formData = cubit.state.formData;
      expect(formData.imageUrl, isNull);
      expect(formData.imageError, 'تعذر رفع الصورة');
    });

    test('canSubmit is false while an image upload is in flight', () async {
      final gate = Completer<void>();
      imageRepository.uploadGate = gate;
      cubit.medicineSelected(_catalogItem);
      fillStock();

      final uploadFuture = cubit.imageSelected(File('medicine.jpg'));
      expect(cubit.state.formData.canSubmit, isFalse);

      gate.complete();
      await uploadFuture;
      expect(cubit.state.formData.canSubmit, isTrue);
    });

    test('picking a second image while the first upload is in flight keeps the newer result',
        () async {
      final firstGate = Completer<void>();
      imageRepository.uploadGate = firstGate;
      final firstUpload = cubit.imageSelected(File('first.jpg'));

      // Second pick starts its own (already-resolved) upload before the first
      // one's gate opens.
      imageRepository
        ..uploadGate = null
        ..result = const Success('https://res.cloudinary.com/demo/image/upload/second.jpg');
      await cubit.imageSelected(File('second.jpg'));

      firstGate.complete();
      await firstUpload;

      expect(
        cubit.state.formData.imageUrl,
        'https://res.cloudinary.com/demo/image/upload/second.jpg',
      );
    });

    test('a failed re-upload does not leave the previous photo silently attached', () async {
      await cubit.imageSelected(File('first.jpg'));
      expect(cubit.state.formData.imageUrl, isNotNull);

      imageRepository.result = const ApiError(UnknownFailure('تعذر رفع الصورة'));
      await cubit.imageSelected(File('second.jpg'));

      final formData = cubit.state.formData;
      expect(formData.imageLocalPath, 'second.jpg');
      expect(formData.imageUrl, isNull);
      expect(formData.imageError, 'تعذر رفع الصورة');
    });
  });

  group('adding by name (POST /pharmacy/medicines/by-name)', () {
    test('canSubmit rejects an Arabic trade name (backend requires English)', () {
      cubit.nameChanged('بانادول');
      cubit.categorySelected(3);
      fillStock();

      expect(cubit.state.formData.nameHasArabicChars, isTrue);
      expect(cubit.state.formData.canSubmit, isFalse);
    });

    test('canSubmit needs the English name and a category, not name_ar or the ingredient', () {
      cubit.nameChanged('Some Unlisted Drug');
      fillStock();
      expect(cubit.state.formData.canSubmit, isFalse);

      cubit.categorySelected(3);
      expect(cubit.state.formData.canSubmit, isTrue);
    });

    test('save sends the names, the ingredient and the category', () async {
      cubit.nameChanged('Abod panadol');
      cubit.nameArChanged('بانادول أبو');
      cubit.activeIngredientChanged('Paracetamol');
      cubit.categorySelected(3);
      cubit.quantityChanged('40');
      cubit.priceChanged('12.5');

      await cubit.save();

      expect(cubit.state, isA<AddMedicineSuccess>());
      expect(repository.lastTradeName, 'Abod panadol');
      expect(repository.lastTradeNameAr, 'بانادول أبو');
      expect(repository.lastActiveIngredient, 'Paracetamol');
      expect(repository.lastCategoryId, 3);
      expect(repository.lastQuantity, 40);
      expect(repository.lastPrice, 12.5);
      // Must not also hit the by-ID endpoint.
      expect(repository.lastMedicineId, isNull);
      expect(repository.lastMohMedicineId, isNull);
    });

    test('save omits trade_name_ar/active_ingredient when left blank', () async {
      cubit.nameChanged('Abod panadol');
      cubit.categorySelected(3);
      fillStock();

      await cubit.save();

      expect(repository.lastTradeNameAr, isNull);
      expect(repository.lastActiveIngredient, isNull);
    });

    test('save surfaces a by-name repository failure', () async {
      cubit.nameChanged('Abod panadol');
      cubit.categorySelected(3);
      fillStock();
      repository.addByNameResult = const ApiError(ApiFailure(message: 'فشل الحفظ'));

      await cubit.save();

      final state = cubit.state as AddMedicineFailure;
      expect(state.message, 'فشل الحفظ');
    });
  });
}
