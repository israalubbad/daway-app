import 'dart:typed_data';

import 'package:daway_app/core/erroring/failure.dart';
import 'package:daway_app/core/helpers/api_result.dart';
import 'package:daway_app/features/auth/domain/entities/account_type.dart';
import 'package:daway_app/features/auth/domain/entities/user_session.dart';
import 'package:daway_app/features/auth/domain/repositories/session_repository.dart';
import 'package:daway_app/features/pharmacy/domain/entities/inventory_import_preview.dart';
import 'package:daway_app/features/pharmacy/domain/repositories/pharmacy_inventory_import_repository.dart';
import 'package:daway_app/features/pharmacy/domain/usecases/analyze_inventory_import_usecase.dart';
import 'package:daway_app/features/pharmacy/domain/usecases/cancel_inventory_import_usecase.dart';
import 'package:daway_app/features/pharmacy/domain/usecases/commit_inventory_import_usecase.dart';
import 'package:daway_app/features/pharmacy/domain/usecases/download_inventory_import_template_usecase.dart';
import 'package:daway_app/features/pharmacy/presentation/cubit/pharmacy_stock_import_cubit.dart';
import 'package:daway_app/features/pharmacy/presentation/cubit/pharmacy_stock_import_state.dart';
import 'package:flutter_test/flutter_test.dart';

const _preview = InventoryImportPreview(
  importId: 'uuid-7',
  totalCount: 128,
  newCount: 24,
  updatedCount: 104,
  errorCount: 0,
);
const _file = PickedStockFile(path: '/tmp/products.xlsx', name: 'products.xlsx', sizeBytes: 2048);

class _FakeImportRepository implements PharmacyInventoryImportRepository {
  ApiResult<InventoryImportPreview> previewResult = const Success(_preview);
  ApiResult<void> commitResult = const Success(null);
  String? lastFilePath;
  final List<String> committed = [];
  final List<String> cancelled = [];

  @override
  Future<ApiResult<InventoryImportPreview>> preview({
    required String token,
    required String filePath,
  }) async {
    lastFilePath = filePath;
    return previewResult;
  }

  @override
  Future<ApiResult<Uint8List>> downloadTemplate({required String token}) async =>
      Success(Uint8List.fromList([1, 2, 3]));

  @override
  Future<ApiResult<void>> commit({required String token, required String importId}) async {
    committed.add(importId);
    return commitResult;
  }

  @override
  Future<ApiResult<void>> cancel({required String token, required String importId}) async {
    cancelled.add(importId);
    return const Success(null);
  }
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
  late _FakeImportRepository repository;
  late PharmacyStockImportCubit cubit;

  setUp(() {
    repository = _FakeImportRepository();
    final session = _FakeSessionRepository();
    cubit = PharmacyStockImportCubit(
      AnalyzeInventoryImportUseCase(repository, session),
      CommitInventoryImportUseCase(repository, session),
      CancelInventoryImportUseCase(repository, session),
      DownloadInventoryImportTemplateUseCase(repository, session),
    );
  });

  tearDown(() => cubit.close());

  test('starts with no file', () {
    expect(cubit.state, isA<StockImportIdle>());
    expect(cubit.state.file, isNull);
  });

  test('analyze does nothing before a file is picked', () async {
    await cubit.analyze();

    expect(repository.lastFilePath, isNull);
    expect(cubit.state, isA<StockImportIdle>());
  });

  test('analyze uploads the picked file and holds the preview', () async {
    cubit.fileSelected(_file);

    await cubit.analyze();

    expect(repository.lastFilePath, '/tmp/products.xlsx');
    final state = cubit.state as StockImportAnalyzed;
    expect(state.preview, _preview);
    expect(state.file, _file);
  });

  test('a failed analysis goes back to the picked file with the message', () async {
    repository.previewResult = const ApiError(ApiFailure(message: 'ملف غير صالح'));
    cubit.fileSelected(_file);

    await cubit.analyze();

    final state = cubit.state as StockImportIdle;
    expect(state.message, 'ملف غير صالح');
    expect(state.file, _file);
  });

  test('update confirms the analysed import', () async {
    cubit.fileSelected(_file);
    await cubit.analyze();

    await cubit.update();

    expect(repository.committed, ['uuid-7']);
    expect(cubit.state, isA<StockImportUpdated>());
  });

  test('a failed update stays on the analysis with the message', () async {
    repository.commitResult = const ApiError(ApiFailure(message: 'فشل التحديث'));
    cubit.fileSelected(_file);
    await cubit.analyze();

    await cubit.update();

    final state = cubit.state as StockImportAnalyzed;
    expect(state.updateError, 'فشل التحديث');
    expect(state.preview, _preview);
  });

  test('update does nothing before the file is analysed', () async {
    cubit.fileSelected(_file);

    await cubit.update();

    expect(repository.committed, isEmpty);
  });

  test('replacing an analysed file cancels its import', () async {
    cubit.fileSelected(_file);
    await cubit.analyze();

    cubit.fileSelected(_file);
    await Future<void>.delayed(Duration.zero);

    expect(repository.cancelled, ['uuid-7']);
    expect(cubit.state, isA<StockImportIdle>());
  });
}
