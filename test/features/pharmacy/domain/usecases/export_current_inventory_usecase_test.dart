import 'package:daway_app/core/erroring/failure.dart';
import 'package:daway_app/core/helpers/api_result.dart';
import 'package:daway_app/features/auth/domain/entities/account_type.dart';
import 'package:daway_app/features/auth/domain/entities/user_session.dart';
import 'package:daway_app/features/auth/domain/repositories/session_repository.dart';
import 'package:daway_app/features/pharmacy/domain/entities/medicine.dart';
import 'package:daway_app/features/pharmacy/domain/repositories/pharmacy_medicine_repository.dart';
import 'package:daway_app/features/pharmacy/domain/usecases/export_current_inventory_usecase.dart';
import 'package:daway_app/features/pharmacy/domain/usecases/get_pharmacy_medicines_usecase.dart';
import 'package:excel/excel.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeMedicineRepository implements PharmacyMedicineRepository {
  ApiResult<List<Medicine>> result = const Success([
    Medicine(
      id: 1,
      medicineId: 10,
      name: 'Panadol',
      nameAr: 'بانادول',
      activeIngredient: 'Paracetamol',
      price: 12.5,
      quantity: 40,
      isAvailable: true,
    ),
    Medicine(id: 2, medicineId: 11, name: 'Adol', price: 8, quantity: 0, isAvailable: false),
  ]);

  @override
  Future<ApiResult<List<Medicine>>> getMedicines({required String token}) async => result;

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

class _FakeSessionRepository implements SessionRepository {
  @override
  Future<void> saveSession(UserSession session) async {}

  @override
  Future<UserSession?> getSession() async =>
      const UserSession(accountType: AccountType.pharmacy, token: 'tok-1');

  @override
  Future<void> clearSession() async {}
}

void main() {
  late _FakeMedicineRepository repository;
  late ExportCurrentInventoryUseCase useCase;

  setUp(() {
    repository = _FakeMedicineRepository();
    useCase = ExportCurrentInventoryUseCase(
      GetPharmacyMedicinesUseCase(repository, _FakeSessionRepository()),
    );
  });

  test('writes a header row and one row per medicine', () async {
    final result = await useCase();

    final bytes = (result as Success).data as List<int>;
    final excel = Excel.decodeBytes(bytes);
    final rows = excel.tables.values.first.rows
        .map((row) => row.map((cell) => cell?.value?.toString()).toList())
        .toList();

    expect(rows[0], ExportCurrentInventoryUseCase.headers);
    expect(rows[1], ['Panadol', 'بانادول', 'Paracetamol', '12.5', '40']);
    expect(rows[2].sublist(0, 2), ['Adol', '']);
    expect(rows.length, 3);
  });

  test('a failed load comes back as the failure', () async {
    repository.result = const ApiError(NetworkFailure('تعذر الاتصال بالخادم'));

    final result = await useCase();

    expect((result as ApiError).failure.message, 'تعذر الاتصال بالخادم');
  });
}
